require 'visit'
require 'image_dataset'
require 'net/ssh'
require 'net/sftp'
require 'open3'
require 'metamri'
require 'fileutils'
#require 'net/http'
#require 'net/https'
#require 'net/http/post/multipart'
#require 'json'  

class Shared  < ActionController::Base
  extend SharedHelper
  def self.adrc_sftp_username; adrc_sftp_user end
  def self.adrc_sftp_host_address; adrc_sftp_host end
  def self.adrc_sftp_password; adrc_sftp_pwd end
  def self.dom_sftp_host_address; dom_sftp_host end
  def self.panda_admin_sftp_username; panda_admin_sftp_user end
  def self.panda_admin_sftp_password; panda_admin_sftp_pwd end
  def self.panda_user_sftp_username; panda_user_sftp_user end
  def self.panda_user_sftp_password; panda_user_sftp_pwd end
  def self.antuano_target_path; antuano_target end
  def self.selley_target_path; selley_target end

  def self.booked_disconnect_user;booked_disconnect_user end
  def self.booked_disconnect_pwd; booked_disconnect_pwd end
  def self.booked_address_page; booked_address_page end
  def self.booked_address_base; booked_address_base end
  
  def test_return( p_var)
    return "BBBBBBAAAAAAAAAAAAA"+p_var
  end
  
  def apply_cg_edits(p_tn)
    connection = ActiveRecord::Base.connection();
    if !p_tn.include?('cg_')  
        v_tn = "cg_"+p_tn.gsub(/\./,'_')  # made for the fs aseg, lh.aparc.arae, rh.aprac.area
     else
       v_tn = p_tn
    end
    @cg_tns = CgTn.where(" tn = '"+v_tn+"'")
    @cg_tn = nil
    @cg_tns.each do |tns|
      if !tns.id.blank?
         @cg_tn = CgTn.find(tns.id)
      end
    end

    @cns = []
    @key_cns = []
    @v_key = []
    @cns_type_dict ={}
    @cns_common_name_dict = {}
    @cg_data_dict = {}
    @cg_edit_data_dict = {}

    @cg_tn_cns =CgTnCn.where("cg_tn_id in (?)",@cg_tn.id)
    @cg_tn_cns.each do |cg_tn_cn|
        @cns.push(cg_tn_cn.cn)
        @cns_common_name_dict[cg_tn_cn.cn] = cg_tn_cn.common_name
        if cg_tn_cn.key_column_flag == "Y"
          @key_cns.push(cg_tn_cn.cn)
        end 
        if !cg_tn_cn.data_type.blank?
          @cns_type_dict[cg_tn_cn.cn] = cg_tn_cn.data_type
        end
    end
    # apply cg_edit to cg_data and refresh cg_edit , same as above, but no key array
    sql = "SELECT "+@cns.join(',') +",delete_key_flag FROM "+@cg_tn.tn+"_edit" 
    @edit_results = connection.execute(sql)         
    @edit_results.each do |r|
        v_key_array = []
        v_cnt  = 0
        v_key =""
        v_delete_data_row="N"
        r.each do |rc| # make and save cn-value| key
          if @key_cns.include?(@cns[v_cnt]) # key column
            v_key = v_key+@cns[v_cnt] +"^"+rc.to_s+"|"
            v_key_array.push( @cns[v_cnt] +"='"+rc.to_s+"'")
          end
          v_cnt = v_cnt + 1
        end  
        if !v_key.blank? and !@v_key.include?(v_key) 
            @v_key.push(v_key)
        end
        # update cg_data
        v_cnt = 0
        v_col_value_array = []
        r.each do |rc|
          if !@key_cns.include?(@cns[v_cnt])
            # might need to int, to date, etc from datatype
            if @cns[v_cnt].blank?
             # v_col_value_array.push(" delete_key_flag ='"+rc.to_s+"' ")
               if rc.to_s == "Y"
                v_delete_data_row="Y"
              end
            else
                if rc.to_s != "|"
                    v_col_value_array.push(@cns[v_cnt]+"='"+rc.to_s.gsub(/'/, "''")+"' ")
                end
            end
          end               
          v_cnt = v_cnt + 1
        end
        if v_delete_data_row=="N"
            if v_col_value_array.size > 0
              sql = "update "+@cg_tn.tn+" set "+v_col_value_array.join(',')+" where "+v_key_array.join(" and ")
               @results = connection.execute(sql)
             end
        else
            sql = "delete from "+@cg_tn.tn+" where "+v_key_array.join(" and ")
             @results = connection.execute(sql)
        end        
    end
    
    
  end

  def check_ids_for_severe_or_incomplete( p_ids_id)
    v_ok_flag = "Y"  # defaulting to Y , no severe or incomplete
       v_idss = ImageDataset.where("image_datasets.id in (?)", p_ids_id).where("image_datasets.id in ( select image_dataset_quality_checks.image_dataset_id 
                       from image_dataset_quality_checks where image_dataset_quality_checks.image_dataset_id in (?) and  ( image_dataset_quality_checks.incomplete_series  = 'Incomplete'  
or   image_dataset_quality_checks.garbled_series  = 'Severe'  
or  image_dataset_quality_checks.fov_cutoff  = 'Severe'  
or  image_dataset_quality_checks.field_inhomogeneity  = 'Severe'   
or  image_dataset_quality_checks.ghosting_wrapping  = 'Severe' 
 or  image_dataset_quality_checks.banding  = 'Severe'  
or  image_dataset_quality_checks.registration_risk  = 'Severe'  
or  image_dataset_quality_checks.motion_warning  = 'Severe'  
or   image_dataset_quality_checks.omnibus_f  = 'Severe'  or  spm_mask  = 'Severe'))", p_ids_id)
     if !v_idss.nil? and !v_idss[0].nil?
         v_ok_flag = "N"
     end
     return v_ok_flag
  end
  
  def compare_file_header(p_standard_header,p_file_header)
    v_comment =""
    v_flag = "Y"
    if p_standard_header.gsub(/	/,"").gsub(/\n/,"") !=  p_file_header.gsub(/	/,"").gsub(/\n/,"")
      v_comment = "ERROR!!! file header  not match expected header \n"+p_standard_header+"\n"+p_file_header 
      v_flag = "N"              
    else
      #v_comment =" header matches expected."
    end
    return v_flag, v_comment
  end

  def get_age_at_appointment(p_visit_id)
     v_age_at_appointment = ""
     sql = "select distinct a.age_at_appointment from appointments a, visits v 
            where a.id = v.appointment_id and v.id =  "+p_visit_id.to_s
        connection = ActiveRecord::Base.connection();
        results =  connection.execute(sql)
        results.each do |a|
            v_age_at_appointment = a[0]
        end
     return   v_age_at_appointment
   end

  def get_lookup_refs_description ( p_label, p_value)
    v_return = ""
    if !p_value.blank?
        sql_val = "select lookup_refs.description from lookup_refs where label='"+ p_label+"' and ref_value in ("+p_value+")"
        connection = ActiveRecord::Base.connection();
        vals =  connection.execute(sql_val)
        val=[]
        vals.each do |v|
            val.push(v[0])
        end
        v_return = val.join(",")
     end
     return v_return   
  end
  
  def get_file_diff(p_script,p_script_dev,p_error_comment,p_comment)
      v_error_comment = p_error_comment
      v_comment = ""
      v_call = "diff "+p_script+" "+p_script_dev
      # check for differences between dev and production
      begin
         stdin, stdout, stderr = Open3.popen3(v_call)
       rescue => msg  
          v_error_comment = v_error_comment + msg+"\n"  
       end
       v_diff = "N"
       while !stdout.eof?
         v_diff = "Y"
         v_output = stdout.read 1024 
          v_comment = v_output + p_comment
       end
       if v_diff == "Y" 
               v_error_comment = v_error_comment + " There are differences between "+p_script+" and dev- "+p_script_dev
       end
       return v_error_comment,v_comment
  end
  
  def get_schedule_owner_email(p_schedule_id)
    v_email_array = ['noreply_johnson_lab@medicine.wisc.edu']
    @schedule = Schedule.find(p_schedule_id)
    (@schedule.users).each do |u|
      v_email_array.push(u.email)
    end
    return v_email_array    
  end  

  def get_enrollment_id_from_subjectid_v(p_subjectid_v)
        v_enrollment_id = nil
        v_subjectid_chop = (p_subjectid_v).gsub('_v2','').gsub('_v3','').gsub('_v4','').gsub('_v5','')
        v_enrollment = Enrollment.where("enumber in (?)",v_subjectid_chop)
        if !v_enrollment[0].nil? 
            v_enrollment_id = v_enrollment[0].id
        end    
    return v_enrollment_id
  end
  
  def get_sp_id_from_subjectid_v(p_subjectid_v)
    v_subjectid_chop = p_subjectid_v.gsub(/_v/,"").delete("0-9")
    v_visit_number = 1
    if p_subjectid_v.include?('_v2')
          v_visit_number = 2
    elsif p_subjectid_v.include?('_v3')
          v_visit_number = 3
    elsif p_subjectid_v.include?('_v4')
          v_visit_number = 4
    elsif p_subjectid_v.include?('_v5')
          v_visit_number = 5
    end
    if(v_subjectid_chop.include? "wscs")
       v_subjectid_chop = "wscs"  # they have another letter 
    end
    if v_visit_number > 1
      scan_procedures = ScanProcedure.where("subjectid_base ='"+v_subjectid_chop+"' and codename like '%visit"+v_visit_number.to_s+"'")
    else
      scan_procedures = ScanProcedure.where("subjectid_base ='"+v_subjectid_chop+"' and ( codename like '%visit"+v_visit_number.to_s+"' or codename not like '%visit%' )")
    end
    v_cnt = 0
    scan_procedures.each do |sp|
       v_cnt = v_cnt +1
    end
    if v_cnt > 1
      puts "MULTIPLE SP "+p_subjectid_v
    end
    if v_cnt < 1
        v_subjectid = p_subjectid_v.gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")

        scan_procedures = ScanProcedure.where("scan_procedures.id in 
          ( select spvg.scan_procedure_id from scan_procedures_vgroups spvg,enrollment_vgroup_memberships evgm, enrollments e
              where  spvg.vgroup_id = evgm.vgroup_id and e.id = evgm.enrollment_id and e.enumber ='"+v_subjectid+"' ) and codename like '%visit"+v_visit_number.to_s+"'")
        scan_procedures.each do |sp|
           v_cnt = v_cnt +1
        end
        if v_cnt > 1
            puts "MULTIPLE SP "+p_subjectid_v
        end
    end
    
    scan_procedures.each do |sp|
      # puts sp.codename+"= codename"
      return sp.id
    end
    
    return nil
  end


  def get_sp_visit_num_array
      connection = ActiveRecord::Base.connection();
      v_sp_visit1_array = []
      v_sp_visit2_array = []
      v_sp_visit3_array = []
      v_sp_visit4_array = []
      sql = "select id from scan_procedures where codename like '%visit2'"        
      results = connection.execute(sql)
      results.each do |r|
        v_sp_visit2_array.push(r[0])
      end      
      
      sql = "select id from scan_procedures where codename like '%visit3'"        
      results = connection.execute(sql)
      results.each do |r|
        v_sp_visit3_array.push(r[0])
      end
      
      sql = "select id from scan_procedures where codename like '%visit4'"        
      results = connection.execute(sql)
      results.each do |r|
        v_sp_visit4_array.push(r[0])
      end
      
      sql = "select id from scan_procedures where codename not like '%visit2' and  codename  not like '%visit3' and  codename  not like '%visit4'"        
      results = connection.execute(sql)
      results.each do |r|
        v_sp_visit1_array.push(r[0])
      end      
      return v_sp_visit1_array,v_sp_visit2_array,v_sp_visit3_array,v_sp_visit4_array
  end
  
  def get_user_email
    v_user = `echo $USER`
    v_user = v_user.gsub("\n","")
    v_email = nil
    if v_user == 'admin' or v_user == 'panda_admin' or v_user == 'panda_user'
       v_email = nil
     else       
       v_users = User.where("username='"+v_user+"'")
       v_email = v_users[0].email
      end
    return v_email
   end
  
  def get_vgroups_from_enumber_sp(p_subjectid,p_sp_array,p_subjectid_base)
             vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollments, enrollment_vgroup_memberships 
                         where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enumber in (?))
                         and vgroups.id in (select appointments.vgroup_id from appointments where appointment_type = 'mri' )
                        and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups,scan_procedures
                      where scan_procedures_vgroups.scan_procedure_id in (?)
                      and scan_procedures.id = scan_procedures_vgroups.scan_procedure_id 
                     and scan_procedures.subjectid_base in (?))", p_subjectid,p_sp_array,p_subjectid_base)                                                                               
           
     return vgroups
  end

  def make_schedule_process_stop_file(p_file_path)
    v_value = "stopping process"
    if File.file?(p_file_path)
         # not do anything?
    else
      f = File.open(p_file_path, 'w')
      f.write(v_value)
      f.close
    end
  end  
  
 def move_present_to_old_new_to_present(p_tn, p_colum_list,p_conditions,p_comment)
   v_comment = p_comment
   connection = ActiveRecord::Base.connection();
   # check move cg_ to cg_old
    sql = "select count(*) from "+p_tn+"_old"
    results_old = connection.execute(sql)
    
    sql = "select count(*) from "+p_tn
    results = connection.execute(sql)
    v_old_cnt = results_old.first.to_s.to_i
    v_present_cnt = results.first.to_s.to_i
    v_old_minus_present =v_old_cnt-v_present_cnt
    v_present_minus_old = v_present_cnt-v_old_cnt
    v_comment = "  v_present_cnt="+v_present_cnt.to_s+"   v_old_cnt="+v_old_cnt.to_s+"   "+v_comment
    if ( (v_old_minus_present <= 0   ) or ( v_old_cnt > 0 and  ( (v_present_cnt.to_f/v_old_cnt.to_f)>0.7  )   ) )
      sql =  "truncate table "+p_tn+"_old"
      results = connection.execute(sql)
      sql = "insert into "+p_tn+"_old select * from "+p_tn
      results = connection.execute(sql)
    else
      v_comment = "ERROR!!! The "+p_tn+"_old table has 30% more rows than the present "+p_tn+" \n Not truncating "+p_tn+"_old "+v_comment 
    end
    #  truncate cg_ and insert cg_new
    sql =  "truncate table "+p_tn+""
    results = connection.execute(sql)
    
    sql = "insert into "+p_tn+"("+p_colum_list+")
    select distinct "+p_colum_list+" from "+p_tn+"_new 
                                   where "+p_conditions
    results = connection.execute(sql)
   
   return v_comment
  end 
  
  
  def process_logs_delete_old( p_process_name, p_log_base)
    v_sec_day = 86400
    t = Time.now
    v_days_back_array = [100,130,160]
    v_days_back_array.each do |v_back|
      tback = t - (v_sec_day * v_back)
      v_log_path = p_log_base+p_process_name+"_"+tback.strftime("%Y%m")
      if File.file?(v_log_path)
         File.delete(v_log_path)
      end
    end
  end
  
  def process_log_append(p_log_path, p_value)
    v_value = p_value.gsub("^H"," ")
    if File.file?(p_log_path)
      f = File.open(p_log_path, 'a') 
      f.write(v_value) 
      f.close
    else
      f = File.open(p_log_path, 'w')
      f.write(v_value)
      f.close
    end
  end  

  def run_sftp
      v_username = Shared.adrc_sftp_username # get from shared helper
      v_passwrd = Shared.adrc_sftp_password   # get from shared helperwhich is not on github
      v_ip = Shared.adrc_sftp_host_address # get from shared helper
      v_source ="/Users/panda_user/upload_adrc/test_upload.txt"
      v_target ="/coho2/home/wisconsin/test_upload.txt"
      Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
           sftp.upload!(v_source, "test_upload.txt")
      end

      
      # need to run from merida as panda_admin/ panda_user-- adrc expects the ip address
    
  end
  
 # subset of adrc_upload -- just dti
   def run_adrc_dti  
     v_base_path = Shared.get_base_path()
      @schedule = Schedule.where("name in ('adrc_dti')").first
       @schedulerun = Schedulerun.new
       @schedulerun.schedule_id = @schedule.id
       @schedulerun.comment ="starting adrc_dti- MOVED TO SHARED_RETIRED"
       @schedulerun.save
       @schedulerun.start_time = @schedulerun.created_at
       @schedulerun.save
    end
 
   # subset of adrc_upload -- just pcvipr, asl raw, asl_fmap, pdmap
      def run_adrc_pcvipr  
        v_base_path = Shared.get_base_path()
        v_preprocessed_path = v_base_path+"/preprocessed/visits/"
         @schedule = Schedule.where("name in ('adrc_pcvipr')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting adrc_pcvipr   MOVED TO SHARED_RETIRED"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
      end
 
  
  def run_adrc_upload  
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('adrc_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting adrc_upload"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_computer = "merida"   # adrc expects merida ip address
    connection = ActiveRecord::Base.connection();
    sql = "truncate table cg_adrc_upload_new"       
    results = connection.execute(sql)
    sql = "insert into cg_adrc_upload_new(subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,status_comment,dir_list,  dti_sent_flag, dti_status_flag,  dti_dir_list ,  pcvipr_sent_flag,  pcvipr_status_flag,  pcvipr_dir_list ,
  wahlin_t1_asl_resting_sent_flag,  wahlin_t1_asl_resting_status_flag, wahlin_t1_asl_resting_dir_list ,xnat_sent_flag,  xnat_status_flag,  xnat_dir_list ) select subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,status_comment,dir_list, dti_sent_flag, dti_status_flag,  dti_dir_list ,  pcvipr_sent_flag,  pcvipr_status_flag,  pcvipr_dir_list ,
  wahlin_t1_asl_resting_sent_flag,  wahlin_t1_asl_resting_status_flag, wahlin_t1_asl_resting_dir_list ,xnat_sent_flag,  xnat_status_flag,  xnat_dir_list  from cg_adrc_upload "
    results = connection.execute(sql)
    # recruit new adrc scans ---   change 
    v_weeks_back = "2"
    sql = "select distinct enrollments.enumber from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups  where enrollments.enumber like 'adrc%' 
              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
              and scan_procedures_vgroups.vgroup_id = vgroups.id
              and scan_procedures_vgroups.scan_procedure_id = 22
              and vgroups.vgroup_date < DATE_SUB(curdate(), INTERVAL "+v_weeks_back+" WEEK)             
              and enrollments.enumber NOT IN ( select subjectid from cg_adrc_upload_new)
              and vgroups.transfer_mri ='yes'"
    results = connection.execute(sql)
    results.each do |r|
          enrollment = Enrollment.where("enumber in (?)",r[0])
          sql2 = "insert into cg_adrc_upload_new (subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,dti_sent_flag,dti_status_flag) values('"+r[0]+"','N','Y', "+enrollment[0].id.to_s+",22,'N','Y')"
          results2 = connection.execute(sql2)
    end
     # its going to grab ~70 -need to adjust v_weeks_back  to cover 2015-08-05
        sql = "select distinct enrollments.enumber from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups  where enrollments.enumber like 'adrc%' 
              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
              and scan_procedures_vgroups.vgroup_id = vgroups.id
              and scan_procedures_vgroups.scan_procedure_id = 65
              and vgroups.vgroup_date < DATE_SUB(curdate(), INTERVAL "+v_weeks_back+" WEEK)             
              and concat(enrollments.enumber,'_v2') NOT IN ( select subjectid from cg_adrc_upload_new)
              and vgroups.transfer_mri ='yes'"
    results = connection.execute(sql)
    results.each do |r|
          enrollment = Enrollment.where("enumber in (?)",r[0])
          sql2 = "insert into cg_adrc_upload_new (subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,dti_sent_flag,dti_status_flag) values('"+r[0]+"_v2','N','Y', "+enrollment[0].id.to_s+",65,'N','Y')"
          results2 = connection.execute(sql2)
    end   

        sql = "select distinct enrollments.enumber from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups  where enrollments.enumber like 'adrc%' 
              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
              and scan_procedures_vgroups.vgroup_id = vgroups.id
              and scan_procedures_vgroups.scan_procedure_id = 89
              and vgroups.vgroup_date < DATE_SUB(curdate(), INTERVAL "+v_weeks_back+" WEEK)             
              and concat(enrollments.enumber,'_v3') NOT IN ( select subjectid from cg_adrc_upload_new)
              and vgroups.transfer_mri ='yes'"
    results = connection.execute(sql)
    results.each do |r|
          enrollment = Enrollment.where("enumber in (?)",r[0])
          sql2 = "insert into cg_adrc_upload_new (subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,dti_sent_flag,dti_status_flag) values('"+r[0]+"_v3','N','Y', "+enrollment[0].id.to_s+",89,'N','Y')"
          results2 = connection.execute(sql2)
    end 



    v_comment = self.move_present_to_old_new_to_present("cg_adrc_upload",
    "subjectid, general_comment, sent_flag, sent_comment, status_flag, status_comment, dir_list,enrollment_id, scan_procedure_id,dti_sent_flag,dti_status_flag,dti_dir_list,  pcvipr_sent_flag,  pcvipr_status_flag,  pcvipr_dir_list ,
  wahlin_t1_asl_resting_sent_flag,  wahlin_t1_asl_resting_status_flag, wahlin_t1_asl_resting_dir_list ,xnat_sent_flag,  xnat_status_flag,  xnat_dir_list ",
                   "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)


    # apply edits  -- made into a function  in shared model
    self.apply_cg_edits('cg_adrc_upload')
    
    
    # get adrc subjectid to upload
    sql = "select distinct subjectid,scan_procedure_id from cg_adrc_upload where sent_flag ='N' and status_flag in ('Y','R') "
    results = connection.execute(sql)
    # changed to series_description_maps table
    v_folder_array = Array.new
    v_scan_desc_type_array = Array.new
    # check for dir in /tmp
    v_target_dir ="/tmp/adrc_upload"
    # v_target_dir ="/Volumes/Macintosh_HD2/adrc_upload"
    if !File.directory?(v_target_dir)
      v_call = "mkdir "+v_target_dir
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
    end
    v_comment = " :list of subjectid "+v_comment
    results.each do |r|
      v_comment = r[0]+","+v_comment
    end
    @schedulerun.comment =v_comment[0..1990]
    @schedulerun.save
    results.each do |r|
      v_comment = "strt "+r[0]+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      v_subjectid_chop = (r[0]).gsub('_v2','').gsub('_v3','').gsub('_v4','').gsub('_v5','')
      sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+v_subjectid_chop+"')
    and v.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg where spvg.scan_procedure_id = "+r[1].to_s+")"
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/adrc_upload/[subjectid]_YYYYMMDD_wisc
      v_subject_dir = r[0]+"_"+(results_vgroup.first)[0].to_s+"_wisc"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "mkdir "+v_parent_dir_target
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close 
      # T2 ==> ?EpiT2* ????  
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                  from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                  and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','T2','T2 Flair','T2_Flair','T2+Flair','DTI') 
                  and image_datasets.series_description != 'DTI whole brain  2mm FATSAT ASSET'
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+v_subjectid_chop+"')
              and vgroups.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg where spvg.scan_procedure_id = "+r[1].to_s+")
                   order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_folder_array = [] # how to empty
      v_scan_desc_type_array = []
      v_cnt = 1
      results_dataset.each do |r_dataset|
         v_ids_ok_flag = "Y"
         v_ids_id = r_dataset[2]
         v_ids_ok_flag = self.check_ids_for_severe_or_incomplete(v_ids_id)
         if v_ids_ok_flag == "Y" # no quality check severe or incomplete
            v_series_description_type = r_dataset[5].gsub(" ","_")
            if !v_scan_desc_type_array.include?(v_series_description_type)
                 v_scan_desc_type_array.push(v_series_description_type)
            end
            v_path = r_dataset[4]
            v_dir_array = v_path.split("/")
            v_dir = v_dir_array[(v_dir_array.size - 1)]
            v_dir_target = v_dir+"_"+v_series_description_type
            v_path = v_path.gsub("/Volumes/team/","").gsub("/Volumes/team-1/","").gsub("/Data/vtrak1/","")  #v_base_path+"/"+
            if v_folder_array.include?(v_dir_target)
              v_dir_target = v_dir_target+"_"+v_cnt.to_s
              v_cnt = v_cnt +1
              # might get weird if multiple types have dups - only expect T1/Bravo
            end
            v_folder_array.push(v_dir_target)
            FileUtils.cp_r(v_path,v_parent_dir_target+"/"+v_dir_target)  
             # had trouble with rsync failing in big directories
             v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"   
             #### trying to not use mise/dependencies   
             # v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
#puts "v_path = "+v_path
#puts "v_parent_dir_target = "+ v_parent_dir_target
#puts "v_dir_target="+v_dir_target
puts "AAAAAA "+v_call
             stdin, stdout, stderr = Open3.popen3(v_call)
              stderr.each {|line|
                  puts line
                }
                while !stdout.eof?
                  puts stdout.read 1024    
                 end
             stdin.close
             stdout.close
             stderr.close
             # temp - replace /Volumes/team/ and /Data/vtrak1/ with /Volumes/team-1 in dev
            # split on / --- get the last dir
            # make new dir name dir_series_description_type 
            # check if in v_folder_array , if in v_folder_array , dir_series_description_type => dir_series_description_type_2
            # add  dir, dir_series_description_type to v_folder_array
            # cp path ==> /tmp/adrc_upload/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
         end # skipping if qc severe or incomplete    
      end

      sql_status = "select status_flag from cg_adrc_upload where subjectid ='"+r[0]+"'"
      results_status = connection.execute(sql_status)
      # changing from 4 to 3 - DTI not going anymore
      if v_scan_desc_type_array.size < 2   and (results_status.first)[0] != "R"
    puts "bbbbb !R or not enough scan types "
        sql_dirlist = "update cg_adrc_upload set general_comment =' NOT ALL SCAN TYPES!!!! "+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' "
        results_dirlist = connection.execute(sql_dirlist)
        # send email 
        v_subject = "adrc_upload "+r[0]+" is missing some scan types --- set status_flag ='R' to send  : scans ="+v_folder_array.join(", ")
        v_email = "noreply_johnson_lab@medicine.wisc.edu"
        PandaMailer.schedule_notice(v_subject,{:send_to => v_email}).deliver

        # mail(
        #   :from => "noreply_johnson_lab@medicine.wisc.edu"
        #   :to => "noreply_johnson_lab@medicine.wisc.edu", 
        #   :subject => v_subject
        # )
        PandaMailer.schedule_notice(v_subject,{:send_to => "noreply_johnson_lab@medicine.wisc.edu"}).deliver
         v_comment_warning = v_comment_warning+"  "+v_scan_desc_type_array.size.to_s+" scan type "+r[0]
      v_call = "rm -rf "+v_parent_dir_target
# puts "BBBBBBBB "+v_call
      stdin, stdout, stderr = Open3.popen3(v_call)
      stderr.each {|line|
           puts line
      }
      while !stdout.eof?
        puts stdout.read 1024    
       end   
      stdin.close
      stdout.close
      stderr.close
      else
         puts "AAAAAAAAA DCM PATH TMP ="+v_parent_dir_target+"/*/*/*.dcm"
#         /tmp/adrc_upload/adrc00045_20130920_wisc/008_DTI/008

        sql_dirlist = "update cg_adrc_upload set dir_list ='"+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' "
        results_dirlist = connection.execute(sql_dirlist)
        if(File.exist?(v_parent_dir_target+'/*.yaml') )
          File.delete(v_parent_dir_target+'/*.yaml')
        end
        if(File.exist?(v_parent_dir_target+'/*/*.yaml') )
          File.delete(v_parent_dir_target+'/*/*.yaml')
        end
        if(File.exist?(v_parent_dir_target+'/*/*/*.yaml') )
          File.delete(v_parent_dir_target+'/*/*/*.yaml')
        end
        if(File.exist?(v_parent_dir_target+'/*/*/*/*.yaml') )
          File.delete(v_parent_dir_target+'/*/*/*/*.yaml')
        end
        if(File.exist?(v_parent_dir_target+'/*.json') )
          File.delete(v_parent_dir_target+'/*.json')
        end
        if(File.exist?(v_parent_dir_target+'/*/*.json') )
          File.delete(v_parent_dir_target+'/*/*.json')
        end
        if(File.exist?(v_parent_dir_target+'/*/*/*.json') )
          File.delete(v_parent_dir_target+'/*/*/*.json')
        end
        if(File.exist?(v_parent_dir_target+'/*/*/*/*.json') )
          File.delete(v_parent_dir_target+'/*/*/*/*.json')
        end
        if(File.exist?(v_parent_dir_target+'/*.pickle') )
          File.delete(v_parent_dir_target+'/*.pickle')
        end
        if(File.exist?(v_parent_dir_target+'/*/*.pickle') )
          File.delete(v_parent_dir_target+'/*/*.pickle')
        end
        if(File.exist?(v_parent_dir_target+'/*/*/*.pickle') )
          File.delete(v_parent_dir_target+'/*/*/*.pickle')
        end
        if(File.exist?(v_parent_dir_target+'/*/*/*/*.pickle') )
          File.delete(v_parent_dir_target+'/*/*/*/*.pickle')
        end
# TURN INTO A LOOP
        v_dicom_field_array =['0010,0030','0010,0010','0008,0050','0008,1030','0010,0020','0040,0254','0008,0080','0008,1010','0009,1002','0009,1030','0018,1000',
                        '0025,101A','0040,0242','0040,0243']
        v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name','0008,0050'=>'Accession Number',
                           '0008,1030'=>'Study Description', '0010,0020'=>'Patient ID','0040,0254'=>'Performed Proc Step Desc',
                            '0008,0080'=>'Institution Name','0008,1010'=>'Station Name','0009,1002'=>'Private',
                            '0009,1030'=>'Private','0018,1000'=>'Device Serial Number','0025,101A'=>'Private',
                            '0040,0242'=>'Performed Station Name','0040,0243'=>'Performed Location'}
     ####  v_dicom_field_array.each do |dicom_key|
               Dir.glob(v_parent_dir_target+'/*/*/*.dcm').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                     v_dicom_field_array.each do |dicom_key|
                                                                                           if !d[dicom_key].nil? 
                                                                                                 d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                      end }
              Dir.glob(v_parent_dir_target+'/*/*/*.0*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
              Dir.glob(v_parent_dir_target+'/*/*/*.1*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
              Dir.glob(v_parent_dir_target+'/*/*/*.2*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
              Dir.glob(v_parent_dir_target+'/*/*/*.3*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
                                                                                                
       ####  end                            
                                    
#                             
# # #puts "bbbbb dicom clean "+v_parent_dir_target+"/*/"
# Dir.glob(v_parent_dir_target+'/*/*/*.dcm').each {|dcm| puts d = DICOM::DObject.read(dcm); if !d["0010,0030"].nil? 
#                                                                                           d["0010,0030"].value = "DOB"; d.write(dcm) 
#                                                                                               end } 
        v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_adrc/"    #+v_subject_dir
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
                                                                           
        #v_call = "zip -r "+v_target_dir+"/"+v_subject_dir+".zip  "+v_parent_dir_target
        #v_call = "cd "+v_target_dir+"; zip -r "+v_subject_dir+"  "+v_subject_dir   #  ???????    PROBLEM HERE????
        #v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
        v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "  tar  -C /home/panda_user/upload_adrc  -zcf /home/panda_user/upload_adrc/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
        puts "bbbbbbb "+v_call

        v_call = ' rm -rf '+v_target_dir+'/'+v_subject_dir
           stdin, stdout, stderr = Open3.popen3(v_call)
           while !stdout.eof?
             puts stdout.read 1024    
            end
           stdin.close
           stdout.close
           stderr.close
        # 
        v_call = 'ssh panda_user@"+v_computer+".dom.wisc.edu " rm -rf /home/panda_user/upload_adrc/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on "+v_computer+" to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_adrc
         v_call = "rsync -av panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_adrc/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close

        # sftp -- shared helper hasthe username /password and address
        v_username = Shared.adrc_sftp_username # get from shared helper
        v_passwrd = Shared.adrc_sftp_password   # get from shared helperwhich is not on github
        v_ip = Shared.adrc_sftp_host_address # get from shared helper
        v_source = v_target_dir+'/'+v_subject_dir+".tar.gz"
        v_target = v_subject_dir+".tar.gz"
       v_comment = " BEFORE SFTP "+v_comment 
       @schedulerun.comment = v_comment[0..1990]+@schedulerun.comment
       @schedulerun.save 

# problems with locking up with NACC new sftp server 20150806
#        Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
#            sftp.upload!(v_source, v_target)
#        end
# trying Net::SSH

#still problem
#Rails.logger.info("Creating SFTP connection")
#session=Net::SSH.start(v_ip,v_username, :password=>v_passwrd,:port=>22)
#sftp=Net::SFTP::Session.new(session).connect!
#Rails.logger.info("SFTP Connection created, uploading files.")
#sftp.upload!(v_source, v_target)
#Rails.logger.info("First file uploaded.")
#Rails.logger.info("Connection terminated.")
       # sftp_adrc_uplod.py  keeps calling sftp_adrc_uplod.sh until the uploaded file size is right
       # then it move file to /home/panda_user/upload_adrc/sent
       v_call_sftp = 'ssh panda_user@'+v_computer+'.dom.wisc.edu "/home/panda_user/upload_adrc/sftp_adrc_upload.py" '
        stdin, stdout, stderr = Open3.popen3(v_call_sftp)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close 

        # need to check that file is uploaded/moved to /sent
        v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu "ls /home/panda_user/upload_adrc/'+v_subject_dir+'.tar.gz"'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
           v_return = stdout.read 1024  
           #v_return_array = v_return.split(' ')
           if v_return.include?("No such file or directory") 
              @schedulerun.comment = " ERROR in sftp "+@schedulerun.comment
              @schedulerun.save
              v_comment_warning = " ERROR in sftp " +v_comment_warning
           end  
         end
        stdin.close
        stdout.close
        stderr.close  

        v_comment = " AFTER SFTP "+v_comment 
       @schedulerun.comment = v_comment[0..1990]+@schedulerun.comment
       @schedulerun.save 

# WANT TO CHECK TRANSFERS
        v_call = " rm -rf "+v_target_dir+"/"+v_subject_dir+".tar.gz"
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close        
        
        sql_sent = "update cg_adrc_upload set sent_flag ='Y' where subjectid ='"+r[0]+"' "
        results_sent = connection.execute(sql_sent)
      end
      v_comment = "end "+r[0]+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save 
    end
              
    @schedulerun.comment =("successful finish adrc_upload "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
       @schedulerun.status_flag ="Y"
     end
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save          
      
    
  end

def run_batch_visit_import

  v_log_base ="/mounts/data/preprocessed/logs/"
      v_process_name = "batch_visit_import"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('batch_visit_import')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting batch_visit_import"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
    connection = ActiveRecord::Base.connection();

    v_current_user = User.find("30")
   # = Shared.get_base_path()
    v_base_path = "/mounts/data/raw/ADNI-2/mri/"
    #v_scan_procedure_id = "49"
    v_scan_procedure = ScanProcedure.find(49)
    v_dir_array = ["099_S_2146_4976_12072012","099_S_2146_6735_11042013","127_S_0112_4739_01182012","127_S_0112_5509_01232013","127_S_0112_936_01232014","127_S_0259_1154_04092014","127_S_0259_4898_04022012","127_S_0259_58_04192013","127_S_0260_1215_05082014","127_S_0260_4994_04262012","127_S_0260_64_04232013","127_S_0925_4562_11092011","127_S_0925_5368_11142012","127_S_0925_785_11132013","127_S_1032_4686_12152011","127_S_1032_5409_12042012","127_S_1032_835_12042013","127_S_1419_4252_08242011","127_S_1427_4232_08192011","127_S_1427_502_08192013","127_S_1427_5278_08152012","127_S_2213_3191_12012011","127_S_2213_4982_12102012","127_S_2213_6743_12172013","127_S_2234_3278_12192011","127_S_2234_5152_01252013","127_S_2234_6747_12182013","127_S_4148_3093_11092011","127_S_4148_3568_02162012","127_S_4148_4425_08302012","127_S_4148_6312_08152013","127_S_4197_2556_08222011","127_S_4197_3204_12052011","127_S_4197_3557_02152012","127_S_4197_4352_08142012","127_S_4197_6453_09102013","127_S_4198_2602_09012011","127_S_4198_3210_12062011","127_S_4198_3814_03282012","127_S_4198_4453_09062012","127_S_4198_6509_09242013","127_S_4210_2635_09082011","127_S_4210_3241_12122011","127_S_4210_3774_03222012","127_S_4210_4599_10012012","127_S_4240_2724_09232011","127_S_4240_3257_12142011","127_S_4240_3827_03292012","127_S_4240_4560_09252012","127_S_4240_6527_09272013","127_S_4240_6529_09272013","127_S_4301_2938_10242011","127_S_4301_3422_01242012","127_S_4301_4046_05102012","127_S_4301_4866_11082012","127_S_4301_6640_11192013","127_S_4500_3513_02082012","127_S_4500_4039_05092012","127_S_4500_4326_08082012","127_S_4500_5608_04112013","127_S_4500_6986_02182014","127_S_4604_3762_03212012","127_S_4604_4038_06142012","127_S_4604_4545_09202012","127_S_4604_5597_04102013","127_S_4604_7179_03262014","127_S_4624_3968_05312012","127_S_4624_4449_09052012","127_S_4624_4995_12122012","127_S_4624_6085_07082013","127_S_4645_3864_04042012","127_S_4645_4174_07092012","127_S_4645_4738_10192012","127_S_4645_5606_04112013","127_S_4645_7292_04172014","127_S_4749_3965_05312012","127_S_4765_4006_06082012","127_S_4765_4583_09272012","127_S_4765_4984_12102012","127_S_4765_6005_06192013","127_S_4765_7511_06122014","127_S_4843_4232_07182012","127_S_4843_4824_11012012","127_S_4843_6369_08262013","127_S_4844_4231_07182012","127_S_4844_4823_11012012","127_S_4844_6377_08272013","127_S_4928_4445_09052012","127_S_4928_5009_12142012","127_S_4928_5428_03142013","127_S_4928_6651_11202013","127_S_4940_4533_09192012","127_S_4940_5007_12142012","127_S_4940_5487_03252013","127_S_4940_6562_10032013","127_S_4992_4778_10252012","127_S_4992_5166_01282013","127_S_4992_5680_04252013","127_S_4992_6791_11112013","127_S_5028_4890_11142012","127_S_5028_5308_02202013","127_S_5028_5927_06052013","127_S_5028_6723_12122013","127_S_5028_6814_01132014","127_S_5056_5044_01032013","127_S_5056_5673_04242013","127_S_5056_6159_07222013","127_S_5056_6930_02062014","127_S_5058_5081_01102013","127_S_5058_5713_05012013","127_S_5058_6121_07152013","127_S_5067_5211_02042013","127_S_5067_5757_05072013","127_S_5067_6259_08052013","127_S_5095_5352_02272013","127_S_5095_5846_05212013","127_S_5095_6487_09172013","127_S_5095_7123_03172014","127_S_5132_5676_04252013","127_S_5132_6186_07252013","127_S_5132_7354_05012014","127_S_5168_5980_06142013","127_S_5185_6379_08272013","127_S_5200_5951_06102013","127_S_5200_6513_09242013","127_S_5218_6026_06242013","127_S_5228_6025_06242013","127_S_5266_6212_07302013"]
    #params[:raw_data_import] =""
    #params[:raw_data_import][:directory] = v_base_path+ v_dir
    #params[:raw_data_import][:scan_procedure] = v_scan_procedure
    #v_raw_data_import = RawDataImport.new
    #v_raw_data_import.create( directory:"/mounts/data/raw/ADNI-2/mri/127_S_5266_6212_07302013",scan_proceure:"49")
    # not sure how to specify controller raw_data_import which does not have a model
v_dir_array.each do |v_dir|
    # MAKING COPY OF RAW_DATA_IMPORTS_CONTROLLER.rb create
    @visit_directory_to_scan = (v_base_path + v_dir).chomp(' ')
if File.directory?(@visit_directory_to_scan)
      v = VisitRawDataDirectory.new(@visit_directory_to_scan, v_scan_procedure.codename )
      logger.info "Current User: #{Etc.getlogin}"
      logger.info  "+++ Importing #{v.visit_directory} as part of #{v.scan_procedure_name} +++"
       @schedulerun.comment = @schedulerun.comment + "Current User: #{Etc.getlogin}"
       @schedulerun.comment = @schedulerun.comment + "+++ Importing #{v.visit_directory} as part of #{v.scan_procedure_name} +++"
       @schedulerun.save

      begin
        v.scan
      rescue Exception => e
        v = nil
        #flash[:error] = "Awfully sorry, this raw data directory could not be scanned. #{e}"
        @schedulerun.comment = @schedulerun.comment +  "Awfully sorry, this raw data directory could not be scanned. #{e}"
        v_comment_warning = v_comment_warning +  "Awfully sorry, this raw data directory could not be scanned. #{e}"
        @schedulerun.save
      end
      unless v.nil?
        puts "GGGGGGGGGG before Visit.create_or_update_from_metamri"
        @visit = Visit.create_or_update_from_metamri(v, created_by = v_current_user)
        unless @visit.new_record?
          #flash[:notice] = "Sucessfully imported raw data directory."
          v_appointment = Appointment.find( @visit.appointment_id)
           v_vgroup = Vgroup.find(v_appointment.vgroup_id)
           v_vgroup.transfer_mri = "yes"
          v_vgroup.save
          v_dir_array = v_dir.split("_")
          v_enumber = v_dir_array[0]+"_"+v_dir_array[1]+"_"+v_dir_array[2]
          v_enrollments = Enrollment.where("enumber in (?)", v_enumber)
          if !v_enrollments[0].nil?
              v_enrollment = v_enrollments[0]
          else
           v_enrollment = Enrollment.new
          end

           v_enrollment.enumber= v_enumber
           v_enrollment.save
           sql = "insert into enrollment_vgroup_memberships(vgroup_id, enrollment_id) values("+v_vgroup.id.to_s+","+v_enrollment.id.to_s+")" 
           results = connection.execute(sql)

           sql = "insert into enrollment_visit_memberships(visit_id, enrollment_id) values("+@visit.id.to_s+","+v_enrollment.id.to_s+")"
           results = connection.execute(sql)
          @schedulerun.comment = @schedulerun.comment +  "Sucessfully imported raw data directory."
           @schedulerun.save
          
          
          begin
            PandaMailer.visit_confirmation(@visit, {:send_to => "noreply_johnson_lab@medicine.wisc.edu"}).deliver
            #flash[:notice] = flash[:notice].to_s + "; Email was succesfully sent."
            @schedulerun.comment = @schedulerun.comment + " Email was succesfully sent."
             @schedulerun.save
          rescue Errno::ECONNREFUSED, LoadError, OpenSSL::SSL::SSLError => load_error
            logger.info load_error
            #flash[:error] = "Sorry, your email was not delivered: " + load_error.to_s
            @schedulerun.comment = @schedulerun.comment + "Sorry, your email was not delivered: " + load_error.to_s
             @schedulerun.save
          rescue Timeout::Error => timeout_error
            logger.info timeout_error
            #flash[:error] = "Sorry, mail took too long to be delivered: " + timeout_error.to_s
            @schedulerun.comment = @schedulerun.comment + "Sorry, mail took too long to be delivered: " + timeout_error.to_s
             @schedulerun.save
          end
        else
          logger.info @visit.errors
           v_error_tmp =""
           @visit.errors.each do |r|
              v_error_tmp = v_error_tmp+" "+r.to_s
           end
           #flash[:error] = "Awfully sorry, this raw data directory could not be saved to the database. #{@visit.errors} @visit.errors="+v_error_tmp
           @schedulerun.comment = @schedulerun.comment + "Awfully sorry, this raw data directory could not be saved to the database. #{@visit.errors} @visit.errors="+v_error_tmp
           v_comment_warning = v_comment_warning  + "Awfully sorry, this raw data directory could not be saved to the database. #{@visit.errors} @visit.errors="+v_error_tmp
            @schedulerun.save
        end
      end
      puts "aaaaaa redirect_to root_url"
    else
      #flash[:error] = "Invalid raw data directory #{@visit_directory_to_scan}, please check your path and try again. Try running fixrights to cleanup permissions of directory."
      @schedulerun.comment = @schedulerun.comment +  "Invalid raw data directory #{@visit_directory_to_scan}, please check your path and try again. Try running fixrights to cleanup permissions of directory."
      v_comment_warning = v_comment_warning +"Invalid raw data directory #{@visit_directory_to_scan}, please check your path and try again. Try running fixrights to cleanup permissions of directory."
       @schedulerun.save
      puts " bbbbbbb redirect_to new_raw_data_import_path"
    end


    @schedulerun.comment =("successful finish batch_visit_import "+v_comment_warning+" "+@schedulerun.comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
end
end
   # backs up all the updates to all the question related tables
   # backup table need to be altered if the source tables are altered
  def run_change_log
    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "change_log"
   process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('change_log')").first
      v_runner_email = self.get_user_email()  #  want to send errors to the user running the process
      v_schedule_owner_email_array = []
      if !v_runner_email.blank?
        v_schedule_owner_email_array.push(v_runner_email)
      else
        v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
      end
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting change_log - If the source table has been altered, the target table also has to be altered!!!."
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      t = Time.now
      v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
      v_log_name =v_process_name+"_"+v_date_YM
      v_log_path =v_log_base+v_log_name 
    connection = ActiveRecord::Base.connection();
    @schedulerun.comment =@schedulerun.comment+" str q_data;"
    @schedulerun.save
    sql ="insert into change_log_q_data
    select * from q_data where updated_at > (select max(updated_at )   from change_log_q_data )"
    @results = connection.execute(sql)
    @schedulerun.comment =@schedulerun.comment+" str q_data_forms;"
    @schedulerun.save

    sql ="insert into change_log_q_data_forms
    select * from q_data_forms where updated_at > (select max(updated_at )     from change_log_q_data_forms )"
    @results = connection.execute(sql)
    @schedulerun.comment =@schedulerun.comment+" str question_scan_procedures;"
    @schedulerun.save
    sql ="insert into change_log_question_scan_procedures
    select * from question_scan_procedures where updated_at > (select max(updated_at )    from change_log_question_scan_procedures )"
    @results = connection.execute(sql)
    @schedulerun.comment =@schedulerun.comment+" str questionform_questions;"
    @schedulerun.save
    sql ="insert into change_log_questionform_questions
    select * from questionform_questions where updated_at > (select max(updated_at )   from change_log_questionform_questions )"
    @results = connection.execute(sql)
    @schedulerun.comment =@schedulerun.comment+" str questionform_scan_procedures;"
    @schedulerun.save
    sql ="insert into change_log_questionform_scan_procedures
    select * from questionform_scan_procedures where updated_at > (select max(updated_at )     from change_log_questionform_scan_procedures )"
    @results = connection.execute(sql)
    @schedulerun.comment =@schedulerun.comment+" str questionforms;"
    @schedulerun.save
    sql ="insert into change_log_questionforms
    select * from questionforms where updated_at > (select max(updated_at )    from change_log_questionforms )"
    @results = connection.execute(sql)
    @schedulerun.comment =@schedulerun.comment+" str questions;"
    @schedulerun.save
    sql ="insert into change_log_questions
    select * from questions where updated_at > (select max(updated_at )    from change_log_questions )"
    @results = connection.execute(sql)
    @schedulerun.comment =@schedulerun.comment+" str questionformnamesps;"
    @schedulerun.save
    sql ="insert into change_log_questionformnamesps
    select * from questionformnamesps where updated_at > (select max(updated_at )    from change_log_questionformnamesps )"
    @results = connection.execute(sql)
    @schedulerun.comment =@schedulerun.comment+" str lookup_refs;"
    @schedulerun.save
    sql ="insert into change_log_lookup_refs
    select * from lookup_refs where updated_at > (select max(updated_at )     from change_log_lookup_refs )"
    @results = connection.execute(sql)


    @schedulerun.comment =("successful finish change_log "+v_comment_warning+" "+@schedulerun.comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
  end

  def run_check_if_raw_dirs_exist
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('check_if_raw_dirs_exist')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting check_if_raw_dirs_exist"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.status_flag ="N"
      @schedulerun.save
      v_comment = "Missing dirs:"
      v_comment_warning ="" 
      v_process_name = 'check_if_raw_dirs_exist'
      v_missing_dir_array = ['/mounts/data/raw/bendlin.bfit.visit1/mri/bfit10011_1572_06052017','/mounts/data/raw/bendlin.adcp.visit1/mri/adcp2042_8626_09292017',
        '/mounts/data/raw/adcs.a4.v27/mri/A41270257B_3235_09062017','/mounts/data/raw/ADNI-2/mri/ADNI3_PHANTOM_1565_11012016',
        '/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015','/mounts/data/raw/peppard.sleepcohort.visit1/mri/wscsPT1001_8120_10152014',
        '/mounts/data/raw/peppard.sleepcohort.visit1/mri/wscsPT1002_8121_10152014','/mounts/data/raw/gleason.falls.visit1/fal00028_9602_01282010',
        '/mounts/data/raw/johnson.merit220.visit1/mrtP00002','/mounts/data/raw/johnson.merit220.visit1/mrtP00001','/mounts/data/raw/bendlin_WMAD/ge3T_750_scanner/wmadP003',
        '/mounts/data/raw/bendlin_WMAD/ge3T_750_scanner/wmadP002','/mounts/data/raw/bendlin_WMAD/ge3T_750_scanner/wmadpilot1',
        '/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/001','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/002',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/003','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/004',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/006','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/007',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/009','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/010',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/011','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/012',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/013','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/014',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/015','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/016',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/017','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/019',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/020','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/1000',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/1001','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/1600',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/700','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/vipr/012',
'/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/vipr/013','/mounts/data/raw/gallagher.lmpd.visit2/mri/TESTLMPDP00001_9261_07152015/vipr/014','/mounts/data/raw/bendlin.adcp.visit1/mri/adcp2024_8474_08142017/8474/5','/mounts/data/raw/bendlin.adcp.visit1/mri/adcp2024_8474_08142017/8474/6','/mounts/data/raw/bendlin.adcp.visit1/mri/adcp2024_8474_08142017/8474/7','/mounts/data/raw/bendlin.adcp.visit1/mri/adcp2024_8474_08142017/8474/8'] # the known bad ones
      @mri_visits = Visit.all
      @mri_visits.each do |v_mri_visit|
        v_path = v_mri_visit.path
        if  !v_path.nil? and v_path > '' and !v_missing_dir_array.include?(v_path)
          if File.directory?(v_path)
           # all good
          else
              v_comment = v_comment+"; "+v_path
          end
        end
      end
      @schedulerun.comment = v_comment
      if v_comment > "Missing dirs:" # send email set status = ""
          @schedulerun.status_flag ="E"
          v_comment = "ERROR "+v_comment
          v_subject = "New missing dirs in "+v_process_name+": "+v_comment
          v_email = "noreply_johnson_lab@medicine.wisc.edu"
          PandaMailer.schedule_notice(v_subject,{:send_to => v_email}).deliver
      end
    # check all the ids
    v_check_ids_flag = "Y"
    if v_check_ids_flag == "Y"
      v_comment_ids= ""
      @ids = ImageDataset.all
      @ids.each do |idset|
          v_path = idset.path
          #puts "checking="+v_path
          if  !v_path.nil? and v_path > '' and !v_missing_dir_array.include?(v_path)
            if File.directory?(v_path)
             # all good
            else
              v_comment_ids = v_comment_ids+"; ids="+v_path
              puts "ids not found="+v_path
            end
          end
      end
      @schedulerun.comment = v_comment_ids
      if v_comment_ids > "Missing ImageDataset dirs:" # send email set status = ""
          @schedulerun.status_flag ="E"
          v_comment = "ERROR "+v_comment_ids
          v_subject = "New missing IMAGE DATASET dirs in "+v_process_name+": "+v_comment_ids
          v_email = "noreply_johnson_lab@medicine.wisc.edu"
          PandaMailer.schedule_notice(v_subject,{:send_to => v_email}).deliver
      end  
    end
    # check all the processedimages
    v_check_processedimages_flag = "Y"
    if v_check_processedimages_flag == "Y"
      v_comment_processedimages= ""
      @processedimages = Processedimage.all
      @processedimages.each do |pi|
          v_path = pi.file_path
          #puts "checking="+v_path
          if  !v_path.nil? and v_path > '' and !v_missing_dir_array.include?(v_path)
            if File.file?(v_path) or File.directory?(v_path)
             # all good
              pi.exists_flag = 'Y'
              pi.save
            else
              v_comment_processedimages = v_comment_processedimages+"; pi="+v_path
              pi.exists_flag = 'N'
              pi.save
              puts "processedimage not found="+v_path
            end
          end
      end
      @schedulerun.comment = v_comment_processedimages+"; "+@schedulerun.comment 
    end

    @schedulerun.comment =("successful finish check_if_raw_dirs_exist "+v_comment_warning+" "+@schedulerun.comment[0..2990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
  end

  def run_fsl_first_volumes

    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "fsl_first_volumes"
    v_script_dev = v_base_path+"/data1/lab_scripts/first_labsetup.sh"
    v_script = v_base_path+"/SysAdmin/production/first_labsetup.sh"
    v_computer = "kanga"
    # only in dev
    v_script = v_script_dev
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('fsl_first_volumes')").first
      v_runner_email = self.get_user_email()  #  want to send errors to the user running the process
      v_schedule_owner_email_array = []
      if !v_runner_email.blank?
        v_schedule_owner_email_array.push(v_runner_email)
      else
        v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
      end
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting fsl_first_volumes"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_error_comment = ""
      v_secondary_key_array =["b","c","d","e",".R"]
      t = Time.now
      v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
      v_log_name =v_process_name+"_"+v_date_YM
      v_log_path =v_log_base+v_log_name 
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
    connection = ActiveRecord::Base.connection();
    v_comment_base = @schedulerun.comment
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"
    sp_exclude_array = [-1,62,53,54,55,56,57,15,19,17,30,6,13,11,12,32,35,25,23,8,48,16]   # old sp's
    @scan_procedures = ScanProcedure.where("scan_procedures.id not in (?)", sp_exclude_array)
    @scan_procedures.each do |sp|
        @schedulerun.comment = "start "+sp.codename+" "+v_comment_base
        @schedulerun.save
        v_visit_number =""
        if sp.codename.include?("visit2")
            v_visit_number ="_v2"
        elsif sp.codename.include?("visit3")
            v_visit_number ="_v3"
        elsif sp.codename.include?("visit4")
            v_visit_number ="_v4"
        elsif sp.codename.include?("visit5")
            v_visit_number ="_v5"
        end   
        v_preprocessed_full_path = v_preprocessed_path+sp.codename  
        if File.directory?(v_preprocessed_full_path)
          sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups,  appointments, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+"  
                                    and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
          @results = connection.execute(sql_enum)
                                    
          @results.each do |r|
              enrollment = Enrollment.where("enumber='"+r[0]+"'")
              if !enrollment.blank?
                v_log = ""
                v_subjectid_path = v_preprocessed_full_path+"/"+enrollment[0].enumber
                v_subjectid = enrollment[0].enumber
                v_subjectid_v_num = enrollment[0].enumber + v_visit_number
                @schedulerun.comment = "start "+v_subjectid_v_num+" "+v_comment_base
                @schedulerun.save
                v_subjectid_unknown =v_subjectid_path+"/unknown"
                v_subjectid_array = []
                if File.directory?(v_subjectid_unknown)
                     v_subjectid_array.push(v_subjectid)
                 end
                 v_secondary_key_array.each do |k|
                    if File.directory?(v_subjectid_path+k+"/unknown")
                        v_subjectid_array.push((v_subjectid+k))
                    end
                 end
                v_subjectid_array = v_subjectid_array.uniq
                v_subjectid_array.each do |subj|
                  v_subjectid = subj
                  v_subjectid_v_num = subj + v_visit_number
                  v_subjectid_path = v_preprocessed_full_path+"/"+subj
                  v_subjectid_unknown =v_subjectid_path+"/unknown"
                  if File.directory?(v_subjectid_unknown)   # need to also look for [subjectid]b,c,d,.R
                    v_dir_array = Dir.entries(v_subjectid_unknown)
                    v_dir_array.each do |f|
                    if f.start_with?("o") and f.end_with?(".nii")
                        # check for first dir 
                        v_subjectid_first =v_subjectid_path+"/first"
                        if File.directory?(v_subjectid_first) or !File.directory?(v_subjectid_first)
                          if !File.file?(v_subjectid_first+"/"+v_subjectid+"_first_roi_vol.csv")
                            v_comment = "str "+v_subjectid_v_num+";"+v_comment  
                             v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "'  +v_script+' -p '+sp.codename+'  -b '+v_subjectid+'  "  ' 
                             v_log = v_log + v_call+"\n"
                             begin
                               stdin, stdout, stderr = Open3.popen3(v_call)
                               rescue => msg  
                                  v_log = v_log +"IN RESCUE ERROR " +msg+"\n" 
                             end
                             v_success ="N"
                             while !stdout.eof?
                                v_output = stdout.read 1024 
                                v_log = v_log + v_output  
                                if (v_log.tr("\n","")).include? "first_mult_bcorr"   # in log "BrStem_first.vtk to save"  # line wrapping? Done ==> Do\nne
                                  v_success ="Y"
                                  v_log = v_log + "SUCCESS !!!!!!!!! \n"
                                end
                                puts v_output  
                             end
                             v_err =""
                             v_log = v_log +"IN ERROR \n"
                             while !stderr.eof?
                               v_err = stderr.read 1024
                               v_log = v_log +v_err
                              end
                              if v_err > ""
                                 v_schedule_owner_email_array.each do |e|
                                    v_subject = "Error in "+v_process_name+": "+v_subjectid_v_num+ " see ==> "+v_log_path+" <== ALl the output from process is in the file."
                                    PandaMailer.schedule_notice(v_subject,{:send_to => e}).deliver
                                end
                              end
                   #           puts "err="+v_err
                              if v_success == "N"
                                 v_comment_warning = " "+ v_subjectid_v_num +"; "+v_comment_warning 
                                 v_log = "warning on "+ v_subjectid_v_num +"; "+v_log
                              end
                              process_log_append(v_log_path, v_log)
                          end
                        end
                    end
                   end 
                  end 
                end
              end
           end
        end
     end
    if v_comment_warning > ""
        v_comment_warning = "warning on "+v_comment_warning
    end
    @schedulerun.comment =("successful finish fsl_first_volumes "+v_comment_warning+" "+v_comment[0..3900])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
    
  end

    
  def run_generic_upload   # CHNAGE _STATUS_FLAG = Y !!!!!!!
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('generic_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting generic_upload"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning ="" 
     v_weeks_back = "2"  # cwant to give time for quality checks etc. 
    connection = ActiveRecord::Base.connection();
    # get from cg_generic_upload_config 
     v_wisc_siteid ="wisc" 
     v_scan_procedure_exclude =   [8,21,28,31,34,53,64,55,56,57,22,65,64,67,47,12,16]
     v_scan_procedures = [4,29,27,14,15,19,24,36,35,20,26,41,16,11,37,38,39,58,66]  
     v_pet_tracer_array = [1,2]  
     v_scan_type_limit = 1 
     v_series_desc_array =['T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','DTI','resting_fMRI'] # just t1,'T2','T2 Flair','T2_Flair','T2+Flair','ASL']
     v_series_desc_nii_hash = {'nothing'=>"Y"}    #{ 'T1 Volumetic'=>"Y",'T1 Volumetric'=>"Y",'T1+Volumetric'=>"Y",'T1_Volumetric'=>"Y",'T1'=>"Y"} 
     # doing recruitment outside this function
     v_generic_participant_tn = "cg_apoewrap_participants"
     v_generic_upload_tn = "cg_apoewrap_upload"  
     v_machine ="kanga" 

     # MAKE SURE panda_user is member of rvm group on machine 
     # sudo usermod -G rvm panda_user 
     v_run_status_flag = "R"
     v_generic_target_path = "/home/panda_user/upload_apoewrap/"+v_machine+"/" 
     v_generic_tmp_target_path = "/tmp/upload_apoewrap"
     v_stop_status_value ="NONE"

      #SFTP AND RM FLAGS   -- user name/password from helper
    # get from cg_generic_upload_config 
          sql = "select distinct value_group from cg_generic_upload_config where status_flag='Y'  and variable_name ='value_group'"  
     results = connection.execute(sql)  
     v_value_group = results.first[0]
    puts "value_group ="+v_value_group
    sql = "select variable_name, variable_value from cg_generic_upload_config where status_flag ='Y' and value_group ='"+v_value_group+"'"
     results = connection.execute(sql)
     results.each do |r|
puts " "+r[0]+"  ="+r[1]
        if(r[0] == "machine") # MAKE SURE IT PANDA_USER OIS MEMBER OF rvm GROUP
            v_machine =r[1]
        elsif(r[0] == "run_status_flag")
           v_run_status_flag =r[1]
           puts " v_run_status_flag="+v_run_status_flag
        elsif(r[0] == "generic_target_path")
           v_generic_target_path =r[1]
        elsif(r[0] == "generic_tmp_target_path")
           v_generic_tmp_target_path =r[1]
        elsif(r[0] == "generic_upload_tn")
           v_generic_upload_tn =r[1]
        elsif(r[0] == "generic_participant_tn")
              v_generic_participant_tn =r[1]  
        elsif(r[0] == "wisc_siteid")
            v_wisc_siteid =r[1] 
        elsif(r[0] == "scan_procedure_exclude")
            v_scan_procedure_exclude =r[1].split(",").map { |s| s.to_i }  
        elsif(r[0] == "scan_procedures")
            v_scan_procedures =r[1].split(",").map { |s| s.to_i }
        elsif(r[0] == "pet_tracer")
            v_pet_tracer_array =r[1].split(",").map { |s| s.to_i }
        elsif(r[0] == "scan_type_limit")
             v_scan_type_limit =r[1] 
        elsif(r[0] == "series_desc_array")
             v_series_desc_array =r[1].split(",")
        elsif(r[0] == "stop_status_value")
           v_stop_status_value =r[1]
        end
     end

    v_folder_array = Array.new
    v_scan_desc_type_array = Array.new
    # check for dir in /tmp   # still like doing thgings in /tmp, then rsync and rm 
    v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "cd /tmp; mkdir  '+v_generic_tmp_target_path+'"'
    stdin, stdout, stderr = Open3.popen3(v_call)
    while !stdout.eof?
      puts stdout.read 1024    
     end
    stdin.close
    stdout.close
    stderr.close
 
     #PET
    sql = "select distinct vgroup_id,export_id,enumbers from "+v_generic_upload_tn+" where pet_sent_flag ='N' and pet_status_flag in ('"+v_run_status_flag+"')
            and  vgroup_id in  ( select vg.id from vgroups vg,appointments a, petscans pet  
                         where transfer_pet ='yes' and vg.id = a.vgroup_id and a.id = pet.appointment_id and pet.lookup_pettracer_id in ("+v_pet_tracer_array.join(",")+"))" # ('Y','R') "
    results = connection.execute(sql)
    v_comment =  " ||| "+v_machine+" status_flag="+v_run_status_flag+"  stop="+v_stop_status_value+"||| "+v_comment
    v_comment = " :list of vgroupids"+v_comment
    results.each do |r|
      v_comment = r[0].to_s+","+v_comment
    end
    @schedulerun.comment =v_comment[0..1990]
    @schedulerun.save
    results.each do |r|
     sql_check = "select variable_name, variable_value from cg_generic_upload_config where status_flag ='Y' and value_group ='"+v_value_group+"' and variable_name ='stop_status_value'"
     results_check = connection.execute(sql_check)
     results_check.each do |r_check|
        if(r_check[0] == "stop_status_value")
           v_stop_status_value =r_check[1]
        end
     end

     if(v_stop_status_value != 'ALL' and v_stop_status_value != v_run_status_flag)
      v_vgroup_id = r[0].to_s
      v_export_id = v_wisc_siteid+r[1].to_s.rjust(6,padstr='0')
      v_comment = "strt "+v_vgroup_id+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
    
      sql_vgroup = "select round((DATEDIFF(max(v.vgroup_date),p.dob)/365.25),2) from vgroups v, participants p where 
                 v.participant_id = p.id
                and v.id = "+v_vgroup_id+" and v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e,scan_procedures_vgroups spvg where spvg.vgroup_id = evm.vgroup_id and 
                                                            evm.enrollment_id = e.id and  e.do_not_share_scans_flag ='N')"
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/padi_upload/[subjectid]_YYYYMMDD_wisc
      v_age = (results_vgroup.first)[0].to_s
      if v_age.gsub(/\./,"") > ""   # no age if enumber on do not share list
        v_subject_dir = v_export_id+"_"+v_age.gsub(/\./,"")+"_pet"
        v_parent_dir_target =v_generic_tmp_target_path+"/"+v_subject_dir
        v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "cd '+v_generic_tmp_target_path+'; mkdir  '+v_subject_dir+'"' 
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
        end
        stdin.close
        stdout.close
        stderr.close 
        sql_pet = "select distinct appointments.appointment_date, petscans.id petscan_id, petfiles.id petfile_id, lookup_pettracers.name, petfiles.path,petscans.lookup_pettracer_id
                  from vgroups , appointments, petscans, lookup_pettracers, petfiles  
                  where vgroups.transfer_pet = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = petscans.appointment_id and petscans.id = petfiles.petscan_id
                  and petscans.lookup_pettracer_id = lookup_pettracers.id
                  and petscans.lookup_pettracer_id in ("+v_pet_tracer_array.join(",")+") 
                  and vgroups.id  = "+v_vgroup_id+" 
                   order by appointments.appointment_date "
        results_pet = connection.execute(sql_pet)
        v_folder_array = [] # how to empty
        v_tracer_array = []
        v_cnt = 1
        results_pet.each do |r_dataset|
           v_subject_id = ""
           v_tracer = r_dataset[3].gsub(/ /,"_").gsub(/\[/,"_").gsub(/\]/,"_")
           if !v_tracer_array.include?(v_tracer)
                 v_tracer_array.push(v_tracer)
           end
           v_petfile_path = r_dataset[4]
           v_petfile_name = (r_dataset[4].split("/")).last
           v_pettracer_id = r_dataset[5]
           #/mounts/data/raw/johnson.pipr.visit1/pet/pipr00001_2ef_c95_de11.v
           v_enumbers_array = r[2].split(",")
           v_enumbers_array.each do |e|
               v_subject_id = e
               v_petfile_name = v_petfile_name.gsub(v_subject_id,v_export_id )
           end
           if  v_pet_tracer_array.include? v_pettracer_id
             v_petfile_target_name = v_tracer+"_"+v_petfile_name
             v_call ='ssh panda_user@'+v_machine+'.dom.wisc.edu " rsync -av '+v_petfile_path+' '+v_parent_dir_target+'/'+v_petfile_target_name+' "'             
             puts("this petid= "+v_pettracer_id.to_s )
             stdin, stdout, stderr = Open3.popen3(v_call)
             stderr.each {|line|
               puts line
             }
             while !stdout.eof?
                 puts stdout.read 1024    
             end
             stdin.close
             stdout.close
             stderr.close
           end
         end

         v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "rsync -av '+v_parent_dir_target+'  '+v_generic_target_path+'"'    #+v_subject_dir
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
         end
         stdin.close
         stdout.close
         stderr.close
#UP TO HERE                                                                          
        #v_call = "zip -r "+v_target_dir+"/"+v_subject_dir+".zip  "+v_parent_dir_target
        #v_call = "cd "+v_target_dir+"; zip -r "+v_subject_dir+"  "+v_subject_dir   #  ???????    PROBLEM HERE????
        #v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
        ## switch to zop for xnat 
        ## v_call =  'ssh panda_user@'+v_machine+'.dom.wisc.edu "  tar  -C /home/panda_user/upload_padi  -zcf /home/panda_user/upload_padi/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '

        #v_call =  'ssh panda_user@'+v_machine+'.dom.wisc.edu " cd '+v_generic_target_path+'; zip -r '+v_subject_dir+'.zip '+v_subject_dir+'  "  '      
         v_call =  'ssh panda_user@'+v_machine+'.dom.wisc.edu " cd '+v_generic_target_path+'; /bin/tar -zcf '+v_subject_dir+'.tar.gz '+v_subject_dir+'/  "  '      
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
         end
         stdin.close
         stdout.close
         stderr.close
         puts "bbbbbbb "+v_call

          v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "  rm -rf '+v_generic_tmp_target_path+'/'+v_subject_dir+'"'
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
             puts stdout.read 1024    
          end
          stdin.close
          stdout.close
          stderr.close
        # 
          v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "  rm -rf '+v_generic_target_path+'/'+v_subject_dir+'"' 
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
            puts stdout.read 1024    
          end
          stdin.close
          stdout.close
          stderr.close
       
        
         # did the tar.gz on "+v_computer+" to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_padi
 #        v_call = "rsync -av panda_user@"+v_machine+".dom.wisc.edu:/home/panda_user/upload_padi/"+v_subject_dir+".zip "+v_target_dir+'/'+v_subject_dir+".zip"
 #        stdin, stdout, stderr = Open3.popen3(v_call)
 #        while !stdout.eof?
 #          puts stdout.read 1024    
 #         end
 #        stdin.close
 #        stdout.close
 #        stderr.close

####        # sftp -- shared helper hasthe username /password and address
####        v_username = Shared.padi_sftp_username # get from shared helper
####        v_passwrd = Shared.padi_sftp_password   # get from shared helperwhich is not on github
####        v_ip = Shared.padi_sftp_host_address # get from shared helper
       # v_source = v_target_dir+'/'+v_subject_dir+".zip"
       # v_target = v_subject_dir+".zip"

 

####        Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
####            sftp.upload!(v_source, v_target)
####        end
# WANT TO CHECK TRANSFERS
 #       v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".zip"
 #       stdin, stdout, stderr = Open3.popen3(v_call)
 #       while !stdout.eof?
 #         puts stdout.read 1024    
 #        end
 #       stdin.close
 #       stdout.close
 #       stderr.close        
        
          sql_sent = "update "+v_generic_upload_tn+" set pet_sent_flag ='Y' where vgroup_id ='"+r[0].to_s+"'  "
          results_sent = connection.execute(sql_sent) 
        end # enumber in not share  
     end # stop_status_value
    end   
#MRI start
    # get  subjectid to upload    # USING v_run_status_flag AS LIMIT FOR EACH RUN
    #MRI  switching to appointment
    sql = "select distinct "+v_generic_upload_tn+".vgroup_id,export_id,appointments.id from "+v_generic_upload_tn+",appointments 
     where appointments.vgroup_id = "+v_generic_upload_tn+".vgroup_id and
            appointments.appointment_type = 'mri'
            and    mri_sent_flag ='N' and mri_status_flag in ('"+v_run_status_flag+"') 
            and "+v_generic_upload_tn+".vgroup_id  in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e,scan_procedures_vgroups spvg where spvg.vgroup_id = evm.vgroup_id and 
                                                            evm.enrollment_id = e.id  and e.do_not_share_scans_flag ='N')" # ('Y','R') "
    results = connection.execute(sql)
    v_comment =  " ||| "+v_machine+" status_flag="+v_run_status_flag+" ||| "+v_comment
    v_comment = " :list of vgroupid "+v_comment
    results.each do |r|
      v_comment = r[0].to_s+","+v_comment
    end
    @schedulerun.comment =v_comment[0..1990]
    @schedulerun.save
    v_past_vgroup_id = "0"
    v_cnt = 1
    results.each do |r|
     sql_check = "select variable_name, variable_value from cg_generic_upload_config where status_flag ='Y' and value_group ='"+v_value_group+"' and variable_name ='stop_status_value'"
     results_check = connection.execute(sql_check)
     results_check.each do |r_check|
        if(r_check[0] == "stop_status_value")
           v_stop_status_value =r_check[1]
        end
     end
     if(v_stop_status_value != 'ALL' and v_stop_status_value != v_run_status_flag)
      v_folder_array = [] # how to empty
      v_vgroup_id = r[0].to_s
      if v_vgroup_id  != v_past_vgroup_id
            v_past_vgroup_id = v_vgroup_id
            v_cnt = 1
      else
            v_cnt = v_cnt + 1
      end
      v_export_id  =v_wisc_siteid+r[1].to_s.rjust(6,padstr='0')
      v_appointment_id = r[2].to_s
      v_comment = "strt "+v_vgroup_id+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      # just using appt date
      sql_vgroup = "select round((DATEDIFF(a.appointment_date,p.dob)/365.25),2),
      round((DATEDIFF(v.vgroup_date,p.dob)/365.25),2),
      a.id from appointments a,vgroups v,participants p where v.id = "+v_vgroup_id+" 
                          and v.id = a.vgroup_id and a.id = "+v_appointment_id+"
                          and a.appointment_type = 'mri'
                          and v.participant_id = p.id
                           and v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e,scan_procedures_vgroups spvg where spvg.vgroup_id = evm.vgroup_id and 
                                                            evm.enrollment_id = e.id  and e.do_not_share_scans_flag ='N')"     
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/padi_upload/[subjectid]_YYYYMMDD_wisc
       # just using appt age "_"+(results_vgroup.first)[1].to_s+
      v_age = ((results_vgroup.first)[0].to_s).gsub(/\./,"")
      v_subject_dir = v_export_id+"_"+((results_vgroup.first)[0].to_s).gsub(/\./,"")+"_"+v_cnt.to_s+"_mri"
      v_parent_dir_target =v_generic_tmp_target_path+"/"+v_subject_dir
      v_call =  'ssh panda_user@'+v_machine+'.dom.wisc.edu "mkdir '+v_parent_dir_target+'"'
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close   
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                  from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                  and (image_datasets.do_not_share_scans_flag is NULL or image_datasets.do_not_share_scans_flag ='N')
                  and (image_datasets.lock_default_scan_flag != 'Y' or image_datasets.lock_default_scan_flag  is NULL)
                  and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('"+v_series_desc_array.join("','")+"') 
                  and image_datasets.series_description != 'DTI whole brain  2mm FATSAT ASSET'
                  and vgroups.id = "+v_vgroup_id+"  and appointments.id = "+v_appointment_id+"
                   order by appointments.appointment_date "

      results_dataset = connection.execute(sql_dataset)
      v_scan_desc_type_array = []
      v_cnt = 1
      v_this_dir_list_array =[]
      results_dataset.each do |r_dataset|
         v_ids_ok_flag = "Y"
         v_ids_id = r_dataset[2]
         v_ids_ok_flag = self.check_ids_for_severe_or_incomplete(v_ids_id) # ADD THE DO NOT SHARE
         if v_ids_ok_flag == "Y" # no quality check severe or incomplete
            v_series_description_type = r_dataset[5].gsub(" ","_")
            v_path = r_dataset[4]
            v_dir_array = v_path.split("/")
            v_dir = v_dir_array[(v_dir_array.size - 1)]
            v_dir_target = v_dir+"_"+v_series_description_type
            v_path = v_path.gsub("/Volumes/team/","").gsub("/Volumes/team-1/","").gsub("/Data/vtrak1/","")  #v_base_path+"/"+
            if v_folder_array.include?(v_dir_target)
              v_dir_target = v_dir_target+"_"+v_cnt.to_s
              v_cnt = v_cnt +1
              # might get weird if multiple types have dups - only expect T1/Bravo
            end
            v_folder_array.push(v_dir_target)
            v_nii_flag = "N"   
            #NOT SO SURE ABOUT THE NII
  ####          v_nii_file_name =  [subjectid]_[series_description /replace " " with -] , _[] , path- split / , last value]
            v_path_dir_array = r_dataset[4].split("/")
            #/mounts/data/raw/wrap140/wrp002_5938_03072008/001
            v_subject_vgroup_array = v_path_dir_array[4].split("_")
            v_subject_id = v_subject_vgroup_array[0]
            v_nii_file_name = v_subject_id+"_"+r_dataset[3].gsub(/ /,"-")+"_"+v_path_dir_array.last+".nii"
            v_nii_file_path = v_base_path+"/preprocessed/visits/"+v_path_dir_array[4].to_s+"/"+v_subject_id+"/unknown/"+v_nii_file_name

            if(v_series_desc_nii_hash[r_dataset[5]] == "Y")
                v_nii_flag = "Y"
                v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "rsync -av '+v_nii_file_path+' '+v_parent_dir_target+'/'+v_export_id+'_'+r_dataset[3].gsub(/ /,"-")+'_'+v_path_dir_array.last+'.nii "'                
                stdin, stdout, stderr = Open3.popen3(v_call)
                 stderr.each {|line|
                     puts line
                  }
                 while !stdout.eof?
                    puts stdout.read 1024    
                 end
                 stdin.close
                 stdout.close
                 stderr.close
            end
            if !v_scan_desc_type_array.include?(v_series_description_type)
                 v_scan_desc_type_array.push(v_series_description_type)
            end
              v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "rm -rf '+v_parent_dir_target+'/'+v_dir_target+' "' 
              stdin, stdout, stderr = Open3.popen3(v_call)
              stderr.each {|line|
                  puts line
                }
                while !stdout.eof?
                  puts stdout.read 1024    
                 end
             stdin.close
             stdout.close
             stderr.close 
             # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
             # v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work 
              v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "cp -r '+v_path+' '+v_parent_dir_target+'/'+v_dir_target+' "' 
              stdin, stdout, stderr = Open3.popen3(v_call)
              stderr.each {|line|
                  puts line
                }
                while !stdout.eof?
                  puts stdout.read 1024    
                 end
             stdin.close
             stdout.close
             stderr.close  

              v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "cd '+v_parent_dir_target+'/'+v_dir_target+'/;bunzip2 *.bz2 "' 
              stdin, stdout, stderr = Open3.popen3(v_call)
              stderr.each {|line|
                  puts line
                }
                while !stdout.eof?
                  puts stdout.read 1024    
                 end
             stdin.close
             stdout.close
             stderr.close

             v_delete_array = ["*.yaml","*/*.yaml","*/*/*.yaml","*.json","*/*.json","*/*/*.json","*.txt","*/*.txt","*/*/*.txt","*.pickle","*/*.pickle","*/*/*.pickle"] 
             v_delete_array.each do |v_match|
               v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "rm -rf  '+v_parent_dir_target+'/'+v_dir_target+'/'+v_match+' "' 
               stdin, stdout, stderr = Open3.popen3(v_call)
               stderr.each {|line|
                  puts line
                }
                while !stdout.eof?
                  puts stdout.read 1024    
                 end
               stdin.close
               stdout.close
               stderr.close 
              end

                         # CHECK if script works
           #####  
               v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "/mounts/data/SysAdmin/production/dicom_clean_replace.rb     '+v_parent_dir_target+'/'+v_dir_target+'  '+v_export_id+'  '+v_age+'"' 
               puts v_call
               stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                 puts stdout.read 1024    
              end
              while !stderr.eof?
                v_comment = "ERROR IN dicom_clean_replace.rb, "+v_comment
                 puts stderr.read 1024    
        
              end   
              stdin.close
              stdout.close
              stderr.close 
            

             
             # temp - replace /Volumes/team/ and /Data/vtrak1/ with /Volumes/team-1 in dev
            # split on / --- get the last dir
            # make new dir name dir_series_description_type 
            # check if in v_folder_array , if in v_folder_array , dir_series_description_type => dir_series_description_type_2
            # add  dir, dir_series_description_type to v_folder_array
            # cp path ==> /tmp/padi_upload/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
         end # skipping if qc severe or incomplete    
      end

      sql_status = "select mri_status_flag from "+v_generic_upload_tn+" where vgroup_id ='"+r[0].to_s+"' "
      results_status = connection.execute(sql_status)
      if v_scan_desc_type_array.size < v_scan_type_limit.to_i   and (results_status.first)[0] != "R"
        sql_dirlist = "update "+v_generic_upload_tn+" set general_comment =' NOT ALL SCAN TYPES!!!! "+v_folder_array.join(", ")+"' where vgroup_id ='"+r[0].to_s+"' "
        results_dirlist = connection.execute(sql_dirlist)
        # send email 
        v_subject = "generic_upload "+r[0].to_s+" is missing some scan types --- set mri_status_flag ='R' to send  : scans ="+v_folder_array.join(", ")
        v_email = "noreply_johnson_lab@medicine.wisc.edu"
        PandaMailer.schedule_notice(v_subject,{:send_to => v_email}).deliver
        #PandaMailer.schedule_notice(v_subject,{:send_to => "noreply_johnson_lab@medicine.wisc.edu"}).deliver
         v_comment_warning = v_comment_warning+"  "+v_scan_desc_type_array.size.to_s+" scan type "+r[0].to_s+" sp"+r[1].to_s
      v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu " rm -rf '+v_parent_dir_target+'"'
      stdin, stdout, stderr = Open3.popen3(v_call)
      stderr.each {|line|
           puts line
      }
      while !stdout.eof?
        puts stdout.read 1024    
       end   
      stdin.close
      stdout.close
      stderr.close
      else
#         puts "AAAAAAAAA DCM PATH TMP ="+v_parent_dir_target+"/*/*/*.dcm"
#         /tmp/padi_upload/adrc00045_20130920_wisc/008_DTI/008
        # concat on null = nulll
        sql_dirlist = "update "+v_generic_upload_tn+" set mri_dir_list =concat('"+v_folder_array.join(", ")+"',mri_dir_list) where vgroup_id ='"+r[0].to_s+"' "
        results_dirlist = connection.execute(sql_dirlist) 
             
     # CHECK if script works
     #####  

        v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu "/mounts/data/SysAdmin/production/dicom_clean_replace.rb     '+v_parent_dir_target+'  '+v_export_id+'  '+v_age+'"'
        puts v_call
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close

        v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu " rsync -av '+v_parent_dir_target+'  '+v_generic_target_path+'"'    #+v_subject_dir
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
                                                                           
        #v_call = "zip -r "+v_target_dir+"/"+v_subject_dir+".zip  "+v_parent_dir_target
        #v_call = "cd "+v_target_dir+"; zip -r "+v_subject_dir+"  "+v_subject_dir   #  ???????    PROBLEM HERE????
        #v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
        # switching to zip for xnat
        v_call =  'ssh panda_user@'+v_machine+'.dom.wisc.edu " cd '+v_generic_target_path+'; tar -zcf '+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
        #v_call =  'ssh panda_user@'+v_machine+'.dom.wisc.edu " cd /home/panda_user/upload_padi/; zip -r '+v_subject_dir+'.zip '+v_subject_dir+' "  '
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
        puts "bbbbbbb "+v_call

        v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu " rm -rf '+v_generic_target_path+'/'+v_subject_dir+'"'
           stdin, stdout, stderr = Open3.popen3(v_call)
           while !stdout.eof?
             puts stdout.read 1024    
            end
           stdin.close
           stdout.close
           stderr.close
        # 
        v_call = 'ssh panda_user@'+v_machine+'.dom.wisc.edu " rm -rf '+v_generic_tmp_target_path+'/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       

####        # sftp -- shared helper hasthe username /password and address
####        v_username = Shared.padi_sftp_username # get from shared helper
####        v_passwrd = Shared.padi_sftp_password   # get from shared helperwhich is not on github
####        v_ip = Shared.padi_sftp_host_address # get from shared helper
#        v_source = v_target_dir+'/'+v_subject_dir+".zip"
#        v_target = v_subject_dir+".tar.gz"

 

####        Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
####            sftp.upload!(v_source, v_target)
####        end
# WANT TO CHECK TRANSFERS
#        v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".tar.gz"
#        stdin, stdout, stderr = Open3.popen3(v_call)
#        while !stdout.eof?
#          puts stdout.read 1024    
#         end
#        stdin.close
#        stdout.close
#        stderr.close        
        sql_sent = "update "+v_generic_upload_tn+" set mri_sent_flag ='Y', mri_dir_list ='"+v_folder_array.join(", ")+"' where vgroup_id ='"+r[0].to_s+"'  "
        results_sent = connection.execute(sql_sent)
       end #stop_status_value
      end
      v_comment = "end "+r[0].to_s+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save 
    end
              
    @schedulerun.comment =("successful finish generic_upload "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
       @schedulerun.status_flag ="Y"
     end
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save          
      

#MRI end
  end

  def run_padi_dvr_acpc_ids
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('padi_dvr_acpc_ids')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting padi_dvr_acpc_ids -MOVED TO SHARED_RETIRED.rb"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
  
  end
 
 # uses t_padi_dvr_20170215  as driver table  ==> populated by run_padi_dvr_acpc_ids
 # wash U wants dicom, penn wants nifties
 # curated set by Jen pib/flair and bravo/mpnrage
 #The naming convention is site (P0#), subject number (####), modality (MR/PIB), and visit (v01).
 #wisc = 4
 def run_padi_upload_20170227_dicom()
      run_padi_upload_20170227("dicom")
 end 
 def run_padi_upload_20170227_nifty()
      run_padi_upload_20170227("nifty")
 end 
  def run_padi_upload_20170227(p_dicom_nifty) # CHNAGE _STATUS_FLAG = Y !!!!!!!  ## add mri_visit_number????
    v_base_path = Shared.get_base_path()
      v_schedulerun_name = "padi_upload_20170227_"+p_dicom_nifty
     @schedule = Schedule.where("name in (?)",v_schedulerun_name).first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting padi_upload_20170227 MOVED TO SHARED_RETIRE.rb"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
    
  end


  # for the scan share consortium - upload to padi
  def run_padi_upload   # CHNAGE _STATUS_FLAG = Y !!!!!!!  ## add mri_visit_number????
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('padi_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting padi_upload -MOVED TO SHARED_RETIRED"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
    
  end


def  run_pet_mk6240_harvest
      v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('pet_mk6240_harvest')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting pet_mk6240_harvest"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning ="" 
      v_comment_base = ""
      v_shared = Shared.new
      connection = ActiveRecord::Base.connection();
      v_mk6240_tracer_id = "11"
      # truncate cg table new 
      v_cg_tn_roi = "cg_pet_mk6240_roi"
      v_cg_tn_roi_atlas_tjb_mni_v1 = "cg_pet_mk6240_roi_atlas_tjb_mni_v1"
      v_aal_atlas = "aal_MNI_V4"
      v_tjb_mni_v1 = "tjb_MNI_V1"
      # ALSO A SECOND TABLE WITH A DIFFERENT ATLAS -- keeping columns same in both tables
      # ADD AS SINMGLE COLUMN ["Region","Atlas"]
      # CHANGE LOOP THRU ALL roi ROWS - make Key of suvr_+lower(region), volume_cc_+lower(region)
      v_roi_file_cn_array = ["Region","Atlas","ROI_Number","SUVR","Volume_cc"]
      v_roi_cn_array =  ["suvr_precentral_l","suvr_precentral_r","suvr_frontal_sup_l","suvr_frontal_sup_r","suvr_frontal_sup_orb_l","suvr_frontal_sup_orb_r","suvr_frontal_mid_l","suvr_frontal_mid_r","suvr_frontal_mid_orb_l","suvr_frontal_mid_orb_r","suvr_frontal_inf_oper_l","suvr_frontal_inf_oper_r","suvr_frontal_inf_tri_l","suvr_frontal_inf_tri_r","suvr_frontal_inf_orb_l","suvr_frontal_inf_orb_r","suvr_rolandic_oper_l","suvr_rolandic_oper_r","suvr_supp_motor_area_l","suvr_supp_motor_area_r","suvr_olfactory_l","suvr_olfactory_r","suvr_frontal_sup_medial_l","suvr_frontal_sup_medial_r","suvr_frontal_med_orb_l","suvr_frontal_med_orb_r","suvr_rectus_l","suvr_rectus_r","suvr_insula_l","suvr_insula_r","suvr_cingulum_ant_l","suvr_cingulum_ant_r","suvr_cingulum_mid_l","suvr_cingulum_mid_r","suvr_cingulum_post_l","suvr_cingulum_post_r","suvr_hippocampus_l","suvr_hippocampus_r","suvr_parahippocampal_l","suvr_parahippocampal_r","suvr_amygdala_l","suvr_amygdala_r","suvr_calcarine_l","suvr_calcarine_r","suvr_cuneus_l","suvr_cuneus_r","suvr_lingual_l","suvr_lingual_r","suvr_occipital_sup_l","suvr_occipital_sup_r","suvr_occipital_mid_l","suvr_occipital_mid_r","suvr_occipital_inf_l","suvr_occipital_inf_r","suvr_fusiform_l","suvr_fusiform_r","suvr_postcentral_l","suvr_postcentral_r","suvr_parietal_sup_l","suvr_parietal_sup_r","suvr_parietal_inf_l","suvr_parietal_inf_r","suvr_supramarginal_l","suvr_supramarginal_r","suvr_angular_l","suvr_angular_r","suvr_precuneus_l","suvr_precuneus_r","suvr_paracentral_lobule_l","suvr_paracentral_lobule_r","suvr_caudate_l","suvr_caudate_r","suvr_putamen_l","suvr_putamen_r","suvr_pallidum_l","suvr_pallidum_r","suvr_thalamus_l","suvr_thalamus_r","suvr_heschl_l","suvr_heschl_r","suvr_temporal_sup_l","suvr_temporal_sup_r","suvr_temporal_pole_sup_l","suvr_temporal_pole_sup_r","suvr_temporal_mid_l","suvr_temporal_mid_r","suvr_temporal_pole_mid_l","suvr_temporal_pole_mid_r","suvr_temporal_inf_l","suvr_temporal_inf_r","suvr_cerebelum_crus1_l","suvr_cerebelum_crus1_r","suvr_cerebelum_crus2_l","suvr_cerebelum_crus2_r","suvr_cerebelum_3_l","suvr_cerebelum_3_r","suvr_cerebelum_4_5_l","suvr_cerebelum_4_5_r","suvr_cerebelum_6_l","suvr_cerebelum_6_r","suvr_cerebelum_7b_l","suvr_cerebelum_7b_r","suvr_cerebelum_8_l","suvr_cerebelum_8_r","suvr_cerebelum_9_l","suvr_cerebelum_9_r","suvr_cerebelum_10_l","suvr_cerebelum_10_r","suvr_vermis_1_2","suvr_vermis_3","suvr_vermis_4_5","suvr_vermis_6","suvr_vermis_7","suvr_vermis_8","suvr_vermis_9","suvr_vermis_10","suvr_clivus","suvr_ethmoid","suvr_meninges","suvr_pineal","suvr_vermis_sup_ant","suvr_cerebellum_superior","suvr_substantia_nigra","suvr_sphenotemporalbuttress","suvr_pons","volume_cc_precentral_l","volume_cc_precentral_r","volume_cc_frontal_sup_l","volume_cc_frontal_sup_r","volume_cc_frontal_sup_orb_l","volume_cc_frontal_sup_orb_r","volume_cc_frontal_mid_l","volume_cc_frontal_mid_r","volume_cc_frontal_mid_orb_l","volume_cc_frontal_mid_orb_r","volume_cc_frontal_inf_oper_l","volume_cc_frontal_inf_oper_r","volume_cc_frontal_inf_tri_l","volume_cc_frontal_inf_tri_r","volume_cc_frontal_inf_orb_l","volume_cc_frontal_inf_orb_r","volume_cc_rolandic_oper_l","volume_cc_rolandic_oper_r","volume_cc_supp_motor_area_l","volume_cc_supp_motor_area_r","volume_cc_olfactory_l","volume_cc_olfactory_r","volume_cc_frontal_sup_medial_l","volume_cc_frontal_sup_medial_r","volume_cc_frontal_med_orb_l","volume_cc_frontal_med_orb_r","volume_cc_rectus_l","volume_cc_rectus_r","volume_cc_insula_l","volume_cc_insula_r","volume_cc_cingulum_ant_l","volume_cc_cingulum_ant_r","volume_cc_cingulum_mid_l","volume_cc_cingulum_mid_r","volume_cc_cingulum_post_l","volume_cc_cingulum_post_r","volume_cc_hippocampus_l","volume_cc_hippocampus_r","volume_cc_parahippocampal_l","volume_cc_parahippocampal_r","volume_cc_amygdala_l","volume_cc_amygdala_r","volume_cc_calcarine_l","volume_cc_calcarine_r","volume_cc_cuneus_l","volume_cc_cuneus_r","volume_cc_lingual_l","volume_cc_lingual_r","volume_cc_occipital_sup_l","volume_cc_occipital_sup_r","volume_cc_occipital_mid_l","volume_cc_occipital_mid_r","volume_cc_occipital_inf_l","volume_cc_occipital_inf_r","volume_cc_fusiform_l","volume_cc_fusiform_r","volume_cc_postcentral_l","volume_cc_postcentral_r","volume_cc_parietal_sup_l","volume_cc_parietal_sup_r","volume_cc_parietal_inf_l","volume_cc_parietal_inf_r","volume_cc_supramarginal_l","volume_cc_supramarginal_r","volume_cc_angular_l","volume_cc_angular_r","volume_cc_precuneus_l","volume_cc_precuneus_r","volume_cc_paracentral_lobule_l","volume_cc_paracentral_lobule_r","volume_cc_caudate_l","volume_cc_caudate_r","volume_cc_putamen_l","volume_cc_putamen_r","volume_cc_pallidum_l","volume_cc_pallidum_r","volume_cc_thalamus_l","volume_cc_thalamus_r","volume_cc_heschl_l","volume_cc_heschl_r","volume_cc_temporal_sup_l","volume_cc_temporal_sup_r","volume_cc_temporal_pole_sup_l","volume_cc_temporal_pole_sup_r","volume_cc_temporal_mid_l","volume_cc_temporal_mid_r","volume_cc_temporal_pole_mid_l","volume_cc_temporal_pole_mid_r","volume_cc_temporal_inf_l","volume_cc_temporal_inf_r","volume_cc_cerebelum_crus1_l","volume_cc_cerebelum_crus1_r","volume_cc_cerebelum_crus2_l","volume_cc_cerebelum_crus2_r","volume_cc_cerebelum_3_l","volume_cc_cerebelum_3_r","volume_cc_cerebelum_4_5_l","volume_cc_cerebelum_4_5_r","volume_cc_cerebelum_6_l","volume_cc_cerebelum_6_r","volume_cc_cerebelum_7b_l","volume_cc_cerebelum_7b_r","volume_cc_cerebelum_8_l","volume_cc_cerebelum_8_r","volume_cc_cerebelum_9_l","volume_cc_cerebelum_9_r","volume_cc_cerebelum_10_l","volume_cc_cerebelum_10_r","volume_cc_vermis_1_2","volume_cc_vermis_3","volume_cc_vermis_4_5","volume_cc_vermis_6","volume_cc_vermis_7","volume_cc_vermis_8","volume_cc_vermis_9","volume_cc_vermis_10","volume_cc_clivus","volume_cc_ethmoid","volume_cc_meninges","volume_cc_pineal","volume_cc_vermis_sup_ant","volume_cc_cerebellum_superior","volume_cc_substantia_nigra","volume_cc_sphenotemporalbuttress","volume_cc_pons"]
      v_cg_tn_tacs = "cg_pet_mk6240_tacs"  
      v_tacs_cn_array = ["Time_min","cblm_gm_inf","Precentral_L","Precentral_R","Frontal_Sup_L","Frontal_Sup_R","Frontal_Sup_Orb_L","Frontal_Sup_Orb_R","Frontal_Mid_L","Frontal_Mid_R","Frontal_Mid_Orb_L","Frontal_Mid_Orb_R","Frontal_Inf_Oper_L","Frontal_Inf_Oper_R","Frontal_Inf_Tri_L","Frontal_Inf_Tri_R","Frontal_Inf_Orb_L","Frontal_Inf_Orb_R","Rolandic_Oper_L","Rolandic_Oper_R","Supp_Motor_Area_L","Supp_Motor_Area_R","Olfactory_L","Olfactory_R","Frontal_Sup_Medial_L","Frontal_Sup_Medial_R","Frontal_Med_Orb_L","Frontal_Med_Orb_R","Rectus_L","Rectus_R","Insula_L","Insula_R","Cingulum_Ant_L","Cingulum_Ant_R","Cingulum_Mid_L","Cingulum_Mid_R","Cingulum_Post_L","Cingulum_Post_R","Hippocampus_L","Hippocampus_R","ParaHippocampal_L","ParaHippocampal_R","Amygdala_L","Amygdala_R","Calcarine_L","Calcarine_R","Cuneus_L","Cuneus_R","Lingual_L","Lingual_R","Occipital_Sup_L","Occipital_Sup_R","Occipital_Mid_L","Occipital_Mid_R","Occipital_Inf_L","Occipital_Inf_R","Fusiform_L","Fusiform_R","Postcentral_L","Postcentral_R","Parietal_Sup_L","Parietal_Sup_R","Parietal_Inf_L","Parietal_Inf_R","SupraMarginal_L","SupraMarginal_R","Angular_L","Angular_R","Precuneus_L","Precuneus_R","Paracentral_Lobule_L","Paracentral_Lobule_R","Caudate_L","Caudate_R","Putamen_L","Putamen_R","Pallidum_L","Pallidum_R","Thalamus_L","Thalamus_R","Heschl_L","Heschl_R","Temporal_Sup_L","Temporal_Sup_R","Temporal_Pole_Sup_L","Temporal_Pole_Sup_R","Temporal_Mid_L","Temporal_Mid_R","Temporal_Pole_Mid_L","Temporal_Pole_Mid_R","Temporal_Inf_L","Temporal_Inf_R","Cerebelum_Crus1_L","Cerebelum_Crus1_R","Cerebelum_Crus2_L","Cerebelum_Crus2_R","Cerebelum_3_L","Cerebelum_3_R","Cerebelum_4_5_L","Cerebelum_4_5_R","Cerebelum_6_L","Cerebelum_6_R","Cerebelum_7b_L","Cerebelum_7b_R","Cerebelum_8_L","Cerebelum_8_R","Cerebelum_9_L","Cerebelum_9_R","Cerebelum_10_L","Cerebelum_10_R","Vermis_1_2","Vermis_3","Vermis_4_5","Vermis_6","Vermis_7","Vermis_8","Vermis_9","Vermis_10","Clivus","Ethmoid","Meninges","Pineal","Vermis_Sup_Ant","Cerebellum_Superior","Substantia_Nigra","SphenotemporalButtress","Pons"]
      v_log_file_cn_array = ["Description","Value"]             
      # <enum>_analysis-log_mk6240_suvr_<codename-hyphen>_2a.csv. source filenames
      #<enum>_pet-processing-log_31-May-2018_mk6240_suvr_visit3_2a.csv  
      #<enum>_roi-summary_mk6240_suvr_<codename-hyphen>_2a.csv --multiple rois, suvr col and volume col
      #<enum>_tacs_mk6240_suvr_<codename-hyphen>_2a.csv --- for one subject, multiple times, series of roi
      sql = "truncate table "+v_cg_tn_roi_atlas_tjb_mni_v1+"_new"
      results = connection.execute(sql)
      sql = "truncate table "+v_cg_tn_roi+"_new"
      results = connection.execute(sql)
      sql = "truncate table "+v_cg_tn_tacs+"_new"
      results = connection.execute(sql)
    v_mk6240_path = "/pet/mk6240/suvr/code_ver2a/"
    v_roi_file_name = "_roi-summary_mk6240_suvr_"
    v_tacs_file_name = "_tacs_mk6240_suvr_"
    v_log_file_name = "_panda-log_mk6240_suvr_"   #"_analysis-log_mk6240_suvr_"
    v_code_version = "2a"
    v_product_file = ""
      #subjectid,general_comment,enrollment_id,scan_procedure_id,file_name,secondary_key,pet_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name,
    v_roi_column_list = "suvr_precentral_l,suvr_precentral_r,suvr_frontal_sup_l,suvr_frontal_sup_r,suvr_frontal_sup_orb_l,suvr_frontal_sup_orb_r,suvr_frontal_mid_l,suvr_frontal_mid_r,suvr_frontal_mid_orb_l,suvr_frontal_mid_orb_r,suvr_frontal_inf_oper_l,suvr_frontal_inf_oper_r,suvr_frontal_inf_tri_l,suvr_frontal_inf_tri_r,suvr_frontal_inf_orb_l,suvr_frontal_inf_orb_r,suvr_rolandic_oper_l,suvr_rolandic_oper_r,suvr_supp_motor_area_l,suvr_supp_motor_area_r,suvr_olfactory_l,suvr_olfactory_r,suvr_frontal_sup_medial_l,suvr_frontal_sup_medial_r,suvr_frontal_med_orb_l,suvr_frontal_med_orb_r,suvr_rectus_l,suvr_rectus_r,suvr_insula_l,suvr_insula_r,suvr_cingulum_ant_l,suvr_cingulum_ant_r,suvr_cingulum_mid_l,suvr_cingulum_mid_r,suvr_cingulum_post_l,suvr_cingulum_post_r,suvr_hippocampus_l,suvr_hippocampus_r,suvr_parahippocampal_l,suvr_parahippocampal_r,suvr_amygdala_l,suvr_amygdala_r,suvr_calcarine_l,suvr_calcarine_r,suvr_cuneus_l,suvr_cuneus_r,suvr_lingual_l,suvr_lingual_r,suvr_occipital_sup_l,suvr_occipital_sup_r,suvr_occipital_mid_l,suvr_occipital_mid_r,suvr_occipital_inf_l,suvr_occipital_inf_r,suvr_fusiform_l,suvr_fusiform_r,suvr_postcentral_l,suvr_postcentral_r,suvr_parietal_sup_l,suvr_parietal_sup_r,suvr_parietal_inf_l,suvr_parietal_inf_r,suvr_supramarginal_l,suvr_supramarginal_r,suvr_angular_l,suvr_angular_r,suvr_precuneus_l,suvr_precuneus_r,suvr_paracentral_lobule_l,suvr_paracentral_lobule_r,suvr_caudate_l,suvr_caudate_r,suvr_putamen_l,suvr_putamen_r,suvr_pallidum_l,suvr_pallidum_r,suvr_thalamus_l,suvr_thalamus_r,suvr_heschl_l,suvr_heschl_r,suvr_temporal_sup_l,suvr_temporal_sup_r,suvr_temporal_pole_sup_l,suvr_temporal_pole_sup_r,suvr_temporal_mid_l,suvr_temporal_mid_r,suvr_temporal_pole_mid_l,suvr_temporal_pole_mid_r,suvr_temporal_inf_l,suvr_temporal_inf_r,suvr_cerebelum_crus1_l,suvr_cerebelum_crus1_r,suvr_cerebelum_crus2_l,suvr_cerebelum_crus2_r,suvr_cerebelum_3_l,suvr_cerebelum_3_r,suvr_cerebelum_4_5_l,suvr_cerebelum_4_5_r,suvr_cerebelum_6_l,suvr_cerebelum_6_r,suvr_cerebelum_7b_l,suvr_cerebelum_7b_r,suvr_cerebelum_8_l,suvr_cerebelum_8_r,suvr_cerebelum_9_l,suvr_cerebelum_9_r,suvr_cerebelum_10_l,suvr_cerebelum_10_r,suvr_vermis_1_2,suvr_vermis_3,suvr_vermis_4_5,suvr_vermis_6,suvr_vermis_7,suvr_vermis_8,suvr_vermis_9,suvr_vermis_10,suvr_clivus,suvr_ethmoid,suvr_meninges,suvr_pineal,suvr_vermis_sup_ant,suvr_cerebellum_superior,suvr_substantia_nigra,suvr_sphenotemporalbuttress,suvr_pons,volume_cc_precentral_l,volume_cc_precentral_r,volume_cc_frontal_sup_l,volume_cc_frontal_sup_r,volume_cc_frontal_sup_orb_l,volume_cc_frontal_sup_orb_r,volume_cc_frontal_mid_l,volume_cc_frontal_mid_r,volume_cc_frontal_mid_orb_l,volume_cc_frontal_mid_orb_r,volume_cc_frontal_inf_oper_l,volume_cc_frontal_inf_oper_r,volume_cc_frontal_inf_tri_l,volume_cc_frontal_inf_tri_r,volume_cc_frontal_inf_orb_l,volume_cc_frontal_inf_orb_r,volume_cc_rolandic_oper_l,volume_cc_rolandic_oper_r,volume_cc_supp_motor_area_l,volume_cc_supp_motor_area_r,volume_cc_olfactory_l,volume_cc_olfactory_r,volume_cc_frontal_sup_medial_l,volume_cc_frontal_sup_medial_r,volume_cc_frontal_med_orb_l,volume_cc_frontal_med_orb_r,volume_cc_rectus_l,volume_cc_rectus_r,volume_cc_insula_l,volume_cc_insula_r,volume_cc_cingulum_ant_l,volume_cc_cingulum_ant_r,volume_cc_cingulum_mid_l,volume_cc_cingulum_mid_r,volume_cc_cingulum_post_l,volume_cc_cingulum_post_r,volume_cc_hippocampus_l,volume_cc_hippocampus_r,volume_cc_parahippocampal_l,volume_cc_parahippocampal_r,volume_cc_amygdala_l,volume_cc_amygdala_r,volume_cc_calcarine_l,volume_cc_calcarine_r,volume_cc_cuneus_l,volume_cc_cuneus_r,volume_cc_lingual_l,volume_cc_lingual_r,volume_cc_occipital_sup_l,volume_cc_occipital_sup_r,volume_cc_occipital_mid_l,volume_cc_occipital_mid_r,volume_cc_occipital_inf_l,volume_cc_occipital_inf_r,volume_cc_fusiform_l,volume_cc_fusiform_r,volume_cc_postcentral_l,volume_cc_postcentral_r,volume_cc_parietal_sup_l,volume_cc_parietal_sup_r,volume_cc_parietal_inf_l,volume_cc_parietal_inf_r,volume_cc_supramarginal_l,volume_cc_supramarginal_r,volume_cc_angular_l,volume_cc_angular_r,volume_cc_precuneus_l,volume_cc_precuneus_r,volume_cc_paracentral_lobule_l,volume_cc_paracentral_lobule_r,volume_cc_caudate_l,volume_cc_caudate_r,volume_cc_putamen_l,volume_cc_putamen_r,volume_cc_pallidum_l,volume_cc_pallidum_r,volume_cc_thalamus_l,volume_cc_thalamus_r,volume_cc_heschl_l,volume_cc_heschl_r,volume_cc_temporal_sup_l,volume_cc_temporal_sup_r,volume_cc_temporal_pole_sup_l,volume_cc_temporal_pole_sup_r,volume_cc_temporal_mid_l,volume_cc_temporal_mid_r,volume_cc_temporal_pole_mid_l,volume_cc_temporal_pole_mid_r,volume_cc_temporal_inf_l,volume_cc_temporal_inf_r,volume_cc_cerebelum_crus1_l,volume_cc_cerebelum_crus1_r,volume_cc_cerebelum_crus2_l,volume_cc_cerebelum_crus2_r,volume_cc_cerebelum_3_l,volume_cc_cerebelum_3_r,volume_cc_cerebelum_4_5_l,volume_cc_cerebelum_4_5_r,volume_cc_cerebelum_6_l,volume_cc_cerebelum_6_r,volume_cc_cerebelum_7b_l,volume_cc_cerebelum_7b_r,volume_cc_cerebelum_8_l,volume_cc_cerebelum_8_r,volume_cc_cerebelum_9_l,volume_cc_cerebelum_9_r,volume_cc_cerebelum_10_l,volume_cc_cerebelum_10_r,volume_cc_vermis_1_2,volume_cc_vermis_3,volume_cc_vermis_4_5,volume_cc_vermis_6,volume_cc_vermis_7,volume_cc_vermis_8,volume_cc_vermis_9,volume_cc_vermis_10,volume_cc_clivus,volume_cc_ethmoid,volume_cc_meninges,volume_cc_pineal,volume_cc_vermis_sup_ant,volume_cc_cerebellum_superior,volume_cc_substantia_nigra,volume_cc_sphenotemporalbuttress,volume_cc_pons"

 #subjectid,general_comment,enrollment_id,scan_procedure_id,file_name,secondary_key,pet_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name,
    v_tacs_column_list = "time_min,cblm_gm_inf,precentral_l,precentral_r,frontal_sup_l,frontal_sup_r,frontal_sup_orb_l,frontal_sup_orb_r,frontal_mid_l,frontal_mid_r,frontal_mid_orb_l,frontal_mid_orb_r,frontal_inf_oper_l,frontal_inf_oper_r,frontal_inf_tri_l,frontal_inf_tri_r,frontal_inf_orb_l,frontal_inf_orb_r,rolandic_oper_l,rolandic_oper_r,supp_motor_area_l,supp_motor_area_r,olfactory_l,olfactory_r,frontal_sup_medial_l,frontal_sup_medial_r,frontal_med_orb_l,frontal_med_orb_r,rectus_l,rectus_r,insula_l,insula_r,cingulum_ant_l,cingulum_ant_r,cingulum_mid_l,cingulum_mid_r,cingulum_post_l,cingulum_post_r,hippocampus_l,hippocampus_r,parahippocampal_l,parahippocampal_r,amygdala_l,amygdala_r,calcarine_l,calcarine_r,cuneus_l,cuneus_r,lingual_l,lingual_r,occipital_sup_l,occipital_sup_r,occipital_mid_l,occipital_mid_r,occipital_inf_l,occipital_inf_r,fusiform_l,fusiform_r,postcentral_l,postcentral_r,parietal_sup_l,parietal_sup_r,parietal_inf_l,parietal_inf_r,supramarginal_l,supramarginal_r,angular_l,angular_r,precuneus_l,precuneus_r,paracentral_lobule_l,paracentral_lobule_r,caudate_l,caudate_r,putamen_l,putamen_r,pallidum_l,pallidum_r,thalamus_l,thalamus_r,heschl_l,heschl_r,temporal_sup_l,temporal_sup_r,temporal_pole_sup_l,temporal_pole_sup_r,temporal_mid_l,temporal_mid_r,temporal_pole_mid_l,temporal_pole_mid_r,temporal_inf_l,temporal_inf_r,cerebelum_crus1_l,cerebelum_crus1_r,cerebelum_crus2_l,cerebelum_crus2_r,cerebelum_3_l,cerebelum_3_r,cerebelum_4_5_l,cerebelum_4_5_r,cerebelum_6_l,cerebelum_6_r,cerebelum_7b_l,cerebelum_7b_r,cerebelum_8_l,cerebelum_8_r,cerebelum_9_l,cerebelum_9_r,cerebelum_10_l,cerebelum_10_r,vermis_1_2,vermis_3,vermis_4_5,vermis_6,vermis_7,vermis_8,vermis_9,vermis_10,clivus,ethmoid,meninges,pineal,vermis_sup_ant,cerebellum_superior,substantia_nigra,sphenotemporalbuttress,pons"
    v_secondary_key_array =["b","c","d","e",".R"]
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"
    sp_exclude_array = [69,53,54,56,57,95,55,76,78,72,70,71,49,79,99,81,75,80,83,92,93,88,68,97,29,52,87,48,27,14,61,62,46,60,8,21,28,31,34,82,84,85,86,33,40,50,42,44,51,96,9,25,23,19,15,24,36,100,35,20,73,32,45,6,12,16,13,11,10,90,59,63,43,4,17,30,74,98]
    @scan_procedures = ScanProcedure.where("scan_procedures.id not in (?)", sp_exclude_array)
    # for testing@scan_procedures = ScanProcedure.where("scan_procedures.id  in (?)", "77")
    @scan_procedures.each do |sp|
      @schedulerun.comment = "start "+sp.codename+" "+v_comment_base
      @schedulerun.save
      v_visit_number =""
      if sp.codename.include?("visit2")
            v_visit_number ="_v2"
      elsif sp.codename.include?("visit3")
            v_visit_number ="_v3"
      elsif sp.codename.include?("visit4")
            v_visit_number ="_v4"
      elsif sp.codename.include?("visit5")
            v_visit_number ="_v5"
      end  
      v_codename_hyphen =  sp.codename
      v_codename_hyphen = v_codename_hyphen.gsub(".","-")

      v_preprocessed_full_path = v_preprocessed_path+sp.codename  
      if File.directory?(v_preprocessed_full_path)
        sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups,  appointments, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+"  
                                    and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id 
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
        @results = connection.execute(sql_enum)                                 
        @results.each do |r|
          enrollment = Enrollment.where("enumber='"+r[0]+"'")
          if !enrollment.blank?
            v_log = ""
            v_subjectid_path = v_preprocessed_full_path+"/"+enrollment[0].enumber
            v_subjectid = enrollment[0].enumber
            v_subjectid_v_num = enrollment[0].enumber + v_visit_number
            @schedulerun.comment = "start "+v_subjectid_v_num+" "+v_comment_base
            @schedulerun.save
            v_subjectid_pet_mk6240 =v_subjectid_path+v_mk6240_path
            v_subjectid_array = []
            begin
              if File.directory?(v_subjectid_pet_mk6240)
                v_subjectid_array.push(v_subjectid)
              end
              v_secondary_key_array.each do |k|
                if File.directory?(v_subjectid_path+k+v_mk6240_path)
                  v_subjectid_array.push((v_subjectid+k))
                  v_subjectid_v_num = v_subjectid+k + v_visit_number
                  v_subjectid_path = v_preprocessed_full_path+"/"+v_subjectid+k
                  v_subjectid_pet_mk6240 =v_subjectid_path+v_mk6240_path
                end
              end
             rescue => msg  
                v_comment = v_comment + "IN RESCUE ERROR "+msg+"\n"  
            end

            v_subjectid_array = v_subjectid_array.uniq
            v_subjectid_array.each do |subj|
              v_seconbdary_key =""
              if subj != enrollment.first.enumber
                 v_secondary_key = subj
                 v_secondary_key = v_secondary_key.gsub(enrollment.first.enumber,"")
              end
              v_subjectid = subj
              v_subjectid_v_num = subj + v_visit_number
              v_subjectid_path = v_preprocessed_full_path+"/"+subj
              v_subjectid_pet_mk6240 =v_subjectid_path+v_mk6240_path
              if File.directory?(v_subjectid_pet_mk6240)
                v_dir_array = Dir.entries(v_subjectid_pet_mk6240)
                v_dir_array.each do |f|
                  # get roi, tac, log files and final file = wpdt00235_mk6240_suvr70-90_visit3_2a.nii
                   #<enum>_roi-summary_mk6240_suvr_<codename-hyphen>_2a.csv --multiple rois, suvr col and volume col
                  v_subjectid_roi_file_name = v_subjectid_pet_mk6240+v_subjectid+v_roi_file_name+v_codename_hyphen+"_"+v_code_version+".csv"
                  #<enum>_tacs_mk6240_suvr_<codename-hyphen>_2a.csv --- for one subject, multiple times, series of roi
                  v_subjectid_tacs_file_name = v_subjectid_pet_mk6240+v_subjectid+v_tacs_file_name+v_codename_hyphen+"_"+v_code_version+".csv"
                  # <enum>_analysis-log_mk6240_suvr_<codename-hyphen>_2a.csv. source filenames
                  #<enum>_panda-log_mk6240_suvr_<codename-hyphen>_2a.csv
                  v_subjectid_log_file_name = v_subjectid_pet_mk6240+v_subjectid+v_log_file_name+v_codename_hyphen+"_"+v_code_version+".csv"
                  # final product file - insert into processed images - get source file names from the log file
                  v_skip_flag = "Y"
                  v_product_file = ""
                  if f.start_with?("w"+v_subjectid) and f.end_with?(".nii")
                    v_product_file = f
                      #check if exists in processedimages
                      v_age_at_appointment =""
                      v_ecat_file = ""
                      v_original_t1_mri_file = ""
                      v_tracer = ""
                      v_method = ""
                      v_pet_code_version = ""
                      v_protocol_description = ""
                      v_pet_processing_date = ""
                     if File.file?(v_subjectid_log_file_name)
                      # check column header "Description,Value". #v_log_file_cn_array
                      # check "study ID" = v_subjectid  "protocol description" = sp.codename, tracer = mk6240, method = suvr, "PET code version" = v_code_version
                      # email if different - set flag to skip
                       # parse by rows, get "ecat file", "original t1 MRI file"
                       # check if
                        # check column headers
                        v_cnt = 0
                        v_header = ""
                        File.open(v_subjectid_log_file_name,'r') do |file_a|
                          while line = file_a.gets and v_cnt < 1
                            if v_cnt < 1
                              v_header = line
                            end
                            v_cnt = v_cnt +1
                          end
                        end
                       v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_log_file_cn_array.join(","))
                       if v_return_flag == "N" 
                               v_comment = v_subjectid_log_file_name+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment
                               v_skip_flag = "Y"               
                       else 
                         v_skip_flag = "N"
                         v_cnt = 0
                          File.open(v_subjectid_log_file_name,'r') do |file_a|
                            while line = file_a.gets
                              if v_cnt > 0
                               # line.gsub(/\n/,"") #.each do |v_line|
                                  v = line.gsub(/\n/,"").split(",")
                                   if v[0] == "tracer" 
                                     if v[1] == "mk6240"
                                         v_tracer = v[1]
                                     else
                                         v_skip_flag = "Y"
                                     end
                                   elsif v[0] == "study ID" 
                                     if v[1] == v_subjectid
                                         # ok
                                     else
                                         v_skip_flag = "Y"
                                     end
                                   elsif v[0] == "protocol description" 
                                     if v[1] == sp.codename
                                         v_protocol_description = v[1]

                                     else
                                         v_skip_flag = "Y"
                                     end
                                   elsif v[0] == "method" 
                                     if v[1] == "suvr"
                                         v_method = v[1]
                                     else
                                         v_skip_flag = "Y"
                                     end
                                   elsif v[0] == "PET code version" 
                                     if v[1] == v_code_version
                                         v_pet_code_version = v[1]
                                     else
                                         v_skip_flag = "Y"
                                     end
                                   elsif v[0] == "PET image processing date" 
                                     v_pet_processing_date = v[1].to_s
                                   elsif v[0] == "original t1 MRI file" 
                                     v_original_t1_mri_file = v[1].to_s
                                   elsif v[0] == "ecat file" 
                                     v_ecat_file = v[1].to_s
                                     # get v_age_at_appointment
                                     v_petscans = Petscan.where("petscans.path in (?)",v_ecat_file)
                                     if v_petscans.count > 0
                                        v_appointment = Appointment.find(v_petscans.first.appointment_id)
                                        v_age_at_appointment = v_appointment.age_at_appointment.to_s
                                     else # sometimes the processing ecat not match the panda ecat 
                                          # use tracer, enumber and scan_procedure
                                          v_appointments = Appointment.where("appointments.appointment_type = 'pet_scan' 
                                             and appointments.id in (select petscans.appointment_id from petscans where petscans.lookup_pettracer_id in (?))
                                             and appointments.vgroup_id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships 
                                                                 where enrollment_vgroup_memberships.enrollment_id in (?))
                                             and appointments.vgroup_id in (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups
                                                               where scan_procedures_vgroups.scan_procedure_id in (?))",v_mk6240_tracer_id,enrollment.first.id,sp.id)
                                           if v_appointments.count > 0
                                               v_age_at_appointment = v_appointments.first.age_at_appointment.to_s
                                           end

                                     end
                                       
                                   end
                               
                                end
                              #end
                              v_cnt = v_cnt + 1
                            end
                          end  
                       end 
                     end
                  end
                  if v_pet_processing_date.nil?
                       v_pet_processing_date =""
                  end
                  if v_original_t1_mri_file.nil?
                      v_original_t1_mri_file =""
                  end
                  if v_ecat_file.nil?
                     v_ecat_file= ""
                  end
                  if v_skip_flag == "N"
                     # CHECK IN PROCESSEDIMAGES for v_subjectid_pet_mk6240+v_product_file - , insert with sources v_original_t1_mri_file, v_ecat_file 
                     v_processesimages = Processedimage.where("file_path in (?)",v_subjectid_pet_mk6240+v_product_file)
                     if v_processesimages.count <1
                                      # need to collect source files, then make processedimage record
                         v_processedimage = Processedimage.new
                         v_processedimage.file_type ="suvr mk6240"
                         v_processedimage.file_name = v_product_file
                         v_processedimage.file_path = v_subjectid_pet_mk6240+v_product_file
                         v_processedimage.scan_procedure_id = sp.id
                         v_processedimage.enrollment_id = enrollment.first.id
                         v_processedimage.save  
                         v_processedimage_file_id = v_processedimage.id
    
                         # sources - ecat pet file -- petfile_id?
                         # petfile_id from ecat file
                         v_petfiles = Petfile.where("petfiles.path in (?)",v_ecat_file)
                         if v_petfiles.count > 1
                           v_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'petfile'",v_processedimage_file_id,v_petfiles.first.id)
                           if v_processedimagesources.count < 1 and v_petfiles.count > 0
                             v_processedimagesource = Processedimagessource.new
                             v_processedimagesource.file_name = v_ecat_file.split("/").last
                             v_processedimagesource.file_path = v_ecat_file
                             v_processedimagesource.source_image_id = v_petfiles.first.id
                             v_processedimagesource.source_image_type = 'petfile'
                             v_processedimagesource.processedimage_id= v_processedimage_file_id
                             v_processedimagesource.save
                           end
                         end
                         v_mri_processedimage_id = ""
                         v_original_t1_mri_file_unknown = v_original_t1_mri_file
                         v_original_t1_mri_file_unknown = v_original_t1_mri_file_unknown.gsub("tissue_seg","unknown") # think the oACPC in tissue seg are from unknown
                         v_mri_processesimages = Processedimage.where("file_path in (?) or file_path in (?)",v_original_t1_mri_file,v_original_t1_mri_file_unknown)
                         if v_mri_processesimages.count < 1
                             v_mri_processedimage = Processedimage.new
                             v_mri_processedimage.file_type ="o_acpc T1"
                             v_mri_processedimage.file_name = v_original_t1_mri_file.split("/").last
                             v_mri_processedimage.file_path = v_original_t1_mri_file
                             v_mri_processedimage.scan_procedure_id = sp.id
                             v_mri_processedimage.enrollment_id = enrollment.first.id
                             v_mri_processedimage.save  
                             v_mri_processedimage_id = v_mri_processedimage.id

                         else
                           v_mri_processedimage_id = v_mri_processesimages.first.id
                         end
                         v_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'processedimage'",v_processedimage_file_id,v_mri_processedimage_id)
                         if v_processedimagesources.count < 1 
                             v_processedimagesource = Processedimagessource.new
                             v_processedimagesource.file_name = v_original_t1_mri_file.split("/").last
                             v_processedimagesource.file_path = v_original_t1_mri_file
                             v_processedimagesource.source_image_id = v_mri_processedimage_id
                             v_processedimagesource.source_image_type = 'processedimage'
                             v_processedimagesource.processedimage_id= v_processedimage_file_id
                             v_processedimagesource.save
                         end
                     end

 # MAKE TRACKER QC

                    # check for roi file
                    if File.file?(v_subjectid_roi_file_name)
                        # check column headers 
                        puts "v_subjectid_roi_file_name="+v_subjectid_roi_file_name
                        v_cnt = 0
                        v_header = ""
                        File.open(v_subjectid_roi_file_name,'r') do |file_a|
                          while line = file_a.gets and v_cnt < 1
                            if v_cnt < 1
                              v_header = line.gsub("\n","")
                            end
                            v_cnt = v_cnt +1
                          end
                        end
                       v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_roi_file_cn_array.join(","))
                       if v_return_flag == "N" 
                               v_comment = v_subjectid_roi_file_name+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                       else
                       # insert v_cg_tn_roi -- with _v#  v_subjectid_v_num  
                       # CHECK FOR subjectid_v# to SP/ENUMBER/ have sp.id have enrollment.id
                       # CHECK FOR empty ROWS
                          v_cnt = 0
                          v_line_array = []
                          v_roi_hash = Hash.new

                          v_roi_hash_atlas_tjb_mni_v1 = Hash.new
                          v_atlas = ""
                          v_atlas_tjb_mni_v1 = ""
                          File.open(v_subjectid_roi_file_name,'r') do |file_a|

                            while line = file_a.gets
                              if v_cnt > 0 
                                v_line_array = []
                                v_line_array =line.gsub(/\n/,"").split(",")
                                if v_line_array[1] == v_aal_atlas
                                  v_atlas = v_line_array[1]
                                  v_roi_hash["suvr_"+v_line_array[0].downcase] = v_line_array[3]
                                  v_roi_hash["volume_cc_"+v_line_array[0].downcase] = v_line_array[4]
                                elsif v_line_array[1] == v_tjb_mni_v1
                                  v_atlas_tjb_mni_v1 = v_line_array[1]
                                  v_roi_hash_atlas_tjb_mni_v1["suvr_"+v_line_array[0].downcase] = v_line_array[3]
                                  v_roi_hash_atlas_tjb_mni_v1["volume_cc_"+v_line_array[0].downcase] = v_line_array[4]
                                end
                              end   
                              v_cnt = v_cnt + 1                 
                            end
                            
                          end # file read
                          sql = "insert into cg_pet_mk6240_roi_new(file_name,subjectid,enrollment_id,scan_procedure_id,secondary_key,pet_processing_date,pet_code_version,original_t1_mri_file_name,ecat_file_name,atlas,age_at_appointment,"+v_roi_column_list+" ) values('"+v_subjectid_roi_file_name.split("/").last.to_s+"','"+v_subjectid_v_num+"',"+enrollment.first.id.to_s+","+sp.id.to_s+",'"+v_secondary_key.to_s+"','"+v_pet_processing_date.to_s+"','"+v_pet_code_version+"','"+v_original_t1_mri_file.to_s+"','"+v_ecat_file.to_s+"','"+v_atlas+"','"+v_age_at_appointment+"'"
                          v_col_array = v_roi_column_list.split(",")
                          v_col_array.each do |cn|
                               if v_roi_hash[cn].nil?
#puts "bbbbbbb nil="+cn
                                 sql = sql+",''"
                               else
                                   sql = sql+",'"+v_roi_hash[cn]+"'"
                               end
                          end
                          sql = sql+")"
                          results = connection.execute(sql)
                          sql = "insert into cg_pet_mk6240_roi_atlas_tjb_mni_v1_new(file_name,subjectid,enrollment_id,scan_procedure_id,secondary_key,pet_processing_date,pet_code_version,original_t1_mri_file_name,ecat_file_name,atlas,age_at_appointment,"+v_roi_column_list+" ) values('"+v_subjectid_roi_file_name.split("/").last.to_s+"','"+v_subjectid_v_num+"',"+enrollment.first.id.to_s+","+sp.id.to_s+",'"+v_secondary_key.to_s+"','"+v_pet_processing_date.to_s+"','"+v_pet_code_version+"','"+v_original_t1_mri_file.to_s+"','"+v_ecat_file.to_s+"','"+v_atlas_tjb_mni_v1+"','"+v_age_at_appointment+"'"
                          v_col_array = v_roi_column_list.split(",")
                          v_col_array.each do |cn|
                               if v_roi_hash_atlas_tjb_mni_v1[cn].nil?
#puts "bbbbbbb nil="+cn
                                 sql = sql+",''"
                               else
                                   sql = sql+",'"+v_roi_hash_atlas_tjb_mni_v1[cn]+"'"
                               end
                          end
                          sql = sql+")"
                          results = connection.execute(sql)
                                
                       end
                    end
                    if File.file?(v_subjectid_tacs_file_name)
                          # check column headers  
                        v_cnt = 0
                        v_header = ""
                        File.open(v_subjectid_tacs_file_name,'r') do |file_a|
                          while line = file_a.gets and v_cnt < 1
                            if v_cnt < 1
                              v_header = line.gsub("\n","")
                            end
                            v_cnt = v_cnt +1
                          end
                        end
                       v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_tacs_cn_array.join(","))
                       if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                       else
                        # insert v_cg_tn_tacs -- with _v# ?
                           v_cnt = 0
                          v_line_array = []
                          File.open(v_subjectid_tacs_file_name,'r') do |file_a|

                            while line = file_a.gets
                              if v_cnt > 0 and v_cnt < 2
                                sql = "insert into cg_pet_mk6240_tacs_new(file_name,subjectid,enrollment_id,scan_procedure_id,secondary_key,pet_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name,"+v_tacs_column_list+" ) values('"+v_subjectid_tacs_file_name.split("/").last.to_s+"','"+v_subjectid_v_num+"',"+enrollment.first.id.to_s+","+sp.id.to_s+",'"+v_secondary_key.to_s+"','"+v_pet_processing_date.to_s+"','"+v_pet_code_version+"','"+v_original_t1_mri_file.to_s+"','"+v_ecat_file.to_s+"',"
                                v_line_array = []
                                line.gsub(/\n/,"").split(",").each do |v|
                                  v_line_array.push("'"+v+"'")
                                end 
                                sql = sql+v_line_array.join(",")
                                sql = sql+")"
                                results = connection.execute(sql)
                              end   
                              v_cnt = v_cnt + 1                 
                            end
                            
                          end
                       end
                        
                    end
                  end # end of skip flag
                end # file loop  
              end # if pet_mk6240 exists
            end # subject array loop
          end # enrollment not blank
        end # results loop
      end # preprocessed sp dir exists
    end   # scan procedure loop
    
                

                # check move cg_ to cg_old
                sql = "select count(*) from cg_pet_mk6240_roi_old"
                results_old = connection.execute(sql)
                
                sql = "select count(*) from cg_pet_mk6240_roi"
                results = connection.execute(sql)
                v_old_cnt = results_old.first.to_s.to_i
                v_present_cnt = results.first.to_s.to_i
                v_old_minus_present =v_old_cnt-v_present_cnt
                v_present_minus_old = v_present_cnt-v_old_cnt
                if ( v_old_minus_present <= 0 or ( v_old_cnt > 0 and  (v_present_minus_old/v_old_cnt)>0.7     ) )
                  sql =  "truncate table cg_pet_mk6240_roi_old"
                  results = connection.execute(sql)
                  sql = "insert into cg_pet_mk6240_roi_old select * from cg_pet_mk6240_roi"
                  results = connection.execute(sql)
                else
                  v_comment = " The cg_pet_mk6240_roi_old table has 30% more rows than the present cg_pet_mk6240_roi\n Not truncating cg_pet_mk6240_roi_old "+v_comment 
                end
                #  truncate cg_ and insert cg_new
                sql =  "truncate table cg_pet_mk6240_roi"
                results = connection.execute(sql)

                sql = "insert into cg_pet_mk6240_roi("+v_roi_column_list+",subjectid,enrollment_id,scan_procedure_id,secondary_key,file_name,pet_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name,atlas,age_at_appointment) 
                select distinct "+v_roi_column_list+",t.subjectid,t.enrollment_id, scan_procedure_id,secondary_key,file_name,pet_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name,atlas,age_at_appointment from cg_pet_mk6240_roi_new t
                                               where t.scan_procedure_id is not null  and t.enrollment_id is not null "
                results = connection.execute(sql)

                # apply edits  -- made into a function  in shared model
              
                v_shared.apply_cg_edits("cg_pet_mk6240_roi")

                 # DIFFERENT ATLAS atlas_tjb_mni_v1_
                sql = "select count(*) from cg_pet_mk6240_roi_atlas_tjb_mni_v1_old"
                results_old = connection.execute(sql)
                
                sql = "select count(*) from cg_pet_mk6240_roi_atlas_tjb_mni_v1"
                results = connection.execute(sql)
                v_old_cnt = results_old.first.to_s.to_i
                v_present_cnt = results.first.to_s.to_i
                v_old_minus_present =v_old_cnt-v_present_cnt
                v_present_minus_old = v_present_cnt-v_old_cnt
                if ( v_old_minus_present <= 0 or ( v_old_cnt > 0 and  (v_present_minus_old/v_old_cnt)>0.7     ) )
                  sql =  "truncate table cg_pet_mk6240_roi_atlas_tjb_mni_v1_old"
                  results = connection.execute(sql)
                  sql = "insert into cg_pet_mk6240_roi_atlas_tjb_mni_v1_old select * from cg_pet_mk6240_roi_atlas_tjb_mni_v1"
                  results = connection.execute(sql)
                else
                  v_comment = " The cg_pet_mk6240_roi_atlas_tjb_mni_v1_old table has 30% more rows than the present cg_pet_mk6240_roi_atlas_tjb_mni_v1\n Not truncating cg_pet_mk6240_roi_atlas_tjb_mni_v1_old "+v_comment 
                end
                #  truncate cg_ and insert cg_new
                sql =  "truncate table cg_pet_mk6240_roi_atlas_tjb_mni_v1"
                results = connection.execute(sql)

                sql = "insert into cg_pet_mk6240_roi_atlas_tjb_mni_v1("+v_roi_column_list+",subjectid,enrollment_id,scan_procedure_id,secondary_key,file_name,pet_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name,atlas,age_at_appointment) 
                select distinct "+v_roi_column_list+",t.subjectid,t.enrollment_id, scan_procedure_id,secondary_key,file_name,pet_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name,atlas,age_at_appointment from cg_pet_mk6240_roi_atlas_tjb_mni_v1_new t
                                               where t.scan_procedure_id is not null  and t.enrollment_id is not null "
                results = connection.execute(sql)

                # apply edits  -- made into a function  in shared model
              
                v_shared.apply_cg_edits("cg_pet_mk6240_roi_atlas_tjb_mni_v1")
                # tacs
                sql = "select count(*) from cg_pet_mk6240_tacs_old"
                results_old = connection.execute(sql)
                
                sql = "select count(*) from cg_pet_mk6240_tacs"
                results = connection.execute(sql)
                v_old_cnt = results_old.first.to_s.to_i
                v_present_cnt = results.first.to_s.to_i
                v_old_minus_present =v_old_cnt-v_present_cnt
                v_present_minus_old = v_present_cnt-v_old_cnt
                if ( v_old_minus_present <= 0 or ( v_old_cnt > 0 and  (v_present_minus_old/v_old_cnt)>0.7     ) )
                  sql =  "truncate table cg_pet_mk6240_tacs_old"
                  results = connection.execute(sql)
                  sql = "insert into cg_pet_mk6240_tacs select * from cg_pet_mk6240_tacs"
                  results = connection.execute(sql)
                else
                  v_comment = " The cg_pet_mk6240_tacs_old table has 30% more rows than the present cg_pet_mk6240_tacs\n Not truncating cg_pet_mk6240_tacs_old "+v_comment 
                end
                #  truncate cg_ and insert cg_new
                sql =  "truncate table cg_pet_mk6240_tacs"
                results = connection.execute(sql)

                sql = "insert into cg_pet_mk6240_tacs("+v_tacs_column_list+",subjectid,enrollment_id,scan_procedure_id,secondary_key,file_name,pet_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name) 
                select distinct "+v_tacs_column_list+",t.subjectid,t.enrollment_id, scan_procedure_id,secondary_key,file_name,pet_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name from cg_pet_mk6240_tacs_new t
                                               where t.scan_procedure_id is not null  and t.enrollment_id is not null "
                results = connection.execute(sql)

                # apply edits  -- made into a function  in shared model
              
                v_shared.apply_cg_edits("cg_pet_mk6240_tacs")

        #BRAAK INSERT NEW ROWS
                sql = "insert into cg_mk6240_braak(subjectid,participant_id, scan_procedure_id,file_name,enrollment_id)
                      select cg_pet_mk6240_roi.subjectid,enrollments.participant_id,cg_pet_mk6240_roi.scan_procedure_id,cg_pet_mk6240_roi.ecat_file_name,cg_pet_mk6240_roi.enrollment_id
                      from cg_pet_mk6240_roi, enrollments where cg_pet_mk6240_roi.enrollment_id = enrollments.id
                      and cg_pet_mk6240_roi.subjectid not in ( select cg_mk6240_braak.subjectid from cg_mk6240_braak)"
              results = connection.execute(sql)

     @schedulerun.comment =("successful finish pet_mk6240_harvest "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
       @schedulerun.status_flag ="Y"
     end
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save  


end


#WHAT SHOULD TRIGGER PROCCESSING 
# panda record=> file path
# file path ==> panda record
# WHAT should stop processing
# for now just that dir exisits
# later file exists and log not say "something"
def run_pet_mk6240_process
      v_base_path = Shared.get_base_path()
      v_preprocessed_path = v_base_path+"/preprocessed/visits/"
      v_mk6240_path = "/pet/mk6240/suvr/code_ver2a"
     @schedule = Schedule.where("name in ('pet_mk6240_process')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting pet_mk6240_process"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning ="" 
      v_mk6240_tracer_id = "11"
    connection = ActiveRecord::Base.connection();
      v_mk6240_petscans = Petscan.where("petscans.lookup_pettracer_id in (?)",v_mk6240_tracer_id)
    # get list of mk6240 Petscans
    #check if has precprocessed codever 2a dir
    # if there, stop, else 
    # check if ecat file exisits, single file, correct size
    # check for single o acpc corrected file linked to vgroup
    # run command, make tracker record
    # using ecat file name to get subjectid, scan_procedure from ecat file path
      v_mk6240_petscans.each do |pet_appt|
          # puts "pet_appt.path="+pet_appt.path
          v_enumber = ""
          v_scan_procedure = ""
          v_pet_path_array = (pet_appt.path).split("/")
          v_pet_path_ok = "Y"
          v_scan_procedure_codename = ""
          v_subjectid = ""
          if v_pet_path_array.count < 8 #or !File.file?(pet_appt.path)
             v_pet_path_ok = "N"
          else
             v_scan_procedure_codename = v_pet_path_array[4] # leading slash shifts register
             v_subjectid_array = v_pet_path_array[7].split("_")
             v_subjectid = v_subjectid_array[0].downcase
             #check if enumber and scan_procedure are valid
             v_enumbers = Enrollment.where("enumber in (?)", v_subjectid)
             v_scan_procedures =ScanProcedure.where("codename in (?)",v_scan_procedure_codename)
             if v_enumbers.count > 0
                v_enumber = v_enumbers.first
             else
               v_pet_path_ok = "N"
             end
             if v_scan_procedures.count >0
                v_scan_procedure = v_scan_procedures.first
             else
                v_pet_path_ok = "N"
             end
          end
          v_subjectid_pet_mk6240 = v_preprocessed_path+v_scan_procedure_codename+"/"+v_subjectid+v_mk6240_path
          if File.directory?(v_subjectid_pet_mk6240) and v_pet_path_ok == "Y"
           #  dir exists - not run - extend to look at logs - re-run criteria or flag
           # puts "dddd v_subjectid_pet_mk6240="+v_subjectid_pet_mk6240
          elsif File.file?(pet_appt.path)
            # check for expected size
            @petscan_tracer_file_size = {}
            @petscan_tracer_file_size_multiple = {}
            if !v_scan_procedure.petscan_tracer_file_size.nil?
               v_tmp_tracer_size = v_scan_procedure.petscan_tracer_file_size.split("|")
               v_tmp_tracer_size.each do |tr|
                v_tmp_size = tr.split(":")
                @petscan_tracer_file_size[v_tmp_size[0]] = v_tmp_size[1]
                if @petscan_tracer_file_size_multiple[v_tmp_size[0]].nil?
                   @petscan_tracer_file_size_multiple[v_tmp_size[0]] = [v_tmp_size[1]]
                else
                  @petscan_tracer_file_size_multiple[v_tmp_size[0]] = @petscan_tracer_file_size_multiple[v_tmp_size[0]].push(v_tmp_size[1])
                end
               end
             #v_mk6240_tracer_id
               if !@petscan_tracer_file_size_multiple.nil? and !@petscan_tracer_file_size_multiple[v_mk6240_tracer_id.to_s].nil? 
                    if @petscan_tracer_file_size_multiple[v_mk6240_tracer_id.to_s].include?(File.stat(pet_appt.path).size.to_s)
                      # petfile not expected size
                      v_pet_path_ok = "N"
                      v_comment = v_comment+" :"+v_subjectid+" ecat file wrong size:"
                    end
               end
             end

            end
            v_o_acpc_file = ""
            if v_pet_path_ok == "Y"
               # check for one o-acpc  file -- using tissue_seg - a winnowing of the unknown dir files
               v_subjectid_tissue_seg = v_preprocessed_path+v_scan_procedure.codename+"/"+v_subjectid+"/tissue_seg"
               
               if File.directory?(v_subjectid_tissue_seg)   # need to also look for [subjectid]b,c,d,.R
                    v_cnt = 0
                    v_dir_array = Dir.entries(v_subjectid_tissue_seg)
                    v_dir_array.each do |f|
                      if f.start_with?("o") and f.end_with?(".nii")
                         v_cnt = v_cnt + 1
                         v_o_acpc_file = f
                      end
                    end
                    if v_cnt > 1
                      v_pet_path_ok = "N"
                      v_comment = v_comment+" :"+v_subjectid+" multiple o_acpc in tissue_seg:"
                    end

            end  
            if v_pet_path_ok == "Y"
              # netinjecteddose
              puts " need to run="+v_subjectid_pet_mk6240
            end
          else
            puts "no ecat file"
            v_comment = v_comment+" :"+v_subjectid+" no ecat file:"
          end
      end


    @schedulerun.comment =("successful finish pet_mk6240_process "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
       @schedulerun.status_flag ="Y"
     end
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save  
end


# Kate Sprecher Sleep study needs t1 - clean out dicom
def run_sleep_t1

    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "sleep_t1"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('sleep_t1')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting sleep_t1 -MOVED TO SHARED_RETIRED"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
   
  end

#compares raw data table with edited versions - logs all cells which have change
#compared 2 edits tables for differences - logs all cells which are different
#uses col name and col order array for each table to make comparisons
#key columns  - 
  def run_table_cell_comparison
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('table_cell_comparison')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting table_cell_comparison"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning ="" 
    connection = ActiveRecord::Base.connection();

       v_raw_tn ="t_champs_adrc_raw_20180511"
       #  v_raw_tn_cn_array =["ptid","champs_visit_number","champs_frndfam","champs_frndfam_fq","champs_frndfam_hw","champs_snrctr","champs_snrctr_fq","champs_snrctr_hw","champs_volun","champs_volun_fq","champs_volun_hw","champs_church","champs_church_fq","champs_church_hw","champs_clubmtg","champs_clubmtg_fq","champs_clubmtg_hw","champs_usecomp","champs_usecomp_fq","champs_usecomp_hw","champs_dance","champs_dance_fq","champs_dance_hw","champs_artcraft","champs_artcraft_fq","champs_artcraft_hw","champs_golfcrryeqp","champs_golfcrryeqp_fq","champs_golfcrryeqp_hw","champs_golfrde","champs_golfrde_fq","champs_golfrde_hw","champs_concert","champs_concert_fq","champs_concert_hw","champs_games","champs_games_fq","champs_games_hw","champs_pool","champs_pool_fq","champs_pool_hw","champs_tennissng","champs_tennissng_fq","champs_tennissng_hw","champs_tennisdbl","champs_tennisdbl_fq","champs_tennisdbl_hw","champs_skate","champs_skate_fq","champs_skate_hw","champs_plymuscins","champs_plymuscins_fq","champs_plymuscins_hw","champs_read","champs_read_fq","champs_read_hw","champs_hsehvywrk","champs_hsehvywrk_fq","champs_hsehvywrk_hw","champs_hseltwrk","champs_hseltwrk_fq","champs_hseltwrk_hw","champs_grdnhvywrk","champs_grdnhvywrk_fq","champs_grdnhvywrk_hw","champs_grdnltwrk","champs_grdnltwrk_fq","champs_grdnltwrk_hw","champs_wrkonmchn","champs_wrkonmchn_fq","champs_wrkonmchn_hw","champs_run","champs_run_fq","champs_run_hw","champs_walkuphll","champs_walkuphll_fq","champs_walkuphll_hw","champs_walkfast","champs_walkfast_fq","champs_walkfast_hw","champs_walkerrnd","champs_walkerrnd_fq","champs_walkerrnd_hw","champs_walkleisure","champs_walkleisure_fq","champs_walkleisure_hw","champs_ridebike","champs_ridebike_fq","champs_ridebike_hw","champs_othaerobic","champs_othaerobic_fq","champs_othaerobic_hw","champs_waterex","champs_waterex_fq","champs_waterex_hw","champs_swimmodfast","champs_swimmodfast_fq","champs_swimmodfast_hw","champs_swimgent","champs_swimgent_fq","champs_swimgent_hw","champs_stretch","champs_stretch_fq","champs_stretch_hw","champs_yoga","champs_yoga_fq","champs_yoga_hw","champs_aerobics","champs_aerobics_fq","champs_aerobics_hw","champs_strngtrnmodhv","champs_strngtrnmodhv_fq","champs_strngtrnmodhv_hw","champs_strngtrnlt","champs_strngtrnlt_fq","champs_strngtrnlt_hw","champs_genconditn","champs_genconditn_fq","champs_genconditn_hw","champs_plybbscrb","champs_plybbscrb_fq","champs_plybbscrb_hw","champs_othphysact","champs_othphysact_fq","champs_othphysact_hw","champs_complete"]
       # excluding the _fq - not used by champs R formula
       v_raw_tn_cn_array =["ptid","champs_visit_number","champs_frndfam","champs_frndfam_hw","champs_snrctr","champs_snrctr_hw","champs_volun","champs_volun_hw","champs_church","champs_church_hw","champs_clubmtg","champs_clubmtg_hw","champs_usecomp","champs_usecomp_hw","champs_dance","champs_dance_hw","champs_artcraft","champs_artcraft_hw","champs_golfcrryeqp","champs_golfcrryeqp_hw","champs_golfrde","champs_golfrde_hw","champs_concert","champs_concert_hw","champs_games","champs_games_hw","champs_pool","champs_pool_hw","champs_tennissng","champs_tennissng_hw","champs_tennisdbl","champs_tennisdbl_hw","champs_skate","champs_skate_hw","champs_plymuscins","champs_plymuscins_hw","champs_read","champs_read_hw","champs_hsehvywrk","champs_hsehvywrk_hw","champs_hseltwrk","champs_hseltwrk_hw","champs_grdnhvywrk","champs_grdnhvywrk_hw","champs_grdnltwrk","champs_grdnltwrk_hw","champs_wrkonmchn","champs_wrkonmchn_hw","champs_run","champs_run_hw","champs_walkuphll","champs_walkuphll_hw","champs_walkfast","champs_walkfast_hw","champs_walkerrnd","champs_walkerrnd_hw","champs_walkleisure","champs_walkleisure_hw","champs_ridebike","champs_ridebike_hw","champs_othaerobic","champs_othaerobic_hw","champs_waterex","champs_waterex_hw","champs_swimmodfast","champs_swimmodfast_hw","champs_swimgent","champs_swimgent_hw","champs_stretch","champs_stretch_hw","champs_yoga","champs_yoga_hw","champs_aerobics","champs_aerobics_hw","champs_strngtrnmodhv","champs_strngtrnmodhv_hw","champs_strngtrnlt","champs_strngtrnlt_hw","champs_genconditn","champs_genconditn_hw","champs_plybbscrb","champs_plybbscrb_hw","champs_othphysact","champs_othphysact_hw","champs_complete"]
       v_raw_tn_cn_order_dict ={'ptid' => '1', 'redcap_event_name' => '2', 'champs_visit_number' => '3', 'champs_frndfam' => '4', 'champs_frndfam_fq' => '5', 'champs_frndfam_hw' => '6', 'champs_snrctr' => '7', 'champs_snrctr_fq' => '8', 'champs_snrctr_hw' => '9', 'champs_volun' => '10', 'champs_volun_fq' => '11', 'champs_volun_hw' => '12', 'champs_church' => '13', 'champs_church_fq' => '14', 'champs_church_hw' => '15', 'champs_clubmtg' => '16', 'champs_clubmtg_fq' => '17', 'champs_clubmtg_hw' => '18', 'champs_usecomp' => '19', 'champs_usecomp_fq' => '20', 'champs_usecomp_hw' => '21', 'champs_dance' => '22', 'champs_dance_fq' => '23', 'champs_dance_hw' => '24', 'champs_artcraft' => '25', 'champs_artcraft_fq' => '26', 'champs_artcraft_hw' => '27', 'champs_golfcrryeqp' => '28', 'champs_golfcrryeqp_fq' => '29', 'champs_golfcrryeqp_hw' => '30', 'champs_golfrde' => '31', 'champs_golfrde_fq' => '32', 'champs_golfrde_hw' => '33', 'champs_concert' => '34', 'champs_concert_fq' => '35', 'champs_concert_hw' => '36', 'champs_games' => '37', 'champs_games_fq' => '38', 'champs_games_hw' => '39', 'champs_pool' => '40', 'champs_pool_fq' => '41', 'champs_pool_hw' => '42', 'champs_tennissng' => '43', 'champs_tennissng_fq' => '44', 'champs_tennissng_hw' => '45', 'champs_tennisdbl' => '46', 'champs_tennisdbl_fq' => '47', 'champs_tennisdbl_hw' => '48', 'champs_skate' => '49', 'champs_skate_fq' => '50', 'champs_skate_hw' => '51', 'champs_plymuscins' => '52', 'champs_plymuscins_fq' => '53', 'champs_plymuscins_hw' => '54', 'champs_read' => '55', 'champs_read_fq' => '56', 'champs_read_hw' => '57', 'champs_hsehvywrk' => '58', 'champs_hsehvywrk_fq' => '59', 'champs_hsehvywrk_hw' => '60', 'champs_hseltwrk' => '61', 'champs_hseltwrk_fq' => '62', 'champs_hseltwrk_hw' => '63', 'champs_grdnhvywrk' => '64', 'champs_grdnhvywrk_fq' => '65', 'champs_grdnhvywrk_hw' => '66', 'champs_grdnltwrk' => '67', 'champs_grdnltwrk_fq' => '68', 'champs_grdnltwrk_hw' => '69', 'champs_wrkonmchn' => '70', 'champs_wrkonmchn_fq' => '71', 'champs_wrkonmchn_hw' => '72', 'champs_run' => '73', 'champs_run_fq' => '74', 'champs_run_hw' => '75', 'champs_walkuphll' => '76', 'champs_walkuphll_fq' => '77', 'champs_walkuphll_hw' => '78', 'champs_walkfast' => '79', 'champs_walkfast_fq' => '80', 'champs_walkfast_hw' => '81', 'champs_walkerrnd' => '82', 'champs_walkerrnd_fq' => '83', 'champs_walkerrnd_hw' => '84', 'champs_walkleisure' => '85', 'champs_walkleisure_fq' => '86', 'champs_walkleisure_hw' => '87', 'champs_ridebike' => '88', 'champs_ridebike_fq' => '89', 'champs_ridebike_hw' => '90', 'champs_othaerobic' => '91', 'champs_othaerobic_fq' => '92', 'champs_othaerobic_hw' => '93', 'champs_waterex' => '94', 'champs_waterex_fq' => '95', 'champs_waterex_hw' => '96', 'champs_swimmodfast' => '97', 'champs_swimmodfast_fq' => '98', 'champs_swimmodfast_hw' => '99', 'champs_swimgent' => '100', 'champs_swimgent_fq' => '101', 'champs_swimgent_hw' => '102', 'champs_stretch' => '103', 'champs_stretch_fq' => '104', 'champs_stretch_hw' => '105', 'champs_yoga' => '106', 'champs_yoga_fq' => '107', 'champs_yoga_hw' => '108', 'champs_aerobics' => '109', 'champs_aerobics_fq' => '110', 'champs_aerobics_hw' => '111', 'champs_strngtrnmodhv' => '112', 'champs_strngtrnmodhv_fq' => '113', 'champs_strngtrnmodhv_hw' => '114', 'champs_strngtrnlt' => '115', 'champs_strngtrnlt_fq' => '116', 'champs_strngtrnlt_hw' => '117', 'champs_genconditn' => '118', 'champs_genconditn_fq' => '119', 'champs_genconditn_hw' => '120', 'champs_plybbscrb' => '121', 'champs_plybbscrb_fq' => '122', 'champs_plybbscrb_hw' => '123', 'champs_othphysact' => '124', 'champs_othphysact_fq' => '125', 'champs_othphysact_hw' => '126', 'champs_complete' => '127'}
       v_raw_key_cn_array =["ptid","champs_visit_number"]

       v_edit1_tn ="t_champs_adrc_alex_20180511"
       v_edit1_tn_cn_array = ["ptid","champs_visit_number","champs_frndfam","champs_frndfam_fq","champs_frndfam_hw","champs_snrctr","champs_snrctr_fq","champs_snrctr_hw","champs_volun","champs_volun_fq","champs_volun_hw","champs_church","champs_church_fq","champs_church_hw","champs_clubmtg","champs_clubmtg_fq","champs_clubmtg_hw","champs_usecomp","champs_usecomp_fq","champs_usecomp_hw","champs_dance","champs_dance_fq","champs_dance_hw","champs_artcraft","champs_artcraft_fq","champs_artcraft_hw","champs_golfcrryeqp","champs_golfcrryeqp_fq","champs_golfcrryeqp_hw","champs_golfrde","champs_golfrde_fq","champs_golfrde_hw","champs_concert","champs_concert_fq","champs_concert_hw","champs_games","champs_games_fq","champs_games_hw","champs_pool","champs_pool_fq","champs_pool_hw","champs_tennissng","champs_tennissng_fq","champs_tennissng_hw","champs_tennisdbl","champs_tennisdbl_fq","champs_tennisdbl_hw","champs_skate","champs_skate_fq","champs_skate_hw","champs_plymuscins","champs_plymuscins_fq","champs_plymuscins_hw","champs_read","champs_read_fq","champs_read_hw","champs_hsehvywrk","champs_hsehvywrk_fq","champs_hsehvywrk_hw","champs_hseltwrk","champs_hseltwrk_fq","champs_hseltwrk_hw","champs_grdnhvywrk","champs_grdnhvywrk_fq","champs_grdnhvywrk_hw","champs_grdnltwrk","champs_grdnltwrk_fq","champs_grdnltwrk_hw","champs_wrkonmchn","champs_wrkonmchn_fq","champs_wrkonmchn_hw","champs_run","champs_run_fq","champs_run_hw","champs_walkuphll","champs_walkuphll_fq","champs_walkuphll_hw","champs_walkfast","champs_walkfast_fq","champs_walkfast_hw","champs_walkerrnd","champs_walkerrnd_fq","champs_walkerrnd_hw","champs_walkleisure","champs_walkleisure_fq","champs_walkleisure_hw","champs_ridebike","champs_ridebike_fq","champs_ridebike_hw","champs_othaerobic","champs_othaerobic_fq","champs_othaerobic_hw","champs_waterex","champs_waterex_fq","champs_waterex_hw","champs_swimmodfast","champs_swimmodfast_fq","champs_swimmodfast_hw","champs_swimgent","champs_swimgent_fq","champs_swimgent_hw","champs_stretch","champs_stretch_fq","champs_stretch_hw","champs_yoga","champs_yoga_fq","champs_yoga_hw","champs_aerobics","champs_aerobics_fq","champs_aerobics_hw","champs_strngtrnmodhv","champs_strngtrnmodhv_fq","champs_strngtrnmodhv_hw","champs_strngtrnlt","champs_strngtrnlt_fq","champs_strngtrnlt_hw","champs_genconditn","champs_genconditn_fq","champs_genconditn_hw","champs_plybbscrb","champs_plybbscrb_fq","champs_plybbscrb_hw","champs_othphysact","champs_othphysact_fq","champs_othphysact_hw","champs_complete"]
       v_edit1_tn_cn_array =["ptid","champs_visit_number","champs_frndfam","champs_frndfam_hw","champs_snrctr","champs_snrctr_hw","champs_volun","champs_volun_hw","champs_church","champs_church_hw","champs_clubmtg","champs_clubmtg_hw","champs_usecomp","champs_usecomp_hw","champs_dance","champs_dance_hw","champs_artcraft","champs_artcraft_hw","champs_golfcrryeqp","champs_golfcrryeqp_hw","champs_golfrde","champs_golfrde_hw","champs_concert","champs_concert_hw","champs_games","champs_games_hw","champs_pool","champs_pool_hw","champs_tennissng","champs_tennissng_hw","champs_tennisdbl","champs_tennisdbl_hw","champs_skate","champs_skate_hw","champs_plymuscins","champs_plymuscins_hw","champs_read","champs_read_hw","champs_hsehvywrk","champs_hsehvywrk_hw","champs_hseltwrk","champs_hseltwrk_hw","champs_grdnhvywrk","champs_grdnhvywrk_hw","champs_grdnltwrk","champs_grdnltwrk_hw","champs_wrkonmchn","champs_wrkonmchn_hw","champs_run","champs_run_hw","champs_walkuphll","champs_walkuphll_hw","champs_walkfast","champs_walkfast_hw","champs_walkerrnd","champs_walkerrnd_hw","champs_walkleisure","champs_walkleisure_hw","champs_ridebike","champs_ridebike_hw","champs_othaerobic","champs_othaerobic_hw","champs_waterex","champs_waterex_hw","champs_swimmodfast","champs_swimmodfast_hw","champs_swimgent","champs_swimgent_hw","champs_stretch","champs_stretch_hw","champs_yoga","champs_yoga_hw","champs_aerobics","champs_aerobics_hw","champs_strngtrnmodhv","champs_strngtrnmodhv_hw","champs_strngtrnlt","champs_strngtrnlt_hw","champs_genconditn","champs_genconditn_hw","champs_plybbscrb","champs_plybbscrb_hw","champs_othphysact","champs_othphysact_hw","champs_complete"]
       v_edit1_tn_cn_order_dict ={'ptid' => '1', 'redcap_event_name' => '2', 'champs_visit_number' => '3', 'champs_frndfam' => '4', 'champs_frndfam_fq' => '5', 'champs_frndfam_hw' => '6', 'champs_snrctr' => '7', 'champs_snrctr_fq' => '8', 'champs_snrctr_hw' => '9', 'champs_volun' => '10', 'champs_volun_fq' => '11', 'champs_volun_hw' => '12', 'champs_church' => '13', 'champs_church_fq' => '14', 'champs_church_hw' => '15', 'champs_clubmtg' => '16', 'champs_clubmtg_fq' => '17', 'champs_clubmtg_hw' => '18', 'champs_usecomp' => '19', 'champs_usecomp_fq' => '20', 'champs_usecomp_hw' => '21', 'champs_dance' => '22', 'champs_dance_fq' => '23', 'champs_dance_hw' => '24', 'champs_artcraft' => '25', 'champs_artcraft_fq' => '26', 'champs_artcraft_hw' => '27', 'champs_golfcrryeqp' => '28', 'champs_golfcrryeqp_fq' => '29', 'champs_golfcrryeqp_hw' => '30', 'champs_golfrde' => '31', 'champs_golfrde_fq' => '32', 'champs_golfrde_hw' => '33', 'champs_concert' => '34', 'champs_concert_fq' => '35', 'champs_concert_hw' => '36', 'champs_games' => '37', 'champs_games_fq' => '38', 'champs_games_hw' => '39', 'champs_pool' => '40', 'champs_pool_fq' => '41', 'champs_pool_hw' => '42', 'champs_tennissng' => '43', 'champs_tennissng_fq' => '44', 'champs_tennissng_hw' => '45', 'champs_tennisdbl' => '46', 'champs_tennisdbl_fq' => '47', 'champs_tennisdbl_hw' => '48', 'champs_skate' => '49', 'champs_skate_fq' => '50', 'champs_skate_hw' => '51', 'champs_plymuscins' => '52', 'champs_plymuscins_fq' => '53', 'champs_plymuscins_hw' => '54', 'champs_read' => '55', 'champs_read_fq' => '56', 'champs_read_hw' => '57', 'champs_hsehvywrk' => '58', 'champs_hsehvywrk_fq' => '59', 'champs_hsehvywrk_hw' => '60', 'champs_hseltwrk' => '61', 'champs_hseltwrk_fq' => '62', 'champs_hseltwrk_hw' => '63', 'champs_grdnhvywrk' => '64', 'champs_grdnhvywrk_fq' => '65', 'champs_grdnhvywrk_hw' => '66', 'champs_grdnltwrk' => '67', 'champs_grdnltwrk_fq' => '68', 'champs_grdnltwrk_hw' => '69', 'champs_wrkonmchn' => '70', 'champs_wrkonmchn_fq' => '71', 'champs_wrkonmchn_hw' => '72', 'champs_run' => '73', 'champs_run_fq' => '74', 'champs_run_hw' => '75', 'champs_walkuphll' => '76', 'champs_walkuphll_fq' => '77', 'champs_walkuphll_hw' => '78', 'champs_walkfast' => '79', 'champs_walkfast_fq' => '80', 'champs_walkfast_hw' => '81', 'champs_walkerrnd' => '82', 'champs_walkerrnd_fq' => '83', 'champs_walkerrnd_hw' => '84', 'champs_walkleisure' => '85', 'champs_walkleisure_fq' => '86', 'champs_walkleisure_hw' => '87', 'champs_ridebike' => '88', 'champs_ridebike_fq' => '89', 'champs_ridebike_hw' => '90', 'champs_othaerobic' => '91', 'champs_othaerobic_fq' => '92', 'champs_othaerobic_hw' => '93', 'champs_waterex' => '94', 'champs_waterex_fq' => '95', 'champs_waterex_hw' => '96', 'champs_swimmodfast' => '97', 'champs_swimmodfast_fq' => '98', 'champs_swimmodfast_hw' => '99', 'champs_swimgent' => '100', 'champs_swimgent_fq' => '101', 'champs_swimgent_hw' => '102', 'champs_stretch' => '103', 'champs_stretch_fq' => '104', 'champs_stretch_hw' => '105', 'champs_yoga' => '106', 'champs_yoga_fq' => '107', 'champs_yoga_hw' => '108', 'champs_aerobics' => '109', 'champs_aerobics_fq' => '110', 'champs_aerobics_hw' => '111', 'champs_strngtrnmodhv' => '112', 'champs_strngtrnmodhv_fq' => '113', 'champs_strngtrnmodhv_hw' => '114', 'champs_strngtrnlt' => '115', 'champs_strngtrnlt_fq' => '116', 'champs_strngtrnlt_hw' => '117', 'champs_genconditn' => '118', 'champs_genconditn_fq' => '119', 'champs_genconditn_hw' => '120', 'champs_plybbscrb' => '121', 'champs_plybbscrb_fq' => '122', 'champs_plybbscrb_hw' => '123', 'champs_othphysact' => '124', 'champs_othphysact_fq' => '125', 'champs_othphysact_hw' => '126', 'champs_complete' => '127'}
       v_edit1_key_cn_array =["ptid","champs_visit_number"]

       v_edit2_tn ="t_champs_adrc_kaitlin_20180511"
       v_edit2_tn_cn_array = ["ptid","visitnum","champs_frndfam","champs_frndfam_fq","champs_frndfam_hw","champs_snrctr","champs_snrctr_fq","champs_snrctr_hw","champs_volun","champs_volun_fq","champs_volun_hw","champs_church","champs_church_fq","champs_church_hw","champs_clubmtg","champs_clubmtg_fq","champs_clubmtg_hw","champs_usecomp","champs_usecomp_fq","champs_usecomp_hw","champs_dance","champs_dance_fq","champs_dance_hw","champs_artcraft","champs_artcraft_fq","champs_artcraft_hw","champs_golfcrryeqp","champs_golfcrryeqp_fq","champs_golfcrryeqp_hw","champs_golfrde","champs_golfrde_fq","champs_golfrde_hw","champs_concert","champs_concert_fq","champs_concert_hw","champs_games","champs_games_fq","champs_games_hw","champs_pool","champs_pool_fq","champs_pool_hw","champs_tennissng","champs_tennissng_fq","champs_tennissng_hw","champs_tennisdbl","champs_tennisdbl_fq","champs_tennisdbl_hw","champs_skate","champs_skate_fq","champs_skate_hw","champs_plymuscins","champs_plymuscins_fq","champs_plymuscins_hw","champs_read","champs_read_fq","champs_read_hw","champs_hsehvywrk","champs_hsehvywrk_fq","champs_hsehvywrk_hw","champs_hseltwrk","champs_hseltwrk_fq","champs_hseltwrk_hw","champs_grdnhvywrk","champs_grdnhvywrk_fq","champs_grdnhvywrk_hw","champs_grdnltwrk","champs_grdnltwrk_fq","champs_grdnltwrk_hw","champs_wrkonmchn","champs_wrkonmchn_fq","champs_wrkonmchn_hw","champs_run","champs_run_fq","champs_run_hw","champs_walkuphll","champs_walkuphll_fq","champs_walkuphll_hw","champs_walkfast","champs_walkfast_fq","champs_walkfast_hw","champs_walkerrnd","champs_walkerrnd_fq","champs_walkerrnd_hw","champs_walkleisure","champs_walkleisure_fq","champs_walkleisure_hw","champs_ridebike","champs_ridebike_fq","champs_ridebike_hw","champs_othaerobic","champs_othaerobic_fq","champs_othaerobic_hw","champs_waterex","champs_waterex_fq","champs_waterex_hw","champs_swimmodfast","champs_swimmodfast_fq","champs_swimmodfast_hw","champs_swimgent","champs_swimgent_fq","champs_swimgent_hw","champs_stretch","champs_stretch_fq","champs_stretch_hw","champs_yoga","champs_yoga_fq","champs_yoga_hw","champs_aerobics","champs_aerobics_fq","champs_aerobics_hw","champs_strngtrnmodhv","champs_strngtrnmodhv_fq","champs_strngtrnmodhv_hw","champs_strngtrnlt","champs_strngtrnlt_fq","champs_strngtrnlt_hw","champs_genconditn","champs_genconditn_fq","champs_genconditn_hw","champs_plybbscrb","champs_plybbscrb_fq","champs_plybbscrb_hw","champs_othphysact","champs_othphysact_fq","champs_othphysact_hw","champs_complete"]
       v_edit2_tn_cn_array =["ptid","visitnum","champs_frndfam","champs_frndfam_hw","champs_snrctr","champs_snrctr_hw","champs_volun","champs_volun_hw","champs_church","champs_church_hw","champs_clubmtg","champs_clubmtg_hw","champs_usecomp","champs_usecomp_hw","champs_dance","champs_dance_hw","champs_artcraft","champs_artcraft_hw","champs_golfcrryeqp","champs_golfcrryeqp_hw","champs_golfrde","champs_golfrde_hw","champs_concert","champs_concert_hw","champs_games","champs_games_hw","champs_pool","champs_pool_hw","champs_tennissng","champs_tennissng_hw","champs_tennisdbl","champs_tennisdbl_hw","champs_skate","champs_skate_hw","champs_plymuscins","champs_plymuscins_hw","champs_read","champs_read_hw","champs_hsehvywrk","champs_hsehvywrk_hw","champs_hseltwrk","champs_hseltwrk_hw","champs_grdnhvywrk","champs_grdnhvywrk_hw","champs_grdnltwrk","champs_grdnltwrk_hw","champs_wrkonmchn","champs_wrkonmchn_hw","champs_run","champs_run_hw","champs_walkuphll","champs_walkuphll_hw","champs_walkfast","champs_walkfast_hw","champs_walkerrnd","champs_walkerrnd_hw","champs_walkleisure","champs_walkleisure_hw","champs_ridebike","champs_ridebike_hw","champs_othaerobic","champs_othaerobic_hw","champs_waterex","champs_waterex_hw","champs_swimmodfast","champs_swimmodfast_hw","champs_swimgent","champs_swimgent_hw","champs_stretch","champs_stretch_hw","champs_yoga","champs_yoga_hw","champs_aerobics","champs_aerobics_hw","champs_strngtrnmodhv","champs_strngtrnmodhv_hw","champs_strngtrnlt","champs_strngtrnlt_hw","champs_genconditn","champs_genconditn_hw","champs_plybbscrb","champs_plybbscrb_hw","champs_othphysact","champs_othphysact_hw","champs_complete"]
       v_edit2_tn_cn_order_dict ={'ptid' => '1', 'redcap_event_name' => '2', 'champs_visit_number' => '3', 'champs_frndfam' => '4', 'champs_frndfam_fq' => '5', 'champs_frndfam_hw' => '6', 'champs_snrctr' => '7', 'champs_snrctr_fq' => '8', 'champs_snrctr_hw' => '9', 'champs_volun' => '10', 'champs_volun_fq' => '11', 'champs_volun_hw' => '12', 'champs_church' => '13', 'champs_church_fq' => '14', 'champs_church_hw' => '15', 'champs_clubmtg' => '16', 'champs_clubmtg_fq' => '17', 'champs_clubmtg_hw' => '18', 'champs_usecomp' => '19', 'champs_usecomp_fq' => '20', 'champs_usecomp_hw' => '21', 'champs_dance' => '22', 'champs_dance_fq' => '23', 'champs_dance_hw' => '24', 'champs_artcraft' => '25', 'champs_artcraft_fq' => '26', 'champs_artcraft_hw' => '27', 'champs_golfcrryeqp' => '28', 'champs_golfcrryeqp_fq' => '29', 'champs_golfcrryeqp_hw' => '30', 'champs_golfrde' => '31', 'champs_golfrde_fq' => '32', 'champs_golfrde_hw' => '33', 'champs_concert' => '34', 'champs_concert_fq' => '35', 'champs_concert_hw' => '36', 'champs_games' => '37', 'champs_games_fq' => '38', 'champs_games_hw' => '39', 'champs_pool' => '40', 'champs_pool_fq' => '41', 'champs_pool_hw' => '42', 'champs_tennissng' => '43', 'champs_tennissng_fq' => '44', 'champs_tennissng_hw' => '45', 'champs_tennisdbl' => '46', 'champs_tennisdbl_fq' => '47', 'champs_tennisdbl_hw' => '48', 'champs_skate' => '49', 'champs_skate_fq' => '50', 'champs_skate_hw' => '51', 'champs_plymuscins' => '52', 'champs_plymuscins_fq' => '53', 'champs_plymuscins_hw' => '54', 'champs_read' => '55', 'champs_read_fq' => '56', 'champs_read_hw' => '57', 'champs_hsehvywrk' => '58', 'champs_hsehvywrk_fq' => '59', 'champs_hsehvywrk_hw' => '60', 'champs_hseltwrk' => '61', 'champs_hseltwrk_fq' => '62', 'champs_hseltwrk_hw' => '63', 'champs_grdnhvywrk' => '64', 'champs_grdnhvywrk_fq' => '65', 'champs_grdnhvywrk_hw' => '66', 'champs_grdnltwrk' => '67', 'champs_grdnltwrk_fq' => '68', 'champs_grdnltwrk_hw' => '69', 'champs_wrkonmchn' => '70', 'champs_wrkonmchn_fq' => '71', 'champs_wrkonmchn_hw' => '72', 'champs_run' => '73', 'champs_run_fq' => '74', 'champs_run_hw' => '75', 'champs_walkuphll' => '76', 'champs_walkuphll_fq' => '77', 'champs_walkuphll_hw' => '78', 'champs_walkfast' => '79', 'champs_walkfast_fq' => '80', 'champs_walkfast_hw' => '81', 'champs_walkerrnd' => '82', 'champs_walkerrnd_fq' => '83', 'champs_walkerrnd_hw' => '84', 'champs_walkleisure' => '85', 'champs_walkleisure_fq' => '86', 'champs_walkleisure_hw' => '87', 'champs_ridebike' => '88', 'champs_ridebike_fq' => '89', 'champs_ridebike_hw' => '90', 'champs_othaerobic' => '91', 'champs_othaerobic_fq' => '92', 'champs_othaerobic_hw' => '93', 'champs_waterex' => '94', 'champs_waterex_fq' => '95', 'champs_waterex_hw' => '96', 'champs_swimmodfast' => '97', 'champs_swimmodfast_fq' => '98', 'champs_swimmodfast_hw' => '99', 'champs_swimgent' => '100', 'champs_swimgent_fq' => '101', 'champs_swimgent_hw' => '102', 'champs_stretch' => '103', 'champs_stretch_fq' => '104', 'champs_stretch_hw' => '105', 'champs_yoga' => '106', 'champs_yoga_fq' => '107', 'champs_yoga_hw' => '108', 'champs_aerobics' => '109', 'champs_aerobics_fq' => '110', 'champs_aerobics_hw' => '111', 'champs_strngtrnmodhv' => '112', 'champs_strngtrnmodhv_fq' => '113', 'champs_strngtrnmodhv_hw' => '114', 'champs_strngtrnlt' => '115', 'champs_strngtrnlt_fq' => '116', 'champs_strngtrnlt_hw' => '117', 'champs_genconditn' => '118', 'champs_genconditn_fq' => '119', 'champs_genconditn_hw' => '120', 'champs_plybbscrb' => '121', 'champs_plybbscrb_fq' => '122', 'champs_plybbscrb_hw' => '123', 'champs_othphysact' => '124', 'champs_othphysact_fq' => '125', 'champs_othphysact_hw' => '126', 'champs_complete' => '127'}
       v_edit2_key_cn_array =["ptid","visitnum"]

       v_diff_tn = "t_champs_diff_20180511"
       v_diff_tn_cn_array = ['subjectid','visno','diff_type','raw_tn','raw_tn_cn','raw_value','use_raw_flag','edit1_tn','edit1_tn_cn','edit1_value','use_edit1_flag','edit2_tn','edit2_tn_cn','edit2_value','use_edit2_flag','column_order']
       v_diff_key_cn_array =["subjectid","visno"]
       v_value_size = 100
       v_sql_diff_insert = "insert into "+v_diff_tn+"("+v_diff_tn_cn_array.join(",")+")"
       # limit of 100 characters
        

       sql_base = "select "+v_raw_key_cn_array.join(",")+" from "+v_raw_tn+" where "
       v_cnt = 0
       v_raw_key_cn_array.each do |key_cn|
              if v_cnt > 0
                 sql_base = sql_base+" and "
              end
              sql_base = sql_base+" "+key_cn+" is not null and "+key_cn+" > '' "
              v_cnt = v_cnt +1
       end
#puts sql_base
       @results = connection.execute(sql_base)
       # using 2 key columns - need to make generic
       # using 2 edit tables - need to make generic
         v_diff_type = v_edit1_tn+" vs "+v_edit2_tn
          sql_delete = "delete from "+v_diff_tn+" where diff_type = '"+v_diff_type+"'"
          @results_delete = connection.execute(sql_delete)
          v_diff_type = v_raw_tn+" vs "+v_edit1_tn+" or "+v_edit2_tn
          sql_delete = "delete from "+v_diff_tn+" where diff_type = '"+v_diff_type+"'"
          @results_delete = connection.execute(sql_delete)

       @results.each do |user|
          v_key1 = user[0]
          v_key2 = user[1]
          v_diff_type = v_edit1_tn+" vs "+v_edit2_tn
          v_cnt = 0
          v_raw_tn_cn_array.each do |raw_cn|
            # exclude key column?
             sql_compare = " select "
                 v_raw_key_cn_array.each do |raw_key|
                        sql_compare = sql_compare +" "+v_raw_tn+"."+raw_key+","
                 end
                 v_edit1_key_cn_array.each do |edit1_key|
                        sql_compare = sql_compare +" "+v_edit1_tn+"."+edit1_key+","
                 end
                 v_edit2_key_cn_array.each do |edit2_key|
                        sql_compare = sql_compare +" "+v_edit2_tn+"."+edit2_key+","
                 end
                 sql_compare = sql_compare +" "+v_raw_tn+"."+raw_cn+","
                 sql_compare = sql_compare +" "+v_edit1_tn+"."+v_edit1_tn_cn_array[v_cnt]+","
                 sql_compare = sql_compare +" "+v_edit2_tn+"."+v_edit2_tn_cn_array[v_cnt]+" "
                 sql_compare = sql_compare +" from "+v_raw_tn+","+v_edit1_tn+","+v_edit2_tn+" "
                 sql_compare = sql_compare +" where "+v_edit1_tn+"."+v_edit1_tn_cn_array[v_cnt]+" != "+v_edit2_tn+"."+v_edit2_tn_cn_array[v_cnt]
                 v_cnt_key = 0
                 v_raw_key_cn_array.each do |raw_key|
                       sql_compare = sql_compare +" and "+v_raw_tn+"."+raw_key+" = '"+user[v_cnt_key]+"' and "+v_raw_tn+"."+raw_key+" = "+v_edit1_tn+"."+v_edit1_key_cn_array[v_cnt_key]+" and "+v_raw_tn+"."+raw_key+" = "+v_edit2_tn+"."+v_edit2_key_cn_array[v_cnt_key]+" "
                   v_cnt_key = v_cnt_key + 1
                 end
#puts sql_compare
            

             @results_compare = connection.execute(sql_compare)
             @results_compare.each do |r_compare|
               #puts v_diff_type
               sql_diff_insert = v_sql_diff_insert+" VALUES( '"+v_key1+"','"+v_key2+"','"+v_diff_type+"','"+v_raw_tn+"','"+raw_cn+"','"+r_compare[6].to_s+"','N','"+v_edit1_tn+"','"+v_edit1_tn_cn_array[v_cnt].to_s+"','"+r_compare[7].to_s+"','N','"+v_edit2_tn+"','"+v_edit2_tn_cn_array[v_cnt].to_s+"','"+r_compare[8].to_s+"','N','"+v_raw_tn_cn_order_dict[raw_cn].to_s+"')"
               #puts sql_diff_insert          
               @results_insert = connection.execute(sql_diff_insert)
             end
             v_cnt = v_cnt + 1
          end


          v_diff_type = v_raw_tn+" vs "+v_edit1_tn+" or "+v_edit2_tn
          #puts v_diff_type
          v_cnt = 0
          v_raw_tn_cn_array.each do |raw_cn|
             sql_compare = " select "
                 v_raw_key_cn_array.each do |raw_key|
                        sql_compare = sql_compare +" "+v_raw_tn+"."+raw_key+","
                 end
                 v_edit1_key_cn_array.each do |edit1_key|
                        sql_compare = sql_compare +" "+v_edit1_tn+"."+edit1_key+","
                 end
                 v_edit2_key_cn_array.each do |edit2_key|
                        sql_compare = sql_compare +" "+v_edit2_tn+"."+edit2_key+","
                 end

                 sql_compare = sql_compare +" "+v_raw_tn+"."+raw_cn+","
                 sql_compare = sql_compare +" "+v_edit1_tn+"."+v_edit1_tn_cn_array[v_cnt]+","
                 sql_compare = sql_compare +" "+v_edit2_tn+"."+v_edit2_tn_cn_array[v_cnt]+" "
                 sql_compare = sql_compare +" from "+v_raw_tn+","+v_edit1_tn+","+v_edit2_tn+" "
                 sql_compare = sql_compare +" where "+v_edit1_tn+"."+v_edit1_tn_cn_array[v_cnt]+" = "+v_edit2_tn+"."+v_edit2_tn_cn_array[v_cnt]
                sql_compare = sql_compare +" and ("+v_raw_tn+"."+v_raw_tn_cn_array[v_cnt]+" != "+v_edit1_tn+"."+v_edit1_tn_cn_array[v_cnt]
                sql_compare = sql_compare +" or "+v_raw_tn+"."+v_raw_tn_cn_array[v_cnt]+" != "+v_edit2_tn+"."+v_edit2_tn_cn_array[v_cnt]+" )"
                 v_cnt_key = 0
                 v_raw_key_cn_array.each do |raw_key|
                       sql_compare = sql_compare +" and "+v_raw_tn+"."+raw_key+" = '"+user[v_cnt_key]+"' and "+v_raw_tn+"."+raw_key+" = "+v_edit1_tn+"."+v_edit1_key_cn_array[v_cnt_key]+" and "+v_raw_tn+"."+raw_key+" = "+v_edit2_tn+"."+v_edit2_key_cn_array[v_cnt_key]+" "
                   v_cnt_key = v_cnt_key + 1
                 end
             @results_compare = connection.execute(sql_compare)
             @results_compare.each do |r_compare|
               #puts  v_diff_type
               sql_diff_insert = v_sql_diff_insert+" VALUES( '"+v_key1.to_s+"','"+v_key2.to_s+"','"+v_diff_type+"','"+v_raw_tn+"','"+raw_cn+"','"+r_compare[6].to_s+"','N','"+v_edit1_tn+"','"+v_edit1_tn_cn_array[v_cnt].to_s+"','"+r_compare[7].to_s+"','N','"+v_edit2_tn+"','"+v_edit2_tn_cn_array[v_cnt].to_s+"','"+r_compare[8].to_s+"','N','"+v_raw_tn_cn_order_dict[raw_cn].to_s+"')"
               #puts sql_diff_insert      
               @results_insert = connection.execute(sql_diff_insert)
             end
             v_cnt = v_cnt + 1
          end
        

       end




    @schedulerun.comment =("successful finish table_cell_comparison "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
       @schedulerun.status_flag ="Y"
     end
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save  
  end
  def run_t1seg_spm8_gm_wm_csf_volumes

    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "t1seg_spm8_gm_wm_csf_volumes"
    v_script_dev = v_base_path+"/data1/lab_scripts/T1SegProc/v4.1/t1segproc.sh"
    v_script = v_base_path+"/SysAdmin/production/T1SegProc/v4.1/t1segproc.sh"
    v_computer = "kanga"
    # only in dev
    v_script = v_script_dev
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('t1seg_spm8_gm_wm_csf_volumes')").first
      v_runner_email = self.get_user_email()  #  want to send errors to the user running the process
      v_schedule_owner_email_array = []
      if !v_runner_email.blank?
        v_schedule_owner_email_array.push(v_runner_email)
      else
        v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
      end
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting t1seg_spm8_gm_wm_csf_volumes"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_error_comment = ""
      t = Time.now
      v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
      v_log_name =v_process_name+"_"+v_date_YM
      v_log_path =v_log_base+v_log_name 
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
      v_comment_base = @schedulerun.comment
    connection = ActiveRecord::Base.connection();
    v_secondary_key_array =["b","c","d","e",".R"]
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"
    sp_exclude_array = [33,40,62,53,54,55,56,57]
    @scan_procedures = ScanProcedure.where("scan_procedures.id not in (?)", sp_exclude_array)
    @scan_procedures.each do |sp|
      @schedulerun.comment = "start "+sp.codename+" "+v_comment_base
      @schedulerun.save
        v_visit_number =""
        if sp.codename.include?("visit2")
            v_visit_number ="_v2"
        elsif sp.codename.include?("visit3")
            v_visit_number ="_v3"
        elsif sp.codename.include?("visit4")
            v_visit_number ="_v4"
        elsif sp.codename.include?("visit5")
            v_visit_number ="_v5"
        end   
        v_preprocessed_full_path = v_preprocessed_path+sp.codename  
        if File.directory?(v_preprocessed_full_path)
          sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups,  appointments, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+"  
                                    and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
          @results = connection.execute(sql_enum)
                                    
          @results.each do |r|
              enrollment = Enrollment.where("enumber='"+r[0]+"'")
              if !enrollment.blank?
                v_log = ""
                v_subjectid_path = v_preprocessed_full_path+"/"+enrollment[0].enumber
                v_subjectid = enrollment[0].enumber
                v_subjectid_v_num = enrollment[0].enumber + v_visit_number
                @schedulerun.comment = "start "+v_subjectid_v_num+" "+v_comment_base
                @schedulerun.save
                v_subjectid_unknown =v_subjectid_path+"/unknown"
                v_subjectid_array = []
                if File.directory?(v_subjectid_unknown)
                     v_subjectid_array.push(v_subjectid)
                 end
                 v_secondary_key_array.each do |k|
                    if File.directory?(v_subjectid_path+k+"/unknown")
                        v_subjectid_array.push((v_subjectid+k))
                    end
                 end
                v_subjectid_array = v_subjectid_array.uniq
                v_subjectid_array.each do |subj|
                  v_subjectid = subj
                  v_subjectid_v_num = subj + v_visit_number
                  v_subjectid_path = v_preprocessed_full_path+"/"+subj
                  v_subjectid_unknown =v_subjectid_path+"/unknown"
                  if File.directory?(v_subjectid_unknown)
                    v_dir_array = Dir.entries(v_subjectid_unknown)
                    v_dir_array.each do |f|
                    if f.start_with?("o") and f.end_with?(".nii")
                        # check for t1_aligned_newseg
                        v_subjectid_t1_aligned_newseg =v_subjectid_path+"/t1_aligned_newseg"
                        if File.directory?(v_subjectid_t1_aligned_newseg) or !File.directory?(v_subjectid_t1_aligned_newseg) # makes file
                          if !File.file?(v_subjectid_t1_aligned_newseg+"/segtotals.txt") 
                             v_comment = "str "+v_subjectid_v_num+";"+v_comment
#puts " RUN t1segproc.sh for "+f+"    "+v_subjectid_v_num+"  "+v_subjectid_t1_aligned_newseg
                             v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "'  +v_script+' -p '+sp.codename+'  -b '+v_subjectid+' --all "  ' 
                             v_log = v_log + v_call+"\n"
                             begin
                               stdin, stdout, stderr = Open3.popen3(v_call)
                               rescue => msg  
                                  v_log = v_log + msg+"\n"  
                             end
                             v_success ="N"
                             while !stdout.eof?
                                v_output = stdout.read 1024 
                                v_log = v_log + v_output  
                                if (v_log.tr("\n","")).include? "get_totals.m output saved to"  # line wrapping? Done ==> Do\nne
                                  v_success ="Y"
                                  v_log = v_log + "SUCCESS !!!!!!!!! \n"
                                end
                                puts v_output  
                             end
                             v_err =""
                             v_log = v_log +"IN ERROR \n"
                             while !stderr.eof?
                               v_err = stderr.read 1024
                               v_log = v_log +v_err
                              end
                              if v_err > ""
                                 v_schedule_owner_email_array.each do |e|
                                    v_subject = "Error in "+v_process_name+": "+v_subjectid_v_num+ " see ==> "+v_log_path+" <== ALl the output from process is in the file."
                                    PandaMailer.schedule_notice(v_subject,{:send_to => e}).deliver
                                end
                              end
                   #           puts "err="+v_err
                              if v_success == "N"
                                 v_comment_warning = " "+ v_subjectid_v_num +"; "+v_comment_warning 
                                 v_log = "warning on "+ v_subjectid_v_num +"; "+v_log
                              end
                              process_log_append(v_log_path, v_log)
                          end
                        end
                    end
                   end 
                  end 
                end
              end
           end
        end
     end
    if v_comment_warning > ""
        v_comment_warning = "warning on "+v_comment_warning
    end
    @schedulerun.comment =("successful finish t1seg_spm8_gm_wm_csf_volumes "+v_comment_warning+" "+v_comment[0..3900])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
    
  end

   # data request from anders wahlin for adrc - t1/resting bold => /unknown, asl => /asl
  # from cg_adrc_upload 
  # wahlin_t1_asl_resting_sent_flag = Y means the files has been uploaded
  # wahlin_t1_asl_resting_status_flag = N means do not upload this subjectid
  def run_wahlin_t1_asl_resting
    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "wahlin_t1_asl_resting"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('wahlin_t1_asl_resting')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting wahlin_t1_asl_resting_upload-MOVED TO SHARED_RETIRED"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
 
  end

  def run_tissueseg_spm12

    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "tissueseg_spm12"
    v_script_dev = v_base_path+"/data1/lab_scripts/T1SegProc/v5/t1segproc.sh"
    v_script = v_base_path+"/SysAdmin/production/T1SegProc/v5/t1segproc.sh"
    v_computer = "kanga"
    # only in dev
    v_script = v_script_dev
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('tissueseg_spm12')").first
      v_runner_email = self.get_user_email()  #  want to send errors to the user running the process
      v_schedule_owner_email_array = []
      if !v_runner_email.blank?
        v_schedule_owner_email_array.push(v_runner_email)
      else
        v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
      end
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting tissueseg_spm12"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_error_comment = ""
      t = Time.now
      v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
      v_log_name =v_process_name+"_"+v_date_YM
      v_log_path =v_log_base+v_log_name 
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
      v_comment_base = @schedulerun.comment
    connection = ActiveRecord::Base.connection();
    v_secondary_key_array =["b","c","d","e",".R"]
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"
    sp_exclude_array = [33,40,62,53,54,55,56,57]
    @scan_procedures = ScanProcedure.where("scan_procedures.id not in (?)", sp_exclude_array)
    @scan_procedures.each do |sp|
       @schedulerun.comment = "start "+sp.codename+" "+v_comment_base
      @schedulerun.save
      v_visit_number =""
      if sp.codename.include?("visit2")
            v_visit_number ="_v2"
      elsif sp.codename.include?("visit3")
            v_visit_number ="_v3"
      elsif sp.codename.include?("visit4")
            v_visit_number ="_v4"
      elsif sp.codename.include?("visit5")
            v_visit_number ="_v5"
      end   
      v_preprocessed_full_path = v_preprocessed_path+sp.codename  
      v_log_msg = "Starting scan protocol "+v_preprocessed_full_path
      process_log_append(v_log_path, v_log_msg)
      if File.directory?(v_preprocessed_full_path)
        sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups,  appointments, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+"  
                                    and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
        @results = connection.execute(sql_enum)
                                    
        @results.each do |r|
          enrollment = Enrollment.where("enumber='"+r[0]+"'")
          if !enrollment.blank?
            v_log = ""
            v_subjectid_path = v_preprocessed_full_path+"/"+enrollment[0].enumber
            v_subjectid = enrollment[0].enumber
            v_subjectid_v_num = enrollment[0].enumber + v_visit_number
            @schedulerun.comment = "start "+v_subjectid_v_num+" "+v_comment_base
            @schedulerun.save
            v_subjectid_unknown =v_subjectid_path+"/unknown"
            v_subjectid_array = []
            begin
              if File.directory?(v_subjectid_unknown)
                v_subjectid_array.push(v_subjectid)
              end
              v_secondary_key_array.each do |k|
                if File.directory?(v_subjectid_path+k+"/unknown")
                  v_subjectid_array.push((v_subjectid+k))
                end
              end
             rescue => msg  
                v_log = v_log + "IN RESCUE ERROR "+msg+"\n"  
            end
            v_subjectid_array = v_subjectid_array.uniq
            v_subjectid_array.each do |subj|
              v_subjectid = subj
              v_subjectid_v_num = subj + v_visit_number
              v_subjectid_path = v_preprocessed_full_path+"/"+subj
              v_subjectid_unknown =v_subjectid_path+"/unknown"
              if File.directory?(v_subjectid_unknown)
                v_dir_array = Dir.entries(v_subjectid_unknown)
                v_dir_array.each do |f|
                  if f.start_with?("o") and f.end_with?(".nii")
                    # check for tissue_seg
                    v_subjectid_tissue_seg =v_subjectid_path+"/tissue_seg"
                    if !File.directory?(v_subjectid_tissue_seg)  # or !File.directory?(v_subjectid_tissue_seg) # makes file
                      # if want to run everywhere with out csv
                     #if Dir.glob(v_subjectid_tissue_seg+"/*.csv").empty?
                        v_comment = "str "+v_subjectid_v_num+";"+v_comment
#puts " RUN t1segproc.sh for "+f+"    "+v_subjectid_v_num+"  "+v_subjectid_tissue_seg
                        v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "'  +v_script+' -p '+sp.codename+'  -b '+v_subjectid+' " ' 
                        v_log = v_log + v_call+"\n"
                        begin
                          stdin, stdout, stderr = Open3.popen3(v_call)
                          rescue => msg  
                            v_log = v_log + msg+"\n"  
                        end
                        v_success ="N"
                        # open file, look for values 
                        v_tmp_data = "" 
                        v_tmp_data_array = [] 
                        if File.file?(v_subjectid_tissue_seg+"/tissue_volumes.csv")
                          ftxt = File.open(v_subjectid_tissue_seg+"/tissue_volumes.csv", "r") 
                          v_cnt = 1
                          ftxt.each_line do |line|
                            if v_cnt == 2
                              v_tmp_data = line
                            end
                            v_cnt = v_cnt + 1
                          end
                          ftxt.close
                          v_file = ""
                          v_gm = ""
                          v_wm = ""
                          v_csf = ""
                          v_tmp_data_array = v_tmp_data.strip.split(",")
                          if v_tmp_data_array.length >2
                            v_file = v_tmp_data_array[0]
                            v_gm =v_tmp_data_array[1]
                            v_wm  = v_tmp_data_array[2]
                            v_csf = v_tmp_data_array[3]
                          end
                          if v_wm > ""
                            v_success ="Y"
                            v_log = v_log + "SUCCESS !!!!!!!!! \n"
                          end
                        end     
                        v_err =""
                        v_log = v_log +"IN ERROR \n"
                        while !stderr.eof?
                          v_err = stderr.read 1024
                          v_log = v_log +v_err
                        end
                        if v_err > "" and !v_err.include? "No window system found.  Java option 'MWT' ignored."
                          v_schedule_owner_email_array.each do |e|
                          v_subject = "Error in "+v_process_name+": "+v_subjectid_v_num+ " see ==> "+v_log_path+" <== ALl the output from process is in the file."
                          PandaMailer.schedule_notice(v_subject,{:send_to => e}).deliver
                        end
                      end
                      #           puts "err="+v_err
                      if v_success == "N"
                        v_comment_warning = " "+ v_subjectid_v_num +"; "+v_comment_warning 
                        v_log = "warning on "+ v_subjectid_v_num +"; "+v_log
                      end
                      process_log_append(v_log_path, v_log)
                    end
                  end # if tissue seg
                end  # if acpc file
              end  # if unknown dir
            end # subject array
          end  # enum not blank
        end #  results loop
      end   # full path exisits
    end   # scan procedure loop
    if v_comment_warning > ""
        v_comment_warning = "warning on "+v_comment_warning
    end
    @schedulerun.comment =("successful finish tissueseg_spm12 "+v_comment_warning+" "+v_comment[0..3900])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
    
  end


  def run_tissueseg_spm12_gm_wm_csf_volumes

    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "tissueseg_spm12_gm_wm_csf_volumes"
    v_script_dev = v_base_path+"/data1/lab_scripts/rbmicvproc.sh"
    v_script = v_base_path+"/SysAdmin/production/rbmicvproc.sh"
    v_computer = "kanga"
    # only in dev
    v_script = v_script_dev
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('tissueseg_spm12_gm_wm_csf_volumes')").first
      v_runner_email = self.get_user_email()  #  want to send errors to the user running the process
      v_schedule_owner_email_array = []
      if !v_runner_email.blank?
        v_schedule_owner_email_array.push(v_runner_email)
      else
        v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
      end
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting tissueseg_spm12_gm_wm_csf_volumes"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      sql = "truncate table cg_rbm_icv_new"
      connection = ActiveRecord::Base.connection();        
      results = connection.execute(sql)

      sql_base = "insert into cg_rbm_icv_new(subjectid,secondary_key,enrollment_id, scan_procedure_id,source_file,volume1_gm,volume2_wm,volume3_csf,tissue_seg_dir_flag,rbm_icv)values(" 
      v_comment = ""
      v_comment_warning =""
      v_error_comment = ""
      t = Time.now
      v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
      v_log_name =v_process_name+"_"+v_date_YM
      v_log_path =v_log_base+v_log_name 
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
    connection = ActiveRecord::Base.connection();
    v_secondary_key_array =["b","c","d","e",".R"]
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"
    sp_exclude_array = [-1,62,53,54,55,56,57 ] # if tissuesegmentation run on plaque, ok to run rbm [33,40]
    # @scan_procedures = ScanProcedure.where("scan_procedures.id not in (?)", sp_exclude_array)
    # applying exclusion further down to prevent running the process
    @scan_procedures = ScanProcedure.all 
    v_comment_base = @schedulerun.comment
    @scan_procedures.each do |sp|
      @schedulerun.comment = "start "+sp.codename+" "+v_comment_base
      @schedulerun.save
        v_visit_number =""
        if sp.codename.include?("visit2")
            v_visit_number ="_v2"
        elsif sp.codename.include?("visit3")
            v_visit_number ="_v3"
        elsif sp.codename.include?("visit4")
            v_visit_number ="_v4"
        elsif sp.codename.include?("visit5")
            v_visit_number ="_v5"
        end   
        v_preprocessed_full_path = v_preprocessed_path+sp.codename  
        if File.directory?(v_preprocessed_full_path)
          sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups,  appointments, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+"  
                                    and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
          @results = connection.execute(sql_enum)
                                    
          @results.each do |r|
              enrollment = Enrollment.where("enumber='"+r[0]+"'")
              if !enrollment.blank?
                v_log = ""
                v_subjectid_path = v_preprocessed_full_path+"/"+enrollment[0].enumber
                v_subjectid = enrollment[0].enumber
                v_subjectid_v_num = enrollment[0].enumber + v_visit_number
                @schedulerun.comment = "start "+v_subjectid_v_num+" "+v_comment_base
                @schedulerun.save
                v_subjectid_unknown =v_subjectid_path+"/unknown"
                v_subjectid_array = []
                if File.directory?(v_subjectid_unknown)
                     v_subjectid_array.push(v_subjectid)
                 end
                 v_secondary_key_array.each do |k|
                    if File.directory?(v_subjectid_path+k+"/unknown")
                        v_subjectid_array.push((v_subjectid+k))
                    end
                 end
                v_subjectid_array = v_subjectid_array.uniq
                v_subjectid_array.each do |subj|
                  v_subjectid = subj
                  v_subjectid_actual = subj
                  v_secondary_key = ""
                  v_secondary_key_array.each do |k|
                    # if subjectid ends in secondary key, trim off
                    # get last character
                    v_last_char = v_subjectid.reverse[0,1].reverse
                    v_last_two_char = v_subjectid.reverse[0,2].reverse
                    if v_last_char == k
                        v_secondary_key = k
                        v_subjectid_actual = v_subjectid[0..-2]
                    elsif v_last_two_char == k
                        v_secondary_key = k
                        v_subjectid_actual = v_subjectid[0..-3]
                    end
                  end
                  v_subjectid_v_num = v_subjectid_actual + v_visit_number
                  v_subjectid_path = v_preprocessed_full_path+"/"+subj
                  v_subjectid_unknown =v_subjectid_path+"/unknown"
                  if File.directory?(v_subjectid_unknown)
                    v_dir_array = Dir.entries(v_subjectid_unknown)
                    v_dir_array.each do |f|
                    if (f.start_with?("o") and f.end_with?(".nii") )  or v_subjectid_actual.include?("shp")
                        # check for tissue_seg
                        v_subjectid_tissue_seg =v_subjectid_path+"/tissue_seg"
                        v_subjectid_rbm_icv =v_subjectid_path+"/rbm_icv"
                        if File.directory?(v_subjectid_tissue_seg)  # or !File.directory?(v_subjectid_tissue_seg) # makes file
                          if !File.file?(v_subjectid_tissue_seg+"/tissue_volumes.csv") 
                                v_comment_warning = " "+ v_subjectid_v_num +"; "+v_comment_warning 
                                 v_log = "warning on tissue seg volumes"+ v_subjectid_v_num +"; "+v_log

                          end
                          if !File.file?(v_subjectid_rbm_icv+"/volume_"+v_subjectid+"_rbm_icv_b90.txt")  and !(sp_exclude_array.include?(sp.id) )
                             v_comment = "str "+v_subjectid_v_num+";"+v_comment
#puts " RUN t1segproc.sh for "+f+"    "+v_subjectid_v_num+"  "+v_subjectid_tissue_seg
                             v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "'  +v_script+' -p '+sp.codename+'  -b '+v_subjectid+'"' 
                             v_log = v_log + v_call+"\n"
                             begin
                               stdin, stdout, stderr = Open3.popen3(v_call)
                               rescue => msg  
                                  v_log = v_log + msg+"\n"  
                             end
                             v_success ="N"
                             if File.file?(v_subjectid_rbm_icv+"/volume_"+v_subjectid+"_rbm_icv_b90.txt")
                               # open file, look for values 
                                     v_tmp_data = "" 
                                     ftxt = File.open(v_subjectid_rbm_icv+"/volume_"+v_subjectid+"_rbm_icv_b90.txt", "r") 
                                     v_cnt = 1
                                     ftxt.each_line do |line|
                                        if v_cnt == 1
                                           v_tmp_data = line.gsub("\n","").gsub("\r","")
                                        end
                                        v_cnt = v_cnt + 1
                                     end
                                     ftxt.close
                                    v_rbm_icv = ""
                                     if v_tmp_data > ''
                                        v_rbm_icv  = v_tmp_data
                                     end
                                    if v_wm > ""
                                       v_success ="Y"
                                       v_log = v_log + "SUCCESS !!!!!!!!! \n"
                                     end

                             end
                             v_err =""
                             v_log = v_log +"IN ERROR \n"
                             while !stderr.eof?
                               v_err = stderr.read 1024
                               v_log = v_log +v_err
                              end
                              if v_err > ""
                                 v_schedule_owner_email_array.each do |e|
                                    v_subject = "Error in "+v_process_name+": "+v_subjectid_v_num+ " see ==> "+v_log_path+" <== ALl the output from process is in the file."
                                    PandaMailer.schedule_notice(v_subject,{:send_to => e}).deliver
                                end
                              end
                   #           puts "err="+v_err
                              if v_success == "N"
                                 v_comment_warning = " "+ v_subjectid_v_num +"; "+v_comment_warning 
                                 v_log = "warning on rbm icv "+ v_subjectid_v_num +"; "+v_log
                              end
                              process_log_append(v_log_path, v_log)
                          end
                        end                          #harvest
                        if File.file?(v_subjectid_tissue_seg+"/tissue_volumes.csv") 
                               # open file, look for values 
                                     v_tmp_data = "" 
                                     v_tmp_data_array = []  
                                     ftxt = File.open(v_subjectid_tissue_seg+"/tissue_volumes.csv", "r") 
                                     v_cnt = 1
                                     ftxt.each_line do |line|
                                        if v_cnt == 2
                                           v_tmp_data = line
                                        end
                                        v_cnt = v_cnt + 1
                                     end
                                     ftxt.close
                                    v_file = ""
                                    v_gm = ""
                                    v_wm = ""
                                    v_csf = ""
                                    v_rbm_icv = ""
                                     v_tmp_data_array = v_tmp_data.strip.split(",")
                                     if v_tmp_data_array.length >2
                                        v_file = v_tmp_data_array[0].gsub(/'/,"")
                                    
                                        v_gm =v_tmp_data_array[1]
                                        v_wm  = v_tmp_data_array[2]
                                        v_csf = v_tmp_data_array[3]
                                     end
                                     if File.file?(v_subjectid_rbm_icv+"/volume_"+v_subjectid+"_rbm_icv_b90.txt") 
                                        v_tmp_data = "" 
                                       ftxt = File.open(v_subjectid_rbm_icv+"/volume_"+v_subjectid+"_rbm_icv_b90.txt", "r") 
                                       v_cnt = 1
                                       ftxt.each_line do |line|
                                        if v_cnt == 1
                                           v_tmp_data = line.gsub("\n","").gsub("\r","")
                                        end
                                        v_cnt = v_cnt + 1
                                       end
                                       ftxt.close
                                       if v_tmp_data > ''
                                          v_rbm_icv  = v_tmp_data.chomp()
                                       end
                                     end
                                     
sql = sql_base+"'"+enrollment[0].enumber+v_visit_number+"','"+v_secondary_key+"', "+enrollment[0].id.to_s+","+sp.id.to_s+",'"+v_file+"','"+v_gm+"','"+v_wm+"','"+v_csf+"','Y','"+v_rbm_icv+"')"
                                 results = connection.execute(sql)
                             else
sql = sql_base+"'"+enrollment[0].enumber+v_visit_number+"','"+v_secondary_key+"', "+enrollment[0].id.to_s+","+sp.id.to_s+",NULL,NULL,NULL,NULL,'N',NULL)"
                                 results = connection.execute(sql)
                        end
                    end
                   end 
                  end 
                end
              end
           end
        end
     end
    if v_comment_warning > ""
        v_comment_warning = "warning on "+v_comment_warning
    end
    v_comment = self.move_present_to_old_new_to_present("cg_rbm_icv",
             "subjectid,secondary_key,enrollment_id, scan_procedure_id,source_file,volume1_gm,volume2_wm,volume3_csf,tissue_seg_dir_flag,rbm_icv",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)
    @schedulerun.comment =("successful finish tissueseg_spm12_gm_wm_csf_volumes "+v_comment_warning+" "+v_comment[0..3900])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
    
  end


# for the scan share consortium - upload to washu
  def run_washu_upload   # CHNAGE _STATUS_FLAG = Y !!!!!!!
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('washu_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting washu_upload -MOVED TO SHARED_RETIRED.rb"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save    
    
  end
#NEED TO ADDD!!!!!
# exclude pilots vgroups.pilot_flag = 'N'
# exclude do not shares
# enrollments.do_nat_share_scans_flag = 'N'  
# exclude bad ids
 def run_xnat_upload
     v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "xnat_file"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('xnat_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting xnat_upload"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
      v_computer = "merida"

     v_scan_procedure_array = [26,41,77,91] #pdt's and mk
     v_series_description_category_array = ['T1_Volumetric','T2'] # mpnrage?
     v_series_description_category_id_array = [19, 20] #,1 ]
     v_project = "up-test"

     v_xnat_participant_tn = "xnat_participants"
     v_xnat_appointment_mri_tn ="xnat_mri_appointment"
     v_xnat_ids_tn = "xnat_image_datasets"
     v_working_directory = "/tmp/"   # v_base_path+"/xnat_dev"
     v_xnat_script_dir = v_base_path+"/analyses/rpcary/xnat/scripts/"   # WILL CHANGE LOCATIOON!!!!!
     v_script_dicom_clean = v_xnat_script_dir+"xnat_dicom_upload_cleaner.rb"

     connection = ActiveRecord::Base.connection();
     # get all participants in sp/id not in v_xnat_participant_tn
     #insert and make export_id
     sql = "insert into "+v_xnat_participant_tn+"(participant_id,xnat_exists_flag) 
               select distinct vgroups.participant_id,'N' from vgroups 
               where vgroups.participant_id not in ( select "+v_xnat_participant_tn+".participant_id from "+v_xnat_participant_tn+")
               and vgroups.pilot_flag = 'N'
               and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups 
                                    where scan_procedures_vgroups.scan_procedure_id in ("+v_scan_procedure_array.join(",")+")) 
               and vgroups.id in (select appointments.vgroup_id from appointments, visits, image_datasets, series_description_maps
                  where appointments.id = visits.appointment_id 
                    and visits.id = image_datasets.visit_id
                    and image_datasets.series_description = series_description_maps.series_description
                    and series_description_maps.series_description_type_id in ("+v_series_description_category_id_array.join(",")+") )" 
      results = connection.execute(sql)
      # add export_id
      sql = "select export_id from "+v_xnat_participant_tn+" where export_id is NOT NULL"
      v_exportid_results = connection.execute(sql)
      v_exportid_array = []
      v_exportid_results.each { |r| v_exportid_array << r }

     v_null_check_sql = "select participant_id from "+v_xnat_participant_tn+" where export_id is NULL and participant_id is not NULL"
     v_null_check_cnt = 0
     v_null_cnt_threshold = 10  # repeat 10 times increasing upper range
     while v_null_check_cnt < v_null_cnt_threshold
        v_null_check_cnt = v_null_check_cnt + 1
        v_null_results = connection.execute(v_null_check_sql)
        v_null_array = []
        v_null_results.each { |r| v_null_array << r[0] }
        v_null_count = v_null_array.count 
        if v_null_count > 0
          v_now = Time.new 
          v_date_seed = (v_now.to_i)*v_null_check_cnt
          v_array_cnt = 0
          v_rand_array = Array.new(2*v_null_check_cnt*v_null_results.count) {rand(v_null_count .. v_date_seed)}
          v_rand_array.each do |val|
            if(!v_exportid_array.include?(val))  and  (v_array_cnt < v_null_array.count)
              v_sql = "update "+v_xnat_participant_tn+" t1 
                      set t1.export_id = "+val.to_s+" where t1.participant_id ="+v_null_array[v_array_cnt].to_s
              v_exportid_array.push(val)
              v_update_results = connection.execute(v_sql)
              v_array_cnt = v_array_cnt + 1
            end
          end
        end
     end
# set xnat_do_not_share_flag
#set xnat_exists_flag = 'Y' after upload to xnat
     # get [vgroups]/appointmnent/visit - 
     sql = "insert into "+v_xnat_appointment_mri_tn+"(appointment_id, visit_id,xnat_exists_flag)
     select distinct appointments.id , visits.id, 'N' from appointments, visits
     where appointments.id = visits.appointment_id
     and appointments.vgroup_id in ( select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships, enrollments
                                        where enrollment_vgroup_memberships.enrollment_id = enrollments.id 
                                         and enrollments.do_not_share_scans_flag = 'N'  )
     and appointments.vgroup_id in ( select vgroups.id from vgroups where vgroups.pilot_flag = 'N')
     and appointments.vgroup_id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups 
                                    where scan_procedures_vgroups.scan_procedure_id in ("+v_scan_procedure_array.join(",")+")) 
               and visits.id in (select image_datasets.visit_id from image_datasets, series_description_maps
                  where image_datasets.series_description = series_description_maps.series_description
                    and series_description_maps.series_description_type_id in ("+v_series_description_category_id_array.join(",")+") )
      and (visits.appointment_id,visits.id) NOT IN (select "+v_xnat_appointment_mri_tn+".appointment_id,"+v_xnat_appointment_mri_tn+".visit_id 
                                                         from "+v_xnat_appointment_mri_tn+" )"

     results = connection.execute(sql)
  # doing full participant update - in case p.id changed - a mess either way - fixed or unfixed
     sql = "update "+v_xnat_appointment_mri_tn+" set participant_id = ( select vgroups.participant_id from vgroups, appointments  
                               where vgroups.id = appointments.vgroup_id and appointments.id = "+v_xnat_appointment_mri_tn+".appointment_id)"
     results = connection.execute(sql)


     # get path from appointment_id , get codename/sp , get start , update xnat_session_id  <sp enum start>_export_id_<v#>

     sql = "select "+v_xnat_appointment_mri_tn+".appointment_id, "+v_xnat_participant_tn+".export_id, visits.path
       from "+v_xnat_appointment_mri_tn+","+v_xnat_participant_tn+", visits 
     where ("+v_xnat_appointment_mri_tn+".xnat_session_id is null or "+v_xnat_appointment_mri_tn+".xnat_session_id = '') 
     and "+v_xnat_participant_tn+".participant_id = "+v_xnat_appointment_mri_tn+".participant_id
     and visits.appointment_id = "+v_xnat_appointment_mri_tn+".appointment_id
     and visits.path is not null and visits.path > ''"

     results = connection.execute(sql)

     results.each do |v_val|
        v_appt_id = v_val[0]
        v_export_id = v_val[1]
        v_path = v_val[2]
        v_path_array = v_path.split("/")
        if v_path_array.count > 4
           v_codename = v_path_array[4]
        end
        v_xnat_session_id = ""
        sp_array = ScanProcedure.where("codename in (?)",v_codename)
        if sp_array.count> 0
             v_prepend = sp_array.first.subjectid_base+"_"
             v_number = ""
             if v_codename.include? "visit2"
                 v_number = "_v2"
             elsif v_codename.include? "visit3"
                 v_number = "_v3"
             elsif v_codename.include? "visit4"
                 v_number = "_v4"
             elsif v_codename.include? "visit5"
                 v_number = "_v5"
             elsif v_codename.include? "visit6"
                 v_number = "_v6"
             elsif v_codename.include? "visit7"
                 v_number = "_v7"
             elsif v_codename.include? "visit8"
                 v_number = "_v8"
             end
             v_xnat_session_id = v_prepend+v_export_id.to_s+v_number
             sql_update = "update "+v_xnat_appointment_mri_tn+" set xnat_session_id = '"+v_xnat_session_id+"'
             where "+v_xnat_appointment_mri_tn+".appointment_id = "+v_appt_id.to_s+"
             and ("+v_xnat_appointment_mri_tn+".xnat_session_id is null or "+v_xnat_appointment_mri_tn+".xnat_session_id = '') "
             results = connection.execute(sql_update)
        end
     end


# set xnat_do_not_share_flag
#set xnat_exists_flag = 'Y' after upload to xnat
     sql = "insert into "+v_xnat_ids_tn+"(visit_id,image_dataset_id,xnat_exists_flag,file_path)
     select distinct image_datasets.visit_id, image_datasets.id, 'N',image_datasets.path from image_datasets, visits, appointments, series_description_maps,scan_procedures_vgroups
     where image_datasets.visit_id = visits.id 
     and appointments.id = visits.appointment_id
     and (image_datasets.do_not_share_scans_flag is null or image_datasets.do_not_share_scans_flag != 'Y')
     and image_datasets.series_description = series_description_maps.series_description
                    and series_description_maps.series_description_type_id in ("+v_series_description_category_id_array.join(",")+") 
     and appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
      and  scan_procedures_vgroups.scan_procedure_id in ("+v_scan_procedure_array.join(",")+") 
      and (image_datasets.visit_id, image_datasets.id ) NOT IN (select "+v_xnat_ids_tn+".visit_id,"+v_xnat_ids_tn+".image_dataset_id 
                                                         from "+v_xnat_ids_tn+" )"

     results = connection.execute(sql)
# add file_path --
# make session id from file_path sp --> enum start| export_id|-v#
# add sessionid column in database
# set xnat_do_not_share_flag
#set xnat_exists_flag = 'Y' after upload to xnat

    # R means run, D means done
    # make participants in xnat
    sql = "select export_id, participant_id from "+v_xnat_participant_tn+" where xnat_do_not_share_flag = 'N' and xnat_run_upload_flag = 'R' and xnat_exists_flag = 'N' "
    results = connection.execute(sql)
    results.each do |participant|
       # make user on xnat
       v_sql_update = "update "+v_xnat_participant_tn+" set xnat_run_upload_flag ='D', xnat_exists_flag = 'Y' where export_id = '"+participant[0].to_s+"' "
       ####results_update = connection.execute(v_sql_update)
    end

    # make session and scans in xnat      v_xnat_ids_tn = "xnat_image_datasets"
    sql = "select "+v_xnat_ids_tn+".file_path, "+v_xnat_ids_tn+".visit_id, "+v_xnat_appointment_mri_tn+".xnat_session_id, "+v_xnat_appointment_mri_tn+".xnat_exists_flag,
    "+v_xnat_participant_tn+".export_id, "+v_xnat_participant_tn+".xnat_exists_flag 
                  from "+v_xnat_participant_tn+","+v_xnat_ids_tn+","+v_xnat_appointment_mri_tn+" where "+v_xnat_ids_tn+".xnat_do_not_share_flag = 'N' 
                                  and "+v_xnat_ids_tn+".xnat_exists_flag = 'N' 
                                  and "+v_xnat_participant_tn+".participant_id = "+v_xnat_appointment_mri_tn+".participant_id
                                  and "+v_xnat_appointment_mri_tn+".visit_id = "+v_xnat_ids_tn+".visit_id
                                  and "+v_xnat_participant_tn+".xnat_run_upload_flag = 'R'
                      order by "+v_xnat_appointment_mri_tn+".xnat_session_id "
    #puts "xnat_driver="+sql
    results = connection.execute(sql)
    v_xnat_session ="zzzzz"
    v_target_dir = ""
    v_cnt_ids = 0
    v_path_array = []  # the path pusghed into array is getting split on /
    v_path_full_list_array = []
    v_visit_id = ""
    results.each do |scan|
      puts "aaaaa=0"+scan[0]+"   1="+scan[1].to_s+"  2="+scan[2].to_s
       if v_xnat_session != scan[2]
           # new xnat session
        puts " new session="+v_xnat_session
        if v_cnt_ids  > 0 
          # before new xnat_session, zip v_target_dir  and xnat_seesion != zzzzzz
           v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu \"cd "+v_working_directory+"/;zip -r  "+v_xnat_session+".zip  "+v_xnat_session+"\""
           begin
            stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            rescue => msg    
           end
          # do xnat upload - curl command
          sql_update = "update "+v_xnat_ids_tn+" set "+v_xnat_ids_tn+".xnat_exists_flag = 'Y' 
          where "+v_xnat_ids_tn+".visit_id = "+v_visit_id.to_s+" and "+v_xnat_ids_tn+".xnat_exists_flag = 'N'
          and "+v_xnat_ids_tn+".file_path in('"+v_path_full_list_array.join("','")+"') "
          ######results_update = connection.execute(sql_update)
puts "hhhhh ="+sql_update 
          # update database table
          # update database table
          
             v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'cd "+v_working_directory+"; rm -rf "+v_working_directory+"/"+v_xnat_session+"*'"
          begin
            stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
              rescue => msg    
          end
          
        end
        v_cnt_ids = v_cnt_ids + 1
        v_visit_id = scan[1]
        v_xnat_session = scan[2]
        v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'cd "+v_working_directory+"; mkdir "+v_xnat_session+"'"
  #puts " gggg ="+v_call
        begin
            stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            rescue => msg    
        end
        v_path_full_list_array = []

      end # new sxnat_session
        v_file_path = scan[0]
        v_path_full_list_array.push(v_file_path)
        v_target_dir = v_working_directory+v_xnat_session
      # rsync -av scan[0] v_target_dir
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+scan[0]+"  "+v_working_directory+"/"+v_xnat_session+"/'"
      begin
            stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            rescue => msg    
      end
      v_path = scan[0]
      v_path_array = v_path.split("/")
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu \"cd "+v_working_directory+"/"+v_xnat_session+"/"+v_path_array.last+";find . -name '*.dcm.bz2' -exec bunzip2 {} \\\;\" "
      begin
            stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            rescue => msg    
      end
      # delete json, yaml, pickle
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu \"cd "+v_working_directory+"/"+v_xnat_session+"/"+v_path_array.last+"/;rm -rf *.json \""

      begin
            stdin, stdout, stderr = Open3.popen3(v_call)
             while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            rescue => msg    
      end
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu \"cd "+v_working_directory+"/"+v_xnat_session+"/"+v_path_array.last+"/;rm -rf *.pickle \""
      begin
            stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            rescue => msg    
      end
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu \"cd "+v_working_directory+"/"+v_xnat_session+"/"+v_path_array.last+"/;rm -rf *.yaml \""
      begin
            stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            rescue => msg    
      end
      # find /bunzip bz2
      # v_script_dicom_clean command = "./xnat_dicom_upload_cleaner.rb %s %s %s %s" % (target_dir, meta_info['exportID'], project, session_label)
         # target_dir = v_target_dir + dicom dir
         # meta_info['exportID'] = scan[4]
         # project = v_project
         # session_label = v_xnat_session
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu \""+v_script_dicom_clean+" '"+v_working_directory+"/"+v_xnat_session+"/"+v_path_array.last+"' '"+scan[4].to_s+"' '"+v_project+"' '"+v_xnat_session+"' \" "
      #puts "ddddd ="+v_call
      begin
            stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            rescue => msg    
      end
    end
     # after last xnat_session, zip v_target_dir  and xnat_seesion != zzzzzz
          # do xnat upload - curl command
          # update database table
          #v_call = "ssh panda_user@"+v_computer+" 'cd "+v_working_directory+"; rm -rf "+v_xnat_session+"'"
    v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu \"cd "+v_working_directory+"/;zip -r  "+v_xnat_session+".zip  "+v_xnat_session+"\""
    begin
    stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
          puts stdout.read 1024    
      end
      stdin.close
      stdout.close
      stderr.close
      rescue => msg    
    end
    # do xnat upload - curl command
    sql_update = "update "+v_xnat_ids_tn+" set "+v_xnat_ids_tn+".xnat_exists_flag = 'Y' 
    where "+v_xnat_ids_tn+".visit_id = "+v_visit_id.to_s+" and "+v_xnat_ids_tn+".xnat_exists_flag = 'N'
          and "+v_xnat_ids_tn+".file_path in('"+v_path_full_list_array.join("','")+"') "
  ######results_update = connection.execute(sql_update)
puts "hhhhh ="+sql_update
          
             v_call = "SSSSSSSSSSSssh panda_user@"+v_computer+".dom.wisc.edu 'cd "+v_working_directory+"; rm -rf "+v_working_directory+"/"+v_xnat_session+"*'"
          begin
            stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
              rescue => msg    
          end


    @schedulerun.comment =("successful finish xnat_upload "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save

 end


# ADD EXCLUDE SCAN SHARE
# ADD EXCLUDE SCAN
  def run_xnat_file
     v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "xnat_file"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('xnat_file')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting xnat_file"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
      v_computer = "kanga"
    connection = ActiveRecord::Base.connection();
    sql = "insert into cg_xnat (subjectid, enrollment_id, scan_procedure_id, project_1,vgroup_id)
           select distinct e.enumber, e.id, 22,'ADRC',vg.id
              from vgroups vg,appointments a, visits v,  enrollments e, enrollment_vgroup_memberships evgm, scan_procedures_vgroups spvg
              where a.vgroup_id = evgm.vgroup_id
               and a.vgroup_id = spvg.vgroup_id
               and a.vgroup_id = vg.id
               and vg.transfer_mri = 'yes'
               and a.appointment_type ='mri'
               and a.id = v.appointment_id
               and v.id in ( select ids.visit_id from image_datasets ids, image_dataset_quality_checks idsqc
                      where ids.id = idsqc.image_dataset_id)
               and e.id = evgm.enrollment_id
               and e.enumber like 'adrc%'
               and spvg.scan_procedure_id = 22
              and e.id not in ( select x2.enrollment_id from cg_xnat x2 where x2.scan_procedure_id = 22 and x2.project_1 = 'ADRC')"
    results = connection.execute(sql)

    # update export_id  -- replace subjectid in file name and xml file
    # need to make table of xnat_participant_id --- linkto export_id update cg_xnat
  #  sql ="truncate table cg_xnat_exportid"
  #  results = connection.execute(sql)
    # CLOSE
    sql = "insert into cg_xnat_exportid(participant_id)  select distinct e.participant_id from cg_xnat , enrollments e 
        where cg_xnat.enrollment_id = e.id and cg_xnat.export_id is  NULL"
    results = connection.execute(sql)
    # expect unique key issue
    sql = "insert into cg_random(export_id)(select FLOOR((RAND()*10000000)+2) from cg_xnat_exportid where export_id is NULL)"
    results = connection.execute(sql)
    sql = "update cg_xnat_exportid set cg_xnat_exportid.export_id = ( select cg_random.export_id 
                 from cg_random where cg_random.id = cg_xnat_exportid.id)"
         results = connection.execute(sql)
    sql ="update cg_xnat set cg_xnat.participant_id = ( select distinct e.participant_id
              from  enrollments e where  e.id = cg_xnat.enrollment_id)"
    results = connection.execute(sql)
    # what if participant_id is null?
     sql ="update cg_xnat set cg_xnat.export_id = ( select distinct cg_xnat_exportid.export_id 
              from cg_xnat_exportid, enrollments e where cg_xnat_exportid.participant_id= e.participant_id
               and e.id = cg_xnat.enrollment_id)
           where cg_xnat.participant_id is not null"
    results = connection.execute(sql)

    t_now = Time.now
    v_file_name = 'xnat_mri_scan_list_'+ t_now.strftime("%Y%m%d_%H_%M")+".xml"
    if Rails.env=="production"   
        v_file_target_dir = v_base_path+"/analyses/panda/xnat/"
    else
      v_file_target_dir = v_base_path+"/admin_only/xnat/"
    end
    v_file = v_file_target_dir+v_file_name
     # get adrc only  -- only 20, just T1 and t2, xnat_status_flag =R 
     v_scan_procedure_array = [22]
     v_series_description_category_array = ['T1_Volumetric','T2','ASL']
     v_series_description_category_id_array = [19, 20,1 ]
     sql = "select distinct a.vgroup_id,  vg.participant_id  
         from vgroups vg, appointments a, visits v where vg.id = a.vgroup_id and a.id = v.appointment_id
          and vg.id in ( select spvg.vgroup_id from scan_procedures_vgroups spvg where spvg.scan_procedure_id in ("+v_scan_procedure_array.join(',')+"))
          and vg.id in ( select evgm.vgroup_id from enrollment_vgroup_memberships evgm, enrollments e,cg_xnat
                                 where evgm.enrollment_id = e.id and e.enumber = cg_xnat.subjectid and 
                                  cg_xnat.xnat_sent_flag = 'N' and cg_xnat.xnat_status_flag ='R' and cg_xnat.project_1 = 'ADRC') 
          and vg.transfer_mri ='yes'"
    results = connection.execute(sql)
    v_cnt = 0
    File.open(v_file, "w+") do |f|
      f.write("<root>")
    results.each do |r|
        v_cnt = v_cnt + 1
        v_vgroup_id = r[0]
        v_participant = Participant.find(r[1])
        # LIMITING TO ADRC
        v_enrollments = Enrollment.where("enumber like 'adrc%'").where("enrollments.id in (select enrollment_id from enrollment_vgroup_memberships where vgroup_id in (?))",r[0])
        v_enrollment = v_enrollments[0]
        sql_exportid = "select cg_xnat.export_id from cg_xnat where enrollment_id = "+v_enrollment.id.to_s
        results_exportid = connection.execute(sql_exportid)
        v_export_id = results_exportid.first[0]

        v_comment = "strt "+v_enrollment.enumber+"; "+v_comment
        v_gender = ""
        if v_participant.gender == 2
          v_gender="F"
        elsif v_participant.gender == 1
          v_gender = "M"
        end
        v_vgroup_start ="<vgroup>\n\t<internal_cnt>"+v_cnt.to_s+"</internal_cnt>\n"
        v_vgroup_stop ="</vgroup>"
        v_string_participant_start="\t<participant>\n\t\t<panda_participant_id>"+v_participant.id.to_s+"</panda_participant_id>\n\t\t<subjectid_adrc>"+v_enrollment.enumber+"</subjectid_adrc>\n\t\t<reggieid>"+v_participant.reggieid.to_s+"</reggieid>\n\t\t<gender>"+v_gender+"</gender>\n\t\t<apoe_e1>"+v_participant.apoe_e1.to_s+"</apoe_e1>\n\t\t<apoe_e2>"+v_participant.apoe_e2.to_s+"</apoe_e2><export_id>"+v_export_id.to_s+"</export_id>"
        v_string_participant_stop = "\n\t</participant>"
        f.write(v_vgroup_start)
        f.write(v_string_participant_start+"\n")
 
        sql_appt = "select distinct a.vgroup_id,  v.appointment_id, v.id, vg.participant_id , v.path, date_format(a.appointment_date,'%Y%m%d'),v.scan_number 
         from vgroups vg, appointments a, visits v where vg.id = a.vgroup_id and a.id = v.appointment_id
          and vg.id = "+v_vgroup_id.to_s+"
          and vg.id in ( select spvg.vgroup_id from scan_procedures_vgroups spvg where spvg.scan_procedure_id in ("+v_scan_procedure_array.join(',')+"))
          and vg.id in ( select evgm.vgroup_id from enrollment_vgroup_memberships evgm, enrollments e,cg_xnat 
                                 where evgm.enrollment_id = e.id and e.enumber = cg_xnat.subjectid and 
                                  cg_xnat.xnat_sent_flag = 'N' and cg_xnat.xnat_status_flag ='R') 
          and vg.transfer_mri ='yes'"
          results_appt = connection.execute(sql_appt)
          v_appt_cnt = 0
          v_folder_array = []
          results_appt.each do |r_appt|
             v_age_at_appointment = self.get_age_at_appointment(r_appt[2])
             v_appt_cnt = v_appt_cnt + 1
             v_string_appt_start="\t\t<appointment>\n\t\t\t<internal_appt_cnt>"+v_appt_cnt.to_s+"</internal_appt_cnt>\n\t\t\t<appt_type>mri</appt_type>\n\t\t\t<mri_date>"+r_appt[5]+"</mri_date>\n\t\t\t<exam_number>"+r_appt[6].to_s+"</exam_number>\n\t\t\t<age_at_appointment>"+v_age_at_appointment.to_s+"</age_at_appointment>"
             v_string_appt_stop ="\t\t</appointment>"
             sql_ids = "select ids.id, ids.series_description, ids.path, sdt.series_description_type 
             from image_datasets ids, series_description_maps sdm, series_description_types sdt
             where ids.visit_id = "+r_appt[2].to_s+"  
                  and ids.series_description =   sdm.series_description
                  and sdm.series_description_type_id = sdt.id 
                  and sdt.id in ("+v_series_description_category_id_array.join(',')+")
                    order by sdt.series_description_type, ids.series_description "
             ids_results = connection.execute(sql_ids)
             v_cnt_ids = 0
             

             f.write(v_string_appt_start+"\n")
             ids_results.each do |r_ids|
                v_ids_ok_flag = "Y"
                v_ids_id = r_ids[0]
                v_ids_ok_flag = self.check_ids_for_severe_or_incomplete(v_ids_id)
                if v_ids_ok_flag == "Y" 
                   v_cnt_ids = v_cnt_ids + 1
                   v_path = r_ids[2]
                   v_dir_array = v_path.split("/")
                   v_dir = v_dir_array[(v_dir_array.size - 1)]
                   v_dir_target = v_dir+"_"+r_ids[1]
                   v_folder_array.push(v_dir_target)
                   v_string = "\t\t\t<ids>\n\t\t\t\t<internal_ids_cnt>"+v_cnt_ids.to_s+"</internal_ids_cnt>\n\t\t\t\t<series_description_type>"+r_ids[3]+"</series_description_type>\n\t\t\t\t<series_description>"+r_ids[1]+"</series_description>\n\t\t\t\t<path>"+r_ids[2]+"</path>\n\t\t\t</ids>\n"
                   f.write(v_string)
                end
             end

             f.write(v_string_appt_stop)
           end
           f.write(v_string_participant_stop)
           f.write("\n"+v_vgroup_stop+"\n")
          
         sql_update = " update cg_xnat set xnat_sent_flag ='Y', xnat_dir_list ='"+v_folder_array.join(',')+"' where
              cg_xnat.project_1 = 'ADRC' 
             and subjectid = '"+v_enrollment.enumber+"' and scan_procedure_id in ("+v_scan_procedure_array.join(',')+")"
        update_results = connection.execute(sql_update)

    end
    f.write("</root>")
   end
  
    v_comment = "count="+v_cnt.to_s+"; "+v_comment


    @schedulerun.comment =("successful finish xnat_file "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save

  end
  
  
  # data request from piero antuano, wrap metabolic, resting bold/fmri and t1 volumetric, johnson.prodict.visit1, johnson.merit.visit1
  # from cg_antuano_20130916 
  # done_flag = Y means the files has been uploaded
  # status_flag = N means do not upload this subjectid
  def run_antuano_20130916_upload
    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "antuano_20130916_upload"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('antuano_20130916_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting antuano_20130916_upload -MOVED TO SHARED_RETIRED.rb"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
     
  end

  def run_apoe_fill
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('apoe_fill')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting apoe_fill"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_comment_warning = ""

     connection = ActiveRecord::Base.connection();
     sql = "update cg_apoe_fill set participant_id = ( select enrollments.participant_id from enrollments where enrollments.id = cg_apoe_fill.enrollment_id)"
     results = connection.execute(sql)

      sql = "update cg_apoe_fill set apoe_e1 =replace((substring_index(genotype,'/',1) ),'E',''),
                             apoe_e2 = replace((substring(genotype,(instr(genotype,'/')+1))),'E','') "
      results = connection.execute(sql)

       sql = "update participants set apoe_e1 = ( select cg_apoe_fill.apoe_e1 from cg_apoe_fill where cg_apoe_fill.participant_id = participants.id)
               where ( participants.apoe_e1 = 0 or participants.apoe_e1  is null)
               and participants.id in ( select cg_apoe_fill.participant_id from cg_apoe_fill where apoe_e1 is not null)"
        results = connection.execute(sql)

             sql = "update participants set apoe_e2 = ( select cg_apoe_fill.apoe_e2 from cg_apoe_fill where cg_apoe_fill.participant_id = participants.id)
               where ( participants.apoe_e2 = 0 or participants.apoe_e2 is null)
               and participants.id in ( select cg_apoe_fill.participant_id from cg_apoe_fill where apoe_e2 is not null)"

      results = connection.execute(sql)

            sql = "select cg_apoe_fill.subjectid, cg_apoe_fill.genotype,  cg_apoe_fill.apoe_e1,  cg_apoe_fill.apoe_e2, 
             participants.apoe_e1, participants.apoe_e2
              from  cg_apoe_fill, participants where 
              cg_apoe_fill.participant_id = participants.id
              and (  (cg_apoe_fill.apoe_e1 != participants.apoe_e1 and participants.apoe_e1 != 0 and participants.apoe_e1 is not null)
                     or  cg_apoe_fill.apoe_e2 != participants.apoe_e2 and participants.apoe_e2 != 0 and participants.apoe_e2 is not null)"

      results = connection.execute(sql)
       results.each do |r|
           v_comment= v_comment+" Differences="+r.join("-|  ")
       end

   @schedulerun.comment =("successful finish apoe_fill "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save

   end 
  
  # to add columns --
  # change sql_base insert statement
  # change  sql = sql_base+  insert statement with values
  # change  self.move_present_to_old_new_to_present
  def run_asl_status
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('asl_status')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting asl_status"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_computer = "kanga"
    ####    begin   # catch all exception and put error in comment    
            sql = "truncate table cg_asl_status_new"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)

            sql_base = "insert into cg_asl_status_new(asl_subjectid, asl_general_comment,asl_registered_to_fs_flag,asl_smoothed_and_warped_flag,asl_fmap_flag,asl_fmap_single,
            asl_bkup_registered_to_fs_flag,asl_bkup_smoothed_and_warped_flag,asl_bkup_fmap_flag,asl_bkup_fmap_single,asl_0_fmap_flag,asl_0_fmap_single,
            asl_1525_fmap_flag,asl_1525_fmap_single,asl_2025_fmap_flag,asl_2025_fmap_single,
            asl_0_registered_to_fs_flag,asl_0_smoothed_and_warped_flag,asl_1525_registered_to_fs_flag,asl_1525_smoothed_and_warped_flag,
            asl_2025_registered_to_fs_flag,asl_2025_smoothed_and_warped_flag,pdmap_flag,pdmap_0_flag,pdmap_1525_flag,pdmap_2025_flag,t1_fs_flag,asl_directory_list,
            asl_preproc_v5_1525,asl_preproc_v5_2025,default_subjectspace_masks_v5_1525,default_subjectspace_masks_v5_2025,
            enrollment_id, scan_procedure_id)values("  
            v_raw_path = v_base_path+"/raw"
            v_mri = "/mri"
            no_mri_path_sp_list =['asthana.adrc-clinical-core.visit1',
            'bendlin.mets.visit1','bendlin.tami.visit1','bendlin.wmad.visit1','carlson.sharp.visit1','carlson.sharp.visit2',
            'carlson.sharp.visit3','carlson.sharp.visit4','dempsey.plaque.visit1','dempsey.plaque.visit2','gleason.falls.visit1',
            'johnson.merit220.visit1','johnson.merit220.visit2','johnson.tbi.aware.visit3','johnson.tbi-va.visit1','ries.aware.visit1','wrap140']

            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            # get list of scan_procedure codename -- exclude 4, 10, 15, 19, 32, 
                # ??? johnson.pc vs johnsonpc4000.visit1 vs pc_4000
                # ??? johnson.tbi10000 vs johnson.tbiaware vs tbi_1000
                # ??? johnson.wrap140.visit1 vs wrap140.visit1 vs wrap140
                # NOT exists /Volumes/team-1/raw/carlson.esprit/mri
                # NOT exists /Volumes/team-1/raw/johnson.wrap140.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbiaware.visit3/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit2/mri
                # NOT exists /Volumes/team-1/raw/johnnson.alz.repsup.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.pc4000.visit1/mri
            v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
            @scan_procedures = ScanProcedure.where("id not in (?)",v_exclude_sp)
            @scan_procedures.each do |sp|
              v_visit_number =""
              if sp.codename.include?("visit2")
                v_visit_number ="_v2"
              elsif sp.codename.include?("visit3")
                v_visit_number ="_v3"
              elsif sp.codename.include?("visit4")
                v_visit_number ="_v4"
              elsif sp.codename.include?("visit5")
                v_visit_number ="_v5"
              end
               if no_mri_path_sp_list.include?(sp.codename)
                 v_mri = ""
                else
                  v_mri = "/mri"
                end
                v_raw_full_path = v_raw_path+"/"+sp.codename+v_mri
                v_preprocessed_full_path = v_preprocessed_path+sp.codename
                if File.directory?(v_raw_full_path)
                    if !File.directory?(v_preprocessed_full_path)
                        puts "preprocessed path NOT exists "+v_preprocessed_full_path
                     end
                    Dir.entries(v_raw_full_path).select { |file| File.directory? File.join(v_raw_full_path, file)}.each do |dir|
                      dir_name_array = dir.split('_')
                      if dir_name_array.size == 3
                         enrollment = Enrollment.where("enumber in (?)",dir_name_array[0])
                         if !enrollment.blank?
                             v_asl_registered_to_fs_flag ="N"
                             v_asl_smoothed_and_warped_flag = "N"
                             v_asl_fmap_flag = "N"
                             v_asl_fmap_single ="N"                                
                             v_asl_bkup_registered_to_fs_flag ="N"
                             v_asl_bkup_smoothed_and_warped_flag = "N"
                             v_asl_bkup_fmap_flag = "N"
                             v_asl_bkup_fmap_single ="N"
                             v_asl_0_fmap_flag = "N"
                             v_asl_0_fmap_single ="N"   
                             v_asl_0_registered_to_fs_flag ="N"
                             v_asl_0_smoothed_and_warped_flag = "N"                          
                             v_asl_1525_fmap_flag = "N"
                             v_asl_1525_fmap_single ="N"  
                             v_asl_1525_registered_to_fs_flag ="N"
                             v_asl_1525_smoothed_and_warped_flag = "N"                           
                             v_asl_2025_fmap_flag = "N"
                             v_asl_2025_fmap_single ="N"
                             v_asl_2025_registered_to_fs_flag ="N"
                             v_asl_2025_smoothed_and_warped_flag = "N"
                             v_pdmap_flag = "N"
                             v_pdmap_0_flag = "N"
                             v_pdmap_1525_flag = "N"
                             v_pdmap_2025_flag = "N"
                             v_t1_fs_flag = "N"
                             v_t1_single = ""
                             v_asl_directory_list =""
                             v_asl_directory_list_2025 =""
                             v_asl_directory_list_1525 =""
                             v_asl_preproc_v5_1525 = "N"
                             v_asl_preproc_v5_2025 = "N"
                             v_default_subjectspace_masks_v5_1525 = "N"
                             v_default_subjectspace_masks_v5_2025 = "N"

                             # multiple asl dircectory from image_datasets.path 
                              sql_dir = "select distinct SUBSTRING_INDEX(image_datasets.path,'/',-1) from image_datasets,visits v, appointments a, scan_procedures_vgroups spv, enrollment_vgroup_memberships evm
                                   where image_datasets.visit_id = v.id and v.appointment_id = a.id and a.vgroup_id = spv.vgroup_id and spv.scan_procedure_id ="+sp.id.to_s+"
                                   and evm.enrollment_id ="+enrollment[0].id.to_s+" and a.vgroup_id = evm.vgroup_id 
                                   and image_datasets.series_description in (select series_description_maps.series_description from series_description_maps,series_description_types where series_description_types.id =series_description_maps.series_description_type_id and  series_description_types.series_description_type = 'ASL')"
                             v_asl_directory_array = []
                             v_asl_directory_2025_array = []
                             v_asl_directory_1525_array = []
                             results_dir = connection.execute(sql_dir)
                             results_dir.each do |d|
                                  v_asl_directory_array.push(d[0])
                                  # check if a 2025 inversion -- ASL_fmap_[subectid]_2025-[start of dir].nii in v_preprocessed_full_path+"/"+[subjectid]/asl
                                  v_dir_name_array = d[0].split("_")
                                  v_file_check = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/asl/ASL_fmap_"+enrollment[0].enumber+"_2025_"+v_dir_name_array[0]+".nii"
                                  if File.exist?(v_file_check)
                                      v_asl_directory_2025_array.push(d[0])
                                  end
                                  v_file_check = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/asl/ASL_fmap_"+enrollment[0].enumber+"_1525_"+v_dir_name_array[0]+".nii"
                                  if File.exist?(v_file_check)
                                      v_asl_directory_1525_array.push(d[0])
                                  end
                                  v_file_check = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/asl/ASL_fmap_"+enrollment[0].enumber+"_0_"+v_dir_name_array[0]+".nii"
                                  if File.exist?(v_file_check)
                                      v_asl_directory_1525_array.push(d[0])
                                  end
                                  # now check in new structure /images
                                  v_file_check = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/asl/images/ASL_fmap_"+enrollment[0].enumber+"_2025_"+v_dir_name_array[0]+".nii"
                                  if File.exist?(v_file_check)
                                      v_asl_directory_2025_array.push(d[0])
                                  end
                                  v_file_check = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/asl/images/ASL_fmap_"+enrollment[0].enumber+"_1525_"+v_dir_name_array[0]+".nii"
                                  if File.exist?(v_file_check)
                                      v_asl_directory_1525_array.push(d[0])
                                  end
                                  v_file_check = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/asl/images/ASL_fmap_"+enrollment[0].enumber+"_0_"+v_dir_name_array[0]+".nii"
                                  if File.exist?(v_file_check)
                                      v_asl_directory_1525_array.push(d[0])
                                  end

                             end
                             if v_asl_directory_array.size > 0
                                v_asl_directory_list = v_asl_directory_array.join(",") 
                             end                          
                             # need FS path - use fs_home_to_use if not null
                             # have enrollemnt_id and sp.id
                             v_fs_home = "orig_recon"
                             v_fs_home_path = v_base_path+"/preprocessed/modalities/freesurfer/"
                             sql_fs = "select fs_home_to_use from cg_asl_status where enrollment_id = "+ enrollment[0].id.to_s+" and scan_procedure_id ="+sp.id.to_s
                             results_fs = connection.execute(sql_fs)
                             if results_fs.first.blank? # new will always just be non-edited - blank/default
                               sql_fs = "select fs_home_to_use from cg_asl_status_new where enrollment_id = "+ enrollment[0].id.to_s+" and scan_procedure_id ="+sp.id.to_s
                             end
                             results_fs = connection.execute(sql_fs)
                             if !results_fs.blank? and !results_fs.first.blank? and !(results_fs.first)[0].blank?
                                 v_fs_home = (results_fs.first)[0]  
                             end
                             v_subject_fs_path = v_fs_home_path+v_fs_home+"/"+dir_name_array[0]+v_visit_number+"/mri"
                           #  if File.directory?(v_subject_fs_path)
                           #       v_dir_array = Dir.entries(v_subject_fs_path)
                           #       v_dir_array.each do |f|      
                           #         if f == "T1.mgz"
                           #           v_t1_fs_flag = "Y"
                                      # v_t1_single ????
                           #         end
                           #       end                               
                           #   end
                             
                             
                             
                             v_subjectid_asl = v_preprocessed_full_path+"/"+dir_name_array[0]+"/asl"
                             if File.directory?(v_subjectid_asl)
                                  v_dir_array = Dir.entries(v_subjectid_asl)   # need to get date for specific files
                                  if File.directory?(v_subjectid_asl+"/images")
                                       v_dir_array.concat(Dir.entries(v_subjectid_asl+"/images") )
                                  end
                                  if File.directory?(v_subjectid_asl+"/pproc_v5")
                                       v_dir_array.concat(Dir.entries(v_subjectid_asl+"/pproc_v5") )
                                       if File.directory?(v_subjectid_asl+"/pproc_v5/masks/roi_summary")
                                          Dir.entries(v_subjectid_asl+"/pproc_v5/masks/roi_summary").each do |f|
                                              v_asl_directory_2025_array.each do |d| 
                                                v_dir_tmp_array = d.split("_")
                                                if  f.start_with?(dir_name_array[0]+"_"+v_dir_tmp_array[0]) and f.end_with?("ASL_ROIs_invXgm.csv")
                                                  v_default_subjectspace_masks_v5_2025 = "Y"
                                                 end
                                              end
                                              v_asl_directory_1525_array.each do |d|
                                                v_dir_tmp_array = d.split("_")
                                                if  f.start_with?(dir_name_array[0]+"_"+v_dir_tmp_array[0]) and f.end_with?("ASL_ROIs_invXgm.csv")
                                                  v_default_subjectspace_masks_v5_1525 = "Y"
                                                end
                                              end
                                          end
                                       end
                                  end
                                  # evalute for asl_registered_to_fs_flag = rFS_ASL_[subjectid]_fmap.nii ,
                                  # asl_smoothed_and_warped_flag = swrFS_ASL_[subjectid]_fmap.nii,
                                  # asl_fmap_flag = [ASL_[subjectid]_[sdir]_fmap.nii or ASL_[subjectid]_fmap.nii],
                                  # asl_fmap_single = ASL_[subjectid]_fmap.nii
                                  # dir_name_array[0] is just subjectid
                                v_asl_fmap_single =""
                                v_dir_array.each do |f|
                                  
                                  if f == "swrFS_ASL_"+dir_name_array[0]+"_fmap.nii"
                                    v_asl_smoothed_and_warped_flag = "Y"
                                 # elsif  f == "rFS_ASL_"+dir_name_array[0]+"_fmap.nii"
                                 #   v_asl_registered_to_fs_flag ="Y"
                                  elsif  f.start_with?("ASL_fmap_"+dir_name_array[0]+"_0_") and f.end_with?(".nii")
                                    v_asl_0_fmap_flag = "Y"
                                    v_asl_1525_fmap_flag = "Y"
                                    v_asl_0_fmap_single ="Y"
                                    if v_asl_fmap_single == ""
                                       v_asl_fmap_single ="Y"
                                     elsif v_asl_fmap_single == "Y"
                                      v_asl_fmap_single = "N"
                                     end
                                 # elsif f.start_with?("swASL_fmap_"+dir_name_array[0]+"_0_") and f.end_with?(".nii")  # not doing r_FS 
                                 #     v_asl_0_smoothed_and_warped_flag = "Y"
                                 #     v_asl_1525_smoothed_and_warped_flag = "Y"
                                 # elsif  f.start_with?("rFS_ASL_fmap_"+dir_name_array[0]+"_0_") and f.end_with?(".nii")
                                 #     v_asl_0_registered_to_fs_flag ="Y"    
                                 #     v_asl_1525_registered_to_fs_flag ="Y"                                                                      
                                  elsif   f.start_with?("ASL_fmap_"+dir_name_array[0]+"_1525_") and f.end_with?(".nii")
                                      v_asl_1525_fmap_flag = "Y"
                                      v_asl_1525_fmap_single ="Y"
                                      if v_asl_fmap_single == ""
                                         v_asl_fmap_single ="Y"
                                       elsif v_asl_fmap_single == "Y"
                                        v_asl_fmap_single = "N"
                                       end
                                  #elsif f.start_with?("swASL_fmap_"+dir_name_array[0]+"_1525_") and f.end_with?(".nii") # not doing r_FS
                                  #    v_asl_1525_smoothed_and_warped_flag = "Y"
                                  #elsif  f.start_with?("rFS_ASL_fmap_"+dir_name_array[0]+"_1525_") and f.end_with?(".nii")
                                  #    v_asl_1525_registered_to_fs_flag ="Y"                                                                       
                                  elsif   f.start_with?("ASL_fmap_"+dir_name_array[0]+"_2025_") and f.end_with?(".nii")
                                      v_asl_2025_fmap_flag = "Y"
                                      v_asl_2025_fmap_single ="Y" 
                                      if v_asl_fmap_single == ""
                                         v_asl_fmap_single ="Y"
                                       elsif v_asl_fmap_single == "Y"
                                        v_asl_fmap_single = "N"
                                       end 
                                 # elsif f.start_with?("swASL_fmap_"+dir_name_array[0]+"_2025_") and f.end_with?(".nii") # not doing r_FS
                                 #     v_asl_2025_smoothed_and_warped_flag = "Y"
                                 # elsif  f.start_with?("rFS_ASL_fmap_"+dir_name_array[0]+"_2025_") and f.end_with?(".nii")
                                 #     v_asl_2025_registered_to_fs_flag ="Y" 
                                 # elsif   f.start_with?("PDmap_"+dir_name_array[0]+"_0_") and f.end_with?(".nii")
                                 #     v_pdmap_0_flag = "Y" 
                                 # elsif   f.start_with?("PDmap_"+dir_name_array[0]+"_1525_") and f.end_with?(".nii")
                                 #     v_pdmap_1525_flag = "Y"
                                 # elsif   f.start_with?("PDmap_"+dir_name_array[0]+"_2025_") and f.end_with?(".nii")
                                 #     v_pdmap_2025_flag = "Y" 
                                  elsif   f.start_with?("swrASL_fmap_"+dir_name_array[0]+"_0_") and f.end_with?(".nii")
                                      v_asl_preproc_v5_1525 = "Y" 
puts "ppppppp "+dir_name_array[0]
                                  elsif   f.start_with?("swrASL_fmap_"+dir_name_array[0]+"_1525_") and f.end_with?(".nii")
                                      v_asl_preproc_v5_1525 = "Y"
                                  elsif   f.start_with?("swrASL_fmap_"+dir_name_array[0]+"_2025_") and f.end_with?(".nii")
                                      v_asl_preproc_v5_2025 = "Y" 
                                  end                                                          
                                  if v_asl_0_fmap_flag == "Y" or v_asl_1525_fmap_flag == "Y" or v_asl_2025_fmap_flag == "Y"
                                    v_asl_fmap_flag = "Y"
                                  end 
                                  
                                  if v_pdmap_0_flag == "Y" or v_pdmap_1525_flag == "Y" or v_pdmap_2025_flag == "Y"
                                    v_pdmap_flag = "Y"
                                  end                                 
                                end
                             end
                             if File.directory?(v_subjectid_asl) # or  File.directory?(v_subjectid_asl_bkup)
                                sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','','"+v_asl_registered_to_fs_flag+"','"+v_asl_smoothed_and_warped_flag+"','"+v_asl_fmap_flag+"',
                                                           '"+v_asl_fmap_single+"','"+v_asl_bkup_registered_to_fs_flag+"','"+v_asl_bkup_smoothed_and_warped_flag+"','"+v_asl_bkup_fmap_flag+"',
                                                           '"+v_asl_bkup_fmap_single+"','"+v_asl_0_fmap_flag+"', '"+v_asl_0_fmap_single+"','"+v_asl_1525_fmap_flag+"', '"+v_asl_1525_fmap_single+"',
                                                          '"+v_asl_2025_fmap_flag+"', '"+v_asl_2025_fmap_single+"','"+v_asl_0_registered_to_fs_flag+"','"+v_asl_0_smoothed_and_warped_flag+"'
                                                          ,'"+v_asl_1525_registered_to_fs_flag+"','"+v_asl_1525_smoothed_and_warped_flag+"','"+v_asl_2025_registered_to_fs_flag+"',
                                                          '"+v_asl_2025_smoothed_and_warped_flag+"','"+v_pdmap_flag+"','"+v_pdmap_0_flag+"','"+v_pdmap_1525_flag+"','"+v_pdmap_2025_flag+"','"+v_t1_fs_flag+"','"+v_asl_directory_list+"','"+v_asl_preproc_v5_1525+"','"+v_asl_preproc_v5_2025+"','"+v_default_subjectspace_masks_v5_1525+"','"+v_default_subjectspace_masks_v5_2025+"',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                 results = connection.execute(sql) 
                                 if v_asl_directory_2025_array.size > 1
                                    # check in acpc which one was used?  is acpc linked to asl?
                                   
                                 end
                                 if v_asl_directory_2025_array.size == 1 or v_asl_directory_1525_array.size == 1 # use the 2025 by preference
                                      v_tmp_asl_dir_array = []
                                      if v_asl_directory_2025_array.size == 1
                                         v_tmp_asl_dir_array.push(v_asl_directory_2025_array) 
                                      end
                                      if v_asl_directory_1525_array.size == 1
                                         v_tmp_asl_dir_array.push(v_asl_directory_1525_array) 
                                      end                                   
                                      sql = "update cg_asl_status_new set asl_fmap_file_to_use ='"+v_tmp_asl_dir_array.join(',')+"' where enrollment_id ="+enrollment[0].id.to_s+" and scan_procedure_id="+sp.id.to_s
                                      results = connection.execute(sql)
                                 elsif v_asl_fmap_single == "Y" and v_asl_directory_list.split(",").size == 1   # asl_fmap_single ='Y' and ?????
                                      sql = "update cg_asl_status_new set asl_fmap_file_to_use ='"+v_asl_directory_list+"' where  enrollment_id ="+enrollment[0].id.to_s+" and scan_procedure_id="+sp.id.to_s
                                      results = connection.execute(sql)
                                  end
                             else
                                 sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','no ASL or ASL_bkup dir','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','N','N','N','N',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                 results = connection.execute(sql)
                             end # check for subjectid asl dir
                         else
                           #puts "no enrollment "+dir_name_array[0]
                         end # check for enrollment
                      end # check that dir name is in expected format [subjectid]_exam#_MMDDYY - just test size of array
                    end # loop thru the subjectids
                 else
                        #puts "               # NOT exists "+v_raw_full_path
                 end # check if raw dir exisits
            end            
            # check move cg_ to cg_old
            # v_shared = Shared.new 
             # move from new to present table -- made into a function  in shared model
             v_comment = self.move_present_to_old_new_to_present("cg_asl_status",
             "asl_subjectid, asl_general_comment,asl_registered_to_fs_flag, asl_smoothed_and_warped_flag, asl_fmap_flag, asl_fmap_single, 
             asl_bkup_registered_to_fs_flag, asl_bkup_smoothed_and_warped_flag, asl_bkup_fmap_flag, asl_bkup_fmap_single, 
             asl_0_fmap_flag, asl_0_fmap_single, 
             asl_1525_fmap_flag, asl_1525_fmap_single, 
            asl_2025_fmap_flag, asl_2025_fmap_single,
            asl_0_registered_to_fs_flag,asl_0_smoothed_and_warped_flag,asl_1525_registered_to_fs_flag,asl_1525_smoothed_and_warped_flag,
            asl_2025_registered_to_fs_flag,asl_2025_smoothed_and_warped_flag,pdmap_flag,pdmap_0_flag,pdmap_1525_flag,pdmap_2025_flag,t1_fs_flag,asl_directory_list,asl_fmap_file_to_use,asl_fmap_file_used,asl_preproc_v5_1525,asl_preproc_v5_2025,default_subjectspace_masks_v5_1525,default_subjectspace_masks_v5_2025,
              enrollment_id,scan_procedure_id",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)


             # apply edits  -- made into a function  in shared model
             self.apply_cg_edits('cg_asl_status')

             puts "successful finish asl_status "+v_comment[0..459]
              @schedulerun.comment =("successful finish asl_status "+v_comment[0..459])
              if !v_comment.include?("ERROR")
                 @schedulerun.status_flag ="Y"
               end
               @schedulerun.save
               @schedulerun.end_time = @schedulerun.updated_at      
               @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end
    
    
  end
  

    def run_asl_sw_fs_process
        v_process_name = "asl_sw_fs_process"
        v_log_base ="/mounts/data/preprocessed/logs/"
        process_logs_delete_old( v_process_name, v_log_base)            
        v_base_path = Shared.get_base_path()
        @schedule = Schedule.where("name in ('asl_sw_fs_process')").first
        v_runner_email = self.get_user_email()  #  want to send errors to the user running the process
        v_schedule_owner_email_array = []
        if !v_runner_email.blank?
          v_schedule_owner_email_array.push(v_runner_email)
        else
          v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
        end
        @schedulerun = Schedulerun.new
        @schedulerun.schedule_id = @schedule.id
        @schedulerun.comment ="asl_sw_fs_process"
        @schedulerun.save
        @schedulerun.start_time = @schedulerun.created_at
        @schedulerun.save
        v_comment = ""
        v_error_comment = ""
        v_computer = "kanga"
        t = Time.now
        v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
        v_log_name =v_process_name+"_"+v_date_YM
        v_log_path =v_log_base+v_log_name 
        v_stop_file_name = v_process_name+"_stop"
        v_stop_file_path = v_log_base+v_stop_file_name  # use to stop the results loop  
        v_subjectid_v_num = ""              
        v_script = v_base_path+"/data1/lab_scripts/AslProc/v3.1/aslproc.sh"

        connection = ActiveRecord::Base.connection();  
       # NEED GLOBAL - non-inversion specific 
        # do_not_run_process_asl_smoothed_and_warped == Y means do not run, == R means run -- requiring active input as well as matching conditions
        # do_not_run_process_asl_registered_to_fs == Y means do not run   == R means run -- requiring active input as well as matching conditions

        # ??? t1_fs_file_to_use,  t1_fs_single 
        # asl_smoothed_and_warped_flag , asl_registered_to_fs_flag --- not care, because may re-run or run for ask multiple ?

        # if these is only one ask fmap -- should use?????
        sql = "select distinct enrollment_id, scan_procedure_id, asl_subjectid,asl_fmap_single,asl_fmap_file_to_use,fs_home_to_use 
        from cg_asl_status where  t1_fs_flag = 'Y' and asl_fmap_flag = 'Y' 
        and ( asl_fmap_single = 'Y' or (asl_fmap_single ='N' and asl_fmap_file_to_use  is NOT NULL) ) 
        and pdmap_flag  = 'Y'  and  ( do_not_run_process_asl_registered_to_fs = 'R' or do_not_run_process_asl_smoothed_and_warped = 'R') "
        results = connection.execute(sql)
        results.each do |r|
            v_break = 0  # need a kill swith
             v_log = ""
            if File.file?(v_stop_file_path)
              File.delete(v_stop_file_path)
              v_break = 1
              v_log = v_log + " STOPPING the results loop"
              v_comment = " STOPPING the results loop  "+v_comment
            end
            break if v_break > 0

            sql_update = "update cg_asl_status set do_not_run_process_asl_smoothed_and_warped = 'N' where do_not_run_process_asl_smoothed_and_warped = 'R' and asl_subjectid = '"+r[2]+"'"
            results_update = connection.execute(sql_update)   # stop from re-running
            sql_update = "update cg_asl_status set do_not_run_process_asl_registered_to_fs = 'N' where do_not_run_process_asl_registered_to_fs = 'R' and asl_subjectid = '"+r[2]+"'"
            results_update = connection.execute(sql_update)   # stop from re-running
            
            # need to insert row in not there
            sql_check = "select count(*) from cg_asl_status_edit where asl_subjectid = '"+r[2]+"'"
            results_check = connection.execute(sql_check)
            results_check.each do |r_check|
              if r_check[0] < 1  # expect an edit row -- use edit to set R
                  sql_insert = "insert into cg_asl_status_edit(asl_subjectid )values('"+r[2]+"')"  
                  results_insert = connection.execute(sql_insert)
              end
            end
            
            sql_update = "update cg_asl_status_edit set do_not_run_process_asl_smoothed_and_warped = 'N' where do_not_run_process_asl_smoothed_and_warped = 'R' and asl_subjectid = '"+r[2]+"'"
            results_update = connection.execute(sql_update)   # stop from re-running
            sql_update = "update cg_asl_status_edit set do_not_run_process_asl_registered_to_fs = 'N' where do_not_run_process_asl_registered_to_fs = 'R' and asl_subjectid = '"+r[2]+"'"
            results_update = connection.execute(sql_update)   # stop from re-running
            
            t_now = Time.now
            v_log = v_log + "starting "+r[2]+"   "+ t_now.strftime("%Y%m%d:%H:%M")+"\n"
            v_subjectid_v_num = r[2]
            v_subjectid = r[2].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
            # fs subjects dir  --- eventually use good2go fs edited dir as default
            v_fs_subjects_dir = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon"
            if !r[7].blank? 
                v_fs_subjects_dir = v_base_path+"/preprocessed/modalities/freesurfer/"+r[7]
            end

            # get location
            sql_loc = "select distinct v.path from visits v where v.appointment_id in (select a.id from appointments a, enrollment_vgroup_memberships evg, scan_procedures_vgroups spv where a.vgroup_id = evg.vgroup_id  and evg.enrollment_id = "+r[0].to_s+"  and a.vgroup_id = spv.vgroup_id and spv.scan_procedure_id = "+r[1].to_s+")"
            results_loc = connection.execute(sql_loc)
            v_sp_loc = ""
            results_loc.each do |loc|
              # could have 2 locations dual enrollment with 2 appointments - look for where o*.nii loc
              v_loc_path = loc[0]
              v_loc_path = v_loc_path.gsub(v_base_path+"/raw/","")
              v_loc_parts_array = v_loc_path.split("/")
              v_subjectid_asl =v_base_path+"/preprocessed/visits/"+v_loc_parts_array[0]+"/"+v_subjectid+"/asl"
              if File.directory?(v_subjectid_asl)
                    v_dir_array = Dir.entries(v_subjectid_asl)
                    v_dir_array.each do |f|
                      v_asl_dir_array = (r[4].gsub(" ","")).split(",")
                      v_asl_dir_array.each do |d|
                          v_dir_name_array = d.split("_") # sometimes just want first part of dir name
                          if f.start_with?("ASL_fmap") and f.end_with?(v_dir_name_array[0]+".nii")   # ?? use asl_fmap_file_to_use = r[4], split off first part of dir name
                              v_sp_loc = v_loc_parts_array[0]
                              v_log = v_log + "ASL fmap file found "+d+" "+ v_sp_loc+"\n"
                          end
                      end
                    end 
              end
            end

            if !v_sp_loc.blank? 
                # call processing script- ARE THERE ANY THING WHICH IS REQUIRED ON "+v_computer+", edna, gru
                v_coreg_t1 = v_fs_subjects_dir+"/"+v_subjectid_v_num+"/mri/T1_FS.nii"
                v_asl_dir_array = (r[4].gsub(" ","")).split(",")
                #asl_fmap_file_to_use split into an array --- define loc --- move the loc from above
                v_asl_dir_array.each do |d|    
                    v_dir_name_array = d.split("_") # sometimes just want first part of dir name   # -c '+v_coreg_t1+'   --- not specifying
                    v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "'+v_script+' -p '+v_sp_loc+'  -b '+v_subjectid+' -s1  '+v_dir_name_array[0] +'  --fsdir '+v_fs_subjects_dir +' " ' 
                    @schedulerun.comment ="str "+r[2]+"/"+d+"; "+v_comment[0..1990]
                    @schedulerun.save
                    v_comment = "str "+r[2]+"/"+d+"; "+v_comment
                    puts "rrrrrrr "+v_call
                    v_log = v_log + v_call+"\n"
                # end
                    begin
                        stdin, stdout, stderr = Open3.popen3(v_call)
                        # closing below stdin.close
                        #stdout.close
                        #stderr.close
                        rescue => msg  
                           v_log = v_log + msg+"\n"  
                    end
                    v_success ="N"
                    v_success_process ="N"
                    v_success_coregister ="N"
                    v_success_normalise = "N"
                    while !stdout.eof?
                        v_output = stdout.read 1024 
                        v_log = v_log + v_output  
                        if (v_log.tr("\n","")).include? "Done    'Coregister: Estimate & Reslice'"   # not very sensitive to success 
                           v_success_coregister  ="Y"
                           v_log = v_log + "Coregister: Estimate & Reslice finished ok !!!!!!!!! \n"
                                    # NEED TO  set do not run flag from R ( sw or fs  ) to N 
                        end 
                        if (v_log.tr("\n","")).include? "Done    'Normalise: Estimate & Write'"    # not very sensitive to success  "Done    "'Coregister: Estimate & Reslice'"  
                           v_success_normalise  ="Y"
                           v_log = v_log + "Normalise: Estimate & Write finished ok !!!!!!!!! \n"
                                    # NEED TO  set do not run flag from R ( sw or fs  ) to N 
                        end
                        if (v_log.tr("\n","")).include? "processing completed"  # not very sensitive to success  "Done    "'Coregister: Estimate & Reslice'"    "Done    'Normalise: Estimate & Write'"
                           v_success_process ="Y"
                           v_log = v_log + "Process finished ok !!!!!!!!! \n"
                                    # NEED TO  set do not run flag from R ( sw or fs  ) to N 
                        end
                        puts v_output
                    end

                   if v_success_process =="Y" and v_success_coregister  =="Y"  and  v_success_normalise  =="Y" # NEED TO EDIT!!!!!!  # not very sensitive to success  "Done    "'Coregister: Estimate & Reslice'"    "Done    'Normalise: Estimate & Write'"
                          v_success ="Y"
                           puts "ccccc whole Process finished ok !!!!!!!!! \n"
                           v_log = v_log + "whole Process finished ok !!!!!!!!! \n"
                                    # NEED TO  set do not run flag from R ( sw or fs  ) to N 
                    end

                    v_err =""
                    v_log = v_log +"IN ERROR \n"
                    while !stderr.eof?
                        v_err = stderr.read 1024
                        v_log = v_log +v_err
                    end
                    if !v_err.blank?
                        puts "err="+v_err
                    end
                    sql_update = "update cg_asl_status set asl_fmap_file_used = concat(asl_fmap_file_used,'[ "+t.strftime("%Y%m%d")+" "+v_dir_name_array[0]+"]') where  asl_subjectid = '"+r[2]+"'"
                    results_update = connection.execute(sql_update)   # stop from re-running
                    sql_update = "update cg_asl_status_edit set asl_fmap_file_used = concat(asl_fmap_file_used,'[ "+t.strftime("%Y%m%d")+" "+v_dir_name_array[0]+"]') where asl_subjectid = '"+r[2]+"'"
                    results_update = connection.execute(sql_update)   # stop from re-running
                    if v_success =="Y"
                          # rerun ask status.. file detect
                          v_comment = " finished=>"+r[2]+ "; " +v_comment
                    else
                          puts " in err"
                          v_log = v_log +"IN ERROR \n" 
                          while !stderr.eof?
                              v_err = stderr.read 1024
                              v_log = v_log +v_err
                              v_comment = v_err +" =>"+r[2]+ " ; " +v_comment  
                          end 
                          v_error_comment = "error in "+r[2]+" ;"+v_error_comment
                          # send email to owner
                          v_schedule_owner_email_array.each do |e|
                                v_subject = "Error in "+v_process_name+": "+v_subjectid_v_num+ " see "+v_log_path
                                PandaMailer.schedule_notice(v_subject,{:send_to => e}).deliver
                          end
                    end
                    @schedulerun.comment =v_comment[0..1990]
                    @schedulerun.save
                    stdin.close
                    stdout.close
                    stderr.close
                end
             else
               v_log = v_log + "no  \n"

             end
             process_log_append(v_log_path, v_log)
        end       
      v_comment = v_error_comment+v_comment
      puts "successful finish asl_sw_fs_process "+v_comment[0..459]
       @schedulerun.comment =("successful finish asl_sw_fs_process "+v_comment[0..1959])
       if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
        end
        @schedulerun.save
        @schedulerun.end_time = @schedulerun.updated_at      
        @schedulerun.save
    end


def  run_asl_harvest
  
      v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('asl_harvest')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting asl_harvest"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning ="" 
      v_comment_base = ""
      v_shared = Shared.new
      connection = ActiveRecord::Base.connection();
      v_cg_tn_asl = "cg_asl_pproc_v5"  
      v_asl_cn_array = ["inversion_time","global","file_name","file_path"] 
      v_asl_roi_cn = "enum,series,asl_image,global,GM_sROI_mask,GM_Angular_L,GM_Angular_R,GM_Cingulum_Ant_L,GM_Cingulum_Ant_R,GM_Cingulum_Post_L,GM_Cingulum_Post_R,GM_Frontal_Med_Orb_L,GM_Frontal_Med_Orb_R,GM_Frontal_Mid_L,GM_Frontal_Mid_R,GM_Frontal_Mid_Orb_L,GM_Frontal_Mid_Orb_R,GM_Frontal_Sup_L,GM_Frontal_Sup_R,GM_Frontal_Sup_Medial_L,GM_Frontal_Sup_Medial_R,GM_Frontal_Sup_Orb_L,GM_Frontal_Sup_Orb_R,GM_Hippocampus_L,GM_Hippocampus_R,GM_Precuneus_L,GM_Precuneus_R,GM_SupraMarginal_L,GM_SupraMarginal_R,GM_Temporal_Mid_L,GM_Temporal_Mid_R,GM_Temporal_Sup_L,GM_Temporal_Sup_R"
      v_asl_cn_array = ["enum","series","asl_image","global","GM_sROI_mask","GM_Angular_L","GM_Angular_R","GM_Cingulum_Ant_L","GM_Cingulum_Ant_R","GM_Cingulum_Post_L","GM_Cingulum_Post_R","GM_Frontal_Med_Orb_L","GM_Frontal_Med_Orb_R","GM_Frontal_Mid_L","GM_Frontal_Mid_R","GM_Frontal_Mid_Orb_L","GM_Frontal_Mid_Orb_R","GM_Frontal_Sup_L","GM_Frontal_Sup_R","GM_Frontal_Sup_Medial_L","GM_Frontal_Sup_Medial_R","GM_Frontal_Sup_Orb_L","GM_Frontal_Sup_Orb_R","GM_Hippocampus_L","GM_Hippocampus_R","GM_Precuneus_L","GM_Precuneus_R","GM_SupraMarginal_L","GM_SupraMarginal_R","GM_Temporal_Mid_L","GM_Temporal_Mid_R","GM_Temporal_Sup_L","GM_Temporal_Sup_R"]


      # just one value in global_rASL_fmap_<subjectid>_<inversion_time>_<scan_series>_bmasked.txt  # check for 2 files - could be alternative

      sql = "truncate table "+v_cg_tn_asl+"_new"
      results = connection.execute(sql)
    v_asl_pproc_v5_path = "/asl/pproc_v5/masks/roi_summary/"

    # mask/roi_summary/
    # <subjectid>_<scan_series>_ASL_ROIs_invXgm.cs
    v_asl_file_name_end = "_ASL_ROIs_invXgm.csv"
    v_product_file = ""
 
    v_asl_column_list = "inversion_time,value,file_name,file_path"
    v_secondary_key_array =["b","c","d","e",".R"]
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"
    sp_exclude_array = [-1]
    @scan_procedures = ScanProcedure.where("scan_procedures.id not in (?)", sp_exclude_array)
    # for testing@scan_procedures = ScanProcedure.where("scan_procedures.id  in (?)", "77")
    @scan_procedures.each do |sp|
      @schedulerun.comment = "start "+sp.codename+" "+v_comment_base
      @schedulerun.save
      v_visit_number =""
      if sp.codename.include?("visit2")
            v_visit_number ="_v2"
      elsif sp.codename.include?("visit3")
            v_visit_number ="_v3"
      elsif sp.codename.include?("visit4")
            v_visit_number ="_v4"
      elsif sp.codename.include?("visit5")
            v_visit_number ="_v5"
      end  
      v_codename_hyphen =  sp.codename
      v_codename_hyphen = v_codename_hyphen.gsub(".","-")

      v_preprocessed_full_path = v_preprocessed_path+sp.codename  
      if File.directory?(v_preprocessed_full_path)
        sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups,  appointments, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+"  
                                    and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id 
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
        @results = connection.execute(sql_enum)                                 
        @results.each do |r|
          enrollment = Enrollment.where("enumber='"+r[0]+"'")
          if !enrollment.blank?
            v_log = ""
            v_subjectid_path = v_preprocessed_full_path+"/"+enrollment[0].enumber
            v_subjectid = enrollment[0].enumber
            v_subjectid_v_num = enrollment[0].enumber + v_visit_number
            @schedulerun.comment = "start "+v_subjectid_v_num+" "+v_comment_base
            @schedulerun.save
            v_subjectid_asl =v_subjectid_path+v_asl_pproc_v5_path
            v_subjectid_array = []
            begin
              if File.directory?(v_subjectid_asl)
                v_subjectid_array.push(v_subjectid)
              end
              v_secondary_key_array.each do |k|
                if File.directory?(v_subjectid_path+k+v_asl_pproc_v5_path)
                  v_subjectid_array.push((v_subjectid+k))
                  v_subjectid_v_num = v_subjectid+k + v_visit_number
                  v_subjectid_path = v_preprocessed_full_path+"/"+v_subjectid+k
                  v_subjectid_pet_mk6240 =v_subjectid_path+v_asl_pproc_v5_path
                end
              end
             rescue => msg  
                v_comment = v_comment + "IN RESCUE ERROR "+msg+"\n"  
            end

            v_subjectid_array = v_subjectid_array.uniq
            v_subjectid_array.each do |subj|
              v_seconbdary_key =""
              if subj != enrollment.first.enumber
                 v_secondary_key = subj
                 v_secondary_key = v_secondary_key.gsub(enrollment.first.enumber,"")
              end
              v_subjectid = subj
              v_subjectid_v_num = subj + v_visit_number
              v_subjectid_path = v_preprocessed_full_path+"/"+subj
              v_subjectid_asl =v_subjectid_path+v_asl_pproc_v5_path
              if File.directory?(v_subjectid_asl)
                v_dir_array = Dir.entries(v_subjectid_asl)
                v_dir_array.each do |f|
                  #global_rASL_fmap_<subjectid>_<inversion_time>_<scan_series>_bmasked.txt
                  v_product_file = ""
                  if f.start_with?(v_subjectid) and f.end_with?(v_asl_file_name_end)
                    v_product_file = f
                      #check if exists in processedimages

                      v_column_header_ok = "N"
                      v_scan_series = ""
                      v_asl_file_array = f.split("_")
                      v_scan_series = v_asl_file_array[1]
                      v_values = ""
 # MAKE TRACKER QC

puts "gggg v_subjectid_asl+v_product_file="+v_subjectid_asl+v_product_file
                    if File.file?(v_subjectid_asl+v_product_file)
                        v_cnt = 0
                        File.open(v_subjectid_asl+v_product_file,'r') do |file_a|
                          while line = file_a.gets
                            if v_cnt < 1
                                v_header = line
                                v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_asl_roi_cn)
                                if v_return_flag == "N" 
                                   v_comment = v_subjectid_asl+v_product_file+"=>"+v_return_comment+" \n"+v_comment
                                    puts v_return_comment               
                                else
                                    v_column_header_ok = "Y"
                                 end
                            else
                              v_values = line.gsub("\n","")
                            end
                            v_cnt = v_cnt +1
                          end
                        end
                        if v_column_header_ok == "Y" and v_asl_cn_array.count != v_values.gsub(/\n/,"").split(",").count
                            v_column_header_ok = "N"
                            v_comment = v_subjectid_asl+v_product_file+" roi file wrong columns \n"+v_comment
                        end
                        if v_column_header_ok == "Y"
                          v_line_array = []
                          v_line_array = v_values.gsub(/\n/,"").split(",")
                          v_source_file = v_line_array[2]
                          v_inversion_time = (v_source_file.split("/").last).split("_")[3] # rASL_fmap_<subjectid>_<inversion_time>_<scan_series>.nii
                          sql = "insert into cg_asl_pproc_v5_new(subjectid,enrollment_id,scan_procedure_id,secondary_key,file_name,file_path,inversion_time,"+v_asl_cn_array.join(",")+") 
                            values('"+v_subjectid_v_num+"',"+enrollment.first.id.to_s+","+sp.id.to_s+",'"+v_secondary_key.to_s+"','"+v_product_file+"','"+v_subjectid_asl+v_product_file+"','"+v_inversion_time+"',"
                                        v_line_array = []
                                        v_values.gsub(/\n/,"").split(",").each do |v|
                                           v_line_array.push("'"+v+"'")
                                        end 
                                        sql = sql+v_line_array.join(",")

                           sql = sql+")"
                           results = connection.execute(sql)
                        end
                    end
                  end # if pattern match file name
                end # file loop
              end # has asl/pproc_v5 dir  
            end # subject array loop
          end # enrollment not blank
        end # results loop
      end # preprocessed sp dir exists
    end   # scan procedure loop
                  
                # asl
                sql = "select count(*) from cg_asl_pproc_v5_old"
                results_old = connection.execute(sql)
                
                sql = "select count(*) from cg_asl_pproc_v5"
                results = connection.execute(sql)
                v_old_cnt = results_old.first.to_s.to_i
                v_present_cnt = results.first.to_s.to_i
                v_old_minus_present =v_old_cnt-v_present_cnt
                v_present_minus_old = v_present_cnt-v_old_cnt
                if ( v_old_minus_present <= 0 or ( v_old_cnt > 0 and  (v_present_minus_old/v_old_cnt)>0.7     ) )
                  sql =  "truncate table cg_asl_pproc_v5_old"
                  results = connection.execute(sql)
                  sql = "insert into cg_asl_pproc_v5 select * from cg_asl_pproc_v5"
                  results = connection.execute(sql)
                else
                  v_comment = " The cg_asl_pproc_v5_old table has 30% more rows than the present cg_asl_pproc_v5\n Not truncating cg_asl_pproc_v5_old "+v_comment 
                end
                #  truncate cg_ and insert cg_new
                sql =  "truncate table cg_asl_pproc_v5"
                results = connection.execute(sql)

                sql = "insert into cg_asl_pproc_v5(subjectid,general_comment,status_flag,enrollment_id,scan_procedure_id,inversion_time,global,file_name,file_path,secondary_key,gm_sroi_mask,gm_angular_l,gm_angular_r,gm_cingulum_ant_l,gm_cingulum_ant_r,gm_cingulum_post_l,gm_cingulum_post_r,gm_frontal_med_orb_l,gm_frontal_med_orb_r,gm_frontal_mid_l,gm_frontal_mid_r,gm_frontal_mid_orb_l,gm_frontal_mid_orb_r,gm_frontal_sup_l,gm_frontal_sup_r,gm_frontal_sup_medial_l,gm_frontal_sup_medial_r,gm_frontal_sup_orb_l,gm_frontal_sup_orb_r,gm_hippocampus_l,gm_hippocampus_r,gm_precuneus_l,gm_precuneus_r,gm_supramarginal_l,gm_supramarginal_r,gm_temporal_mid_l,gm_temporal_mid_r,gm_temporal_sup_l,gm_temporal_sup_r,enum,series,asl_image) 
                select distinct subjectid,general_comment,status_flag,enrollment_id,scan_procedure_id,inversion_time,global,file_name,file_path,secondary_key,gm_sroi_mask,gm_angular_l,gm_angular_r,gm_cingulum_ant_l,gm_cingulum_ant_r,gm_cingulum_post_l,gm_cingulum_post_r,gm_frontal_med_orb_l,gm_frontal_med_orb_r,gm_frontal_mid_l,gm_frontal_mid_r,gm_frontal_mid_orb_l,gm_frontal_mid_orb_r,gm_frontal_sup_l,gm_frontal_sup_r,gm_frontal_sup_medial_l,gm_frontal_sup_medial_r,gm_frontal_sup_orb_l,gm_frontal_sup_orb_r,gm_hippocampus_l,gm_hippocampus_r,gm_precuneus_l,gm_precuneus_r,gm_supramarginal_l,gm_supramarginal_r,gm_temporal_mid_l,gm_temporal_mid_r,gm_temporal_sup_l,gm_temporal_sup_r,enum,series,asl_image from cg_asl_pproc_v5_new t
                                               where t.scan_procedure_id is not null  and t.enrollment_id is not null "
                results = connection.execute(sql)

                # apply edits  -- made into a function  in shared model
                v_shared.apply_cg_edits("cg_asl_pproc_v5")

     @schedulerun.comment =("successful finish asl_harvest "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
       @schedulerun.status_flag ="Y"
     end
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save  

end




# takes dicom header field, harvests a value for each ids , puts in cg_table
# need to add schedule_pass_in_value table/class ( schedule_pass_in_group, schedule_pass_in_value), panda form/admin
def run_dicom_header_field_harvest
  
  v_shared = Shared.new
  v_base_path = Shared.get_base_path()
  @schedule = Schedule.where("name in ('dicom_header_field_harvest')").first
  @schedulerun = Schedulerun.new
  @schedulerun.schedule_id = @schedule.id
  @schedulerun.comment ="starting dicom_header_field_harvest"
  @schedulerun.save
  @schedulerun.start_time = @schedulerun.created_at
  @schedulerun.save  
  # this would retrieved from schedule_pass_in_group, schedule_pass_in_value
  v_dicom_tag = "0008,1090"    #"0043,1089"   
  v_insert_base ="insert into cg_dicom_header_field_harvest(vgroup_id, series_description_type, series_description, image_dataset_id,dicom_header_field,dicom_header_field_value)"  
  v_comment = ""
  v_comment_error = ""  
  v_comment_last_vgroup ="" 
  # maybe could use cg_table with cg_edit, but think there are subjectid/key etc issues
  v_exclude_vgroup_id = "-1"   # problems in the dicoms, erros in reading
  connection = ActiveRecord::Base.connection();
  begin   # catch all exception and put error in comment 
    # truncate and populate table
      sql = "truncate table cg_dicom_header_field_harvest"       
      results = connection.execute(sql)  
     sql = "select distinct sp.codename,  vg2.id vg_id, v.id visit_id
     from scan_procedures sp, scan_procedures_vgroups spg,  vgroups vg2 , appointments a, visits v
     where sp.id = spg.scan_procedure_id
     and  vg2.id = spg.vgroup_id
     and vg2.transfer_mri ='yes' 
     and vg2.id = a.vgroup_id
     and a.id = v.appointment_id 
     and vg2.id not in ("+v_exclude_vgroup_id+")
     order by sp.codename, visit_id"        
     results = connection.execute(sql)  

    # loop thru mri visits
    # each new codename, insert old v_scanner_protocol_array, start new v_scanner_protocol_array
    results.each do |r| 
         vgroup_id = r[1]  
         #puts "starting vgroup_id="+vgroup_id.to_s 
         v_comment_last_vgroup  ="starting vgroup_id="+vgroup_id.to_s
         image_datasets = ImageDataset.where("image_datasets.visit_id in (?)",r[2])   
         v_scanner_protocol = ""
         image_datasets.each do |dataset| 
             begin
	             if tags = dataset.dicom_taghash and  !tags[v_dicom_tag].blank? and tags[v_dicom_tag] != v_dicom_tag 
	               begin
	                v_field_value = tags[v_dicom_tag][:value] unless tags[v_dicom_tag][:value].blank?  
	                v_series_description = dataset.series_description 
	                v_series_description_type = "no type defined"
	                v_series_description_type_array = SeriesDescriptionType.where("id in ( select series_description_maps.series_description_type_id from series_description_maps
	                                                                                     where series_description_maps.series_description in (?) )",v_series_description) 
	                if !v_series_description_type_array.nil? and !v_series_description_type_array[0].nil?               
	                     v_series_description_type = v_series_description_type_array[0].series_description_type  
	                end
	                sql_insert = v_insert_base+" values("+vgroup_id.to_s+",'"+v_series_description_type+"','"+v_series_description+"',"+dataset.id.to_s+",'"+v_dicom_tag+"','"+v_field_value+"')" 
	                #puts sql_insert
	                results_insert = connection.execute(sql_insert) 
	                rescue Exception => msg 
	                   v_error = msg.to_s 
	                   puts "ERROR ids !!!!!!!"+"visit_id="+r[2].to_s
                  puts v_error
	                end
	             end 
	           rescue Exception => msg 
                 v_error = msg.to_s   
                 v_comment_error = v_comment_error+" err visit_id="+r[2].to_s+" ids="+dataset.id.to_s 
                 puts "ERROR ids !!!!!!!"+"visit_id="+r[2].to_s
              puts v_error
              end
	       end  
      end  
      @schedulerun.comment =v_comment_last_vgroup+v_comment_error+" successful finish dicom_header_field_harvest"
      @schedulerun.status_flag ="Y"
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save
    rescue Exception => msg
       v_error = msg.to_s
       puts "ERROR !!!!!!!"
       puts v_error
        @schedulerun.comment =v_comment_last_vgroup+v_error[0..499]
        @schedulerun.status_flag="E"
        @schedulerun.save
    end     
  
end

  def run_dir_size
        v_base_path = Shared.get_base_path()
        connection = ActiveRecord::Base.connection(); 
         @schedule = Schedule.where("name in ('dir_size')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting dir_size"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_date = Date.today.strftime("%Y-%m-%d")
          #desc "take a meausrement of every directory in the system"
          v_cnt = 0
      		Directory.where("status_flag ='Y'").each do |directory|   # all. where("status_flag ='Y'")
      			size = (`du -s -k #{directory.path}`).split.first
      			directory.measurements.create :size => size
      			v_cnt = v_cnt + 1
      		end
          # v_dir_array =['data2','data4','data6','SysAdmin','data1','data3','data5','data7','analyses','preprocessed','soar_data','raw'] 
          # # v_dir_array =['data3']    
          # # linux likes "du -ch --max-depth=2 ."
          # # mac like "du -ch -d 2 ."
          # v_cnt = 1
          # v_dir_array.each do |dir|  
          #   v_depth = "1"
          #   if dir == "preprocessed"
          #      v_depth = "2"
          #   end
          #   v_dir_base =   v_base_path+"/"+dir      
          #   v_sql = "delete from dir_size where run_date ='"+v_date+"' and dir_base ='"+v_dir_base+"' "
          #     results = connection.execute(v_sql)                      
          #   v_call = "cd "+v_dir_base+"; du -ch -d "+v_depth+" ."
          #   puts v_call
          #   stdin, stdout, stderr = Open3.popen3(v_call)
          #   while !stdout.eof?
          #     v_val = 1
          #     # just waiting
          #   end
          #   while v_line = stdout.gets 
          #  # (stdout.read).each do |v_line|    
          #     # convert eveything to G
          #     v_cols = v_line.split()
          #     # gsub and to_float, divide
          #     v_dir_size = v_cols[0]
          #     v_dir_size_float =0
          #     if v_dir_size.include?"G"
          #        v_dir_size.gsub("G","")
          #        v_dir_size_float = v_dir_size.to_f
          #     elsif v_dir_size.include?"T"
          #       v_dir_size.gsub("T","")
          #       v_dir_size_float =  (v_dir_size.to_f)*1024
          #     elsif v_dir_size.include?"M"
          #       v_dir_size.gsub("M","")
          #       v_dir_size_float =  (v_dir_size.to_f)/(1024)
          #     elsif v_dir_size.include?"K"
          #       v_dir_size.gsub("K","")
          #       v_dir_size_float =  (v_dir_size.to_f)/(1024*1024)
          #     end
          #     
          #     # split, replace leading ./ with v_dir_base
          #     if v_cols[1][0..0] == "."
          #        v_dir_path = v_dir_base+ (v_cols[1])[1..-1]  # need to trim leading "."
          #     else
          #       if v_cols[1] == "total"
          #         v_dir_path = v_dir_base+"/="+ (v_cols[1])
          #       else
          #           v_dir_path = v_dir_base+"/"+ (v_cols[1])
          #        end
          #     end
          #      v_sql = "insert into dir_size(dir_base,dir_path, run_date,dir_size)Values('"+v_dir_base+"','"+v_dir_path+"','"+v_date+"','"+v_dir_size_float.to_s+"')"
          #      results = connection.execute(v_sql)
          #      v_cnt = v_cnt + 1
          #    end
          #    # how to try/catch errors
          #    
          #   stdin.close
          #   stdout.close
          #   stderr.close
          # end

           puts "successful finish dir_size "+v_comment[0..459]
           @schedulerun.comment =("successful finish dir_size "+v_cnt.to_s+" rows inserted "+ v_comment[0..459])
           if !v_comment.include?("ERROR")
              @schedulerun.status_flag ="Y"
           end
           @schedulerun.save
           @schedulerun.end_time = @schedulerun.updated_at      
           @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end
  end  
    
  # to add columns --
  # change sql_base insert statement
  # change  sql = sql_base+  insert statement with values
  # change  self.move_present_to_old_new_to_present
  def run_dti_status
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('dti_status')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting dti_status"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_computer = "kanga"
    ####    begin   # catch all exception and put error in comment    
            sql = "truncate table cg_dti_status_new"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)

            sql_base = "insert into cg_dti_status_new(dti_subjectid,dti_fa_file_name, dti_general_comment,dti_fa_flag,dti_md_file_name,
                                                dti_md_flag,dti_l1_file_name,dti_l1_flag,dti_l2_file_name,dti_l2_flag,dti_l3_file_name,dti_l3_flag,dti_nativefa_file_name,dti_nativefa_flag,dti_nativemd_file_name,dti_nativemd_flag,dti_nativel1_file_name,dti_nativel1_flag,dti_nativel2_file_name,dti_nativel2_flag,dti_nativel3_file_name,dti_nativel3_flag,enrollment_id, scan_procedure_id)values("  
# just looking in preprocessed for list - but could add the listing from raw later to drive processing 
# added adrc native below  --- none of the adrc are in the regular  -- but check 

            v_preprocessed_path = v_base_path+"/preprocessed/modalities/dti/adluru_pipeline/"
            v_preprocessed_adrc_native_path = v_base_path+"/preprocessed/modalities/dti/adluru_adrc_native_space/"
            v_preprocessed_full_path = v_preprocessed_path   #+sp.codename
            if File.directory?( v_preprocessed_full_path) # v_raw_full_path)
              if !File.directory?(v_preprocessed_full_path)
                  puts "preprocessed path NOT exists "+v_preprocessed_full_path
              end
              # FA
              # ls *_combined_fa.nii*
              # split off subjected - assume all visit1
              v_cnt = 0
              Dir.glob(v_preprocessed_path+"/FA/*_combined_fa.nii*").each do |f|
                  v_file_name = f.gsub(v_preprocessed_path+"/FA/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 3
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_fa_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        sql = sql_base+"'"+file_name_array[0]+"','"+v_file_name+"','','"+v_dti_fa_flag+"',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                        results = connection.execute(sql)
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end
              #FA native -- only adrc
              Dir.glob(v_preprocessed_adrc_native_path+"/nativeFA/*_final_spd_fa.nii*").each do |f|   
                  v_file_name = f.gsub(v_preprocessed_adrc_native_path+"/nativeFA/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 8
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_nativefa_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        # check if file_name_array[0] == dti_subjectid
                        sql = "select * from cg_dti_status_new where dti_subjectid ='"+file_name_array[0]+"'"
                        results = connection.execute(sql)
                        if results.size > 0
                           sql = "update cg_dti_status_new set dti_nativefa_flag ='"+v_dti_nativefa_flag+"', dti_nativefa_file_name='"+v_file_name+"' where dti_subjectid = '"+file_name_array[0]+"'"
                           results = connection.execute(sql)
                        else 
                           sql = sql_base+"'"+file_name_array[0]+"',NULL,'','N',NULL,'N',NULL,'N',NULL,'N',NULL,'N','"+v_file_name+"','"+v_dti_nativefa_flag+"',NULL,'N',NULL,'N',NULL,'N',NULL,'N',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                            results = connection.execute(sql)
                        end
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end
              Dir.glob(v_preprocessed_path+"/MD/*_combined_md.nii*").each do |f|
                  v_file_name = f.gsub(v_preprocessed_path+"/MD/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 3
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_md_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        # check if file_name_array[0] == dti_subjectid
                        sql = "select * from cg_dti_status_new where dti_subjectid ='"+file_name_array[0]+"'"
                        results = connection.execute(sql)
                        if results.size > 0
                           sql = "update cg_dti_status_new set dti_md_flag ='"+v_dti_md_flag+"', dti_md_file_name='"+v_file_name+"' where dti_subjectid = '"+file_name_array[0]+"'"
                           results = connection.execute(sql)
                        else 
                           sql = sql_base+"'"+file_name_array[0]+"',NULL,'','N','"+v_file_name+"','"+v_dti_md_flag+"',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                           results = connection.execute(sql)
                        end
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end
               #MD native -- only adrc
              Dir.glob(v_preprocessed_adrc_native_path+"/nativeMD/*_final_spd_md.nii*").each do |f|
                  v_file_name = f.gsub(v_preprocessed_adrc_native_path+"/nativeMD/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 8
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_nativemd_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        # check if file_name_array[0] == dti_subjectid
                        sql = "select * from cg_dti_status_new where dti_subjectid ='"+file_name_array[0]+"'"
                        results = connection.execute(sql)
                        if results.size > 0
                           sql = "update cg_dti_status_new set dti_nativemd_flag ='"+v_dti_nativemd_flag+"', dti_nativemd_file_name='"+v_file_name+"' where dti_subjectid = '"+file_name_array[0]+"'"
                           results = connection.execute(sql)
                        else 
                           sql = sql_base+"'"+file_name_array[0]+"',NULL,'','N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N','"+v_file_name+"','"+v_dti_md_flag+"',NULL,'N',NULL,'N',NULL,'N',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                           results = connection.execute(sql)
                        end
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end
              
              Dir.glob(v_preprocessed_path+"/L1/*_combined_L1.nii*").each do |f|
                  v_file_name = f.gsub(v_preprocessed_path+"/L1/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 3
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_l1_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        # check if file_name_array[0] == dti_subjectid
                        sql = "select * from cg_dti_status_new where dti_subjectid ='"+file_name_array[0]+"'"
                        results = connection.execute(sql)
                        if results.size > 0
                           sql = "update cg_dti_status_new set dti_l1_flag ='"+v_dti_l1_flag+"', dti_l1_file_name='"+v_file_name+"' where dti_subjectid = '"+file_name_array[0]+"'"
                           results = connection.execute(sql)
                        else 
                           sql = sql_base+"'"+file_name_array[0]+"',NULL,'','N',NULL,'N','"+v_file_name+"','"+v_dti_l1_flag+"',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                           results = connection.execute(sql)
                        end
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end      
          
              #L1 native -- only adrc
              Dir.glob(v_preprocessed_adrc_native_path+"/nativeL1/*_final_spd_lambda1.nii*").each do |f|
                  v_file_name = f.gsub(v_preprocessed_adrc_native_path+"/nativeL1/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 8
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_nativel1_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        # check if file_name_array[0] == dti_subjectid
                        sql = "select * from cg_dti_status_new where dti_subjectid ='"+file_name_array[0]+"'"
                        results = connection.execute(sql)
                        if results.size > 0
                           sql = "update cg_dti_status_new set dti_nativel1_flag ='"+v_dti_nativel1_flag+"', dti_nativel1_file_name='"+v_file_name+"' where dti_subjectid = '"+file_name_array[0]+"'"
                           results = connection.execute(sql)
                        else 
                           sql = sql_base+"'"+file_name_array[0]+"',NULL,'','N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N','"+v_file_name+"','"+v_dti_nativel1_flag+"',NULL,'N',NULL,'N',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                           results = connection.execute(sql)
                        end
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end
              Dir.glob(v_preprocessed_path+"/L2/*_combined_L2.nii*").each do |f|
                  v_file_name = f.gsub(v_preprocessed_path+"/L2/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 3
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_l2_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        # check if file_name_array[0] == dti_subjectid
                        sql = "select * from cg_dti_status_new where dti_subjectid ='"+file_name_array[0]+"'"
                        results = connection.execute(sql)
                        if results.size > 0
                           sql = "update cg_dti_status_new set dti_l2_flag ='"+v_dti_l2_flag+"', dti_l2_file_name='"+v_file_name+"' where dti_subjectid = '"+file_name_array[0]+"'"
                           results = connection.execute(sql)
                        else 
                           sql = sql_base+"'"+file_name_array[0]+"',NULL,'','N',NULL,'N',NULL,'N','"+v_file_name+"','"+v_dti_l2_flag+"',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                           results = connection.execute(sql)
                        end
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end  
              #L2 native -- only adrc
              Dir.glob(v_preprocessed_adrc_native_path+"/nativeL2/*_final_spd_lambda2.nii*").each do |f|
                  v_file_name = f.gsub(v_preprocessed_adrc_native_path+"/nativeL2/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 8
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_nativel2_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        # check if file_name_array[0] == dti_subjectid
                        sql = "select * from cg_dti_status_new where dti_subjectid ='"+file_name_array[0]+"'"
                        results = connection.execute(sql)
                        if results.size > 0
                           sql = "update cg_dti_status_new set dti_nativel2_flag ='"+v_dti_nativel2_flag+"', dti_nativel2_file_name='"+v_file_name+"' where dti_subjectid = '"+file_name_array[0]+"'"
                           results = connection.execute(sql)
                        else 
                           sql = sql_base+"'"+file_name_array[0]+"',NULL,'','N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N','"+v_file_name+"','"+v_dti_nativel2_flag+"',NULL,'N',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                           results = connection.execute(sql)
                        end
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end
              
              Dir.glob(v_preprocessed_path+"/L3/*_combined_L3.nii*").each do |f|
                  v_file_name = f.gsub(v_preprocessed_path+"/L3/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 3
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_l3_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        # check if file_name_array[0] == dti_subjectid
                        sql = "select * from cg_dti_status_new where dti_subjectid ='"+file_name_array[0]+"'"
                        results = connection.execute(sql)
                        if results.size > 0
                           sql = "update cg_dti_status_new set dti_l3_flag ='"+v_dti_l3_flag+"', dti_l3_file_name='"+v_file_name+"' where dti_subjectid = '"+file_name_array[0]+"'"
                           results = connection.execute(sql)
                        else 
                           sql = sql_base+"'"+file_name_array[0]+"',NULL,'','N',NULL,'N',NULL,'N',NULL,'N','"+v_file_name+"','"+v_dti_l3_flag+"',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                           results = connection.execute(sql)
                        end
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end                    
              
              #L3 native -- only adrc
              Dir.glob(v_preprocessed_adrc_native_path+"/nativeL3/*_final_spd_lambda3.nii*").each do |f|
                  v_file_name = f.gsub(v_preprocessed_adrc_native_path+"/nativeL3/","")
                  file_name_array = v_file_name.split('_')
                  if file_name_array.size == 8
                      enrollment = Enrollment.where("enumber in (?)",file_name_array[0])
                      if !enrollment.blank?
                        v_dti_nativel3_flag = "Y"
                        # get v_sp based on subjectid - replace all numbers? look up in scan_procedure -- visit1 
                        v_subjectid_trim = file_name_array[0].gsub(/[0-9]/,"")
                        sql = "select id from scan_procedures where subjectid_base ='"+v_subjectid_trim+"' and codename like '%visit1'"
                        results = connection.execute(sql)
                        v_sp = 0;
                        results.each do |r|
                              v_sp = r[0]
                        end
                        # check if file_name_array[0] == dti_subjectid
                        sql = "select * from cg_dti_status_new where dti_subjectid ='"+file_name_array[0]+"'"
                        results = connection.execute(sql)
                        if results.size > 0
                           sql = "update cg_dti_status_new set dti_nativel3_flag ='"+v_dti_nativel3_flag+"', dti_nativel3_file_name='"+v_file_name+"' where dti_subjectid = '"+file_name_array[0]+"'"
                           results = connection.execute(sql)
                        else 
                           sql = sql_base+"'"+file_name_array[0]+"',NULL,'','N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N',NULL,'N','"+v_file_name+"','"+v_dti_nativel3_flag+"',"+enrollment[0].id.to_s+","+v_sp.to_s+")"
                           results = connection.execute(sql)
                        end
                        v_cnt = v_cnt + 1
                      end
                  else
                        #puts "               # NOT exists "+v_raw_full_path
                  end # check if raw dir exisits
              end
              
           end           
           # check move cg_ to cg_old
           # v_shared = Shared.new 
           # move from new to present table -- made into a function  in shared model
           v_comment = self.move_present_to_old_new_to_present("cg_dti_status",
             "dti_subjectid,dti_fa_file_name, dti_general_comment,dti_fa_flag, dti_fa_comment, dti_fa_global_quality,dti_md_file_name,dti_md_flag, dti_md_comment, dti_md_global_quality, dti_l1_file_name,dti_l1_flag, dti_l1_comment, dti_l1_global_quality,dti_l2_file_name,dti_l2_flag, dti_l2_comment, dti_l2_global_quality, dti_l3_file_name,dti_l3_flag, dti_l3_comment, dti_l3_global_quality,dti_nativefa_file_name,dti_nativefa_flag,dti_nativemd_file_name,dti_nativemd_flag,dti_nativel1_file_name,dti_nativel1_flag,dti_nativel2_file_name,dti_nativel2_flag,dti_nativel3_file_name,dti_nativel3_flag,
              enrollment_id,scan_procedure_id",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)


           # apply edits  -- made into a function  in shared model
           self.apply_cg_edits('cg_dti_status')

           puts "successful finish dti_status "+v_comment[0..459]
           @schedulerun.comment =("successful finish dti_status "+v_cnt.to_s+" records loaded "+v_comment[0..459])
           if !v_comment.include?("ERROR")
              @schedulerun.status_flag ="Y"
           end
           @schedulerun.save
           @schedulerun.end_time = @schedulerun.updated_at      
           @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end
  end  
  
  # to add columns --
  # change sql_base insert statement
  # change  sql = sql_base+  insert statement with values
  # change  self.move_present_to_old_new_to_present
  def run_epi_rest_status
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('epi_rest_status')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting epi_rest_status"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_computer = "kanga"
    ####    begin   # catch all exception and put error in comment    
            sql = "truncate table cg_epi_rest_status_new"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)

            sql_base = "insert into cg_epi_rest_status_new(epi_rest_subjectid, epi_rest_general_comment,w_filter_errts_norm_ra_flag,filter_errts_norm_ra_flag,t1_fs_flag,t1_single,enrollment_id, scan_procedure_id)values("  
            v_raw_path = v_base_path+"/raw"
            v_mri = "/mri"
            no_mri_path_sp_list =['asthana.adrc-clinical-core.visit1',
            'bendlin.mets.visit1','bendlin.tami.visit1','bendlin.wmad.visit1','carlson.sharp.visit1','carlson.sharp.visit2',
            'carlson.sharp.visit3','carlson.sharp.visit4','dempsey.plaque.visit1','dempsey.plaque.visit2','gleason.falls.visit1',
            'johnson.merit220.visit1','johnson.merit220.visit2','johnson.tbi.aware.visit3','johnson.tbi-va.visit1','ries.aware.visit1','wrap140']

            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            # get list of scan_procedure codename -- exclude 4, 10, 15, 19, 32, 
                # ??? johnson.pc vs johnsonpc4000.visit1 vs pc_4000
                # ??? johnson.tbi10000 vs johnson.tbiaware vs tbi_1000
                # ??? johnson.wrap140.visit1 vs wrap140.visit1 vs wrap140
                # NOT exists /Volumes/team-1/raw/carlson.esprit/mri
                # NOT exists /Volumes/team-1/raw/johnson.wrap140.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbiaware.visit3/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit2/mri
                # NOT exists /Volumes/team-1/raw/johnnson.alz.repsup.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.pc4000.visit1/mri
            v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
            @scan_procedures = ScanProcedure.where("id not in (?)",v_exclude_sp)
            @scan_procedures. each do |sp|
              v_visit_number =""
              if sp.codename.include?("visit2")
                v_visit_number ="_v2"
              elsif sp.codename.include?("visit3")
                v_visit_number ="_v3"
              elsif sp.codename.include?("visit4")
                v_visit_number ="_v4"
              elsif sp.codename.include?("visit5")
                v_visit_number ="_v5"
              end
               if no_mri_path_sp_list.include?(sp.codename)
                 v_mri = ""
                else
                  v_mri = "/mri"
                end
                v_raw_full_path = v_raw_path+"/"+sp.codename+v_mri
                v_preprocessed_full_path = v_preprocessed_path+sp.codename
                if File.directory?(v_raw_full_path)
                    if !File.directory?(v_preprocessed_full_path)
                        puts "preprocessed path NOT exists "+v_preprocessed_full_path
                     end
                    Dir.entries(v_raw_full_path).select { |file| File.directory? File.join(v_raw_full_path, file)}.each do |dir|
                      dir_name_array = dir.split('_')
                      if dir_name_array.size == 3
                         enrollment = Enrollment.where("enumber in (?)",dir_name_array[0])
                         if !enrollment.blank?
                             v_t1_fs_flag = "N"
                             v_t1_single = ""
                             # need FS path - use fs_home_to_use if not null
                             # have enrollemnt_id and sp.id
                             v_fs_home = "orig_recon"
                             v_fs_home_path = v_base_path+"/preprocessed/modalities/freesurfer/"
                             sql_fs = "select fs_home_to_use from cg_epi_rest_status where enrollment_id = "+ enrollment[0].id.to_s+" and scan_procedure_id ="+sp.id.to_s
                             results_fs = connection.execute(sql_fs)
                             if results_fs.first.blank? # new will always just be non-edited - blank/default
                               sql_fs = "select fs_home_to_use from cg_epi_rest_status_new where enrollment_id = "+ enrollment[0].id.to_s+" and scan_procedure_id ="+sp.id.to_s
                             end
                             results_fs = connection.execute(sql_fs)
                             if !results_fs.blank? and !results_fs.first.blank? and !(results_fs.first)[0].blank?
                                 v_fs_home = (results_fs.first)[0]  
                             end
                             v_subject_fs_path = v_fs_home_path+v_fs_home+"/"+dir_name_array[0]+"/mri"
                             if File.directory?(v_subject_fs_path)
                                  v_dir_array = Dir.entries(v_subject_fs_path)
                                  v_dir_array.each do |f|
                                    
                                    if f == "T1.mgz"
                                      v_t1_fs_flag = "Y"
                                      # v_t1_single ????
                                     end
                                  end
                                  
                              end
                             
                             v_subjectid_epi_rest = v_preprocessed_full_path+"/"+dir_name_array[0]+"/epi_rest/proc"
                             if File.directory?(v_subjectid_epi_rest)
                                  v_dir_array = Dir.entries(v_subjectid_epi_rest)   # need to get date for specific files
                                v_w_filter_errts_norm_ra_flag ="N"
                                v_filter_errts_norm_ra_flag = "N"
                                v_dir_array.each do |f|
                                  
                                  if f.start_with?("filter_errts_norm_ra"+dir_name_array[0]) and f.end_with?(".nii")
                                    v_filter_errts_norm_ra_flag = "Y"
                                  elsif f.start_with?("w_filter_errts_norm_ra"+dir_name_array[0]) and f.end_with?(".nii")
                                        v_w_filter_errts_norm_ra_flag ="Y"
                                  end
                                end
                                
                                sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','','"+v_w_filter_errts_norm_ra_flag+"','"+v_filter_errts_norm_ra_flag+"','"+v_t1_fs_flag+"','"+v_t1_single +"',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                 results = connection.execute(sql)
                             else
                                 sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','no epi_rest dir','N','N','N','N',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                 results = connection.execute(sql)
                             end # check for subjectid asl dir
                         else
                           #puts "no enrollment "+dir_name_array[0]
                         end # check for enrollment
                      end # check that dir name is in expected format [subjectid]_exam#_MMDDYY - just test size of array
                    end # loop thru the subjectids
                 else
                        #puts "               # NOT exists "+v_raw_full_path
                 end # check if raw dir exisits
            end            
            # check move cg_ to cg_old
            # v_shared = Shared.new 
             # move from new to present table -- made into a function  in shared model
             v_comment = self.move_present_to_old_new_to_present("cg_epi_rest_status",
             "epi_rest_subjectid, epi_rest_general_comment,w_filter_errts_norm_ra_flag, w_filter_errts_norm_ra_comment, w_filter_errts_norm_ra_global_quality, filter_errts_norm_ra_flag, filter_errts_norm_ra_comment, filter_errts_norm_ra_global_quality,t1_fs_flag,t1_single,enrollment_id,scan_procedure_id",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)


             # apply edits  -- made into a function  in shared model
             self.apply_cg_edits('cg_epi_rest_status')

             puts "successful finish epi_rest_status "+v_comment[0..459]
              @schedulerun.comment =("successful finish epi_rest_status "+v_comment[0..459])
              if !v_comment.include?("ERROR")
                 @schedulerun.status_flag ="Y"
               end
               @schedulerun.save
               @schedulerun.end_time = @schedulerun.updated_at      
               @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end
    
    
  end

  def run_error_repeat_schedulerun
          @schedule = Schedule.where("name in ('error_repeat_schedulerun')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting error_repeat_schedulerun"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          puts "in error_repeat_schedulerun"
          v_status_n_threshold = 2;

           # get all sched jobs started yesterday which status = N
           # and then check if last 2-3 instances of job also N
           # send email 
          v_sql ="SELECT distinct t1.schedule_id ,t2.name FROM scheduleruns t1, schedules t2 WHERE t1.status_flag = 'N'
              AND t1.start_time > (NOW() - interval 1 day) 
              AND t1.schedule_id = t2.id"
          connection = ActiveRecord::Base.connection();        
          @results = connection.execute(v_sql)
          @results.each do |r|
               v_cnt = 0
               v_sql_check = "    SELECT t3.schedule_id, t3.status_flag, t3.start_time FROM
                     (select t2.schedule_id , t2.status_flag, t2.start_time FROM scheduleruns t2
                        where t2.schedule_id in  ("+r[0].to_s+") order by t2.start_time DESC LIMIT 3) as t3"

               @check_results = connection.execute(v_sql_check)
               @check_results.each do |cr|
                  if(cr[1] == "N")
                      v_cnt = v_cnt + 1
                  end
               end
               if(v_cnt > v_status_n_threshold)
                  # send email
                  v_subject = "Repeated Failure ==>[ "+r[1]+" ]<== schedule run "
                    @schedulerun.comment = v_subject+" ;"+@schedulerun.comment
                    v_comment = v_subject+" ERROR ;"+v_comment
                     @schedulerun.save
                  v_email = "noreply_johnson_lab@medicine.wisc.edu"
                  PandaMailer.schedule_notice(v_subject,{:send_to => v_email}).deliver
               end
           end 

          puts "successful finish error_repeat_schedulerun "+v_comment[0..459]
          @schedulerun.comment =("successful finish error_repeat_scheduleruns "+v_comment[0..459])
          if !v_comment.include?("ERROR")
                 @schedulerun.status_flag ="Y"
          end
          @schedulerun.save
          @schedulerun.end_time = @schedulerun.updated_at      
          @schedulerun.save 

  end

  # to add columns --
  # change the cg_table in database
  # change the cg_search table
  # change sql_base insert statement
  # change  sql = sql_base+  insert statement with values
  # change  self.move_present_to_old_new_to_present
  def run_fdg_status
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('fdg_status')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting fdg_status"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_computer = "kanga"
          puts "in fdg status"
    ####    begin   # catch all exception and put error in comment    
            sql = "truncate table cg_fdg_status_new"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)

            sql_base = "insert into cg_fdg_status_new(fdg_subjectid, fdg_general_comment,fdg_registered_to_fs_flag,fdg_scaled_registered_to_fs_flag,fdg_smoothed_and_warped_flag,fdg_scaled_smoothed_and_warped_flag,fdg_summed_flag,fdg_preproc_v5,default_subjectspace_masks_v5,enrollment_id, scan_procedure_id)values("  

    # just populating fdg_summed_flag
            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            # get list of scan_procedure codename -- exclude 4, 10, 15, 19, 32, 
                # ??? johnson.pc vs johnsonpc4000.visit1 vs pc_4000
                # ??? johnson.tbi10000 vs johnson.tbiaware vs tbi_1000
                # ??? johnson.wrap140.visit1 vs wrap140.visit1 vs wrap140
                # NOT exists /Volumes/team-1/raw/carlson.esprit/mri
                # NOT exists /Volumes/team-1/raw/johnson.wrap140.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbiaware.visit3/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit2/mri
                # NOT exists /Volumes/team-1/raw/johnnson.alz.repsup.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.pc4000.visit1/mri
            v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
            @scan_procedures = ScanProcedure.where("petscan_flag='Y' and id not in (?)",v_exclude_sp)  # NEED ONLY sp with fdg, but filter later
            @scan_procedures. each do |sp|
               v_visit_number =""
               if sp.codename.include?("visit2")
                  v_visit_number ="_v2"
               elsif sp.codename.include?("visit3")
                  v_visit_number ="_v3"
               elsif sp.codename.include?("visit4")
                  v_visit_number ="_v4"
               elsif sp.codename.include?("visit5")
                  v_visit_number ="_v5"
               end
                # petscans.lookup_pettracer_id = 2 ==> fdg
                v_preprocessed_full_path = v_preprocessed_path+sp.codename
                sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups, vgroups, appointments, petscans, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+" and  vgroups.transfer_pet = 'yes'  
                                    and appointments.vgroup_id = vgroups.id and appointments.appointment_type = 'pet_scan'
                                    and appointments.id = petscans.appointment_id and petscans.lookup_pettracer_id = 2
                                    and enrollment_vgroup_memberships.vgroup_id = vgroups.id and enrollment_vgroup_memberships.enrollment_id = enrollments.id
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
                 @results = connection.execute(sql_enum)
                                    
                 @results.each do |r|
                     enrollment = Enrollment.where("enumber='"+r[0]+"'")
                     if !enrollment.blank?
                        v_subjectid_fdg = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/pet/fdg/pproc_v5"
                        if File.directory?(v_subjectid_fdg)
                            v_dir_array = Dir.entries(v_subjectid_fdg)   # need to get date for specific files
                            v_fdg_registered_to_fs_flag ="N"
                            v_fdg_scaled_registered_to_fs_flag ="N"
                            v_fdg_smoothed_and_warped_flag = "N"
                            v_fdg_scaled_smoothed_and_warped_flag = "N"
                            v_fdg_summed_flag = "N"
                            v_fdg_preproc_v5 = "N"
                            v_default_subjectspace_masks_v5 = "N"
                            v_dir_array.each do |f|
                              if f.start_with?("swr"+enrollment[0].enumber+"_summed.nii")
                                  v_fdg_preproc_v5 ="Y"
                              end
                              if File.directory?(v_subjectid_fdg+"/masks")
                                v_dir_masks_array = Dir.entries(v_subjectid_fdg+"/masks") 
                                if (v_dir_masks_array.length > 55) # expect 56 , assume all files are masks
                                      v_default_subjectspace_masks_v5 = "Y"
                                end  
                              end

                              if f.start_with?("wr") and f.end_with?("summed.nii")
                                  v_fdg_summed_flag ="Y"
                              end
                            end
                                
                            sql = sql_base+"'"+enrollment[0].enumber+v_visit_number+"','','"+v_fdg_registered_to_fs_flag+"','"+v_fdg_scaled_registered_to_fs_flag+"','"+v_fdg_smoothed_and_warped_flag+"','"+v_fdg_scaled_smoothed_and_warped_flag+"','"+v_fdg_summed_flag+"','"+v_fdg_preproc_v5+"','"+v_default_subjectspace_masks_v5+"',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                 results = connection.execute(sql)
                        else   # just insert empty row
                                 sql = sql_base+"'"+enrollment[0].enumber+v_visit_number+"','no fdg dir','N','N','N','N','N','N','N',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                 results = connection.execute(sql)
                        end # check for subjectid asl dir
                     else
                           #puts "no enrollment "+dir_name_array[0]
                     end # check for enrollment
                 end # loop thru the subjectids
            end            
            # check move cg_ to cg_old
            # v_shared = Shared.new 
             # move from new to present table -- made into a function  in shared model
             v_comment = self.move_present_to_old_new_to_present("cg_fdg_status",
             "fdg_subjectid, fdg_general_comment,fdg_registered_to_fs_flag, fdg_registered_to_fs_comment, fdg_registered_to_fs_global_quality,fdg_scaled_registered_to_fs_flag, fdg_scaled_registered_to_fs_comment, fdg_scaled_registered_to_fs_global_quality,fdg_smoothed_and_warped_flag, fdg_smoothed_and_warped_comment, fdg_smoothed_and_warped_global_quality,fdg_scaled_smoothed_and_warped_flag, fdg_scaled_smoothed_and_warped_comment, fdg_scaled_smoothed_and_warped_global_quality,fdg_summed_flag,fdg_preproc_v5,default_subjectspace_masks_v5,enrollment_id,scan_procedure_id",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)


             # apply edits  -- made into a function  in shared model
             self.apply_cg_edits('cg_fdg_status')

             puts "successful finish fdg_status "+v_comment[0..459]
              @schedulerun.comment =("successful finish fdg_status "+v_comment[0..459])
              if !v_comment.include?("ERROR")
                 @schedulerun.status_flag ="Y"
               end
               @schedulerun.save
               @schedulerun.end_time = @schedulerun.updated_at      
               @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end
    
    
  end

  # from cg_fjell_20140507
  # done_flag = Y means the files has been uploaded
  # status_flag = N means do not upload this subjectid
  def run_fjell_20140506_upload
    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "fjell_20140506_upload"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('fjell_20140506_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting fjell_20140506_upload -MOVED TO SHARED_RETIRED.rb"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
     
    
  end
    


  # looks in freesurfer QC trfile trtype=4 , file_completed = Y, global assessment=Pass ,moved to good2go from manual edit
  def run_fs_move_qc_pass_to_good2go

    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "fs_move_qc_pass_to_good2go"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('fs_move_qc_pass_to_good2go')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting fs_move_qc_pass_to_good2goo"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      t = Time.now
      v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
      v_log_name =v_process_name+"_"+v_date_YM
      v_log_path =v_log_base+v_log_name
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
    connection = ActiveRecord::Base.connection();
    v_manual_edit_dir = v_base_path+"/preprocessed/modalities/freesurfer/manual_edits/"
    v_good2go_dir = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"

        # get trtype = 1, file_completed
    @trfiles = Trfile.where("trfiles.trtype_id = 4 and trfiles.file_completed_flag = 'Y' and trfiles.qc_value = 'Pass'")
    @trfiles.each do |trf|
        # get last edit, check for 
        # check if in good2go
        v_subject = trf.subjectid
        if !trf.secondary_key.nil? 
          # need [subjectid]_v# ==> [subjectid][secondary_key]_v#
          if trf.subjectid.include?("_v2")
            v_subject = (trf.subjectid).gsub(/_v2/,"")+trf.secondary_key+"_v2"
          elsif trf.subjectid.include?("_v3")
            v_subject = (trf.subjectid).gsub(/_v3/,"")+trf.secondary_key+"_v3"
          elsif trf.subjectid.include?("_v4")
            v_subject = (trf.subjectid).gsub(/_v4/,"")+trf.secondary_key+"_v4"
          elsif trf.subjectid.include?("_v5")
            v_subject = (trf.subjectid).gsub(/_v5/,"")+trf.secondary_key+"_v5"
          else
             v_subject = trf.subjectid+trf.secondary_key
          end
        end
        v_dir_source = v_manual_edit_dir+v_subject
        v_dir_target = v_good2go_dir+v_subject
        if File.directory?(v_dir_target)
          # already in good2go
         else
            v_comment = v_comment + " copying "+v_subject+"; \n"
            if File.directory?(v_dir_source)
           # if not make rsync or mv command
            #  v_call = "rsync -av "+v_dir_source+" "+v_good2go_dir
            # using mv instead of rsync 
              v_call = " mv -n -v "+v_dir_source+" "+v_good2go_dir
      puts "aaaaaaa "+v_call
              v_comment = v_comment + " "+v_call+"; \n"
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stderr.eof?
                  v_err = stderr.read 1024
                  v_comment_warning = v_comment_warning  +v_err
                end
              while !stdout.eof?
                  v_tmp = (stdout.read 1024)
                  v_comment = v_comment + " "+ v_tmp   
              end
              stdin.close
              stdout.close
              stderr.close
           
             # v_comment = v_comment + " "+v_call+"; "
            else # no source dir
               v_comment_warning = v_comment_warning +"ERROR - no source dir "+v_subject
            end


         end

    end

       @schedulerun.comment =("successful finish fs_move_qc_pass_to_good2go "+v_comment_warning+" "+v_comment[0..3950])
    if !v_comment.include?("ERROR") and !v_comment_warning.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save

  end

  # looks in trfile trtype=1 freesurfer edits, file_completed = Y, moved to good2go from manual edit -- not move while in process
  def run_fs_move_edit_file_complete_to_good2go
    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "fs_move_edit_file_complete_to_good2go"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('fs_move_edit_file_complete_to_good2go')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting fs_move_edit_file_complete_to_good2go"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      t = Time.now
      v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
      v_log_name =v_process_name+"_"+v_date_YM
      v_log_path =v_log_base+v_log_name
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
    connection = ActiveRecord::Base.connection();
    v_manual_edit_dir = v_base_path+"/preprocessed/modalities/freesurfer/manual_edits/"
    v_good2go_dir = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"

        # get trtype = 1, file_completed
    @trfiles = Trfile.where("trfiles.trtype_id = 1 and trfiles.file_completed_flag = 'Y'")
    @trfiles.each do |trf|
        # check if in good2go
        v_subject = trf.subjectid
        if !trf.secondary_key.nil? 
          # need [subjectid]_v# ==> [subjectid][secondary_key]_v#
          if trf.subjectid.include?("_v2")
            v_subject = (trf.subjectid).gsub(/_v2/,"")+trf.secondary_key+"_v2"
          elsif trf.subjectid.include?("_v3")
            v_subject = (trf.subjectid).gsub(/_v3/,"")+trf.secondary_key+"_v3"
          elsif trf.subjectid.include?("_v4")
            v_subject = (trf.subjectid).gsub(/_v4/,"")+trf.secondary_key+"_v4"
          elsif trf.subjectid.include?("_v5")
            v_subject = (trf.subjectid).gsub(/_v5/,"")+trf.secondary_key+"_v5"
          else
             v_subject = trf.subjectid+trf.secondary_key
          end
        end
        v_dir_source = v_manual_edit_dir+v_subject
        v_dir_target = v_good2go_dir+v_subject
        if File.directory?(v_dir_target)
          # already in good2go
         else
            v_comment = v_comment + " copying "+v_subject+"; \n"
            if File.directory?(v_dir_source)
           # if not make rsync or mv command
            #  v_call = "rsync -av "+v_dir_source+" "+v_good2go_dir
            # using mv instead of rsync 
              v_call = " mv -n -v "+v_dir_source+" "+v_good2go_dir
      puts "aaaaaaa "+v_call
              v_comment = v_comment + " "+v_call+"; \n"
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stderr.eof?
                  v_err = stderr.read 1024
                  v_comment_warning = v_comment_warning  +v_err
                end
              while !stdout.eof?
                  v_tmp = (stdout.read 1024)
                  v_comment = v_comment + " "+ v_tmp   
              end
              stdin.close
              stdout.close
              stderr.close
           
             # v_comment = v_comment + " "+v_call+"; "
            else # no source dir
               v_comment_warning = v_comment_warning +"ERROR - no source dir "+v_subject
            end


         end

    end

       @schedulerun.comment =("successful finish fs_move_edit_file_complete_to_good2go "+v_comment_warning+" "+v_comment )   #[0..3990])
    if !v_comment.include?("ERROR") and !v_comment_warning.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
  end
  
  # data request from goveas, wrap with depression, resting bold/fmri, t2 cube, t2 flair, t1 volumetric, dti -nagesh - FA,MD,L1,L2,L3
  # from cg_goveas_20131031
  # done_flag = Y means the files has been uploaded
  # status_flag = N means do not upload this subjectid
  def run_goveas_20131031_upload
    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "goveas_20131031_upload"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('goveas_20131031_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting goveas_20131031_upload -MOVED T+O SHARED_RETIRED.rb"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
    
    
  end



   def run_helpern_20151125_upload  
     v_base_path = Shared.get_base_path()
      @schedule = Schedule.where("name in ('helpern_20151125_upload')").first
       @schedulerun = Schedulerun.new
       @schedulerun.schedule_id = @schedule.id
       @schedulerun.comment ="starting helpern_20151125_upload-MOVED TO SHARED_RETIRED.rb"
       @schedulerun.save
       @schedulerun.start_time = @schedulerun.created_at
       @schedulerun.save
    
   end

##################################################################
    
 # starting with pet with v1/v2 -- just T1_Volumetric
   def run_hyunwoo_20140520_upload  
     v_base_path = Shared.get_base_path()
      @schedule = Schedule.where("name in ('hyunwoo_20140520_upload')").first
       @schedulerun = Schedulerun.new
       @schedulerun.schedule_id = @schedule.id
       @schedulerun.comment ="starting hyunwoo_20140520_upload -MOVED TO SHARED_RETIRED.rb"
       @schedulerun.save
       @schedulerun.start_time = @schedulerun.created_at
       @schedulerun.save
     
   end

  def run_image_dataset_default_bravo
      v_base_path = Shared.get_base_path()
      @schedule = Schedule.where("name in ('image_dataset_default_bravo')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting image_dataset_default_bravo"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning = ""
      v_secondary_key_array =["","b","c","d","e",".R"]
      v_ids_id_array = []
      connection = ActiveRecord::Base.connection();  
       # image_datasets.use_as_default_scan_flag
       # loop thru all mri appointments
          # get   path, directory, secondary key, subjectid, all T1 series descriptions
          # look for o[subjectid][secondarkey]_[series description]_[dicomdir/replace.].nii
      sql = "SELECT visits.id, visits.path, appointments.secondary_key FROM visits, appointments 
                        where appointments.id = visits.appointment_id  
                        and visits.id in ( select image_datasets.visit_id from image_datasets,series_description_maps where 
                                  LOWER(image_datasets.series_description) = LOWER(series_description_maps.series_description)
                                  and  series_description_maps.series_description_type_id in (19,25))"  
  
      results = connection.execute(sql)
      results.each do |r|
         v_visit_id = r[0]
         v_secondary_key = r[2]
         v_path = r[1]
         v_path_array = v_path.split('/')
         v_subjectdir_array = v_path_array[v_path_array.count-1].split('_')
         v_protocol = v_path_array[v_path_array.count-2]
         if( v_protocol == 'mri')
                v_protocol = v_path_array[v_path_array.count-3]
         end
         # old protocols didn't have the /mri in the raw path
         v_preprocessing_path_unknown = "/mounts/data/preprocessed/visits/"+v_protocol+"/"+v_subjectdir_array[0]+"/unknown/"
         # get all the T1 series description and path/dir, check for o[match]
         sql_image_datasets = "SELECT image_datasets.id, image_datasets.path, image_datasets.series_description   
                             FROM image_datasets where image_datasets.visit_id = "+v_visit_id.to_s+"
                              and (image_datasets.lock_default_scan_flag != 'Y' or image_datasets.lock_default_scan_flag  is NULL)
                             AND image_datasets.series_description IN (SELECT series_description_maps.series_description 
                                               FROM series_description_maps WHERE 
                                               series_description_maps.series_description_type_id in (19,25))"
          results_ids = connection.execute(sql_image_datasets)
          v_cnt = 0
          v_ids_id_array.clear
          results_ids.each do |r_ids|
              v_image_dataset_id = r_ids[0]
              v_series_description = r_ids[2]
              v_ids_path_array = r_ids[1].split("/")
              v_id = v_ids_path_array.count-1
              v_dicom_dir = v_ids_path_array[v_id]
              if( v_dicom_dir.include?("."))
                  v_dicom_dir_array = v_dicom_dir.split(".")
                  v_dicom_dir = v_dicom_dir_array[0]
              end
              v_acpc_file_name = "o"+v_subjectdir_array[0]+"_"+v_series_description.gsub(".","").gsub("-","_").gsub(" ","_")+"_"+v_dicom_dir.gsub(".","")+".nii"                       
              if File.directory?(v_preprocessing_path_unknown)
                  v_dir_array = Dir.entries(v_preprocessing_path_unknown)
                  sql_set_flag = "UPDATE image_datasets set image_datasets.use_as_default_scan_flag = NULL
                                        WHERE image_datasets.id = "+v_image_dataset_id.to_s
                  results_set_flag = connection.execute(sql_set_flag)
                  v_dir_array.each do |f|
                      f = f.gsub("-","_")
                    if f.start_with?(v_acpc_file_name)
                       v_ids_id_array.push(v_image_dataset_id)
                       v_cnt = v_cnt + 1
                       sql_set_flag = "UPDATE image_datasets set image_datasets.use_as_default_scan_flag = 'Y'
                                        WHERE image_datasets.id = "+v_image_dataset_id.to_s
                        results_set_flag = connection.execute(sql_set_flag)
                    end
                    
                  end 
              end
          end
          if(v_cnt > 1)
              v_ids_id_array.each do |ids_id|
                  sql_set_flag = "UPDATE image_datasets set image_datasets.use_as_default_scan_flag = NULL
                                        WHERE image_datasets.id = "+ids_id.to_s
                  results_set_flag = connection.execute(sql_set_flag)
              end
          end
      end

      @schedulerun.comment =("successful finish image_dataset_default_bravo "+v_comment_warning+" "+v_comment[0..1990])
     if !v_comment.include?("ERROR")
        @schedulerun.status_flag ="Y"
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save  

  end  


  # to add columns --
  # change sql_base insert statement
  # change  sql = sql_base+  insert statement with values
  # change  self.move_present_to_old_new_to_present
  def run_lst_116_status   # actually the new  lst_122 in column, and lst_116 in separate column
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('lst_116_status')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting lst_116_status"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_secondary_key_array =["","b","c","d","e",".R"]
    ####    begin   # catch all exception and put error in comment    
            sql = "truncate table cg_lst_116_status_new"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)

            sql_base = "insert into cg_lst_116_status_new(lst_subjectid, lst_general_comment,wlesion_030_flag,o_star_nii_flag,multiple_o_star_nii_flag,sag_cube_flair_flag,multiple_sag_cube_flair_flag,wlesion_030_flag_lst_116,enrollment_id, scan_procedure_id,lst_lesion,secondary_key)values("  
            v_raw_path = v_base_path+"/raw"
            v_mri = "/mri"
            no_mri_path_sp_list =['asthana.adrc-clinical-core.visit1',
            'bendlin.mets.visit1','bendlin.tami.visit1','bendlin.wmad.visit1','carlson.sharp.visit1','carlson.sharp.visit2',
            'carlson.sharp.visit3','carlson.sharp.visit4','dempsey.plaque.visit1','dempsey.plaque.visit2','gleason.falls.visit1',
            'johnson.merit220.visit1','johnson.merit220.visit2','johnson.tbi.aware.visit3','johnson.tbi-va.visit1','ries.aware.visit1','wrap140']

            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            # get list of scan_procedure codename -- exclude 4, 10, 15, 19, 32, 
                # ??? johnson.pc vs johnsonpc4000.visit1 vs pc_4000
                # ??? johnson.tbi10000 vs johnson.tbiaware vs tbi_1000
                # ??? johnson.wrap140.visit1 vs wrap140.visit1 vs wrap140
                # NOT exists /Volumes/team-1/raw/carlson.esprit/mri
                # NOT exists /Volumes/team-1/raw/johnson.wrap140.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbiaware.visit3/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit2/mri
                # NOT exists /Volumes/team-1/raw/johnnson.alz.repsup.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.pc4000.visit1/mri
            v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
            @scan_procedures = ScanProcedure.where("id not in (?)",v_exclude_sp)
            @scan_procedures. each do |sp|
              v_visit_number =""
              if sp.codename.include?("visit2")
                v_visit_number ="_v2"
              elsif sp.codename.include?("visit3")
                v_visit_number ="_v3"
              elsif sp.codename.include?("visit4")
                v_visit_number ="_v4"
              elsif sp.codename.include?("visit5")
                v_visit_number ="_v5"
              end
               if no_mri_path_sp_list.include?(sp.codename)
                 v_mri = ""
                else
                  v_mri = "/mri"
                end
                v_raw_full_path = v_raw_path+"/"+sp.codename+v_mri
                v_preprocessed_full_path = v_preprocessed_path+sp.codename
                if File.directory?(v_raw_full_path)
                    if !File.directory?(v_preprocessed_full_path)
                        #puts "preprocessed path NOT exists "+v_preprocessed_full_path
                     end
                    Dir.entries(v_raw_full_path).select { |file| File.directory? File.join(v_raw_full_path, file)}.each do |dir|
                      dir_name_array = dir.split('_')
                      if dir_name_array.size == 3
                        v_secondary_key_array.each do |k|
                         v_secondary_key = k
                         #puts "dir="+dir_name_array[0]+" key="+k
                         enrollment = Enrollment.where("concat(enumber,'"+v_secondary_key+"') in (?)",dir_name_array[0])
                         if !enrollment.blank?
                             #puts "enrollment found"
                             v_comment =""
                             v_wlesion_030_flag ="N"
                             v_wlesion_030_flag_lst_116 ="N"
                             v_o_star_nii_flag ="N"
                             v_multiple_o_star_nii_flag ="N"
                             v_sag_cube_flair_flag ="N"
                             v_multiple_sag_cube_flair_flag ="N"
                             v_lst_lesion_value = ""
                             v_subjectid_unknown = v_preprocessed_full_path+"/"+dir_name_array[0]+"/unknown"
                             v_subjectid_lst_116 = v_preprocessed_full_path+"/"+dir_name_array[0]+"/LST/LST_116"
                             v_subjectid_lst_122 = v_preprocessed_full_path+"/"+dir_name_array[0]+"/LST/LST_122"
                             if File.directory?(v_subjectid_lst_116)
                                  v_dir_array = Dir.entries(v_subjectid_lst_116)   # need to get date for specific files
                                v_wlesion_030_flag_lst_116 ="N"
                                v_dir_array.each do |f|
                                  if f.start_with?("wlesion_030_m"+dir_name_array[0]+"_Sag-CUBE-FLAIR_") and f.end_with?("_cubet2flair.nii")
                                    v_wlesion_030_flag_lst_116 = "Y"
                                   end
                                end
                                v_comment = 'LST 116 dir ;'+v_comment
                             end 
                             
                             if File.directory?(v_subjectid_lst_122)
                                  v_dir_array = Dir.entries(v_subjectid_lst_122)   # need to get date for specific files
                                  v_wlesion_030_flag ="N"
                                  v_dir_array.each do |f|
                                    
                                    if ( f.start_with?("wlesion_lbm3_030_rm"+dir_name_array[0]+"_Sag-CUBE-FLAIR_") or f.start_with?("wlesion_lbm3_030_rm"+dir_name_array[0]+"_Sag-CUBE-flair_") ) and f.end_with?(".nii")
                                      v_wlesion_030_flag = "Y"
                                    end
                                    if f.start_with?("tlv_lesion") and f.end_with?(".txt")
                                       v_tmp_data = "" 
                                       v_tmp_data_array = []  
                                       ftxt = File.open(v_subjectid_lst_122+"/"+f, "r") 
                                       ftxt.each_line do |line|
                                          v_tmp_data += line
                                       end
                                       ftxt.close
                                       v_lst_lesion_value = v_tmp_data.strip
                                     
                                    elsif f.start_with?("tlv_b_") and f.include?("lesion") and f.end_with?(".txt")
                                       v_tmp_data = "" 
                                       v_tmp_data_array = []  
                                       ftxt = File.open(v_subjectid_lst_122+"/"+f, "r") 
                                       ftxt.each_line do |line|
                                          v_tmp_data += line
                                       end
                                       ftxt.close
                                       v_lst_lesion_value = v_tmp_data.strip
                                    end
                                  end
                                  v_comment = 'LST 122 dir ;'+v_comment
                             end
                            #puts "check for unknown "+v_subjectid_unknown
                             if File.directory?(v_subjectid_unknown)
                                  #puts "unknown found"
                                  v_dir_array = Dir.entries(v_subjectid_unknown)   # need to get date for specific files
                                  v_o_star_nii_flag ="N"
                                  v_multiple_o_star_nii_flag ="N"
                                  v_sag_cube_flair_flag ="N"
                                  v_sag_cube_flair_cnt = 0
                                  v_dir_array.each do |f|
                                    
                                    if (f.include? "Sag-CUBE-FLAIR" or f.include? "Sag-CUBE-flair"  or f.include?"Sag-CUBE-T2-FLAIR") and !f.include?"PU" and f.end_with?(".nii")
                                      v_sag_cube_flair_flag = "Y"
                                      v_sag_cube_flair_cnt = v_sag_cube_flair_cnt + 1
                                      if v_sag_cube_flair_cnt > 1
                                        v_multiple_sag_cube_flair_flag ="Y"
                                      end
                                    end
                                  end
                                  v_o_star_cnt = 0
                                  v_dir_array.each do |f|
                                    
                                    if f.start_with?("o") and f.end_with?(".nii")
                                      v_o_star_nii_flag = "Y"
                                      v_o_star_cnt = v_o_star_cnt+ 1
                                      if v_o_star_cnt > 1
                                        v_multiple_o_star_nii_flag ="Y"
                                      end
                                    end
                                  end
                             end
                                 
                                 
                             if v_wlesion_030_flag == "N" and v_wlesion_030_flag_lst_116 == "N"
                                   v_comment ="no LST_116 or LST_122 product ;" +v_comment                               
                             end # check for subjectid asl dir
                             sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','"+v_comment+"','"+v_wlesion_030_flag+"','"+v_o_star_nii_flag+"','"+v_multiple_o_star_nii_flag+"','"+v_sag_cube_flair_flag+"','"+v_multiple_sag_cube_flair_flag+"','"+v_wlesion_030_flag_lst_116+"',"+enrollment[0].id.to_s+","+sp.id.to_s+",'"+v_lst_lesion_value+"','"+v_secondary_key+"')"
                         #puts "insert="+dir_name_array[0]+v_visit_number     
                               results = connection.execute(sql)
                             
                         else
                           #puts "no enrollment "+dir_name_array[0]
                         end # check for enrollment
                       end # loop thru possible secondary key
                      end # check that dir name is in expected format [subjectid]_exam#_MMDDYY - just test size of array
                    end # loop thru the subjectids
                 else
                        #puts "               # NOT exists "+v_raw_full_path
                 end # check if raw dir exisits
            end            
            # check move cg_ to cg_old
            # v_shared = Shared.new 
             # move from new to present table -- made into a function  in shared model
            # puts "before mv from new to present"
             v_comment = self.move_present_to_old_new_to_present("cg_lst_116_status",
             "lst_subjectid, lst_general_comment,wlesion_030_flag, wlesion_030_comment, wlesion_030_global_quality,o_star_nii_flag,multiple_o_star_nii_flag,sag_cube_flair_flag,multiple_sag_cube_flair_flag,wlesion_030_flag_lst_116, wlesion_030_comment_lst_116, wlesion_030_global_quality_lst_116, enrollment_id,scan_procedure_id,lst_lesion,secondary_key",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)
            # puts "after mv from new to present"

             # apply edits  -- made into a function  in shared model
             self.apply_cg_edits('cg_lst_116_status')

             puts "successful finish lst_116_status "+v_comment[0..459]
              @schedulerun.comment =("successful finish lst_116_status "+v_comment[0..459])
              if !v_comment.include?("ERROR")
                 @schedulerun.status_flag ="Y"
               end
               @schedulerun.save
               @schedulerun.end_time = @schedulerun.updated_at      
               @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end
    
    
  end

 # to add columns --
  # change sql_base insert statement
  # change  sql = sql_base+  insert statement with values
  # change  self.move_present_to_old_new_to_present
  def run_lst_v3_status   # actually the new  lst_122 in column, and lst_116 in separate column
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('lst_v3_status')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting lst_v3_status"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_secondary_key_array =["","b","c","d","e",".R"]
    ####    begin   # catch all exception and put error in comment    
            sql = "truncate table cg_lst_v3_status_new"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)
            v_computer = "kanga"

            sql_base = "insert into cg_lst_v3_status_new(lst_subjectid, lst_general_comment,wlesion_030_flag,o_star_nii_flag,multiple_o_star_nii_flag,sag_cube_flair_flag,multiple_sag_cube_flair_flag,wlesion_030_flag_lst_v3,enrollment_id, scan_procedure_id,path,filename,lga,lst_lesion,n,secondary_key)values("  
            v_raw_path = v_base_path+"/raw"
            v_mri = "/mri"
            no_mri_path_sp_list =['asthana.adrc-clinical-core.visit1',
            'bendlin.mets.visit1','bendlin.tami.visit1','bendlin.wmad.visit1','carlson.sharp.visit1','carlson.sharp.visit2',
            'carlson.sharp.visit3','carlson.sharp.visit4','dempsey.plaque.visit1','dempsey.plaque.visit2','gleason.falls.visit1',
            'johnson.merit220.visit1','johnson.merit220.visit2','johnson.tbi.aware.visit3','johnson.tbi-va.visit1','ries.aware.visit1','wrap140']

            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            # get list of scan_procedure codename -- exclude 4, 10, 15, 19, 32, 
                # ??? johnson.pc vs johnsonpc4000.visit1 vs pc_4000
                # ??? johnson.tbi10000 vs johnson.tbiaware vs tbi_1000
                # ??? johnson.wrap140.visit1 vs wrap140.visit1 vs wrap140
                # NOT exists /Volumes/team-1/raw/carlson.esprit/mri
                # NOT exists /Volumes/team-1/raw/johnson.wrap140.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbiaware.visit3/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit2/mri
                # NOT exists /Volumes/team-1/raw/johnnson.alz.repsup.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.pc4000.visit1/mri
            v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
           @scan_procedures = ScanProcedure.where("id not in (?)",v_exclude_sp)
            @scan_procedures. each do |sp|
              v_visit_number =""
              if sp.codename.include?("visit2")
                v_visit_number ="_v2"
              elsif sp.codename.include?("visit3")
                v_visit_number ="_v3"
              elsif sp.codename.include?("visit4")
                v_visit_number ="_v4"
              elsif sp.codename.include?("visit5")
                v_visit_number ="_v5"
              end
               if no_mri_path_sp_list.include?(sp.codename)
                 v_mri = ""
                else
                  v_mri = "/mri"
                end
                v_raw_full_path = v_raw_path+"/"+sp.codename+v_mri
                v_preprocessed_full_path = v_preprocessed_path+sp.codename
                if File.directory?(v_raw_full_path)
                    if !File.directory?(v_preprocessed_full_path)
                        #puts "preprocessed path NOT exists "+v_preprocessed_full_path
                     end
                    Dir.entries(v_raw_full_path).select { |file| File.directory? File.join(v_raw_full_path, file)}.each do |dir|
                      dir_name_array = dir.split('_')
                      if dir_name_array.size == 3
                        v_secondary_key_array.each do |k|
                         v_secondary_key = k
                         #puts "dir="+dir_name_array[0]+" key="+k
                         enrollment = Enrollment.where("concat(enumber,'"+v_secondary_key+"') in (?)",dir_name_array[0])
                         if !enrollment.blank?
                             #puts "enrollment found"
                             v_comment =""
                             v_wlesion_030_flag ="N"
                             v_wlesion_030_flag_lst_v3 ="N"
                             v_o_star_nii_flag ="N"
                             v_multiple_o_star_nii_flag ="N"
                             v_sag_cube_flair_flag ="N"
                             v_multiple_sag_cube_flair_flag ="N"
                             v_lst_lesion_value = ""
                             v_lst_lesion_value_array = ['','','','','']
                             v_subjectid_unknown = v_preprocessed_full_path+"/"+dir_name_array[0]+"/unknown"
                             v_subjectid_lst_v3 = v_preprocessed_full_path+"/"+dir_name_array[0]+"/LST/pproc_v3"
                             #####v_subjectid_lst_122 = v_preprocessed_full_path+"/"+dir_name_array[0]+"/LST/LST_122"
       
                               if File.directory?(v_subjectid_lst_v3)
                                  v_dir_array = Dir.entries(v_subjectid_lst_v3)   # need to get date for specific files
                                  v_wlesion_030_flag ="N"
                                  v_dir_array.each do |f|
                                    if ( f.start_with?("wlesion_lbm3_030_rm"+dir_name_array[0]+"_Sag-CUBE-FLAIR_") or f.start_with?("wlesion_lbm3_030_rm"+dir_name_array[0]+"_Sag-CUBE-flair_") ) and f.end_with?(".nii")
                                      v_wlesion_030_flag = "Y"
                                    end
                                    if f.start_with?("LST_tlv_0.5") and f.end_with?(".csv")
                                       v_tmp_data = "" 
                                       v_tmp_data_array = []  
                                       ftxt = File.open(v_subjectid_lst_v3+"/"+f, "r") 
                                        v_cnt_tmp = 0
                                       ftxt.each_line do |line|
                                          if v_cnt_tmp == 1  # want 2nd line
                                            v_tmp_data = line   #
                                          end 
                                          v_cnt_tmp = v_cnt_tmp + 1
                                       end
                                       ftxt.close
                                       #Path,FileName,LGA,TLV,N
                                       v_lst_lesion_value = v_tmp_data.strip
                                       v_lst_lesion_value_array = v_lst_lesion_value.split(",")
                                     
                                    end
                                  end
                                  v_comment = 'LST v3 dir ;'+v_comment
                             end
                             
                            #puts "check for unknown "+v_subjectid_unknown
                             if File.directory?(v_subjectid_unknown)
                                  #puts "unknown found"
                                  v_dir_array = Dir.entries(v_subjectid_unknown)   # need to get date for specific files
                                  v_o_star_nii_flag ="N"
                                  v_multiple_o_star_nii_flag ="N"
                                  v_sag_cube_flair_flag ="N"
                                  v_sag_cube_flair_cnt = 0
                                  v_dir_array.each do |f|
                                    
                                    if (f.include? "Sag-CUBE-FLAIR" or f.include? "Sag-CUBE-flair"  or f.include?"Sag-CUBE-T2-FLAIR") and !f.include?"PU" and f.end_with?(".nii")
                                      v_sag_cube_flair_flag = "Y"
                                      v_sag_cube_flair_cnt = v_sag_cube_flair_cnt + 1
                                      if v_sag_cube_flair_cnt > 1
                                        v_multiple_sag_cube_flair_flag ="Y"
                                      end
                                    end
                                  end
                                  v_o_star_cnt = 0
                                  v_dir_array.each do |f|
                                    
                                    if f.start_with?("o") and f.end_with?(".nii")
                                      v_o_star_nii_flag = "Y"
                                      v_o_star_cnt = v_o_star_cnt+ 1
                                      if v_o_star_cnt > 1
                                        v_multiple_o_star_nii_flag ="Y"
                                      end
                                    end
                                  end
                             end
                                 
                                 
                             if v_wlesion_030_flag == "N" and v_wlesion_030_flag_lst_v3 == "N"
                                   v_comment ="no LST_v3 product ;" +v_comment                               
                             end # check for subjectid asl dir
                             sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','"+v_comment+"','"+v_wlesion_030_flag+"','"+v_o_star_nii_flag+"','"+v_multiple_o_star_nii_flag+"','"+v_sag_cube_flair_flag+"','"+v_multiple_sag_cube_flair_flag+"','"+v_wlesion_030_flag_lst_v3+"',"+enrollment[0].id.to_s+","+sp.id.to_s+",'"+v_lst_lesion_value_array[0]+"','"+v_lst_lesion_value_array[1]+"','"+v_lst_lesion_value_array[2]+"','"+v_lst_lesion_value_array[3]+"','"+v_lst_lesion_value_array[4]+"','"+v_secondary_key+"')"
                         #puts "insert="+dir_name_array[0]+v_visit_number     
                               results = connection.execute(sql)
                             
                         else
                           #puts "no enrollment "+dir_name_array[0]
                         end # check for enrollment
                       end # loop thru possible secondary key
                      end # check that dir name is in expected format [subjectid]_exam#_MMDDYY - just test size of array
                    end # loop thru the subjectids
                 else
                        #puts "               # NOT exists "+v_raw_full_path
                 end # check if raw dir exisits
            end            
            # check move cg_ to cg_old
            # v_shared = Shared.new 
             # move from new to present table -- made into a function  in shared model
            # puts "before mv from new to present"
             v_comment = self.move_present_to_old_new_to_present("cg_lst_v3_status",
             "lst_subjectid, lst_general_comment,wlesion_030_flag, wlesion_030_comment, wlesion_030_global_quality,o_star_nii_flag,multiple_o_star_nii_flag,sag_cube_flair_flag,multiple_sag_cube_flair_flag,wlesion_030_flag_lst_v3, wlesion_030_comment_lst_v3, wlesion_030_global_quality_lst_v3, enrollment_id,scan_procedure_id,path,filename,lga,lst_lesion,n,secondary_key",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)
            # puts "after mv from new to present"

             # apply edits  -- made into a function  in shared model
             self.apply_cg_edits('cg_lst_v3_status')

             puts "successful finish lst_v3_status "+v_comment[0..459]
              @schedulerun.comment =("successful finish lst_v3_status "+v_comment[0..459])
              if !v_comment.include?("ERROR")
                 @schedulerun.status_flag ="Y"
               end
               @schedulerun.save
               @schedulerun.end_time = @schedulerun.updated_at      
               @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end
    
    
  end

 
   def run_lst_v3_process
      v_process_name = "lst_v3_process"
      v_log_base ="/mounts/data/preprocessed/logs/"
      process_logs_delete_old( v_process_name, v_log_base)            
      v_base_path = Shared.get_base_path()
      @schedule = Schedule.where("name in ('lst_v3_process')").first
      v_runner_email = self.get_user_email()  #  want to send errors to the user running the process
      v_schedule_owner_email_array = []
      if !v_runner_email.blank?
        v_schedule_owner_email_array.push(v_runner_email)
      else
        v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
      end
      
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="lst_v3_process"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_computer = "kanga"
      v_error_comment = ""
      t = Time.now
      v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
      v_log_name =v_process_name+"_"+v_date_YM
      v_log_path =v_log_base+v_log_name 
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name  # use to stop the results loop  
      v_subjectid_v_num = ""              
      v_script_dev = v_base_path+"/data1/lab_scripts/LstProc/v3/lstproc.sh" #"/data1/lab_scripts/lstproc.sh"   #LST/LST.sh"
      v_script = v_base_path+"/data1/lab_scripts/LstProc/v3/lstproc.sh" # v_base_path+"/SysAdmin/production/LST/LST.sh"
      v_script  = v_script_dev   # using the dev script
      v_machine ="kanga"  # change to "+v_computer+" once set up
      #   v_script_only_tlv = v_script+" --only_tlv"  # running whole thing -- just use v_script in call
      (v_error_comment,v_comment) =get_file_diff(v_script,v_script_dev,v_error_comment,v_comment)
      v_comment_base = @schedulerun.comment
      connection = ActiveRecord::Base.connection();  

      # THIS IS THE MAIN RUN
      # do_not_run_process_wlesion_030 == Y means do not run
      # Jen's script deals with multiple sag cube flair
      #removing criteria and (multiple_sag_cube_flair_flag ='N' or (multiple_sag_cube_flair_flag ='Y' and sag_cube_flair_to_use is not null) )
      sql = "select distinct enrollment_id, scan_procedure_id, lst_subjectid,multiple_o_star_nii_flag,o_star_nii_file_to_use, multiple_sag_cube_flair_flag, sag_cube_flair_to_use from cg_lst_v3_status where if(do_not_run_process_wlesion_030 is NULL,'N',do_not_run_process_wlesion_030) != 'Y' and wlesion_030_flag = 'N' and o_star_nii_flag ='Y' and ( multiple_o_star_nii_flag = 'N' or (multiple_o_star_nii_flag = 'Y' and o_star_nii_file_to_use is not null)   ) and sag_cube_flair_flag = 'Y'  and (  lst_subjectid not like 'shp%') " #  or lst_subjectid like 'lead%' or  lst_subjectid like 'adrc%' or  lst_subjectid like 'pdt%'  or lst_subjectid like 'tami%'  or lst_subjectid like 'awr%'  or lst_subjectid like 'wmad%'  or lst_subjectid like 'plq%'  )"  #no acpcY, flairY fal, alz, tbi ;  problems 'shp%' 'pipr%' '
      results = connection.execute(sql)
      results.each do |r|
          v_break = 0  # need a kill swith
           v_log = ""
          if File.file?(v_stop_file_path)
            File.delete(v_stop_file_path)
            v_break = 1
            v_log = v_log + " STOPPING the results loop"
            v_comment = " STOPPING the results loop  "+v_comment
          end
          break if v_break > 0
            
          t_now = Time.now
          v_log = v_log + "starting "+r[2]+"   "+ t_now.strftime("%Y%m%d:%H:%M")+"\n"
          v_subjectid_v_num = r[2]
          v_subjectid = r[2].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
          # get location
          sql_loc = "select distinct v.path from visits v where v.appointment_id in (select a.id from appointments a, enrollment_vgroup_memberships evg, scan_procedures_vgroups spv where a.vgroup_id = evg.vgroup_id  and evg.enrollment_id = "+r[0].to_s+"  and a.vgroup_id = spv.vgroup_id and spv.scan_procedure_id = "+r[1].to_s+")"
          results_loc = connection.execute(sql_loc)
          v_o_star_nii_sp_loc = ""
          v_tlv_lesion_txt = "blank"
          results_loc.each do |loc|
            # could have 2 locations dual enrollment with 2 appointments - look for where o*.nii loc
            v_loc_path = loc[0]
            v_loc_path = v_loc_path.gsub(v_base_path+"/raw/","")
            v_loc_parts_array = v_loc_path.split("/")
            v_subjectid_unknown =v_base_path+"/preprocessed/visits/"+v_loc_parts_array[0]+"/"+v_subjectid+"/unknown"
            if File.directory?(v_subjectid_unknown)
                  v_dir_array = Dir.entries(v_subjectid_unknown)
                  v_dir_array.each do |f|
                    if f.start_with?("o") and f.end_with?(".nii")
                        v_o_star_nii_sp_loc = v_loc_parts_array[0]
                        v_log = v_log + "acpc file found \n"
                    end
                  end 
            end
            v_expected_tlv_file = v_base_path+"/preprocessed/visits/"+v_loc_parts_array[0]+"/"+v_subjectid+"/LST/pproc_v3"
            if File.directory?(v_expected_tlv_file)
                  v_dir_array = Dir.entries(v_expected_tlv_file)
                  v_dir_array.each do |f|
                    if  f.start_with?("LST_tlv_0.5")  and f.end_with?(".csv")
                        v_tlv_lesion_txt = "not blank"
                        v_log = v_log + "tlv_lesion file found \n"
                    end
                  end 
            end
          end

          
          if v_o_star_nii_sp_loc > "" and v_tlv_lesion_txt != "not blank"
              # call processing script- need to have LST toolbox on gru, "+v_computer+" or edna
              # v_call =  v_script+" -p "+v_o_star_nii_sp_loc+"  -b "+v_subjectid
              @schedulerun.comment ="str "+r[2]+"; "+v_comment[0..1990]
              @schedulerun.save
              v_multiple_o_star_nii_flag = r[3]
              v_o_star_nii_file_to_use = r[4]
              v_multiple_sag_cube_flair_flag = r[5]
              v_sag_cube_flair_to_use = r[6]
              # need to change script to accept v_o_star_nii_file_to_use and v_sag_cube_flair_to_use
              v_call =  'ssh panda_user@'+v_machine+'.dom.wisc.edu "'  +v_script+' -a -p '+v_o_star_nii_sp_loc+'  -b '+v_subjectid+' "  ' 
              puts "rrrrrrr "+v_call
              v_log = v_log + v_call+"\n"
              begin
                 stdin, stdout, stderr = Open3.popen3(v_call)
               rescue => msg  
                  v_log = v_log + msg+"\n"  
               end
              v_success ="N"
              while !stdout.eof?
                v_output = stdout.read 1024 
                v_log = v_log + v_output  
                if (v_log.tr("\n","")).include? "Done    'Thresholding of lesion probabilities'"  # line wrapping? Done ==> Do\nne
                  v_success ="Y"
                  v_log = v_log + "SUCCESS !!!!!!!!! \n"
                end
                puts v_output  
                puts "zzzzzzz test write"
               end
               v_err =""
               v_log = v_log +"IN ERROR \n"
               while !stderr.eof?
                  v_err = stderr.read 1024
                  v_log = v_log +v_err
                end
               puts "err="+v_err
               if v_success =="Y"
                 sql_update = "update cg_lst_v3_status set wlesion_030_flag = 'Y' where lst_subjectid = '"+r[2]+"'"
                 # results_update = connection.execute(sql_update)   # rerun wlesion... file detect
                 v_comment = " finished=>"+r[2]+ "; " +v_comment
               else
                puts " in err"
                v_log = v_log +"IN ERROR \n" 
                while !stderr.eof?
                  v_err = stderr.read 1024
                  v_log = v_log +v_err
                  v_comment = v_err +" =>"+r[2]+ " ; " +v_comment  
                 end 
                 v_error_comment = "error in "+r[2]+" ;"+v_error_comment
                 # send email to owner
                 v_schedule_owner_email_array.each do |e|
                   v_subject = "Error in "+v_process_name+": "+v_subjectid_v_num+ " see ==> "+v_log_path+" <== ALl the output from process is in the file."
                   PandaMailer.schedule_notice(v_subject,{:send_to => e}).deliver
                 end
               end
              @schedulerun.comment =v_comment[0..1990]
              @schedulerun.save
              stdin.close
              stdout.close
              stderr.close
           else
             v_log = v_log + "no acpc \n"

           end
           process_log_append(v_log_path, v_log)
      end       
    v_comment = v_error_comment+v_comment
    puts "successful finish lst_v3_process "+v_comment[0..459]
     @schedulerun.comment =("successful finish lst_v3_process "+v_comment[0..1959])
     if !v_comment.include?("ERROR")
        @schedulerun.status_flag ="Y"
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save
  end
 
    
  def run_lst_122_process
      v_process_name = "lst_122_process"
      v_log_base ="/mounts/data/preprocessed/logs/"
      process_logs_delete_old( v_process_name, v_log_base)            
      v_base_path = Shared.get_base_path()
      @schedule = Schedule.where("name in ('lst_122_process')").first
      v_runner_email = self.get_user_email()  #  want to send errors to the user running the process
      v_schedule_owner_email_array = []
      if !v_runner_email.blank?
        v_schedule_owner_email_array.push(v_runner_email)
      else
        v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
      end
      v_computer = "kanga"
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="lst_122_process"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_error_comment = ""
      t = Time.now
      v_date_YM = t.strftime("%Y%m") # just making monthly logs, prepend
      v_log_name =v_process_name+"_"+v_date_YM
      v_log_path =v_log_base+v_log_name 
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name  # use to stop the results loop  
      v_subjectid_v_num = ""              
      v_script_dev = v_base_path+"/data1/lab_scripts/LstProc/v2/lstproc.sh"   #LST/LST.sh"
      #v_script = v_base_path+"/SysAdmin/production/LST/LST.sh"
      v_script  = v_script_dev   # using the dev script
      v_script_only_tlv = v_script+" --only_tlv"  # running whole thing -- just use v_script in call
      (v_error_comment,v_comment) =get_file_diff(v_script,v_script_dev,v_error_comment,v_comment)
      v_comment_base = @schedulerun.comment
      connection = ActiveRecord::Base.connection();  
      #NORMALLY THIS IS NOT RUN  catchup on only_tlv - run everywhere except plq
      # Jen's script handles the multiple sag cube flair
      #removing criteria and (multiple_sag_cube_flair_flag ='N' or (multiple_sag_cube_flair_flag ='Y' and sag_cube_flair_to_use is not null) )
      sql = "select distinct enrollment_id, scan_procedure_id, lst_subjectid,multiple_o_star_nii_flag,o_star_nii_file_to_use, multiple_sag_cube_flair_flag, sag_cube_flair_to_use from cg_lst_116_status where lst_subjectid='DO NOT RUN THIS' and if(do_not_run_process_wlesion_030 is NULL,'N',do_not_run_process_wlesion_030) != 'Y'  and o_star_nii_flag ='Y' and ( multiple_o_star_nii_flag = 'N' or (multiple_o_star_nii_flag = 'Y' and o_star_nii_file_to_use is not null)   ) and sag_cube_flair_flag = 'Y'  and (  lst_subjectid not like 'shp%') and (  lst_subjectid not like 'plq%')  " #  or lst_subjectid like 'lead%' or  lst_subjectid like 'adrc%' or  lst_subjectid like 'pdt%'  or lst_subjectid like 'tami%'  or lst_subjectid like 'awr%'  or lst_subjectid like 'wmad%'  or lst_subjectid like 'plq%'  )"  #no acpcY, flairY fal, alz, tbi ;  problems 'shp%' 'pipr%' '
     
      results = connection.execute(sql)
      results.each do |r|
          v_break = 0  # need a kill swith
           v_log = ""
          if File.file?(v_stop_file_path)
            File.delete(v_stop_file_path)
            v_break = 1
            v_log = v_log + " STOPPING the results loop"
            v_comment = " STOPPING the results loop  "+v_comment
          end
          break if v_break > 0
            
          t_now = Time.now
          v_log = v_log + "starting only_tlv"+r[2]+"   "+ t_now.strftime("%Y%m%d:%H:%M")+"\n"
          v_subjectid_v_num = r[2]
          @schedulerun.comment = "start "+v_subjectid_v_num+" "+v_comment_base
           @schedulerun.save
          v_subjectid = r[2].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
          # get location
          sql_loc = "select distinct v.path from visits v where v.appointment_id in (select a.id from appointments a, enrollment_vgroup_memberships evg, scan_procedures_vgroups spv where a.vgroup_id = evg.vgroup_id  and evg.enrollment_id = "+r[0].to_s+"  and a.vgroup_id = spv.vgroup_id and spv.scan_procedure_id = "+r[1].to_s+")"
          results_loc = connection.execute(sql_loc)
          v_o_star_nii_sp_loc = ""
          v_tlv_lesion_txt = "blank"
          results_loc.each do |loc|
            # could have 2 locations dual enrollment with 2 appointments - look for where o*.nii loc
            v_loc_path = loc[0]
            v_loc_path = v_loc_path.gsub(v_base_path+"/raw/","")
            v_loc_parts_array = v_loc_path.split("/")
            v_subjectid_unknown =v_base_path+"/preprocessed/visits/"+v_loc_parts_array[0]+"/"+v_subjectid+"/unknown"
            if File.directory?(v_subjectid_unknown)
                  v_dir_array = Dir.entries(v_subjectid_unknown)
                  v_dir_array.each do |f|
                    if f.start_with?("o") and f.end_with?(".nii")
                        v_o_star_nii_sp_loc = v_loc_parts_array[0]
                        v_log = v_log + "acpc file found \n"
                    end
                  end 
            end
            v_expected_tlv_file = v_base_path+"/preprocessed/visits/"+v_loc_parts_array[0]+"/"+v_subjectid+"/LST/LST_122"
            if File.directory?(v_expected_tlv_file)
                  v_dir_array = Dir.entries(v_expected_tlv_file)
                  v_dir_array.each do |f|
                    if f.start_with?("tlv_lesion") and f.end_with?(".txt")
                        v_tlv_lesion_txt = "not blank"
                        v_log = v_log + "tlv_lesion file found \n"
                    end
                  end 
            end
          end
          # check for tlv file

          if v_o_star_nii_sp_loc > "" and v_tlv_lesion_txt != "not blank"
              # call processing script- need to have LST toolbox on gru, "+v_computer+" or edna
              # v_call =  v_script+" -p "+v_o_star_nii_sp_loc+"  -b "+v_subjectid
              @schedulerun.comment ="str "+r[2]+"; "+v_comment[0..1990]
              @schedulerun.save
              v_multiple_o_star_nii_flag = r[3]
              v_o_star_nii_file_to_use = r[4]
              v_multiple_sag_cube_flair_flag = r[5]
              v_sag_cube_flair_to_use = r[6]
              # need to change script to accept v_o_star_nii_file_to_use and v_sag_cube_flair_to_use
              v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "'  +v_script_only_tlv+' -p '+v_o_star_nii_sp_loc+'  -b '+v_subjectid+' "  ' 
              puts "rrrrrrr "+v_call
              v_log = v_log + v_call+"\n"
              begin
                 stdin, stdout, stderr = Open3.popen3(v_call)
               rescue => msg  
                  v_log = v_log + msg+"\n"  
               end
               v_err =""               
                while !stderr.eof?
                  v_err = stderr.read 1024
                  v_log = v_log +v_err
                  v_comment = v_err +" =>"+r[2]+ " ; " +v_comment  
                 end
              @schedulerun.comment =v_comment[0..1990]
              @schedulerun.save
              stdin.close
              stdout.close
              stderr.close
           else
             v_log = v_log + "no acpc \n"

           end
           process_log_append(v_log_path, v_log)
      end       
    v_comment = v_error_comment+v_comment
 
puts "DDD mainrun"
      # THIS IS THE MAIN RUN
      # do_not_run_process_wlesion_030 == Y means do not run
      # Jen's script tests for multiple sag cube flair 
      #removing criteria and (multiple_sag_cube_flair_flag ='N' or (multiple_sag_cube_flair_flag ='Y' and sag_cube_flair_to_use is not null) )
      sql = "select distinct enrollment_id, scan_procedure_id, lst_subjectid,multiple_o_star_nii_flag,o_star_nii_file_to_use, multiple_sag_cube_flair_flag, sag_cube_flair_to_use from cg_lst_116_status where if(do_not_run_process_wlesion_030 is NULL,'N',do_not_run_process_wlesion_030) != 'Y' and wlesion_030_flag = 'N' and o_star_nii_flag ='Y' and ( multiple_o_star_nii_flag = 'N' or (multiple_o_star_nii_flag = 'Y' and o_star_nii_file_to_use is not null)   ) and sag_cube_flair_flag = 'Y'  and (  lst_subjectid not like 'shp%')" #  or lst_subjectid like 'lead%' or  lst_subjectid like 'adrc%' or  lst_subjectid like 'pdt%'  or lst_subjectid like 'tami%'  or lst_subjectid like 'awr%'  or lst_subjectid like 'wmad%'  or lst_subjectid like 'plq%'  )"  #no acpcY, flairY fal, alz, tbi ;  problems 'shp%' 'pipr%' '
      results = connection.execute(sql)
      results.each do |r|
  puts "aaaaaa subjectid="+r[2]
          v_break = 0  # need a kill swith
           v_log = ""
          if File.file?(v_stop_file_path)
            File.delete(v_stop_file_path)
            v_break = 1
            v_log = v_log + " STOPPING the results loop"
            v_comment = " STOPPING the results loop  "+v_comment
          end
          break if v_break > 0
            
          t_now = Time.now
          v_log = v_log + "starting "+r[2]+"   "+ t_now.strftime("%Y%m%d:%H:%M")+"\n"
          v_subjectid_v_num = r[2]
          v_subjectid = r[2].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
          # get location
          sql_loc = "select distinct v.path from visits v where v.appointment_id in (select a.id from appointments a, enrollment_vgroup_memberships evg, scan_procedures_vgroups spv where a.vgroup_id = evg.vgroup_id  and evg.enrollment_id = "+r[0].to_s+"  and a.vgroup_id = spv.vgroup_id and spv.scan_procedure_id = "+r[1].to_s+")"
          results_loc = connection.execute(sql_loc)
          v_o_star_nii_sp_loc = ""
          v_tlv_lesion_txt = "blank"
          results_loc.each do |loc|
            # could have 2 locations dual enrollment with 2 appointments - look for where o*.nii loc
            v_loc_path = loc[0]
            v_loc_path = v_loc_path.gsub(v_base_path+"/raw/","")
            v_loc_parts_array = v_loc_path.split("/")
            v_subjectid_unknown =v_base_path+"/preprocessed/visits/"+v_loc_parts_array[0]+"/"+v_subjectid+"/unknown"
            if File.directory?(v_subjectid_unknown)
                  v_dir_array = Dir.entries(v_subjectid_unknown)
                  v_dir_array.each do |f|
                    if f.start_with?("o") and f.end_with?(".nii")
                        v_o_star_nii_sp_loc = v_loc_parts_array[0]
                        v_log = v_log + "acpc file found \n"
                    end
                  end 
            end
            v_expected_tlv_file = v_base_path+"/preprocessed/visits/"+v_loc_parts_array[0]+"/"+v_subjectid+"/LST/LST_122"
            if File.directory?(v_expected_tlv_file)
                  v_dir_array = Dir.entries(v_expected_tlv_file)
                  v_dir_array.each do |f|
                    if ( f.start_with?("tlv_lesion") or f.start_with?("tlv_b_000_lesion") ) and f.end_with?(".txt")
                        v_tlv_lesion_txt = "not blank"
                        v_log = v_log + "tlv_lesion file found \n"
                    end
                  end 
            end
          end
puts "AAAAAAA="+v_log 
          
          if v_o_star_nii_sp_loc > "" and v_tlv_lesion_txt != "not blank"
              # call processing script- need to have LST toolbox on gru, "+v_computer+" or edna
              # v_call =  v_script+" -p "+v_o_star_nii_sp_loc+"  -b "+v_subjectid
              @schedulerun.comment ="str "+r[2]+"; "+v_comment[0..1990]
              @schedulerun.save
              v_multiple_o_star_nii_flag = r[3]
              v_o_star_nii_file_to_use = r[4]
              v_multiple_sag_cube_flair_flag = r[5]
              v_sag_cube_flair_to_use = r[6]
              # need to change script to accept v_o_star_nii_file_to_use and v_sag_cube_flair_to_use
              v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "'  +v_script+' -p '+v_o_star_nii_sp_loc+'  -b '+v_subjectid+' "  ' 
              puts "rrrrrrr "+v_call
              v_log = v_log + v_call+"\n"
              begin
                 stdin, stdout, stderr = Open3.popen3(v_call)
               rescue => msg  
                  v_log = v_log + msg+"\n"  
               end
              v_success ="N"
              while !stdout.eof?
                v_output = stdout.read 1024 
                v_log = v_log + v_output  
                if (v_log.tr("\n","")).include? "Done    'PVE label estimation and lesion segmentation'"  # line wrapping? Done ==> Do\nne
                  v_success ="Y"
                  v_log = v_log + "SUCCESS !!!!!!!!! \n"
                end
                puts v_output  
               end
               v_err =""
               v_log = v_log +"IN ERROR \n"
               while !stderr.eof?
                  v_err = stderr.read 1024
                  v_log = v_log +v_err
                end
               puts "err="+v_err
               if v_success =="Y"
                 sql_update = "update cg_lst_116_status set wlesion_030_flag = 'Y' where lst_subjectid = '"+r[2]+"'"
                 # results_update = connection.execute(sql_update)   # rerun wlesion... file detect
                 v_comment = " finished=>"+r[2]+ "; " +v_comment
               else
                puts " in err"
                v_log = v_log +"IN ERROR \n" 
                while !stderr.eof?
                  v_err = stderr.read 1024
                  v_log = v_log +v_err
                  v_comment = v_err +" =>"+r[2]+ " ; " +v_comment  
                 end 
                 v_error_comment = "error in "+r[2]+" ;"+v_error_comment
                 # send email to owner
                 v_schedule_owner_email_array.each do |e|
                   v_subject = "Error in "+v_process_name+": "+v_subjectid_v_num+ " see ==> "+v_log_path+" <== ALl the output from process is in the file."
                   PandaMailer.schedule_notice(v_subject,{:send_to => e}).deliver
                 end
               end
              @schedulerun.comment =v_comment[0..1990]
              @schedulerun.save
              stdin.close
              stdout.close
              stderr.close
           else
             v_log = v_log + "no acpc \n"

           end
           process_log_append(v_log_path, v_log)
      end       
    v_comment = v_error_comment+v_comment
    puts "successful finish lst_122_process "+v_comment[0..459]
     @schedulerun.comment =("successful finish lst_122_process "+v_comment[0..1959])
     if !v_comment.include?("ERROR")
        @schedulerun.status_flag ="Y"
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save
  end

  # insert and update records in trtype_id = 5
  # walk preprocessed dirs, look for mcd dir and different files
  # make or update tredit traction_edits values
  # THIS WILL BREAK ON PLAQUE 
  def run_mcd_harvest
    v_base_path = Shared.get_base_path()
    @schedule = Schedule.where("name in ('mcd_harvest')").first
    @schedulerun = Schedulerun.new
    @schedulerun.schedule_id = @schedule.id
    @schedulerun.comment ="starting mcd_harvest"
    @schedulerun.save
    @schedulerun.start_time = @schedulerun.created_at
    @schedulerun.save
    v_comment = ""
    v_error_comment = ""
    v_target_dir = ""
    v_preprocessed_full_path = ""
    v_trtype_id = 5
    # expect tractiontype_id 10, 11,12,13,14,15 for load, mask, coreg, despot_1, despot_2, mcdespot
    connection = ActiveRecord::Base.connection(); 
    v_comment_base = @schedulerun.comment
    # walk dirs - scan_procedures 14,20,21,22,24,26,27,28,29,30,31,33,34,36,37,40,41,42,44,45,46 look for mcd dir - all sp with a mcd
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"
    sp_array = [14,20,21,22,24,26,27,28,29,30,31,33,34,36,37,40,41,42,44,45,46]
    @scan_procedures = ScanProcedure.where("scan_procedures.id in (?)", sp_array)
    @scan_procedures.each do |sp|
        @schedulerun.comment = "start "+sp.codename+" "+v_comment_base
        @schedulerun.save
        v_visit_number =""
        if sp.codename.include?("visit2")
            v_visit_number ="_v2"
        elsif sp.codename.include?("visit3")
            v_visit_number ="_v3"
        elsif sp.codename.include?("visit4")
            v_visit_number ="_v4"
        elsif sp.codename.include?("visit5")
            v_visit_number ="_v5"
        end   
        v_preprocessed_full_path = v_preprocessed_path+sp.codename  
        if File.directory?(v_preprocessed_full_path)
          sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups,  appointments, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+"  
                                    and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
          @results = connection.execute(sql_enum)
                                    
          @results.each do |r|
              v_change_flag = "N"
              v_edit_change_flag = "N"
              v_load_flag = 2 #"N"
              v_mask_flag = 2 #"N"
              v_coreg_flag = 2 #"N"
              v_despot_1_flag = 2 #"N"
              v_despot_2_flag = 2 #"N"
              v_mcdespot_flag = 2 #"N"
              v_error_in_log = 2 #"N"

              enrollment = Enrollment.where("enumber='"+r[0]+"'")
              if !enrollment.blank?
                v_subjectid_mcd_path = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/mcd"
                v_subjectid_v_num = enrollment[0].enumber + v_visit_number
                @schedulerun.comment = "start "+v_subjectid_v_num+" "+v_comment_base
                @schedulerun.save
                if File.directory?(v_subjectid_mcd_path)

                  if File.file?(v_subjectid_mcd_path+"/_mcdespot_log.txt")
                     if File.open(v_subjectid_mcd_path+"/_mcdespot_log.txt").each_line.any?{|line| line.include?('Error')}
                       v_error_in_log = "Y"
                       v_error_comment =  v_error_comment +"error in "+v_subjectid_mcd_path
                     end
                     if File.open(v_subjectid_mcd_path+"/_mcdespot_log.txt").each_line.any?{|line| line.include?('Loading Complete')}
                       v_load_flag = 1 # "Y"
                     end
                     if File.open(v_subjectid_mcd_path+"/_mcdespot_log.txt").each_line.any?{|line| line.include?('Masking/BET Complete')}
                       v_load_flag = 1
                       v_mask_flag = 1 # "Y"
                     end
                     if File.open(v_subjectid_mcd_path+"/_mcdespot_log.txt").each_line.any?{|line| line.include?('Coreg Complete')}
                       v_load_flag = 1
                       v_mask_flag = 1 # "Y"
                       v_coreg_flag = 1 # "Y"
                     end
                     if File.open(v_subjectid_mcd_path+"/_mcdespot_log.txt").each_line.any?{|line| line.include?('DESPOT1-HIFI Complete')}
                       v_load_flag = 1
                       v_mask_flag = 1 # "Y"
                       v_coreg_flag = 1 # "Y"
                       v_despot_1_flag =1 #  "Y"
                     end
                     if File.open(v_subjectid_mcd_path+"/_mcdespot_log.txt").each_line.any?{|line| line.include?('DESPOT2-FM Complete')}
                       v_load_flag = 1
                       v_mask_flag = 1 # "Y"
                       v_coreg_flag = 1 # "Y"
                       v_despot_1_flag =1 #  "Y"
                       v_despot_2_flag = 1 # "Y"
                     end
                     if File.open(v_subjectid_mcd_path+"/_mcdespot_log.txt").each_line.any?{|line| line.include?('Processing Run Complete')}
                       v_load_flag = 1
                       v_mask_flag = 1 # "Y"
                       v_coreg_flag = 1 # "Y"
                       v_despot_1_flag =1 #  "Y"
                       v_despot_2_flag = 1 # "Y"
                       v_mcdespot_flag = 1 # "Y"
                     end
                  end

                  
                  @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid_v_num)
                  if !@trfiles.nil? and !@trfiles[0].nil?
                       if v_error_in_log == "Y"
                            if @trfiles[0].qc_notes.nil? 
                                @trfiles[0].qc_notes = "Error in log "
                                v_change_flag = "Y"
                            elsif !(@trfiles[0].qc_notes).include?("Error in log") 
                                @trfiles[0].qc_notes = "Error in log "+@trfiles[0].qc_notes
                                v_change_flag = "Y"
                            end 
                       end
                      # get last edit
                      @tredits = Tredit.where("trfile_id in (?)",@trfiles[0].id).order("tredits.id desc")
                      v_tredit_id = @tredits[0].id
                      # the individual fields
                      # load = 10
                      #  mask = 11
                      v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                      if !v_tractiontypes.nil?
                         v_tractiontypes.each do |tat|
                              v_tredit_action = TreditAction.where("tredit_id in (?)",v_tredit_id).where("tractiontype_id in (?)", tat.id)
                              v_edit_change_flag = "N" 
                              if tat.id == 10 # load
                                 if  v_tredit_action[0].value != v_load_flag
                                     v_change_flag ="Y"
                                     v_edit_change_flag = "Y"
                                     v_tredit_action[0].value = v_load_flag
                                 end
                             elsif tat.id == 11 # mask
                                 if  v_tredit_action[0].value != v_mask_flag
                                     v_change_flag ="Y"
                                     v_edit_change_flag = "Y"
                                     v_tredit_action[0].value = v_mask_flag
                                 end
                             elsif tat.id == 12 # coreg
                                 if  v_tredit_action[0].value != v_coreg_flag
                                     v_change_flag ="Y"
                                     v_edit_change_flag = "Y"
                                     v_tredit_action[0].value = v_coreg_flag
                                 end
                             elsif tat.id == 13 # despot 1
                                 if  v_tredit_action[0].value != v_despot_1_flag
                                     v_change_flag ="Y"
                                     v_edit_change_flag = "Y"
                                     v_tredit_action[0].value = v_despot_1_flag
                                 end
                             elsif tat.id == 14 # despot 2
                                 if  v_tredit_action[0].value != v_despot_2_flag
                                     v_change_flag ="Y"
                                     v_edit_change_flag = "Y"
                                     v_tredit_action[0].value = v_despot_2_flag
                                 end
                             elsif tat.id == 15 # mcdespot
                                 if  v_tredit_action[0].value != v_mcdespot_flag
                                     v_change_flag ="Y"
                                     v_edit_change_flag = "Y"
                                     v_tredit_action[0].value = v_mcdespot_flag
                                 end
                             end
                             if v_edit_change_flag == "Y"
                                  v_tredit_action[0].save 
                             end
                          end
                       end
                       if v_change_flag == "Y"
                           v_datetime = DateTime.now
                           @tredits[0].updated_at = v_datetime.strftime('%Y-%m-%d %H:%M:%S')
                           @tredits[0].save
                           @trfiles[0].updated_at = v_datetime.strftime('%Y-%m-%d %H:%M:%S')
                           @trfiles[0].save

                        end
                       # tredit and trfile updated_at ????
                  else
                       # make a trfile, tredit, traction_edit record
                      @trfile = Trfile.new
                      @trfile.subjectid = v_subjectid_v_num
                      # @trfile.secondary_key = v_secondary_key
                      @trfile.enrollment_id = enrollment[0].id
                      @trfile.scan_procedure_id = sp.id
                      @trfile.trtype_id = v_trtype_id
                      if v_error_in_log == "Y"
                          @trfile.qc_notes = "Error in log "
                       end
                      @trfile.save
                      @tredit = Tredit.new
                      @tredit.trfile_id = @trfile.id
                      #@tredit.user_id = current_user.id
                      @tredit.save
            # make all the edit_actions for the tredit
                      v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                      if !v_tractiontypes.nil?
                         v_tractiontypes.each do |tat|
                             v_tredit_action = TreditAction.new
                             v_tredit_action.tredit_id = @tredit.id
                             v_tredit_action.tractiontype_id = tat.id
                             if !(tat.form_default_value).blank?
                                 v_tredit_action.value = tat.form_default_value
                             end
                             if tat.id == 10 # load
                                v_tredit_action.value = v_load_flag
                             elsif tat.id == 11 # mask
                                v_tredit_action.value = v_mask_flag
                             elsif tat.id == 12 # coreg
                                v_tredit_action.value = v_coreg_flag
                             elsif tat.id == 13 # despot 1
                                v_tredit_action.value = v_despot_1_flag
                             elsif tat.id == 14 # despot 2
                                v_tredit_action.value = v_despot_2_flag
                             elsif tat.id == 15 # mcdespot
                                v_tredit_action.value = v_mcdespot_flag
                             end
                             v_tredit_action.save
                           end
                        end

                  end
                end
              end
          end
        end
     end
     v_comment = v_error_comment+v_comment
     puts "successful finish mcd_harvest "+v_comment[0..459]
     @schedulerun.comment =("successful finish mcd_harvest "+v_comment[0..3959])
     if !v_comment.include?("ERROR")
        @schedulerun.status_flag ="Y"
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save
    


  end
  
  # to add columns --
  # change sql_base insert statement
  # change  sql = sql_base+  insert statement with values
  # change  self.move_present_to_old_new_to_present
  def run_pib_cereb_tac
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('pib_cereb_tac')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting pib_cereb_tac"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
    ####    begin   # catch all exception and put error in comment    
            sql = "truncate table cg_pib_cereb_tac_new"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)

            sql_base = "insert into cg_pib_cereb_tac_new(subjectid, general_comment,done_flag,status_flag,enrollment_id, scan_procedure_id, val_1,val_2,val_3,val_4,val_5,val_6,val_7,val_8,val_9,val_10,val_11,val_12,val_13,val_14,val_15,val_16,val_17)values("  


            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            # get list of scan_procedure codename -- exclude 4, 10, 15, 19, 32, 
                # ??? johnson.pc vs johnsonpc4000.visit1 vs pc_4000
                # ??? johnson.tbi10000 vs johnson.tbiaware vs tbi_1000
                # ??? johnson.wrap140.visit1 vs wrap140.visit1 vs wrap140
                # NOT exists /Volumes/team-1/raw/carlson.esprit/mri
                # NOT exists /Volumes/team-1/raw/johnson.wrap140.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbiaware.visit3/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit2/mri
                # NOT exists /Volumes/team-1/raw/johnnson.alz.repsup.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.pc4000.visit1/mri
            v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
            @scan_procedures = ScanProcedure.where("petscan_flag='Y' and id not in (?)",v_exclude_sp)  # NEED ONLY sp with pib, but filter later
            @scan_procedures. each do |sp|
               v_visit_number =""
               if sp.codename.include?("visit2")
                  v_visit_number ="_v2"
               elsif sp.codename.include?("visit3")
                  v_visit_number ="_v3"
               elsif sp.codename.include?("visit4")
                  v_visit_number ="_v4"
               elsif sp.codename.include?("visit5")
                  v_visit_number ="_v5"
               end

                v_preprocessed_full_path = v_preprocessed_path+sp.codename
                sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups, vgroups, appointments, petscans, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+" and  vgroups.transfer_pet = 'yes'  
                                    and appointments.vgroup_id = vgroups.id and appointments.appointment_type = 'pet_scan'
                                    and appointments.id = petscans.appointment_id and petscans.lookup_pettracer_id = 1
                                    and enrollment_vgroup_memberships.vgroup_id = vgroups.id and enrollment_vgroup_memberships.enrollment_id = enrollments.id
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
                 @results = connection.execute(sql_enum)
                                    
                 @results.each do |r|
                     enrollment = Enrollment.where("enumber='"+r[0]+"'")
                     if !enrollment.blank?
                        v_subjectid_pib = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/pet/pib"
                        if File.directory?(v_subjectid_pib)
                            v_dir_array = Dir.entries(v_subjectid_pib)   # need to get date for specific files
                            v_done_flag ="N"
                            v_status_flag = "N"
                            v_comment =""
                            v_val_arr =["","","","","","","","","","","","","","","","",""] 
                            v_dir_array.each do |f|
                              
                               if f.start_with?(enrollment[0].enumber+v_visit_number) and f.end_with?("_cereb_TAC_HYPR.txt")
                                  v_status_flag = "Y"
                                  v_file_path = v_subjectid_pib+"/"+enrollment[0].enumber+v_visit_number+"_cereb_TAC_HYPR.txt"
                                  # get file and harvest values
                                  v_cnt = 0
                                  if File.size(v_file_path) > 0
                                      File.open(v_file_path, "r").each_line do |line|
                                        v_val_arr[v_cnt] = line.gsub("\n","").gsub("\r","")
                                        v_cnt = v_cnt + 1
                                      end
                                   else
                                     v_comment ="empty "+enrollment[0].enumber+v_visit_number+"_cereb_TAC_HYPR.txt file"
                                   end
                                elsif f.start_with?(enrollment[0].enumber) and f.end_with?("_cereb_TAC_HYPR.txt")
                                    v_status_flag = "Y"
                                    v_file_path = v_subjectid_pib+"/"+enrollment[0].enumber+"_cereb_TAC_HYPR.txt"
                                    # get file and harvest values
                                    v_cnt = 0
                                    if File.size(v_file_path) > 0
                                      File.open(v_file_path, "r").each_line do |line|
                                        v_val_arr[v_cnt] = line.gsub("\n","").gsub("\r","")
                                        v_cnt = v_cnt + 1
                                      end
                                    else
                                      v_comment ="empty "+enrollment[0].enumber+"_cereb_TAC_HYPR.txt file"
                                    end
                                end
                              end
                                
                             sql = sql_base+"'"+enrollment[0].enumber+v_visit_number+"','"+v_comment+"','"+v_done_flag+"','"+v_status_flag+"',"+enrollment[0].id.to_s+","+sp.id.to_s+",'"+v_val_arr[0]+"','"+v_val_arr[1]+"','"+v_val_arr[2]+"','"+v_val_arr[3]+"','"+v_val_arr[4]+"','"+v_val_arr[5]+"','"+v_val_arr[6]+"','"+v_val_arr[7]+"','"+v_val_arr[8]+"','"+v_val_arr[9]+"','"+v_val_arr[10]+"','"+v_val_arr[11]+"','"+v_val_arr[12]+"','"+v_val_arr[13]+"','"+v_val_arr[14]+"','"+v_val_arr[15]+"','"+v_val_arr[16]+"')"
                                 results = connection.execute(sql)
                             else
                                 sql = sql_base+"'"+enrollment[0].enumber+v_visit_number+"','no pib dir','N','N',"+enrollment[0].id.to_s+","+sp.id.to_s+",NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)"
                                 results = connection.execute(sql)
                             end # check for subjectid asl dir
                      else
                           #puts "no enrollment "+dir_name_array[0]
                      end # check for enrollment
                 end # loop thru the subjectids
            end            
            # check move cg_ to cg_old
            # v_shared = Shared.new 
             # move from new to present table -- made into a function  in shared model
             v_comment = self.move_present_to_old_new_to_present("cg_pib_cereb_tac",
             "subjectid, general_comment,done_flag,status_flag, status_comment, val_1,val_2,val_3,val_4,val_5,val_6,val_7,val_8,val_9,val_10,val_11,val_12,val_13,val_14,val_15,val_16,val_17, enrollment_id,scan_procedure_id",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)


             # apply edits  -- made into a function  in shared model
             self.apply_cg_edits('cg_pib_cereb_tac')

             puts "successful finish cg_pib_cereb_tac "+v_comment[0..459]
              @schedulerun.comment =("successful finish cg_pib_cereb_tac "+v_comment[0..459])
              if !v_comment.include?("ERROR")
                 @schedulerun.status_flag ="Y"
               end
               @schedulerun.save
               @schedulerun.end_time = @schedulerun.updated_at      
               @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end
    
    
  end
  
  def run_pet_path
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('pet_path')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting pet_path"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      
      sql = "select distinct  petscans.id, petscans.appointment_id, petscans.ecatfilename, appointments.vgroup_id , petscans.lookup_pettracer_id
        from petscans, appointments where (petscans.path is null or petscans.path ='') and petscans.ecatfilename is not null and petscans.lookup_pettracer_id is not null
        and appointments.id = petscans.appointment_id "
      connection = ActiveRecord::Base.connection();        
      results = connection.execute(sql)
      v_cnt = 0
      results.each do |r|

        # get sp 
        sql_sp = "select distinct scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id ="+r[3].to_s 
        # could limit by scan_procedures.petscan_flag, but don't trust its being populated
        results_sp = connection.execute(sql_sp)   
        results_sp.each do |r_sp|
            # pass to function so can use in petscan edit
            v_petscan = Petscan.find(r[0])
  puts "aaaaaa petscan_id = "+r[0].to_s
            v_return_path = ""     
            # GET SINGLE petscan file -- old version , still running
            v_return_path = v_petscan.get_pet_path(r_sp[0], r[2], r[4])  # pass in sp, file name, tracerid
            if v_return_path > ""
              v_petscan.path = v_return_path
              v_petscan.save
              v_cnt = v_cnt + 1
            end
        end
      end
            sql = "select distinct  petscans.id, petscans.appointment_id, petscans.ecatfilename, appointments.vgroup_id , petscans.lookup_pettracer_id
        from petscans, appointments where petscans.id in ( select petfiles.petscan_id  from petfiles where (petfiles.path is null or petfiles.path  = '') and petfiles.file_name is not null)
            and petscans.lookup_pettracer_id is not null
        and appointments.id = petscans.appointment_id "
      connection = ActiveRecord::Base.connection();        
      results = connection.execute(sql)
      v_cnt = 0
      results.each do |r|

        # get sp 
        sql_sp = "select distinct scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id ="+r[3].to_s 
        # could limit by scan_procedures.petscan_flag, but don't trust its being populated
        results_sp = connection.execute(sql_sp)   
        results_sp.each do |r_sp|
            # pass to function so can use in petscan edit
            v_petscan = Petscan.find(r[0])
  puts "bbb petscan_id = "+r[0].to_s
            ## petfiles - multiples , new version
            v_petfiles = Petfile.where("petfiles.petscan_id in (?) ",v_petscan.id)
            v_petfiles.each do |pf|  # make sure not already in database with this petscan.id
                            v_path = v_petscan.get_pet_path(r_sp[0], pf.file_name, v_petscan.lookup_pettracer_id)
                            if pf.path.blank? and !v_path.blank?
                                       pf.path = v_path
                                       pf.save
                            end
              end
        end
      end
      # get pet PATHSSSSSSS

      
      v_comment = " petscan paths update ="+v_cnt.to_s+"  "+v_comment
      @schedulerun.comment =("successful finish pet_path "+v_comment[0..459])
      if !v_comment.include?("ERROR")
         @schedulerun.status_flag ="Y"
       end
       @schedulerun.save
       @schedulerun.end_time = @schedulerun.updated_at      
       @schedulerun.save
    
  end
 #makes preprocessed/visits/<sp>/<subjectid>/pet/<tracer>/ csv and json or petscan data
  def run_pet_preprocessed_data
         v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('pet_preprocessed_data')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting pet_preprocessed_data"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save

          v_comment = ""
          v_cnt = 0
          v_month_back = "100" # going all the way back - later change back to 1 month 
          # add option for full and partial re-write
          v_preprocessed_visits_base =  v_base_path+"/preprocessed/visits/"
          v_raw_base = v_base_path+"/raw/"
          v_computer = "kanga"
          # tracer_id - dir name
          v_tracer_id_exclude_array = [1,2,3,5,6,7,8,9,10] #[5] # excluding pbr 

         connection = ActiveRecord::Base.connection();
          @lookup_pettracers = LookupPettracer.where("lookup_pettracers.id not in (?)",v_tracer_id_exclude_array)
          @lookup_pettracers.each do |tracer|
              v_tracer_name = (tracer.name).downcase
              # loop thru each tracer  === lower case
              # get all the pet appts with that tracer -- mimic the pet_search query
              # get raw path, infer sp, infer subjectid
              # check for pet dir/mk pet dir
              # check for tracer dir/mk tracer dir
              # make csv
              # make json
            @conditions = []
            v_petfile_conditions = [] # need to find max number of petfiles - some have 1, some 2 , etc, for this mix of scan procedures
            condition ="  petscans.lookup_pettracer_id in ("+(tracer.id).to_s+" )"
            @conditions.push(condition)
            v_petfile_conditions.push(condition)
            condition = "appointments.appointment_date > (DATE_SUB(NOW(), INTERVAL "+v_month_back+" MONTH))"
            @conditions.push(condition)
           # v_petfile_conditions.push(condition)
            condition = "appointments.appointment_type = 'pet_scan' "
            @conditions.push(condition)
           # condition = "appointments.vgroup_id = 8360 "
           # @conditions.push(condition)

            v_petfile_conditions.push("petscans.id = petfiles.petscan_id")
            sql_petfile_cnt = "select max(cnt) from 
                  (select    count(petfiles.id) cnt, petscans.id from petfiles, petscans where "+v_petfile_conditions.join(" and ")+ " group by petscans.id) t2"
            results_petfile_cnt= connection.execute(sql_petfile_cnt) 
            @v_petfile_cnt = 0
            @v_petfile_cnt = results_petfile_cnt.first[0]   # ,'Injection_scan_start_diff'
            @column_headers = ['Date','Protocol','Enumber','RMR','Tracer','Dose','Injection Time','Scan Start','Inj-Scan Strt Diff','Note','Acquisition Duration','Pet status','Pre_BP Systol','Pre_BP Diastol','Pre_Pulse','Blood Glucose','Weight','Height','Post_BP Systol','Post_BP Diastol','Post_Pulse','Age at Appt','Appt Note'] # need to look up values
          
            if !@v_petfile_cnt.nil?
              i = @v_petfile_cnt
              k = 1
              while i > 0
                @column_headers.push("Pet_file_"+k.to_s)
                @column_headers.push("Pet_path_"+k.to_s)
                @column_headers.push("Pet_note_"+k.to_s)
                k = k + 1
                i = i -1
              end
            end
            @column_number =   @column_headers.size
            @fields =["lookup_pettracers.name pettracer","petscans.netinjecteddose",
                    "time_format(timediff( time(petscans.injecttiontime),subtime(utc_time(),time(localtime()))),'%H:%i')",
                    "time_format(timediff( time(scanstarttime),subtime(utc_time(),time(localtime()))),'%H:%i')",
                      "ROUND(TIME_TO_SEC(TIMEDIFF(petscans.scanstarttime,petscans.injecttiontime)))/60",
                    "petscans.petscan_note","petscans.range","vgroups.transfer_pet","vitals.bp_systol","vitals.bp_diastol","vitals.pulse","vitals.bloodglucose","vitals.weight","vitals.height","vitals_post.bp_systol as bp_systol_post","vitals_post.bp_diastol as bp_diastol_post","vitals_post.pulse as pulse_post","appointments.age_at_appointment","petscans.id","appointments.comment"] # vgroups.id vgroup_id always first, include table name 
            @left_join = ["LEFT JOIN lookup_pettracers on petscans.lookup_pettracer_id = lookup_pettracers.id",
                        "LEFT JOIN vitals on petscans.appointment_id = vitals.appointment_id and vitals.pre_post_flag ='pre' ",
                        "LEFT JOIN vitals as vitals_post on petscans.appointment_id = vitals_post.appointment_id and vitals_post.pre_post_flag ='post'  "]
            
            @tables =['petscans'] # trigger joins --- vgroups and appointments by default
            @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]

            # how to call controller function from in another model?
            @results = self.run_search_pet

           @csv_array = []
           @results_tmp_csv = []
           @results.each do |result| 
              v_sp_codename = ""
              v_enumber = ""
              @results_tmp_csv = []
              for i in 0..@column_number-1  # results is an array of arrays%>
    #puts "colum = "+@column_headers[i]
                 if @column_headers[i] == "Pet_path_1"
                      # get scan procedure
                      v_file_path =result[i]
                      if !v_file_path.nil?
                         v_file = v_file_path.gsub(v_raw_base,"")
                         v_file_path_array = v_file.split("/")
                         v_sp_codename = v_file_path_array[0]
                      end
                 end
                 if @column_headers[i] == "Pet_file_1"
                      # get scan procedure
                      v_file_name =result[i]
                      if !v_file_name.nil?
                         
                         v_file_name_array = v_file_name.split("_")
                         v_enumber = v_file_name_array[0]
                      end
                 end
                 @results_tmp_csv.push(result[i])
              end 
              if v_sp_codename > "" and v_enumber > ""
                   # check if is a sp 
                   @scan_procedures = ScanProcedure.where("codename in (?)",v_sp_codename)
                   @enumbers = Enrollment.where("enumber in (?)",v_enumber)
                   if !@scan_procedures.nil? and !@enumbers.nil? and @scan_procedures.count > 0 and @enumbers.count > 0
                       v_pet_enumber_path = v_preprocessed_visits_base+v_sp_codename+"/"+v_enumber
                       v_exists = "N"
                       v_exists_pet = "N"
                       v_exists_tracer = "N"
                       Dir.glob(v_pet_enumber_path).each do|f|
                          v_exists = "Y"
                       end
                       if v_exists == "N" 
                          v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_pet_enumber_path+" ' "
                          puts v_call
                          stdin, stdout, stderr = Open3.popen3(v_call)
                          while !stdout.eof?
                              puts stdout.read 1024    
                          end
                          stdin.close
                          stdout.close
                          stderr.close
            
                          v_exists = "Y"
                       end
                       if v_exists == "Y"
                          Dir.glob(v_pet_enumber_path+"/pet").each do|fp|
                              v_exists_pet = "Y"
                          end
                          if v_exists_pet == "N" 
                               v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_pet_enumber_path+"/pet' "
                               puts v_call
                               stdin, stdout, stderr = Open3.popen3(v_call)
                               while !stdout.eof?
                                   puts stdout.read 1024    
                               end
                               stdin.close
                               stdout.close
                               stderr.close
                               v_exists_pet = "Y"
                          end
                          if v_exists_pet == "Y"
                              Dir.glob(v_pet_enumber_path+"/pet"+v_tracer_name).each do|fp|
                              v_exists_tracer = "Y"
                          end
                          if v_exists_tracer == "N" 
                               v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_pet_enumber_path+"/pet/"+v_tracer_name+"' "
                               puts v_call
                               stdin, stdout, stderr = Open3.popen3(v_call)
                               while !stdout.eof?
                                   puts stdout.read 1024    
                               end
                               stdin.close
                               stdout.close
                               stderr.close
                               v_exists_tracer = "Y"
                          end
                       end

                      end 
                      if v_exists_tracer == "Y"
                        # make file
        puts v_pet_data_csv 

                        v_pet_data_csv = v_pet_enumber_path+"/pet/"+v_tracer_name+"/"+v_enumber+"_"+v_tracer_name+"_"+v_sp_codename.gsub(".","_")+"_pet_data.csv"
                        File.open(v_pet_data_csv, "w+") do |fcsv| 
                             fcsv.write("variable_name,value\n") 
                             v_cnt = 0
                             @results_tmp_csv.each do |rc| 
                                  fcsv.write(@column_headers[v_cnt]+","+rc.to_s+"\n")
                               v_cnt = v_cnt + 1
                             end
                        end
                        v_pet_data_json = v_pet_enumber_path+"/pet/"+v_tracer_name+"/pet_data.json"

                      end
                     
                   end # has sp and enumber

              end
              @csv_array.push(@results_tmp_csv)
            end 


          end

      @schedulerun.comment =("successful finish pet_preprocessed_data "+v_comment[0..459])
      if !v_comment.include?("ERROR")
         @schedulerun.status_flag ="Y"
       end
       @schedulerun.save
       @schedulerun.end_time = @schedulerun.updated_at      
       @schedulerun.save
  end
  def run_search_pet  # need to add the petfiles - file_name, path and note
    # taken from application controller -- not sure how to call from shared model
    @html_request ="N"

  if @tables.size == 1  or @tables.include?("image_datasets")
    # moved ,appointments.comment  to be in field list
       sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date,  vgroups.rmr , "+@fields.join(',')+" 
        FROM vgroups, appointments,scan_procedures, scan_procedures_vgroups, "+@tables.join(',')+" "+@left_join.join(' ')+"
        WHERE vgroups.id = appointments.vgroup_id "
        @tables.each do |tab|
          if tab == "image_datasets"
            sql = sql +" AND "+tab+".visit_id = visits.id  "
          else
            sql = sql +" AND "+tab+".appointment_id = appointments.id  "
          end
        end
        sql = sql +" AND scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
        AND scan_procedures_vgroups.vgroup_id = vgroups.id "

        if @conditions.size > 0
            sql = sql +" AND "+@conditions.join(' and ')
        end
       #conditions - feed thru ActiveRecord? stop sql injection -- replace : ; " ' ( ) = < > - others?
        if @order_by.size > 0
          sql = sql +" ORDER BY "+@order_by.join(',')
        end 
   end

puts sql    
    connection = ActiveRecord::Base.connection();
    @results2 = connection.execute(sql)
    @temp_results = @results2

    @results = []   
    i =0
    @temp_results.each do |var|
      @temp = []
      # TRY TUNING BY GETTING ALL RELEVANT sp , enum , put in hash, with vgroup_id as key
      # take each var --- get vgroup_id => find vgroup
      # get scan procedure(s) -- make string, put in @results[0]
      # vgroup.rmr --- put in @results[1]
      # get enumber(s) -- make string, put in @results[2]
      # put the rest of var - minus vgroup_id, into @results
      # SLOWER THAN sql  -- 9915 msec vs 3193 msec
      #vgroup = Vgroup.find(var[0])
      #@temp[0]=vgroup.scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ")
      #@temp[1]=vgroup.enrollments.collect {|e| e.enumber }.join(", ")
      # change to scan_procedures.id and enrollments.id  or vgroup_id to make links-- maybe keep vgroup_id for display
      @temp[0] = var[1] # want appt date first
      if @html_request =="N"
          sql_sp = "SELECT distinct scan_procedures.codename 
                FROM scan_procedures, scan_procedures_vgroups
                WHERE scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
                AND scan_procedures_vgroups.vgroup_id = "+var[0].to_s
          @results_sp = connection.execute(sql_sp)
          @temp[1] =@results_sp.to_a.join(", ")

          sql_enum = "SELECT distinct enrollments.enumber 
                FROM enrollments, enrollment_vgroup_memberships
                WHERE enrollments.id = enrollment_vgroup_memberships.enrollment_id
                AND enrollment_vgroup_memberships.vgroup_id = "+var[0].to_s
          @results_enum = connection.execute(sql_enum)
          @temp[2] =@results_enum.to_a.join(", ")
          
      else  # need to only get the sp and enums which are displayed - and need object to make link
        @temp[1] = var[0].to_s
        @temp[2] = var[0].to_s
      end 
      var.delete_at(0) # get rid of vgroup_id
      var.delete_at(0) # get rid of extra copy of appt date 

      
      #moving petscan_id to front
      v_length = var.length
      v_petscan_id = var[v_length-2]
      if @html_request =="Y"
          @temp.unshift(v_petscan_id)
      end
      var.delete_at(v_length-2)
      #if @html_request =="N"
         #var.delete_at(0) # seems to need to delete another blank field?
      #end
      v_petfiles = Petfile.where("petscan_id in (?)", v_petscan_id)
      v_petfiles.each do |pf|
         var.push(pf.file_name)
         var.push(pf.path)
         var.push(pf.note)
      end 
      
      @temp_row = @temp + var  

      @results[i] = @temp_row
      i = i+1
    end   
  @v_petfile_cnt.to_s
    return @results
 end

  def run_pcvipr_recon_and_gating_check
         v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('pcvipr_recon_and_gating_check')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting pcvipr_recon_and_gating_check"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_comment_error = ""
          v_process_name = 'pcvipr_recon_and_gating_check'
          v_cnt = 0
          v_month_back = "2" #"100" # going all the way back - later change back to 1 month 
          v_pcvipr_recon_base =  v_base_path+"/analyses/PCVIPR/4DFLOW_DATA/"
          v_computer = "kanga"
          v_runner_email = "" #####self.get_user_email()  #  want to send errors to the user running the process
          v_schedule_owner_email_array = []
          if !v_runner_email.blank?
            v_schedule_owner_email_array.push(v_runner_email)
          else
            v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
          end
          

          v_pcvipr_values_tn = "cg_pcvipr_values"
          v_trtype_id = 2  # pcvipr
          v_scan_procedure_id_exclude_array = [81,33,40,49,21,28,31,34] # barnes bbf , and dempsey plaque and 4 shps  # doing the mbe75
      # exclude list of sp's - e.g. barnes.bbf
      #check for pvvipr in month back which are not in v_pcvipr_values_tn
      # get spS ( could be multiples) and enumberS ( could be multiples)
      # use raw path to pick sp and enum to use
      # check in sp/sp.done sp/sp.orig -if any match found - stop
      # if no match found and no sp found
      # make sp, sp.orig, sp.done
      # if no match found, sp found, but no sp.orig - make sp.orig, make dir _v#
      # if no match found but sp found - make dir /_v# in .orig
      # copy over pcvipr, pcvipr_summary and gating files
      # unbzip pfile
      # run pcvipr recon
      # check log/outoput files
      # email if problem
      # run gating_check
      # check log/output files
      # email if problem
      # rm pfile
      #            and appointments.vgroup_id in (8284)
            # LIMIT FOR TESTING and appointments.vgroup_id in (2875,8174)
          v_ids_array = ImageDataset.where("image_datasets.visit_id in 
            (select visits.id from visits, appointments,image_datasets  where visits.appointment_id = appointments.id and appointments.appointment_date > (DATE_SUB(NOW(), INTERVAL "+v_month_back+" MONTH)) 
            and visits.id = image_datasets.visit_id
            and appointments.appointment_type = 'mri'
            and appointments.vgroup_id not in (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups where 
                       scan_procedures_vgroups.scan_procedure_id in (?)    )
            and image_datasets.series_description in (select series_description_maps.series_description from series_description_maps where series_description_maps.series_description_type_id in (15))
            and image_datasets.visit_id not in ( select v.id from cg_pcvipr_values, visits v, appointments a, scan_procedures_vgroups spvg, 
                            enrollment_vgroup_memberships evgm  where cg_pcvipr_values.enrollment_id = evgm.enrollment_id
                            and a.vgroup_id = evgm.vgroup_id and spvg.scan_procedure_id = cg_pcvipr_values.scan_procedure_id
                            and v.appointment_id = a.id and a.vgroup_id = evgm.vgroup_id and a.vgroup_id = spvg.vgroup_id)
            and image_datasets.series_description in (select series_description_maps.series_description from series_description_maps where series_description_maps.series_description_type_id in (15)) 
            and image_datasets.series_description is not null)", v_scan_procedure_id_exclude_array)

          #same as above but with limited list
 #          v_ids_array = ImageDataset.where("image_datasets.visit_id in 
 #           (select visits.id from visits, appointments,image_datasets, scan_procedures_vgroups, enrollments, enrollment_vgroup_memberships
 #                   where visits.appointment_id = appointments.id and appointments.appointment_date > (DATE_SUB(NOW(), INTERVAL "+v_month_back+" MONTH)) 
 #           and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
 #           and enrollment_vgroup_memberships.enrollment_id = enrollments.id
 #           and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
 #           and ( (scan_procedures_vgroups.scan_procedure_id = 22 and enrollments.enumber in (enumlist))
 #     or
 #      (scan_procedures_vgroups.scan_procedure_id = 65 and enrollments.enumber in (enumlist))
#)
#            and visits.id = image_datasets.visit_id
#            and appointments.appointment_type = 'mri'
#            and appointments.vgroup_id not in (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups where 
#                       scan_procedures_vgroups.scan_procedure_id in (?)    )
#            and image_datasets.series_description in (select series_description_maps.series_description from series_description_maps where series_description_maps.series_description_type_id in (15))
#            and image_datasets.visit_id not in ( select v.id from cg_pcvipr_values, visits v, appointments a, scan_procedures_vgroups spvg, 
#                            enrollment_vgroup_memberships evgm  where cg_pcvipr_values.enrollment_id = evgm.enrollment_id
#                            and a.vgroup_id = evgm.vgroup_id and spvg.scan_procedure_id = cg_pcvipr_values.scan_procedure_id
#                            and v.appointment_id = a.id and a.vgroup_id = evgm.vgroup_id and a.vgroup_id = spvg.vgroup_id)
#            and image_datasets.series_description in (select series_description_maps.series_description from series_description_maps where series_description_maps.series_description_type_id in (15)) 
#            and image_datasets.series_description is not null)", v_scan_procedure_id_exclude_array)

          #same as above but with limited to 2 sp's
   #       v_ids_array = ImageDataset.where("image_datasets.visit_id in 
   #         (select visits.id from visits, appointments,image_datasets, scan_procedures_vgroups
   #                 where visits.appointment_id = appointments.id and appointments.appointment_date > (DATE_SUB(NOW(), INTERVAL "+v_month_back+" MONTH)) 
   #         and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
   #         and  (scan_procedures_vgroups.scan_procedure_id in (46,60))
   #         and visits.id = image_datasets.visit_id
   #         and appointments.appointment_type = 'mri'
   #         and appointments.vgroup_id not in (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups where 
   #                    scan_procedures_vgroups.scan_procedure_id in (?)    )
   #         and image_datasets.series_description in (select series_description_maps.series_description from series_description_maps where series_description_maps.series_description_type_id in (15))
   #         and image_datasets.visit_id not in ( select v.id from cg_pcvipr_values, visits v, appointments a, scan_procedures_vgroups spvg, 
   #                         enrollment_vgroup_memberships evgm  where cg_pcvipr_values.enrollment_id = evgm.enrollment_id
   #                         and a.vgroup_id = evgm.vgroup_id and spvg.scan_procedure_id = cg_pcvipr_values.scan_procedure_id
   #                         and v.appointment_id = a.id and a.vgroup_id = evgm.vgroup_id and a.vgroup_id = spvg.vgroup_id)
   #         and image_datasets.series_description in (select series_description_maps.series_description from series_description_maps where series_description_maps.series_description_type_id in (15)) 
   #         and image_datasets.series_description is not null)", v_scan_procedure_id_exclude_array)
          # not getting juist PCVIPR ??
          v_ids_array = v_ids_array.where("image_datasets.series_description in (select series_description_maps.series_description from series_description_maps where series_description_maps.series_description_type_id in (15))")
          v_ids_array.each do |ids|
           begin
            v_err = ""
            v_ids_path_full = ids.path
            v_subjectid = ""
  puts "full_path="+v_ids_path_full
  puts "series_description="+ids.series_description
            v_ids_path = (ids.path)
                 # gsub replacing everything - variables seem to be linked
                 #if (v_ids_path).include? "\/mri\/"
                 # v_ids_path = (v_ids_path).gsub!("\/mri\/","\/") # replace /mri/ , split on / ==> sp , split on _ ==> subjectid
                 #end
 
            v_path_array = v_ids_path.split("/")
            v_scan_procedure_name = v_path_array[4]

            v_visit_number = ""   # might have to add more some day
            if v_scan_procedure_name.include? "visit2"
              v_visit_number = "_v2"
            elsif v_scan_procedure_name.include? "visit3"
              v_visit_number = "_v3"
            elsif v_scan_procedure_name.include? "visit4"
              v_visit_number = "_v4"
            elsif v_scan_procedure_name.include? "visit5"
              v_visit_number = "_v5"
            elsif v_scan_procedure_name.include? "visit6"
              v_visit_number = "_v6"
            elsif v_scan_procedure_name.include? "visit7"
              v_visit_number = "_v7"
            end
            if v_path_array[5] == "mri"
              v_subjectid_exam_date_array = v_path_array[6].split("_")
              v_subjectid = v_subjectid_exam_date_array[0]
            else
              v_subjectid_exam_date_array = v_path_array[5].split("_")
              v_subjectid = v_subjectid_exam_date_array[0]
            end
                  # check for v_pcvipr_recon_base+v_scan_procedure_name --- make dir
            v_sp_pcvipr = v_pcvipr_recon_base+v_scan_procedure_name
            if File.directory? v_sp_pcvipr
              puts v_sp_pcvipr 
            else
              v_call = "ssh panda_user@kanga.dom.wisc.edu 'mkdir "+v_sp_pcvipr +"' "
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            end
                  # check for v_pcvipr_recon_base+v_scan_procedure_name+"/"+v_scan_procedure_name+".orig/" --- make dir
            v_sp_pcvipr_orig = v_pcvipr_recon_base+v_scan_procedure_name+"/"+v_scan_procedure_name+".orig"
            if File.directory? v_sp_pcvipr_orig
              puts v_sp_pcvipr_orig 
            else
              v_call = "ssh panda_user@kanga.dom.wisc.edu 'mkdir "+v_sp_pcvipr_orig +"' "
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
            end
               # SEWCONDARY_KEY IN PATH CAUSING nil in .first enrollment etc.
                  # used in tracker
            v_ids_id = ids.id
            v_sp_id = (ScanProcedure.where("codename in (?)",v_scan_procedure_name).first).id
            v_enrollment_id = (Enrollment.where("enumber in (?) or concat(enumber,'b') in (?)" ,v_subjectid,v_subjectid).first).id
            v_subjectid_v_num = v_subjectid+v_visit_number

            v_check_path_done = v_pcvipr_recon_base+v_scan_procedure_name+"/"+v_scan_procedure_name+".done/"+v_subjectid+v_visit_number
            v_check_path_orig = v_pcvipr_recon_base+v_scan_procedure_name+"/"+v_scan_procedure_name+".orig/"+v_subjectid+v_visit_number
            v_exisits = "N"
                   #check that not in sp.visit#.orig. and not in sp.visit#.done
                  #make subjectid_v# directory
                  #copy over pfile/gating files
                  #bunzip2 pfile
                  # not detecting or not detecting <subjectid>_v#_otherstuff
            #if (File.directory? v_check_path_done or File.directory? v_check_path_orig )
            v_check_path_done_wildcard = v_check_path_done+"*"
            v_check_path_orig_wildcard = v_check_path_orig+"*"
            Dir.glob(v_check_path_done_wildcard).each do|f|
                v_exisits = "Y"
                puts "exisits = "+v_check_path_done
            end
            Dir.glob(v_check_path_orig_wildcard).each do|f|
                v_exisits = "Y"
                puts "exisits = "+v_check_path_orig
            end
            if v_exisits == "Y"
              v_exisits = "Y"
              puts "exisits = "+v_check_path_done+" or "+v_check_path_orig
            else
              v_comment = "str "+v_subjectid+";"+v_comment
              @schedulerun.comment = "str "+v_subjectid_v_num+";"+@schedulerun.comment
              @schedulerun.save

              v_call = "ssh panda_user@kanga.dom.wisc.edu 'mkdir "+v_check_path_orig +"' "
        puts v_call
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
              v_call = "ssh panda_user@kanga.dom.wisc.edu 'rsync -av  "+v_ids_path_full+"   "+v_check_path_orig+"/' "
        puts v_call
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
              v_call = "ssh panda_user@kanga.dom.wisc.edu 'cd "+v_check_path_orig+";find . -name 'P*.7.bz2' -exec bunzip2 {} \\\;' "
        puts v_call        
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
       #make subjectid_v# directory
       #copy over pfile/gating files
       #bunzip2 pfile
                #run gating check ==> output to gating_check_file.txt

              v_check_gating_base ="check_gating -f "
              v_pcvipr_recon_binary_base = "pcvipr_recon_binary -f "
              v_pcvipr_recon_options =" -dat_plus_dicom -override_autorecon -pils -walsh -lp_frac 0.75 -vs_wdth_high 5 -weighted_echos 0 -viewshare_type tornado -frame_by_frame -echo_stop 0 -viewshare_type tornado -cardiac -tr 6800 -gate_delay 9 -rcframes 20 -gating_type retro_ecg"
                # get path pfile
              v_pfile_path = ""
              v_pfile_dir_path = ""
              v_pfile  = ""
              v_call = "ssh panda_user@kanga.dom.wisc.edu 'cd "+v_check_path_orig+";find . -name 'P*.7' -exec readlink -f {} \\\;'"
          puts v_call        
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                v_pfile_path = stdout.read 1024    
              end
          puts "v_pfile_path="+v_pfile_path  
              v_pfile_dir_path = File.dirname(v_pfile_path)
              v_pfile = File.basename(v_pfile_path)
              stdin.close
              stdout.close
              stderr.close
              v_pfile = v_pfile.strip

#f = File.open('foo.txt', 'a')
#f.write('foo')
#f.close

              if v_pfile.include? "P" and v_pfile.include? ".7"

                v_call = "ssh panda_user@kanga.dom.wisc.edu 'cd "+v_pfile_dir_path+";"+v_check_gating_base+v_pfile+"'"   #' >> "+v_pfile_dir_path+"/gating_check_output_"+v_pfile.strip+".txt'"
                puts v_call        
                stdin, stdout, stderr = Open3.popen3(v_call)
      #IS THERE A SIZE LIMIT IN TEXT OUT BUFFER
                f = File.open(v_pfile_dir_path+"/gating_check_output_"+v_pfile.strip+".txt", 'a')
                while !stdout.eof?
                  #puts stdout.read 1024
                  f.write((stdout.read 1024))  
     
                end
                f.close
                stdin.close
                stdout.close
                stderr.close
               
               # run recon-- output to file

                v_call = "ssh panda_user@kanga.dom.wisc.edu 'cd "+v_pfile_dir_path+";"+v_pcvipr_recon_binary_base+v_pfile+v_pcvipr_recon_options+"'" #' >> "+v_pfile_dir_path+"/recon_output_"+v_pfile.strip+".txt'"
                puts v_call        
                stdin, stdout, stderr = Open3.popen3(v_call)
                f = File.open(v_pfile_dir_path+"/recon_output_"+v_pfile.strip+".txt", 'a')
                while !stdout.eof?
                  #puts stdout.read 1024 
                  f.write((stdout.read 1024)) 
                
                end
                f.close
                stdin.close
                stdout.close
                stderr.close
               # delete pfile
                v_call = "ssh panda_user@kanga.dom.wisc.edu 'cd "+v_pfile_dir_path+";rm "+v_pfile+"'"
                puts v_call        
                stdin, stdout, stderr = Open3.popen3(v_call)
                while !stdout.eof?
                  puts stdout.read 1024    
                end
                stdin.close
                stdout.close
                stderr.close
   
                      #make tracker record
                @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid_v_num)

                if @trfiles.count == 0
                  puts "making trfile"
                  @trfile = Trfile.new
                  @trfile.subjectid = v_subjectid_v_num
                      # @trfile.secondary_key = v_secondary_key
                  @trfile.enrollment_id = v_enrollment_id
                  @trfile.scan_procedure_id = v_sp_id
                  @trfile.trtype_id = v_trtype_id
                  @trfile.image_dataset_id = v_ids_id
                  @trfile.qc_notes = "autorun recon by panda "
                  @trfile.save
                  @tredit = Tredit.new
                  @tredit.trfile_id = @trfile.id
                      #@tredit.user_id = current_user.id
                  @tredit.save
                  v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                  if !v_tractiontypes.nil?
                    v_tractiontypes.each do |tat|
                      v_tredit_action = TreditAction.new
                      v_tredit_action.tredit_id = @tredit.id
                      v_tredit_action.tractiontype_id = tat.id
                      if !(tat.form_default_value).blank?
                        v_tredit_action.value = tat.form_default_value
                      end
                                 # set each field if needed-- just an example from mcd
                                 #if tat.id == 14 # despot 2
                                 #   v_tredit_action.value = v_despot_2_flag
                                 #elsif tat.id == 15 # mcdespot
                                 #   v_tredit_action.value = v_mcdespot_flag
                                 #end
                      v_tredit_action.save
                    end
                  end
                end
               
                v_cnt = v_cnt + 1
                v_comment = "done "+v_subjectid_v_num+";"+v_comment
                @schedulerun.comment = "done "+v_subjectid_v_num+";"+@schedulerun.comment
              else
                v_comment = "no pfile found "+v_subjectid_v_num+";"+v_comment
                @schedulerun.comment = "no pfile found "+v_subjectid_v_num+";"+@schedulerun.comment
              end
puts "end of ids loop"
             end
             rescue => msg
                v_err = msg.inspect
                if !v_err.nil? and v_err > ""
                  v_comment_error = v_err+"; "+v_comment_error
                  v_comment = "ERROR  "+v_comment    # took out v_subjectid_v_num  - not defined?
                  @schedulerun.comment = "ERROR  "+v_err+";"+@schedulerun.comment
                  @schedulerun.save
                   v_schedule_owner_email_array.each do |e|
                       v_subject = "Error in "+v_process_name+":  check enum -extra 0, permission P file, wrong Pfile, no gating file?"
                       PandaMailer.schedule_notice(v_subject,{:send_to => e}).deliver

                   end
                 end

          
            end                 
          end


       # get list of pcvipr scans from X months back. not already in cg_pcvipr_value
       # get sp and subjectid
       #check that not in sp.visit#.orig. and not in sp.visit#.done
       #make subjectid_v# directory
       #copy over pfile/gating files
       #bunzip2 pfile
       #check load on machine
       #run gating check
       #run pcvipr recon
       # make tracker record - 
       # check logs


      @schedulerun.comment =(v_comment_error+"successful finish pcvipr_recon_and_gating_check "+v_cnt.to_s+" recon run  "+v_comment[0..1459])
      if !v_comment.include?("ERROR")
         @schedulerun.status_flag ="Y"
       end
       @schedulerun.save
       @schedulerun.end_time = @schedulerun.updated_at      
       @schedulerun.save

  end

  # look for pcvipr recon in orig which don't have a .dat
  def run_pcvipr_recon_and_fail_list()
         v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('pcvipr_recon_and_fail_list')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting pcvipr_recon_and_fail_list"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = "no dat file;"
          v_computer = "kanga"

       # go into each scan procedure, go into .orig
       # get list of subjectid paths
       # do a find for *.dat
       # log if not found

          v_analyses_path = v_base_path+"/analyses/PCVIPR/4DFLOW_DATA/"

          # go to directory, get list of directories. - could check if there is a scan_procedure
          Dir.glob(v_analyses_path+"/*").each do |v_dir_path_name| 
            if File.directory?(v_dir_path_name)
                #puts v_dir_path_name
               v_scan_procedures = ScanProcedure.where("scan_procedures.codename in (?)",v_dir_path_name.split("/").last)
               if !v_scan_procedures.nil? and !v_scan_procedures[0].nil?
                  #puts v_scan_procedures[0].codename
                  v_dir_path_name_orig = v_dir_path_name+"/"+v_dir_path_name.split("/").last+".orig"
                   Dir.glob(v_dir_path_name_orig+"/*").each do |v_subject_path_name| 

                      if !v_subject_path_name.include? "harvignore" and  Dir.glob(v_subject_path_name+"/*.dat").empty? and  Dir.glob(v_subject_path_name+"/*/*.dat").empty? and  Dir.glob(v_subject_path_name+"/*/*/*.dat").empty?
                            v_comment = v_comment +"; "+v_subject_path_name.gsub(v_analyses_path,"")
                      end
                   end
                end
             end
           end

      @schedulerun.comment =("successful finish pcvipr_recon_and_fail_list  "+v_comment[0..2459])
      if !v_comment.include?("ERROR")
         @schedulerun.status_flag ="Y"
       end
       @schedulerun.save
       @schedulerun.end_time = @schedulerun.updated_at      
       @schedulerun.save

    
  end



  def run_pcvipr_output_file()
         run_pcvipr_output_file_base("leave_output_and_log")
  end
  def run_pcvipr_output_file_rm_output()
         run_pcvipr_output_file_base("rm_output")
  end
  def run_pcvipr_output_file_rm_output_and_log()
         run_pcvipr_output_file_base("rm_output_and_log")
  end
  def run_pcvipr_output_file_rerun_if_no_output()
         run_pcvipr_output_file_base("rerun_if_no_output")
  end

  def run_pcvipr_output_file_base(p_output_log_rm)
         v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('pcvipr_output_file')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting pcvipr_output_file"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_computer = "kanga" # actually baloo == v_machine
           v_machine = "baloo.dom.wisc.edu"  # eventually switch to "+v_computer+" - need packages installed
          v_cnt = 0
          v_rerun_outputs = "N" #"Y"# rm output and log if output present
          v_rerun_full_outputs_log = "N"  # "Y"  # rm all output and log  
          v_rerun_if_no_output = "N"
          if p_output_log_rm == "rm_output"
            v_rerun_outputs = "Y"
            v_rerun_if_no_output = "Y"
          end  
          if p_output_log_rm == "rm_output_and_log"
            v_rerun_if_no_output = "Y"
            v_rerun_outputs = "Y"
          end
          if p_output_log_rm == "rerun_if_no_output"
            v_rerun_if_no_output = "Y"
          end

         #  v_script_path = v_base_path+"/data1/lab_scripts/python_dev/collect_pcvipr_data.py" 
          v_script_path = v_base_path+"/SysAdmin/production/python/collect_pcvipr_data.py"  # CHANGE TO PRODUCTION

          # add check if output.csv was made
          #connection = ActiveRecord::Base.connection();

          v_analyses_path = v_base_path+"/analyses/PCVIPR/4DFLOW_DATA/"

          # go to directory, get list of directories. - could check if there is a scan_procedure
          Dir.glob(v_analyses_path+"/*").each do |v_dir_path_name| 
            if File.directory?(v_dir_path_name)
                #puts v_dir_path_name
               v_scan_procedures = ScanProcedure.where("scan_procedures.codename in (?)",v_dir_path_name.split("/").last)
               if !v_scan_procedures.nil? and !v_scan_procedures[0].nil?
                  #puts v_scan_procedures[0].codename
                  v_dir_path_name_done = v_dir_path_name+"/"+v_dir_path_name.split("/").last+".done"
                  puts "v_dir_path_name_done= "+v_dir_path_name_done
                  Dir.glob(v_dir_path_name_done+"/*").each do |v_dir_path_name_subjectid| # get the subjectid folders
                    # check for Summary.xls and *Summary_Calculator_*.xlsx and output*.csv
                    #NEED TO DO FIND or something to get real path
                    # get path to Summary.xls, could be few directories down
                    
                    if  !Dir.glob(v_dir_path_name_subjectid+"/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*Summary_Calculator_*.xlsx").empty? and (Dir.glob(v_dir_path_name_subjectid+"/*_output.csv").empty? or v_rerun_outputs == "Y") and (Dir.glob(v_dir_path_name_subjectid+"/*_output.csv.log").empty? or v_rerun_if_no_output =="Y")
                        #puts "done===="+v_dir_path_name_subjectid
                        v_just_path = v_dir_path_name_subjectid
                        # run command
                        v_call = "ssh panda_user@"+v_machine+" '"+v_script_path+"  "+v_just_path+"' "
                        stdin, stdout, stderr = Open3.popen3(v_call)
                        
                        while !stdout.eof?
                            puts stdout.read 1024    
                        end
                        stdin.close
                        stdout.close
                        stderr.close
                        if Dir.glob(v_dir_path_name_subjectid+"/*_output.csv").empty?
                                v_comment = v_comment+"; no output file="+v_just_path.gsub!(v_dir_path_name_done,'')
                        else
                          v_cnt = v_cnt +1
                        end

                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*Summary_Calculator_*.xlsx").empty? and (Dir.glob(v_dir_path_name_subjectid+"/*/*_output.csv").empty? or v_rerun_outputs == "Y")  and (Dir.glob(v_dir_path_name_subjectid+"/*/*_output.csv.log").empty? or v_rerun_if_no_output =="Y")
                         #puts "done 1 down===="+v_dir_path_name_subjectid+"/*"
                         # get extra dir path 
                         Dir.glob(v_dir_path_name_subjectid+"/*/Summary.xls").each do |v_file_path| 
                             v_just_path = File.dirname(v_file_path)
                             #puts v_just_path
                             # run command
                             v_call = "ssh panda_user@"+v_machine+" '"+v_script_path+"  "+v_just_path+"' "
                             stdin, stdout, stderr = Open3.popen3(v_call)
                             while !stdout.eof?
                                puts stdout.read 1024    
                             end
                             stdin.close
                             stdout.close
                             stderr.close
                              if Dir.glob(v_dir_path_name_subjectid+"/*/*_output.csv").empty?
                                v_comment = v_comment+"; no output file "+v_just_path.gsub!(v_dir_path_name_done,'')
                              else
                                v_cnt = v_cnt +1
                             end
                          end
                         
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*Summary_Calculator_*.xlsx").empty? and (Dir.glob(v_dir_path_name_subjectid+"/*/*/*_output.csv").empty? or v_rerun_outputs == "Y")  and (Dir.glob(v_dir_path_name_subjectid+"/*/*/*_output.csv.log").empty? or v_rerun_if_no_output =="Y")
                         puts "done 2 down ===="+v_dir_path_name_subjectid+"/*/*"
                         # get extra dir path 
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/Summary.xls").each do |v_file_path| 
                             v_just_path = File.dirname(v_file_path)
                             #puts v_just_path
                             # run command
                             v_call = "ssh panda_user@"+v_machine+" '"+v_script_path+"  "+v_just_path+"' "
                             stdin, stdout, stderr = Open3.popen3(v_call)
                             while !stdout.eof?
                                puts stdout.read 1024    
                             end
                             stdin.close
                             stdout.close
                             stderr.close
                             if Dir.glob(v_dir_path_name_subjectid+"/*/*/*_output.csv").empty?
                                v_comment = v_comment+"; no output file "+v_just_path.gsub!(v_dir_path_name_done,'')
                              else
                                v_cnt = v_cnt +1
                             end
                          end
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*Summary_Calculator_*.xlsx").empty? and (Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_output.csv").empty? or v_rerun_outputs == "Y")  and (Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_output.csv.log").empty? or v_rerun_if_no_output =="Y")
                         #puts "done 3 down ===="+v_dir_path_name_subjectid+"/*/*/*"
                         # get extra dir path 
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/*/Summary.xls").each do |v_file_path| 
                             v_just_path = File.dirname(v_file_path)
                             #puts v_just_path
                             # run command
                             v_call = "ssh panda_user@"+v_machine+" '"+v_script_path+"  "+v_just_path+"' "
                             stdin, stdout, stderr = Open3.popen3(v_call)
                             while !stdout.eof?
                                puts stdout.read 1024    
                             end
                             stdin.close
                             stdout.close
                             stderr.close
                             if Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_output.csv").empty?
                                v_comment = v_comment+"; no output file "+v_just_path.gsub!(v_dir_path_name_done,'')
                              else
                                v_cnt = v_cnt +1
                             end
                          end
                    end
                  end
               end
            end
          end

      @schedulerun.comment =("successful finish pcvipr_output_file "+v_cnt.to_s+" output files made  "+v_comment[0..1459])
      if !v_comment.include?("ERROR")
         @schedulerun.status_flag ="Y"
       end
       @schedulerun.save
       @schedulerun.end_time = @schedulerun.updated_at      
       @schedulerun.save

  end

  def run_pcvipr_output_file_harvest
          v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('pcvipr_output_file_harvest')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting pcvipr_output_file_harvest"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment =""
          v_comment_warning = ""
          v_shared = Shared.new
          v_trtype_id = 2 # pcvipr tracker typeid
          v_second_viewer_flag = "N" # populate from tracker record
          v_harvester_ignore_directory = "harvignore"
          v_computer = "kanga"

          v_file_header_expected ="Left ICA - Cervical (Inferior):maxV,Left ICA - Petrous (Superior):maxV,Right ICA - Cervical (Inferior):maxV,Right ICA - Petrous (Superior):maxV,Basilar Artery:maxV,Left MCA:maxV,Right MCA:maxV,Left PCA:maxV,Right PCA:maxV,SS Sinus:maxV,Straight Sinus:maxV,Left ICA - Cervical (Inferior):Mean Flow,Left ICA - Petrous (Superior):Mean Flow,Right ICA - Cervical (Inferior):Mean Flow,Right ICA - Petrous (Superior):Mean Flow,Basilar Artery:Mean Flow,Left MCA:Mean Flow,Right MCA:Mean Flow,Left PCA:Mean Flow,Right PCA:Mean Flow,SS Sinus:Mean Flow,Straight Sinus:Mean Flow,LeftTS:Mean Flow,RightTS:Mean Flow,Left ICA - Cervical (Inferior):Pulsatility Index,Left ICA - Petrous (Superior):Pulsatility Index,Right ICA - Cervical (Inferior):Pulsatility Index,Right ICA - Petrous (Superior):Pulsatility Index,Basilar Artery:Pulsatility Index,Left MCA:Pulsatility Index,Right MCA:Pulsatility Index,Left PCA:Pulsatility Index,Right PCA:Pulsatility Index,SS Sinus:Pulsatility Index,Straight Sinus:Pulsatility Index,LeftTS:Pulsatility Index,RightTS:Pulsatility Index,Left ICA - Cervical (Inferior):Boolean,Left ICA - Petrous (Superior):Boolean,Right ICA - Cervical (Inferior):Boolean,Right ICA - Petrous (Superior):Boolean,Basilar Artery:Boolean,Left MCA:Boolean,Right MCA:Boolean,Left PCA:Boolean,Right PCA:Boolean,SS Sinus:Boolean,Straight Sinus:Boolean"
          v_column_list = "left_ica_cervical_inferior,left_ica_petrous_superior,right_ica_cervical_inferior,right_ica_petrous_superior,basilar_artery,left_mca,right_mca,left_pca,right_pca,ss_sinus,straight_sinus,left_ica_cervical_inferior_mean_flow,left_ica_petrous_superior_mean_flow,right_ica_cervical_inferior_mean_flow,right_ica_petrous_superior_mean_flow,basilar_artery_mean_flow,left_mca_mean_flow,right_mca_mean_flow,left_pca_mean_flow,right_pca_mean_flow,ss_sinus_mean_flow,straight_sinus_mean_flow,leftts_mean_flow,rightts_mean_flow,left_ica_cervical_inferior_pulsatility_index,left_ica_petrous_superior_pulsatility_index,right_ica_cervical_inferior_pulsatility_index,right_ica_petrous_superior_pulsatility_index,basilar_artery_pulsatility_index,left_mca_pulsatility_index,right_mca_pulsatility_index,left_pca_pulsatility_index,right_pca_pulsatility_index,ss_sinus_pulsatility_index,straight_sinus_pulsatility_index,leftts_pulsatility_index,rightts_pulsatility_index,left_ica_cervical_inferior_boolean,left_ica_petrous_superior_boolean,right_ica_cervical_inferior_boolean,right_ica_petrous_superior_boolean,basilar_artery_boolean,left_mca_boolean,right_mca_boolean,left_pca_boolean,right_pca_boolean,ss_sinus_boolean,straight_sinus_boolean"
         # Directory Name,file_name, == dir name
          v_analyses_path = v_base_path+"/analyses/PCVIPR/4DFLOW_DATA/"
puts "v_analyses_path="+v_analyses_path
          sql = "truncate table cg_pcvipr_values_new"
          connection = ActiveRecord::Base.connection();        
          results = connection.execute(sql)
          v_visit_number_array = ['v2','v3','v4','v5','v6','v7','v8','v9','v10','v11','v12','v13','v14','v15','v16']

          # go to directory, get list of directories. - could check if there is a scan_procedure
          Dir.glob(v_analyses_path+"/*").each do |v_dir_path_name| 
            if File.directory?(v_dir_path_name)
                puts "-bbbbb "+v_dir_path_name
                puts "sp ="+v_dir_path_name.split("/").last+"="
               v_scan_procedures = ScanProcedure.where("scan_procedures.codename in (?)",v_dir_path_name.split("/").last)
               # add check that internal subject_id sp matches top dir sp
               # add check that pcvipr has second view flag=Y

               if !v_scan_procedures.nil? and !v_scan_procedures[0].nil?
                  puts v_scan_procedures[0].codename
                  v_dir_path_name_done = v_dir_path_name+"/"+v_dir_path_name.split("/").last+".done"
                  puts "-aaaaaa v_dir_path_name_done= "+v_dir_path_name_done
                  Dir.glob(v_dir_path_name_done+"/*").each do |v_dir_path_name_subjectid| # get the subjectid folders
                    # check for Summary.xls and *Summary_Calculator_*.xlsx and output*.csv
                    #NEED TO DO FIND or something to get real path
                    # get path to Summary.xls, could be few directories down
                    puts "v_dir_path_name_subjectid.split(/).last="+v_dir_path_name_subjectid.split("/").last
                    v_subjectid_dir = v_dir_path_name_subjectid.split("/").last
                    v_subjectid_array = v_subjectid_dir.split("_")
                    v_subjectid = ""
                    if(!v_subjectid_array[1].nil? and (v_visit_number_array.include? v_subjectid_array[1])) # 
                       v_subjectid = v_subjectid_array[0]+"_"+v_subjectid_array[1]
                    else
                       v_subjectid = v_subjectid_array[0]
                    end
                    puts "v_subjectid="+v_subjectid+"=     v_dir_path_name_subjectid= cd "+v_dir_path_name_subjectid+"; ls *.xls*"
                    if !Dir.glob(v_dir_path_name_subjectid+"/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*_output.csv").empty? 
                        puts "AAAA done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*_output.csv").each do |v_file_path_exact| 
                             v_file_path = v_file_path_exact # File.dirname(v_file_path_exact)
                          if v_file_path.include? v_harvester_ignore_directory
                             print "ignore this directory"
                          else
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                               v_second_viewer_flag = "N"
                               @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid)
                               if !@trfiles.nil? and !@trfiles[0].nil?
                                   # get last edit
                                   @tredits = Tredit.where("trfile_id in (?)",@trfiles[0].id).order("tredits.id desc")
                                   v_tredit_id = @tredits[0].id
                                   # the individual fields
                                   v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                                   if !v_tractiontypes.nil?
                                       v_tractiontypes.each do |tat|
                                           v_tredit_action = TreditAction.where("tredit_id in (?)",v_tredit_id).where("tractiontype_id in (?)", tat.id)
                                           if tat.id == 79 # load
                                               if  !v_tredit_action[0].nil? and !v_tredit_action[0].value.nil? and v_tredit_action[0].value == "1"
                                                   v_second_viewer_flag = "Y"
                                               end
                                            end
                                       end
                                   end
                               end
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               elsif v_second_viewer_flag == "N"
                                     v_comment = v_comment+"; "+v_subjectid+" not done"
                               else
                                   puts v_return_comment
                                   v_comment = v_return_comment+v_comment
                                   v_comment = v_comment[0..1499]
                                   v_cnt = 0
                                   v_line_array = []
                                   File.open(v_file_path,'r') do |file_a|
                                   while line = file_a.gets
                                     if v_cnt > 0
                                       sql = "insert into cg_pcvipr_values_new ( file_name,subjectid, "+v_column_list+" ) values('"+v_file_path.split("/").last+"','"+v_subjectid+"',"
                                       v_line_array = []
                                       line.gsub(/\n/,"").split(",").each do |v|
                                         v_line_array.push("'"+v+"'")
                                       end 
                                       sql = sql+v_line_array.join(",")
                                       sql = sql+")"
                                       results = connection.execute(sql)                    
                                     end
                                     v_cnt = v_cnt + 1
                                   end
                               end # end mismatch sp's
                             end
                            end
                          end
                        end
                        #
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*/*_output.csv").empty? 
                         puts "BBBBB done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*/*_output.csv").each do |v_file_path_exact| 
                          v_file_path = v_file_path_exact #  File.dirname(v_file_path_exact)
                          if v_file_path.include? v_harvester_ignore_directory
                             print "ignore this directory"
                          else
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                               v_second_viewer_flag = "N"
                               @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid)
                               if !@trfiles.nil? and !@trfiles[0].nil?
                                   # get last edit
                                   @tredits = Tredit.where("trfile_id in (?)",@trfiles[0].id).order("tredits.id desc")
                                   v_tredit_id = @tredits[0].id
                                   # the individual fields
                                   v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                                   if !v_tractiontypes.nil?
                                       v_tractiontypes.each do |tat|
                                           v_tredit_action = TreditAction.where("tredit_id in (?)",v_tredit_id).where("tractiontype_id in (?)", tat.id)
                                           if tat.id == 79 # load
                                               if  !v_tredit_action[0].nil? and !v_tredit_action[0].value.nil? and v_tredit_action[0].value == "1"
                                                   v_second_viewer_flag = "Y"
                                               end
                                            end
                                       end
                                   end
                               end
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               elsif v_second_viewer_flag == "N"
                                     v_comment = v_comment+"; "+v_subjectid+" not done"
                               else
                                   puts v_return_comment
                                   v_comment = v_return_comment+v_comment
                                   v_comment = v_comment[0..1499]
                                   v_cnt = 0
                                   v_line_array = []
                                   File.open(v_file_path,'r') do |file_a|
                                   while line = file_a.gets
                                     if v_cnt > 0
                                        sql = "insert into cg_pcvipr_values_new ( file_name,subjectid, "+v_column_list+" ) values('"+v_file_path.split("/").last+"','"+v_subjectid+"',"
                                        v_line_array = []
                                        line.gsub(/\n/,"").split(",").each do |v|
                                          v_line_array.push("'"+v+"'")
                                        end 
                                        sql = sql+v_line_array.join(",")
                                        sql = sql+")"
                                        results = connection.execute(sql)                    
                                     end
                                     v_cnt = v_cnt + 1
                                   end
                                end # sp mismatch
                              end
                             end
                          end
                        end
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*_output.csv").empty? 
                         puts "CCCCCC done 2 down ===="+v_dir_path_name_subjectid+"/*/*"
                         #puts "done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/*_output.csv").each do |v_file_path_exact| 
                          v_file_path = v_file_path_exact #File.dirname(v_file_path_exact)
                          if v_file_path.include? v_harvester_ignore_directory
                             print "ignore this directory"
                          else
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                               v_second_viewer_flag = "N"
                               @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid)
                               if !@trfiles.nil? and !@trfiles[0].nil?
                                   # get last edit
                                   @tredits = Tredit.where("trfile_id in (?)",@trfiles[0].id).order("tredits.id desc")
                                   v_tredit_id = @tredits[0].id
                                   # the individual fields
                                   v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                                   if !v_tractiontypes.nil?
                                       v_tractiontypes.each do |tat|
                                           v_tredit_action = TreditAction.where("tredit_id in (?)",v_tredit_id).where("tractiontype_id in (?)", tat.id)
                                           if tat.id == 79 # load
                                               if  !v_tredit_action[0].nil? and !v_tredit_action[0].value.nil? and v_tredit_action[0].value == "1"
                                                   v_second_viewer_flag = "Y"
                                               end
                                            end
                                       end
                                   end
                               end
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               elsif v_second_viewer_flag == "N"
                                     v_comment = v_comment+"; "+v_subjectid+" not done"
                               else
                                   puts v_return_comment
                                   v_comment = v_return_comment+v_comment
                                   v_comment = v_comment[0..1499]
                                   v_cnt = 0
                                   v_line_array = []
                                   File.open(v_file_path,'r') do |file_a|
                                   while line = file_a.gets
                                      if v_cnt > 0
                                        sql = "insert into cg_pcvipr_values_new ( file_name,subjectid, "+v_column_list+" ) values('"+v_file_path.split("/").last+"','"+v_subjectid+"',"
                                        v_line_array = []
                                        line.gsub(/\n/,"").split(",").each do |v|
                                           v_line_array.push("'"+v+"'")
                                        end 
                                        sql = sql+v_line_array.join(",")
                                        sql = sql+")"
                                        results = connection.execute(sql)                    
                                      end
                                      v_cnt = v_cnt + 1
                                   end
                                end # sp mismatch
                             end
                            end
                          end
                        end
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_output.csv").empty? 
                         puts "DDDDD done 3 down ===="+v_dir_path_name_subjectid+"/*/*/*"
                         #puts "done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_output.csv").each do |v_file_path_exact| 
                             v_file_path = v_file_path_exact #File.dirname(v_file_path_exact)
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                               v_second_viewer_flag = "N"
                               @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid)
                               if !@trfiles.nil? and !@trfiles[0].nil?
                                   # get last edit
                                   @tredits = Tredit.where("trfile_id in (?)",@trfiles[0].id).order("tredits.id desc")
                                   v_tredit_id = @tredits[0].id
                                   # the individual fields
                                   v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                                   if !v_tractiontypes.nil?
                                       v_tractiontypes.each do |tat|
                                           v_tredit_action = TreditAction.where("tredit_id in (?)",v_tredit_id).where("tractiontype_id in (?)", tat.id)
                                           if tat.id == 79 # load
                                               if  !v_tredit_action[0].nil? and !v_tredit_action[0].value.nil? and v_tredit_action[0].value == "1"
                                                   v_second_viewer_flag = "Y"
                                               end
                                            end
                                       end
                                   end
                               end
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               elsif v_second_viewer_flag == "N"
                                     v_comment = v_comment+"; "+v_subjectid+" not done"
                               else
                                   puts v_return_comment
                                   v_comment = v_return_comment+v_comment
                                   v_comment = v_comment[0..1499]
                                   v_cnt = 0
                                   v_line_array = []
                                   File.open(v_file_path,'r') do |file_a|
                                    while line = file_a.gets
                                     if v_cnt > 0
                                        sql = "insert into cg_pcvipr_values_new ( file_name,subjectid, "+v_column_list+" ) values('"+v_file_path.split("/").last+"','"+v_subjectid+"',"
                                        v_line_array = []
                                        line.gsub(/\n/,"").split(",").each do |v|
                                          v_line_array.push("'"+v+"'")
                                        end 
                                        sql = sql+v_line_array.join(",")
                                        sql = sql+")"
                                        results = connection.execute(sql)                    
                                     end
                                     v_cnt = v_cnt + 1
                                   end
                                end # sp mismatch
                             end
                          end
                        end
                    end
                  end
               end
            end
          end
          puts "setting the e.id"
          # update all the 
                # update enrollment -- make into a function?
                sql = "update cg_pcvipr_values_new  t set t.enrollment_id = ( select e.id from enrollments e where e.enumber = replace(replace(replace(replace(t.subjectid,'_v2',''),'_v3',''),'_v4',''),'_v5',''))"
                results = connection.execute(sql)
                # secondary key
                # select all where enrollment_id is null
                # match enumber plus .R, b, c, d , 
                # set secondary key
                sql = "select subjectid from cg_pcvipr_values_new where enrollment_id is null order by subjectid"
                results = connection.execute(sql)
                results.each do |re|
                    enrollment = Enrollment.where("concat(enumber,'.R') in (?) or concat(enumber,'a') in (?) or concat(enumber,'b') in (?) or concat(enumber,'c') in (?) or concat(enumber,'d') in (?) or concat(enumber,'e') in (?)",re[0],re[0],re[0],re[0],re[0],re[0])
                    if !enrollment.blank?
                             v_secondary_key = re[0]
                             v_secondary_key = v_secondary_key.tr(enrollment[0].enumber, "") 
                             sql = "update cg_pcvipr_values_new  t set t.enrollment_id = "+enrollment[0].id.to_s+", secondary_key='"+v_secondary_key+"', subjectid='"+enrollment[0].enumber+"' where subjectid='"+re[0]+"'"
                             results = connection.execute(sql)
                    end
                end

                

                sql = "select subjectid from cg_pcvipr_values_new"
                results = connection.execute(sql)
                results.each do |r|
                  v_sp_id = v_shared.get_sp_id_from_subjectid_v(r[0])
                  if !v_sp_id.blank?
                    sql = "update cg_pcvipr_values_new  t set t.scan_procedure_id = "+v_sp_id.to_s+" where subjectid ='"+r[0]+"'"
                    results = connection.execute(sql)
                  end
                end



                # report on unmapped rows, not insert unmapped rows 

                sql = "select subjectid, enrollment_id from cg_pcvipr_values_new where scan_procedure_id is null order by subjectid"
                results = connection.execute(sql)
                results.each do |re|
                  v_comment = re.join(' | ')+" ,"+v_comment
                end
                if !results.blank?
                   v_comment = "cg_pcvipr_values_new unmapped subjectid,enrollment_id ="+v_comment
                end

                # make copy of full _new harvest
                # wipe out bad pulsavity values based on tracker
                v_full_value_tn = "cg_pcvipr_values_full"
                begin
                  sql = "drop table "+v_full_value_tn
                  results = connection.execute(sql)
                 rescue
                     puts "error in drop/populate "+v_full_value_tn
                 end
                 begin
                  sql = "create table "+v_full_value_tn+" as select * from cg_pcvipr_values_new"
                  results = connection.execute(sql)
                 rescue
                     puts "error in drop/populate "+v_full_value_tn
                 end
                 # other columns ? not just pulsativity?
                #v_tredit_columns_hash = {"65"=>"basilar_artery_pulsatility_index","66"=>"right_ica_petrous_superior_pulsatility_index","67"=>"right_ica_cervical_inferior_pulsatility_index","68"=>"left_ica_petrous_superior_pulsatility_index","69"=>"left_ica_cervical_inferior_pulsatility_index","70"=>"right_mca_pulsatility_index","71"=>"left_mca_pulsatility_index","72"=>"left_pca_pulsatility_index","73"=>"right_pca_pulsatility_index","74"=>"ss_sinus_pulsatility_index","75"=>"straight_sinus_pulsatility_index","76"=>"rightts_pulsatility_index","77"=>"leftts_pulsatility_index"} #####  #####  
              v_tredit_columns_hash = {"65"=>"basilar_artery_pulsatility_index|basilar_artery|basilar_artery_mean_flow","69"=>"left_ica_cervical_inferior_pulsatility_index|left_ica_cervical_inferior|left_ica_cervical_inferior_mean_flow","68"=>"left_ica_petrous_superior_pulsatility_index|left_ica_petrous_superior|left_ica_petrous_superior_mean_flow","71"=>"left_mca_pulsatility_index|left_mca|left_mca_mean_flow","72"=>"left_pca_pulsatility_index|left_pca|left_pca_mean_flow","77"=>"leftts_pulsatility_index|leftts_mean_flow","67"=>"right_ica_cervical_inferior_pulsatility_index|right_ica_cervical_inferior|right_ica_cervical_inferior_mean_flow","66"=>"right_ica_petrous_superior_pulsatility_index|right_ica_petrous_superior|right_ica_petrous_superior_mean_flow","70"=>"right_mca_pulsatility_index|right_mca|right_mca_mean_flow","73"=>"right_pca_pulsatility_index|right_pca|right_pca_mean_flow","76"=>"rightts_pulsatility_index|rightts_mean_flow","74"=>"ss_sinus_pulsatility_index|ss_sinus|ss_sinus_mean_flow","75"=>"straight_sinus_pulsatility_index|straight_sinus|straight_sinus_mean_flow"}#  "65"=>"basilar_artery_pulsatility_index|basilar_artery|basilar_artery_mean_flow","69"=>"left_ica_cervical_inferior_pulsatility_index|left_ica_cervical_inferior|left_ica_cervical_inferior_mean_flow","68"=>"left_ica_petrous_superior_pulsatility_index|left_ica_petrous_superior|left_ica_petrous_superior_mean_flow","71"=>"left_mca_pulsatility_index|left_mca|left_mca_mean_flow","72"=>"left_pca_pulsatility_index|left_pca|left_pca_mean_flow","77"=>"leftts_pulsatility_index|leftts_mean_flow","67"=>"right_ica_cervical_inferior_pulsatility_index|right_ica_cervical_inferior|right_ica_cervical_inferior_mean_flow","66"=>"right_ica_petrous_superior_pulsatility_index|right_ica_petrous_superior|right_ica_petrous_superior_mean_flow","70"=>"right_mca_pulsatility_index|right_mca|right_mca_mean_flow","73"=>"right_pca_pulsatility_index|right_pca|right_pca_mean_flow","76"=>"rightts_pulsatility_index|rightts_mean_flow","74"=>"ss_sinus_pulsatility_index|ss_sinus|ss_sinus_mean_flow","75"=>"straight_sinus_pulsatility_index|straight_sinus|straight_sinus_mean_flow"}
               v_tredit_columns_hash.each do |name, values|
                puts values
                   v_col_array = values.split("|")
                puts v_col_array.first
                   sql = "update cg_pcvipr_values_new t1
                      set t1."+v_col_array.first+" = 'Bad Pulstatility'
                         where t1.subjectid in 
                        ( select trfile2.subjectid  from  trfiles trfile2, tredits , tredit_actions
                      where trfile2.id = tredits.trfile_id 
                      and tredits.id = tredit_actions.tredit_id 
                      and tredits.id in ( select tredit3.id from tredits tredit3, tredit_actions tredit_action3 where  tredit3.id = tredit_action3.tredit_id 
                                           and tredit_action3.tractiontype_id = 79 and tredit_action3.value = 1  and tredit3.status_flag = 'Y')
                      and tredit_actions.tractiontype_id = "+name+"
                      and tredit_actions.value =  2
                      and trfile2.trtype_id = 2 
                      and tredits.id in ( select max(tredit2.id) from tredits tredit2 where tredit2.trfile_id = trfile2.id and tredit2.status_flag = 'Y') )"
                      results = connection.execute(sql)
                   # bad gating = 62, fail = 3
                   sql = "update cg_pcvipr_values_new t1
                      set t1."+v_col_array.first+" = 'Bad Pulsatility'
                         where t1.subjectid in 
                        ( select trfile2.subjectid  from  trfiles trfile2, tredits , tredit_actions 
                      where trfile2.id = tredits.trfile_id 
                      and tredits.id = tredit_actions.tredit_id 
                                            and tredits.id in ( select tredit3.id from tredits tredit3, tredit_actions tredit_action3 where  tredit3.id = tredit_action3.tredit_id 
                                           and tredit_action3.tractiontype_id = 79 and tredit_action3.value = 1  and tredit3.status_flag = 'Y')
                      and tredit_actions.tractiontype_id = 62
                      and tredit_actions.value = 3
                      and trfile2.trtype_id = 2 
                      and tredits.id in ( select max(tredit2.id) from tredits tredit2 where tredit2.trfile_id = trfile2.id and tredit2.status_flag = 'Y' ) )"
                      results = connection.execute(sql)
                      v_do_not_use_column_set = ""
                      v_col_cnt = 0
                      for v_col in v_col_array
                          if v_col_cnt > 0
                             v_do_not_use_column_set = v_do_not_use_column_set+" , "
                          end 
                          v_do_not_use_column_set = v_do_not_use_column_set+"t1."+v_col+" = 'Do Not Use' "
                          v_col_cnt = v_col_cnt + 1
                    end
                   sql = "update cg_pcvipr_values_new t1
                      set "+v_do_not_use_column_set+"
                         where t1.subjectid in 
                        ( select trfile2.subjectid  from  trfiles trfile2, tredits , tredit_actions
                      where trfile2.id = tredits.trfile_id 
                      and tredits.id = tredit_actions.tredit_id 
                                            and tredits.id in ( select tredit3.id from tredits tredit3, tredit_actions tredit_action3 where  tredit3.id = tredit_action3.tredit_id 
                                           and tredit_action3.tractiontype_id = 79 and tredit_action3.value = 1 and tredit3.status_flag = 'Y')
                      and tredit_actions.tractiontype_id = "+name+"
                      and tredit_actions.value =  4
                      and trfile2.trtype_id = 2 
                      and tredits.id in ( select max(tredit2.id) from tredits tredit2 where tredit2.trfile_id = trfile2.id and tredit2.status_flag = 'Y' ) )"
                      results = connection.execute(sql)



                end
                

                # check move cg_ to cg_old
                sql = "select count(*) from cg_pcvipr_values_old"
                results_old = connection.execute(sql)
                
                sql = "select count(*) from cg_pcvipr_values"
                results = connection.execute(sql)
                v_old_cnt = results_old.first.to_s.to_i
                v_present_cnt = results.first.to_s.to_i
                v_old_minus_present =v_old_cnt-v_present_cnt
                v_present_minus_old = v_present_cnt-v_old_cnt
                if ( v_old_minus_present <= 0 or ( v_old_cnt > 0 and  (v_present_minus_old/v_old_cnt)>0.7     ) )
                  sql =  "truncate table cg_pcvipr_values_old"
                  results = connection.execute(sql)
                  sql = "insert into cg_pcvipr_values_old select * from cg_pcvipr_values"
                  results = connection.execute(sql)
                else
                  v_comment = " The cg_pcvipr_values_old table has 30% more rows than the present cg_pcvipr_values\n Not truncating cg_pcvipr_values_old "+v_comment 
                end
                #  truncate cg_ and insert cg_new
                sql =  "truncate table cg_pcvipr_values"
                results = connection.execute(sql)

                sql = "insert into cg_pcvipr_values("+v_column_list+",subjectid,enrollment_id,scan_procedure_id,secondary_key,file_name) 
                select distinct "+v_column_list+",t.subjectid,t.enrollment_id, scan_procedure_id,secondary_key,file_name from cg_pcvipr_values_new t
                                               where t.scan_procedure_id is not null  and t.enrollment_id is not null "
                results = connection.execute(sql)

                # apply edits  -- made into a function  in shared model
              
                v_shared.apply_cg_edits("cg_pcvipr_values")
        v_comment = v_comment_warning+v_comment
        puts v_comment
        @schedulerun.comment =("successful finish pcvipr_output_file_harvest "+v_comment[0..1459])
      if !v_comment.include?("ERROR")
         @schedulerun.status_flag ="Y"
       end
       @schedulerun.save
       @schedulerun.end_time = @schedulerun.updated_at      
       @schedulerun.save

  end
  # not tested
  def run_pcvipr_html_full_replace()
         run_pcvipr_html_base("full_replace")
  end
  def run_pcvipr_html()
         run_pcvipr_html_base("ignore existing")
  end

 # base on pcvipr_outyput_file_harvest
 # check if html file exisits, else make html file
 # option for full replace of all html
 # some existiing html with weird <subjectid>_<exam#>_<date> names- just making an extra file
  def run_pcvipr_html_base(p_full_replace)
          v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('pcvipr_html')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting pcvipr_html"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment =""
          v_comment_warning = ""
          v_shared = Shared.new
          v_second_viewer_flag = "N" # populate from tracker record
          v_harvester_ignore_directory = "harvignore"
          v_computer = "kanga"
          v_script_path = v_base_path+"/SysAdmin/production/make_webbody_pcvipr.bash"
          v_full_replace = "N"
          if p_full_replace == "full_replace"
              v_full_replace = "Y"
          end


          v_file_header_expected ="Left ICA - Cervical (Inferior):maxV,Left ICA - Petrous (Superior):maxV,Right ICA - Cervical (Inferior):maxV,Right ICA - Petrous (Superior):maxV,Basilar Artery:maxV,Left MCA:maxV,Right MCA:maxV,Left PCA:maxV,Right PCA:maxV,SS Sinus:maxV,Straight Sinus:maxV,Left ICA - Cervical (Inferior):Mean Flow,Left ICA - Petrous (Superior):Mean Flow,Right ICA - Cervical (Inferior):Mean Flow,Right ICA - Petrous (Superior):Mean Flow,Basilar Artery:Mean Flow,Left MCA:Mean Flow,Right MCA:Mean Flow,Left PCA:Mean Flow,Right PCA:Mean Flow,SS Sinus:Mean Flow,Straight Sinus:Mean Flow,LeftTS:Mean Flow,RightTS:Mean Flow,Left ICA - Cervical (Inferior):Pulsatility Index,Left ICA - Petrous (Superior):Pulsatility Index,Right ICA - Cervical (Inferior):Pulsatility Index,Right ICA - Petrous (Superior):Pulsatility Index,Basilar Artery:Pulsatility Index,Left MCA:Pulsatility Index,Right MCA:Pulsatility Index,Left PCA:Pulsatility Index,Right PCA:Pulsatility Index,SS Sinus:Pulsatility Index,Straight Sinus:Pulsatility Index,LeftTS:Pulsatility Index,RightTS:Pulsatility Index,Left ICA - Cervical (Inferior):Boolean,Left ICA - Petrous (Superior):Boolean,Right ICA - Cervical (Inferior):Boolean,Right ICA - Petrous (Superior):Boolean,Basilar Artery:Boolean,Left MCA:Boolean,Right MCA:Boolean,Left PCA:Boolean,Right PCA:Boolean,SS Sinus:Boolean,Straight Sinus:Boolean"
          v_column_list = "left_ica_cervical_inferior,left_ica_petrous_superior,right_ica_cervical_inferior,right_ica_petrous_superior,basilar_artery,left_mca,right_mca,left_pca,right_pca,ss_sinus,straight_sinus,left_ica_cervical_inferior_mean_flow,left_ica_petrous_superior_mean_flow,right_ica_cervical_inferior_mean_flow,right_ica_petrous_superior_mean_flow,basilar_artery_mean_flow,left_mca_mean_flow,right_mca_mean_flow,left_pca_mean_flow,right_pca_mean_flow,ss_sinus_mean_flow,straight_sinus_mean_flow,leftts_mean_flow,rightts_mean_flow,left_ica_cervical_inferior_pulsatility_index,left_ica_petrous_superior_pulsatility_index,right_ica_cervical_inferior_pulsatility_index,right_ica_petrous_superior_pulsatility_index,basilar_artery_pulsatility_index,left_mca_pulsatility_index,right_mca_pulsatility_index,left_pca_pulsatility_index,right_pca_pulsatility_index,ss_sinus_pulsatility_index,straight_sinus_pulsatility_index,leftts_pulsatility_index,rightts_pulsatility_index,left_ica_cervical_inferior_boolean,left_ica_petrous_superior_boolean,right_ica_cervical_inferior_boolean,right_ica_petrous_superior_boolean,basilar_artery_boolean,left_mca_boolean,right_mca_boolean,left_pca_boolean,right_pca_boolean,ss_sinus_boolean,straight_sinus_boolean"
         # Directory Name,file_name, == dir name
          v_analyses_path = v_base_path+"/analyses/PCVIPR/4DFLOW_DATA/"
puts "v_analyses_path="+v_analyses_path
          sql = "truncate table cg_pcvipr_values_new"
          connection = ActiveRecord::Base.connection();        
          results = connection.execute(sql)
          v_visit_number_array = ['v2','v3','v4','v5','v6','v7','v8','v9','v10','v11','v12','v13','v14','v15','v16']

          # go to directory, get list of directories. - could check if there is a scan_procedure
          Dir.glob(v_analyses_path+"/*").each do |v_dir_path_name| 
            if File.directory?(v_dir_path_name)
                puts "-bbbbb "+v_dir_path_name
                puts "sp ="+v_dir_path_name.split("/").last+"="
               v_scan_procedures = ScanProcedure.where("scan_procedures.codename in (?)",v_dir_path_name.split("/").last)
               # add check that internal subject_id sp matches top dir sp
               # add check that pcvipr has second view flag=Y

               if !v_scan_procedures.nil? and !v_scan_procedures[0].nil?
                  puts v_scan_procedures[0].codename
                  v_dir_path_name_done = v_dir_path_name+"/"+v_dir_path_name.split("/").last+".done"
                  puts "-aaaaaa v_dir_path_name_done= "+v_dir_path_name_done
                  Dir.glob(v_dir_path_name_done+"/*").each do |v_dir_path_name_subjectid| # get the subjectid folders
                    # check for Summary.xls and *Summary_Calculator_*.xlsx and output*.csv
                    #NEED TO DO FIND or something to get real path
                    # get path to Summary.xls, could be few directories down
                    puts "v_dir_path_name_subjectid.split(/).last="+v_dir_path_name_subjectid.split("/").last
                    v_subjectid_dir = v_dir_path_name_subjectid.split("/").last
                    v_subjectid_array = v_subjectid_dir.split("_")
                    v_subjectid = ""
                    if(!v_subjectid_array[1].nil? and (v_visit_number_array.include? v_subjectid_array[1])) # 
                       v_subjectid = v_subjectid_array[0]+"_"+v_subjectid_array[1]
                    else
                       v_subjectid = v_subjectid_array[0]
                    end
                    puts "v_subjectid="+v_subjectid+"=     v_dir_path_name_subjectid= cd "+v_dir_path_name_subjectid+"; ls *.xls*"
                    if !Dir.glob(v_dir_path_name_subjectid+"/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*_output.csv").empty? 
                        puts "AAAA done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*_output.csv").each do |v_file_path_exact| 
                             v_file_path = v_file_path_exact # File.dirname(v_file_path_exact)
                          if v_file_path.include? v_harvester_ignore_directory
                             print "ignore this directory"
                          else
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                       
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               else
                                   # CHECK FOR HTML
                                  # MAKE HTML
                                  #puts "PPPP check for v#="+v_dir_path_name_subjectid+"/"+v_subjectid+".html"
                                  if File.exist?(v_dir_path_name_subjectid+"/"+v_subjectid+".html") and v_full_replace == "N"
                                    # html exists
                                  else
                                     v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu '"+v_script_path+" "+v_dir_path_name_subjectid+"/"+" "+v_dir_path_name_subjectid+"/"+v_subjectid+".html'"
                                     puts v_call        
                                     stdin, stdout, stderr = Open3.popen3(v_call)
                                     while !stdout.eof?
                                         puts stdout.read 1024    
                                     end
                                     stdin.close
                                     stdout.close
                                     stderr.close

                                  end
                                end # sp mismatch
                             ##?end
                            end # return flag==N
                          end # harvignore
                        end # dir glob
                        #
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*/*_output.csv").empty? 
                         puts "BBBBB done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*/*_output.csv").each do |v_file_path_exact| 
                          v_file_path = v_file_path_exact #  File.dirname(v_file_path_exact)
                          if v_file_path.include? v_harvester_ignore_directory
                             print "ignore this directory"
                          else
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                       
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               else
                                  #puts "PPPP check for v#="+v_dir_path_name_subjectid+"/"+v_subjectid+".html"
                                  if File.exist?(v_dir_path_name_subjectid+"/"+v_subjectid+".html") and v_full_replace == "N"
                                    # html exists
                                  else
                                     v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu '"+v_script_path+" "+v_dir_path_name_subjectid+"/"+" "+v_dir_path_name_subjectid+"/"+v_subjectid+".html'"
                                     puts v_call        
                                     stdin, stdout, stderr = Open3.popen3(v_call)
                                     while !stdout.eof?
                                         puts stdout.read 1024    
                                     end
                                     stdin.close
                                     stdout.close
                                     stderr.close

                                  end
                                end # sp mismatch
                               
                              ##?end
                             end
                          end
                        end
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*_output.csv").empty? 
                         puts "CCCCCC done 2 down ===="+v_dir_path_name_subjectid+"/*/*"
                         #puts "done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/*_output.csv").each do |v_file_path_exact| 
                          v_file_path = v_file_path_exact #File.dirname(v_file_path_exact)
                          if v_file_path.include? v_harvester_ignore_directory
                             print "ignore this directory"
                          else
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                       
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               else
                                  #puts "PPPP check for v#="+v_dir_path_name_subjectid+"/"+v_subjectid+".html"
                                  if File.exist?(v_dir_path_name_subjectid+"/"+v_subjectid+".html") and v_full_replace == "N"
                                    # html exists
                                  else
                                     v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu '"+v_script_path+" "+v_dir_path_name_subjectid+"/"+" "+v_dir_path_name_subjectid+"/"+v_subjectid+".html'"
                                     puts v_call        
                                     stdin, stdout, stderr = Open3.popen3(v_call)
                                     while !stdout.eof?
                                         puts stdout.read 1024    
                                     end
                                     stdin.close
                                     stdout.close
                                     stderr.close

                                  end
                                end # sp mismatch
                             ##?end
                            end
                          end
                        end
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_output.csv").empty? 
                         puts "DDDDD done 3 down ===="+v_dir_path_name_subjectid+"/*/*/*"
                         #puts "done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_output.csv").each do |v_file_path_exact| 
                             v_file_path = v_file_path_exact #File.dirname(v_file_path_exact)
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                               
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               else
                                  #puts "PPPP check for v#="+v_dir_path_name_subjectid+"/"+v_subjectid+".html"
                                  if File.exist?(v_dir_path_name_subjectid+"/"+v_subjectid+".html") and v_full_replace == "N"
                                        # html exists
                                  else
                                     v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu '"+v_script_path+" "+v_dir_path_name_subjectid+"/"+" "+v_dir_path_name_subjectid+"/"+v_subjectid+".html'"
                                     puts v_call        
                                     stdin, stdout, stderr = Open3.popen3(v_call)
                                     while !stdout.eof?
                                         puts stdout.read 1024    
                                     end
                                     stdin.close
                                     stdout.close
                                     stderr.close

                                  end
                                end # sp mismatch
                             ##?end
                          end
                        end
                    end
                  end
               end
            end
          end
        v_comment = v_comment_warning+v_comment
        puts v_comment
        @schedulerun.comment =("successful finish pcvipr_html "+v_comment[0..1459])
      if !v_comment.include?("ERROR")
         @schedulerun.status_flag ="Y"
       end
       @schedulerun.save
       @schedulerun.end_time = @schedulerun.updated_at      
       @schedulerun.save
  end
  
  # to add columns --
  # change sql_base insert statement
  # change  sql = sql_base+  insert statement with values
  # change  self.move_present_to_old_new_to_present
  def run_pib_status
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('pib_status')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting pib_status"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_computer = "kanga"
    ####    begin   # catch all exception and put error in comment    
            sql = "truncate table cg_pib_status_new"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)

            sql_base = "insert into cg_pib_status_new(pib_subjectid, pib_general_comment,pib_registered_to_fs_flag,pib_smoothed_and_warped_flag,pib_dvr_hypr_flag,enrollment_id, scan_procedure_id)values("  


            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            # get list of scan_procedure codename -- exclude 4, 10, 15, 19, 32, 
                # ??? johnson.pc vs johnsonpc4000.visit1 vs pc_4000
                # ??? johnson.tbi10000 vs johnson.tbiaware vs tbi_1000
                # ??? johnson.wrap140.visit1 vs wrap140.visit1 vs wrap140
                # NOT exists /Volumes/team-1/raw/carlson.esprit/mri
                # NOT exists /Volumes/team-1/raw/johnson.wrap140.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbiaware.visit3/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit2/mri
                # NOT exists /Volumes/team-1/raw/johnnson.alz.repsup.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.pc4000.visit1/mri
            v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
            @scan_procedures = ScanProcedure.where("petscan_flag='Y' and id not in (?)",v_exclude_sp)  # NEED ONLY sp with pib, but filter later
            @scan_procedures. each do |sp|
               v_visit_number =""
               if sp.codename.include?("visit2")
                  v_visit_number ="_v2"
               elsif sp.codename.include?("visit3")
                  v_visit_number ="_v3"
               elsif sp.codename.include?("visit4")
                  v_visit_number ="_v4"
               elsif sp.codename.include?("visit5")
                  v_visit_number ="_v5"
               end

                v_preprocessed_full_path = v_preprocessed_path+sp.codename
                sql_enum = "select distinct enrollments.enumber from enrollments, scan_procedures_vgroups, vgroups, appointments, petscans, enrollment_vgroup_memberships
                                    where scan_procedures_vgroups.scan_procedure_id = "+sp.id.to_s+" and  vgroups.transfer_pet = 'yes'  
                                    and appointments.vgroup_id = vgroups.id and appointments.appointment_type = 'pet_scan'
                                    and appointments.id = petscans.appointment_id and petscans.lookup_pettracer_id = 1
                                    and enrollment_vgroup_memberships.vgroup_id = vgroups.id and enrollment_vgroup_memberships.enrollment_id = enrollments.id
                                    and enrollments.enumber like '"+sp.subjectid_base+"%' order by enrollments.enumber"
                 @results = connection.execute(sql_enum)
                                    
                 @results.each do |r|
                     enrollment = Enrollment.where("enumber='"+r[0]+"'")
                     if !enrollment.blank?
                        v_subjectid_pib = v_preprocessed_full_path+"/"+enrollment[0].enumber+"/pet/pib"
                        if File.directory?(v_subjectid_pib)
                            v_dir_array = Dir.entries(v_subjectid_pib)   # need to get date for specific files
                            v_pib_registered_to_fs_flag ="N"
                            v_pib_smoothed_and_warped_flag = "N"
                            v_pib_dvr_hypr_flag = "N"
                            v_dir_array.each do |f|
                              
                               if f.start_with?("swr") and f.end_with?(".nii")
                                  v_pib_smoothed_and_warped_flag = "Y"
                               elsif f.start_with?("rFS") and f.end_with?(".nii")
                                  v_pib_registered_to_fs_flag ="Y"
                                elsif f.start_with?("r"+enrollment[0].enumber+v_visit_number) and f.end_with?("realignPIB_DVR_HYPR.nii")
                                   v_pib_dvr_hypr_flag ="Y"
                                end
                              end
                                
                             sql = sql_base+"'"+enrollment[0].enumber+v_visit_number+"','','"+v_pib_registered_to_fs_flag+"','"+v_pib_smoothed_and_warped_flag+"','"+v_pib_dvr_hypr_flag+"',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                 results = connection.execute(sql)
                             else
                                 sql = sql_base+"'"+enrollment[0].enumber+v_visit_number+"','no pib dir','N','N','N',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                 results = connection.execute(sql)
                             end # check for subjectid asl dir
                      else
                           #puts "no enrollment "+dir_name_array[0]
                      end # check for enrollment
                 end # loop thru the subjectids
            end            
            # check move cg_ to cg_old
            # v_shared = Shared.new 
             # move from new to present table -- made into a function  in shared model
             v_comment = self.move_present_to_old_new_to_present("cg_pib_status",
             "pib_subjectid, pib_general_comment,pib_registered_to_fs_flag, pib_registered_to_fs_comment, pib_registered_to_fs_global_quality, pib_smoothed_and_warped_flag, pib_smoothed_and_warped_comment, pib_smoothed_and_warped_global_quality,pib_dvr_hypr_flag, enrollment_id,scan_procedure_id",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)


             # apply edits  -- made into a function  in shared model
             self.apply_cg_edits('cg_pib_status')

             puts "successful finish pib_status "+v_comment[0..459]
              @schedulerun.comment =("successful finish pib_status "+v_comment[0..459])
              if !v_comment.include?("ERROR")
                 @schedulerun.status_flag ="Y"
               end
               @schedulerun.save
               @schedulerun.end_time = @schedulerun.updated_at      
               @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end  
  end

   # walk the preprocessed/visits/sp/subject/unknown etc. 
   # try to link to ids
   def run_processedimage_unknown_harvest


      v_base_path = Shared.get_base_path()
      v_log_base ="/mounts/data/preprocessed/logs/"
      v_process_name = "processedimage_unknown_harvest"
      process_logs_delete_old( v_process_name, v_log_base)
      @schedule = Schedule.where("name in ('processedimage_unknown_harvest')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting processedimage_unknown_harvest"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_computer = "kanga"
      v_raw_path = v_base_path+"/raw"
      v_mri = "/mri"
      no_mri_path_sp_list =['asthana.adrc-clinical-core.visit1',
      'bendlin.mets.visit1','bendlin.tami.visit1','bendlin.wmad.visit1','carlson.sharp.visit1','carlson.sharp.visit2',
       'carlson.sharp.visit3','carlson.sharp.visit4','dempsey.plaque.visit1','dempsey.plaque.visit2','gleason.falls.visit1',
      'johnson.merit220.visit1','johnson.merit220.visit2','johnson.tbi.aware.visit3','johnson.tbi-va.visit1','ries.aware.visit1','wrap140']

      v_preprocessed_path = v_base_path+"/preprocessed/visits/"
      v_unknown_subpath = "/unknown/"
      v_t1_series_description_type_id = "19"
      v_t2_series_description_type_id = "20"

      v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
      @scan_procedures = ScanProcedure.where("id not in (?)",v_exclude_sp)   #.where("scan_procedures.codename in ('asthana.adrc-clinical-core.visit1')")
      @scan_procedures.each do |sp|
          v_visit_number =""
          if sp.codename.include?("visit2")
              v_visit_number ="_v2"
          elsif sp.codename.include?("visit3")
              v_visit_number ="_v3"
          elsif sp.codename.include?("visit4")
              v_visit_number ="_v4"
          elsif sp.codename.include?("visit5")
              v_visit_number ="_v5"
          end
          if no_mri_path_sp_list.include?(sp.codename)
              v_mri = ""
          else
              v_mri = "/mri"
          end
          v_raw_full_path = v_raw_path+"/"+sp.codename+v_mri
          v_preprocessed_full_path = v_preprocessed_path+sp.codename+"/"
          if File.directory?(v_raw_full_path)
              if !File.directory?(v_preprocessed_full_path)
                @schedulerun.comment = "preprocessed path NOT exists "+v_preprocessed_full_path+";"+@schedulerun.comment
              else
                Dir.entries(v_raw_full_path).select { |file| File.directory? File.join(v_raw_full_path, file)}.each do |dir|
                 # if dir.include? "shp00027"
                      dir_name_array = dir.split('_')
                      v_subjectid = dir_name_array[0]
                      v_enrollments = Enrollment.where("enumber in (?)", v_subjectid)
                      if File.directory?(v_preprocessed_full_path+v_subjectid+v_unknown_subpath) and v_enrollments.count > 0
                          v_enrollment = v_enrollments.first
                                   # get the o<subjectid> from unknown
                                   Dir.glob(v_preprocessed_full_path+v_subjectid+v_unknown_subpath+'o'+v_subjectid+'_*.nii').each do|source3_f|
                                      v_source3_file_full_path = source3_f 
                                      v_source3_file = File.basename(source3_f)
        #puts "aaaa v_source3_file="+v_source3_file
                                      v_source3_file_array = v_source3_file.split('_')
                                      v_t1_scan_series_dir = (v_source3_file_array.last).gsub(".nii","")
        #puts "bbbbb v_t1_scan_series_dir="+v_t1_scan_series_dir
                                      v_t1_scan_series_dir_2words = (v_source3_file_array.last(2).join("_")).gsub(".nii","")
         #puts "ccccc v_t1_scan_series_dir="+v_t1_scan_series_dir
         #puts "ddddd v_t1_scan_series_dir_2words="+v_t1_scan_series_dir_2words

                                      #olead00123_Ax-FSPGR-BRAVO-T1_00002.nii ==> 00002.Ax_FSPGR_BRAVO_T1
                                      v_source3_file_array.drop(1)
                                      v_last_item = (v_source3_file_array.last).gsub(".nii","")
                                      v_source3_file_array.pop
                                      v_t1_scan_series_dir_waisman_flip = v_last_item+"."+(v_source3_file_array.join("_")).gsub("-","_")

          #puts "eeee v_t1_scan_series_dir_waisman_flip="+v_t1_scan_series_dir_waisman_flip

                                      v_source3_processesimages = Processedimage.where("file_path in (?)",v_source3_file_full_path)
                                      v_source3_file_id = nil
                                      if v_source3_processesimages.count <1
                                      # need to collect source files, then make processedimage record
                                          v_source3_processedimage = Processedimage.new
                                          v_source3_processedimage.file_type ="o_acpc T1"
                                          v_source3_processedimage.file_name = v_source3_file
                                          v_source3_processedimage.file_path = v_source3_file_full_path
                                          v_source3_processedimage.scan_procedure_id = sp.id
                                          v_source3_processedimage.enrollment_id = v_enrollment.id
                                          v_source3_processedimage.save  
                                          v_source3_file_id = v_source3_processedimage.id
                                      else
                                          v_source3_processesimage = v_source3_processesimages.first
                                          v_source3_file_id = v_source3_processesimage.id   
                                      end
          
                                      # get the image_dataset of the T1 CHANGE THE IMAGE TYPE / look in LOG   T1 vs T2??? 
                                      v_image_datasets = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%/"+v_t1_scan_series_dir+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                            # looking for ...%/003 == 003 vs ...%003 ==> 003 and 40003 - processed t1 - same type   
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_last2 = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%"+v_t1_scan_series_dir_2words+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_last2.count > 0 and v_image_datasets_last2.count < 2
                                                v_image_datasets = v_image_datasets_last2
                                             end
                                       end
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_waisman_flip = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%"+v_t1_scan_series_dir_waisman_flip+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_waisman_flip.count > 0 and v_image_datasets_waisman_flip.count < 2
                                                v_image_datasets = v_image_datasets_waisman_flip
                                             end
                                       end
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_type_limit = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_type_limit.count > 0 and v_image_datasets_type_limit.count < 2
                                                v_image_datasets = v_image_datasets_type_limit
                                             end
                                       end

                                      if v_image_datasets.count > 0 and v_image_datasets.count < 2
                                         v_image_dataset = v_image_datasets.first
                                         v_source4_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'image_dataset'",v_source3_file_id,v_image_dataset.id)
                                         if v_source4_processedimagesources.count < 1
                                             v_source4_processedimagesource = Processedimagessource.new
                                             v_source4_processedimagesource.file_name = v_image_dataset.scanned_file
                                             v_source4_processedimagesource.file_path = v_image_dataset.path
                                             v_source4_processedimagesource.source_image_id = v_image_dataset.id
                                             v_source4_processedimagesource.source_image_type = 'image_dataset'
                                             v_source4_processedimagesource.processedimage_id= v_source3_file_id
                                             v_source4_processedimagesource.save

                                        else
                                            v_source4_processedimagesource = v_source4_processedimagesources.first
                                        end
                                      elsif v_image_datasets.count > 1
                                        #puts "multiples ids found"
                                        v_image_datasets.each do |ids|
                                           puts "t1 ids multiple="+ids.id.to_s
                                        end
                                      else
                                        puts " ids not found"
                                      end 
                                   end # unknown o loop
                      end # check if this subjectid proprocessed exists and that subjectid is an enumber
                  #end # TEMPORARY LIMIT TO one subjectid
                end # loop thru all subjectid in raw -- used to look at preporcessed
              end #check if preprocessed exists
          end #check if raw exists                      
      end # sp loop                          




      if !v_comment.include?("ERROR")
            @schedulerun.status_flag ="Y"
      else
          @schedulerun.comment ="Suceess ;"+@schedulerun.comment
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save
   end

 # walk the preprocessed/visits/sp/subject/tissue_seg etc. 
   # link to unknown o_acpc 
   # try to link to ids
   def run_processedimage_tissue_seg_harvest


      v_base_path = Shared.get_base_path()
      v_log_base ="/mounts/data/preprocessed/logs/"
      v_process_name = "processedimage_tissue_seg_harvest"
      process_logs_delete_old( v_process_name, v_log_base)
      @schedule = Schedule.where("name in ('processedimage_tissue_seg_harvest')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting processedimage_tissue_seg_harvest"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_computer = "kanga"
      v_raw_path = v_base_path+"/raw"
      v_mri = "/mri"
      no_mri_path_sp_list =['asthana.adrc-clinical-core.visit1',
      'bendlin.mets.visit1','bendlin.tami.visit1','bendlin.wmad.visit1','carlson.sharp.visit1','carlson.sharp.visit2',
       'carlson.sharp.visit3','carlson.sharp.visit4','dempsey.plaque.visit1','dempsey.plaque.visit2','gleason.falls.visit1',
      'johnson.merit220.visit1','johnson.merit220.visit2','johnson.tbi.aware.visit3','johnson.tbi-va.visit1','ries.aware.visit1','wrap140']

      v_preprocessed_path = v_base_path+"/preprocessed/visits/"
      v_tissue_seg_subpath = "/tissue_seg/"
      v_unknown_subpath = "/unknown/"
      v_t1_series_description_type_id = "19"
      v_t2_series_description_type_id = "20"

      v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
      @scan_procedures = ScanProcedure.where("id not in (?)",v_exclude_sp)  #.where("scan_procedures.codename in ('asthana.adrc-clinical-core.visit1')")
      @scan_procedures.each do |sp|
          v_visit_number =""
          if sp.codename.include?("visit2")
              v_visit_number ="_v2"
          elsif sp.codename.include?("visit3")
              v_visit_number ="_v3"
          elsif sp.codename.include?("visit4")
              v_visit_number ="_v4"
          elsif sp.codename.include?("visit5")
              v_visit_number ="_v5"
          end
          if no_mri_path_sp_list.include?(sp.codename)
              v_mri = ""
          else
              v_mri = "/mri"
          end
          v_raw_full_path = v_raw_path+"/"+sp.codename+v_mri
          v_preprocessed_full_path = v_preprocessed_path+sp.codename+"/"
          if File.directory?(v_raw_full_path)
              if !File.directory?(v_preprocessed_full_path)
                @schedulerun.comment = "preprocessed path NOT exists "+v_preprocessed_full_path+";"+@schedulerun.comment
              else
                Dir.entries(v_raw_full_path).select { |file| File.directory? File.join(v_raw_full_path, file)}.each do |dir|
                  #if dir.include? "adrc00540"
                      dir_name_array = dir.split('_')
                      v_subjectid = dir_name_array[0]
                      v_enrollments = Enrollment.where("enumber in (?)", v_subjectid)
                      if File.directory?(v_preprocessed_full_path+v_subjectid+v_tissue_seg_subpath) and v_enrollments.count > 0
                          v_enrollment = v_enrollments.first
                                # get the mo<subjectid> from tissue_seg
                                Dir.glob(v_preprocessed_full_path+v_subjectid+v_tissue_seg_subpath+'mo'+v_subjectid+'_*.nii').each do|source2_f|
                                   v_source2_file_full_path = source2_f 
                                   v_source2_file = File.basename(source2_f)
                                   v_source2_file_array = v_source2_file.split('_')
                                   v_t1_scan_series_dir = (v_source2_file_array.last).gsub(".nii","")
                                   v_t1_scan_series_dir_2words = (v_source2_file_array.last(2).join("_")).gsub(".nii","")
                                   v_source2_file_array.drop(1)
                                   v_last_item = (v_source2_file_array.last).gsub(".nii","")
                                   v_source2_file_array.pop
                                   v_t1_scan_series_dir_waisman_flip = v_last_item+"."+(v_source2_file_array.join("_")).gsub("-","_")

                                   v_source2_processesimages = Processedimage.where("file_path in (?)",v_source2_file_full_path)
                                   v_source2_file_id = nil
                                   if v_source2_processesimages.count <1
                                # need to collect source files, then make processedimage record
                                       v_source2_processedimage = Processedimage.new
                                       v_source2_processedimage.file_type ="m_acpc T1"
                                       v_source2_processedimage.file_name = v_source2_file
                                       v_source2_processedimage.file_path = v_source2_file_full_path
                                       v_source2_processedimage.scan_procedure_id = sp.id
                                       v_source2_processedimage.enrollment_id = v_enrollment.id
                                       v_source2_processedimage.save  
                                       v_source2_file_id = v_source2_processedimage.id
                                   else
                                       v_source2_processesimage = v_source2_processesimages.first
                                       v_source2_file_id = v_source2_processesimage.id   
                                   end

                                   # get the o<subjectid> from unknown
                                   Dir.glob(v_preprocessed_full_path+v_subjectid+v_unknown_subpath+'o'+v_subjectid+'_*_'+v_t1_scan_series_dir+'.nii').each do|source3_f|
                                      v_source3_file_full_path = source3_f 
                                      v_source3_file = File.basename(source3_f)
                                      #v_source3_file_array = v_source3_file.split('_')
                                      #v_t1_scan_series_dir = (v_source3_file_array.last).gsub(".nii","")
                                      v_source3_processesimages = Processedimage.where("file_path in (?)",v_source3_file_full_path)
                                      v_source3_file_id = nil
                                      if v_source3_processesimages.count <1
                                      # need to collect source files, then make processedimage record
                                          v_source3_processedimage = Processedimage.new
                                          v_source3_processedimage.file_type ="o_acpc T1"
                                          v_source3_processedimage.file_name = v_source3_file
                                          v_source3_processedimage.file_path = v_source3_file_full_path
                                          v_source3_processedimage.scan_procedure_id = sp.id
                                          v_source3_processedimage.enrollment_id = v_enrollment.id
                                          v_source3_processedimage.save  
                                          v_source3_file_id = v_source3_processedimage.id
                                      else
                                          v_source3_processesimage = v_source3_processesimages.first
                                          v_source3_file_id = v_source3_processesimage.id   
                                      end
          
                                      v_source3_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'processedimage'",v_source2_file_id,v_source3_file_id)
                                      if v_source3_processedimagesources.count < 1
                                          v_source3_processedimagesource = Processedimagessource.new
                                          v_source3_processedimagesource.file_name = v_source3_file
                                          v_source3_processedimagesource.file_path = v_source3_file_full_path
                                          v_source3_processedimagesource.source_image_id = v_source3_file_id
                                          v_source3_processedimagesource.source_image_type = 'processedimage'
                                          v_source3_processedimagesource.processedimage_id= v_source2_file_id
                                          v_source3_processedimagesource.save

                                      else
                                          v_source3_processedimagesource = v_source3_processedimagesources.first
                                      end
                                      # get the image_dataset of the T1 CHANGE THE IMAGE TYPE / look in LOG   T1 vs T2??? 
                                      v_image_datasets = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%/"+v_t1_scan_series_dir+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                            # looking for ...%/003 == 003 vs ...%003 ==> 003 and 40003 - processed t1 - same type   
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_last2 = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%"+v_t1_scan_series_dir_2words+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_last2.count > 0 and v_image_datasets_last2.count < 2
                                                v_image_datasets = v_image_datasets_last2
                                             end
                                       end
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_waisman_flip = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%"+v_t1_scan_series_dir_waisman_flip+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_waisman_flip.count > 0 and v_image_datasets_waisman_flip.count < 2
                                                v_image_datasets = v_image_datasets_waisman_flip
                                             end
                                       end
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_type_limit = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_type_limit.count > 0 and v_image_datasets_type_limit.count < 2
                                                v_image_datasets = v_image_datasets_type_limit
                                             end
                                       end

                                      if v_image_datasets.count > 0 and v_image_datasets.count < 2
                                         v_image_dataset = v_image_datasets.first
                                         v_source4_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'image_dataset'",v_source3_file_id,v_image_dataset.id)
                                         if v_source4_processedimagesources.count < 1
                                             v_source4_processedimagesource = Processedimagessource.new
                                             v_source4_processedimagesource.file_name = v_image_dataset.scanned_file
                                             v_source4_processedimagesource.file_path = v_image_dataset.path
                                             v_source4_processedimagesource.source_image_id = v_image_dataset.id
                                             v_source4_processedimagesource.source_image_type = 'image_dataset'
                                             v_source4_processedimagesource.processedimage_id= v_source3_file_id
                                             v_source4_processedimagesource.save

                                        else
                                            v_source4_processedimagesource = v_source4_processedimagesources.first
                                        end
                                      elsif v_image_datasets.count > 1
                                        #puts "multiples ids found"
                                        v_image_datasets.each do |ids|
                                           puts "t1 ids multiple="+ids.id.to_s
                                        end
                                      else
                                        puts " ids not found"
                                      end 
                                   end # unknown o loop
                                end # tissue seg mo loop
                      end # check if this subjectid proprocessed exists and that subjectid is an enumber
                  #end # TEMPORARY LIMIT TO one subjectid
                end # loop thru all subjectid in raw -- used to look at preporcessed
              end #check if preprocessed exists
          end #check if raw exists                      
      end # sp loop 



      if !v_comment.include?("ERROR")
            @schedulerun.status_flag ="Y"
      else
          @schedulerun.comment ="Suceess ;"+@schedulerun.comment
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save
   end
   # walk the preprocessed/visits/sp/subject/asl etc. 
   # get the ASL file name
   # try to link to ids asl, ids t1/flair
  def run_processedimage_asl_harvest


      v_base_path = Shared.get_base_path()
      v_log_base ="/mounts/data/preprocessed/logs/"
      v_process_name = "processedimage_asl_harvest"
      process_logs_delete_old( v_process_name, v_log_base)
      @schedule = Schedule.where("name in ('processedimage_asl_harvest')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting processedimage_asl_harvest"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_computer = "kanga"
      v_raw_path = v_base_path+"/raw"
      v_mri = "/mri"
      no_mri_path_sp_list =['asthana.adrc-clinical-core.visit1',
      'bendlin.mets.visit1','bendlin.tami.visit1','bendlin.wmad.visit1','carlson.sharp.visit1','carlson.sharp.visit2',
       'carlson.sharp.visit3','carlson.sharp.visit4','dempsey.plaque.visit1','dempsey.plaque.visit2','gleason.falls.visit1',
      'johnson.merit220.visit1','johnson.merit220.visit2','johnson.tbi.aware.visit3','johnson.tbi-va.visit1','ries.aware.visit1','wrap140']

      v_preprocessed_path = v_base_path+"/preprocessed/visits/"
      v_asl_subpath = "/asl/pproc_v5/"
      v_tissue_seg_subpath = "/tissue_seg/"
      v_unknown_subpath = "/unknown/"
      v_asl_series_description_type_id = "1"
      v_t1_series_description_type_id = "19"
      v_t2_series_description_type_id = "20"

      v_asl_processedimage_type = 'asl version#5'
      v_source_image_type = 'image_dataset'

      v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
      @scan_procedures = ScanProcedure.where("id not in (?)",v_exclude_sp).where("scan_procedures.codename in ('asthana.adrc-clinical-core.visit1')")
      @scan_procedures.each do |sp|
          v_visit_number =""
          if sp.codename.include?("visit2")
              v_visit_number ="_v2"
          elsif sp.codename.include?("visit3")
              v_visit_number ="_v3"
          elsif sp.codename.include?("visit4")
              v_visit_number ="_v4"
          elsif sp.codename.include?("visit5")
              v_visit_number ="_v5"
          end
          if no_mri_path_sp_list.include?(sp.codename)
              v_mri = ""
          else
              v_mri = "/mri"
          end
          v_raw_full_path = v_raw_path+"/"+sp.codename+v_mri
          v_preprocessed_full_path = v_preprocessed_path+sp.codename+"/"
          if File.directory?(v_raw_full_path)
              if !File.directory?(v_preprocessed_full_path)
                  @schedulerun.comment = "preprocessed path NOT exists "+v_preprocessed_full_path+";"+@schedulerun.comment
              else
                # look for asl files -- multipl inversion times
                # get product => source => source_of_source => source_of_source_of_source etc. until back to ids
                # check that anything in processedimages
                # then starting with the source_of_source_... before the ids, check for source_of_source_... in processedimages
                #.  if not in processedimages, make record, else use processedimage_id,
                #  continue until back to final product
                # get list of subjectid's 
                # check if file already in processedimages
                # look in sp/subjectid/visit/ids for one match on series_desc_type_id
                #a) look for swrASL_fmap_adrc00540_1525_004.nii.     swrASL_fmap_<subjectid>_<inversion_time>_<dirname>.nii  --- Waisman vs WIMR for dir names
                #b) get scan series from dir name
                #c) look for ASL_fmap_<subjectid>_<inversion_time>_<dirname>.nii 
                #d) get image_dataset_id from <dirname>

                #e) look for y_o<subjectid>_<scan desc>_<dir>.nii
                #f) from tissue_seg/mo<subjectid>_<scan desc>_<dir>.nii
                #g) from unknown o<subjectid>_<scan desc>_<dir>.nii
                #h) get image_dataset_id from <dir>

                #grep tissue_seg log. gives directory source -- flair vs t1?
                #grep asl log. gives directory source 
                # add logging / comment/status for issues with finding children - e.g. 2 matches
                Dir.entries(v_raw_full_path).select { |file| File.directory? File.join(v_raw_full_path, file)}.each do |dir|
                  #if dir.include? "adrc00540".  ### NEED to GET log parse/T2
                      dir_name_array = dir.split('_')
                      v_subjectid = dir_name_array[0]
                      v_enrollments = Enrollment.where("enumber in (?)", v_subjectid)
                      if File.directory?(v_preprocessed_full_path+v_subjectid+v_asl_subpath) and v_enrollments.count > 0
                          v_enrollment = v_enrollments.first
                          # get all the matches
                          #swrASL_fmap_<subjectid>_<inversion_time>_<dirname>.nii
                          Dir.glob(v_preprocessed_full_path+v_subjectid+v_asl_subpath+'swrASL_fmap_'+v_subjectid+'_*_*.nii').each do|f|
                             v_final_file_full_path = f 
                             v_final_file = File.basename(f) 
                             v_final_file_array = v_final_file.split('_')
                             v_scan_series_dir = (v_final_file_array.last).gsub(".nii","")
                             v_asl_inversion_time = v_final_file_array[-2]
                             v_t1_scan_series_dir_2words = (v_final_file_array.last(2).join("_")).gsub(".nii","")
                             v_final_file_array.drop(1)
                             v_last_item = (v_final_file_array.last).gsub(".nii","")
                             v_final_file_array.pop
                             v_t1_scan_series_dir_waisman_flip = v_last_item+"."+(v_final_file_array.join("_")).gsub("-","_")

                             v_final_processesimages = Processedimage.where("file_path in (?)",v_final_file_full_path)
                             v_final_file_id = nil
                             if v_final_processesimages.count <1
                                # need to collect source files, then make processedimage record
                                v_final_processedimage = Processedimage.new
                                v_final_processedimage.file_type ="ASL pproc_v5 final"
                                v_final_processedimage.file_name = v_final_file
                                v_final_processedimage.file_path = v_final_file_full_path
                                v_final_processedimage.scan_procedure_id = sp.id
                                v_final_processedimage.enrollment_id = v_enrollment.id

                                v_final_processedimage.save  
                                v_final_file_id = v_final_processedimage.id
                              else
                                v_final_processedimage = v_final_processesimages.first
                                v_final_file_id = v_final_processedimage.id   
                             end
                             # check for ASL_fmap_<subjectid>_<inversion_time>_<dirname>.nii
                             # check if already in processedimages
                             # check if already a child processedimagessources for the parent v_asl_final_processedimage
                             Dir.glob(v_preprocessed_full_path+v_subjectid+v_asl_subpath+'ASL_fmap_'+v_subjectid+'_'+v_asl_inversion_time+'_'+v_scan_series_dir+'.nii').each do|source1_f|
                                v_source1_file_full_path = source1_f 
                                v_source1_file = File.basename(source1_f)
                                v_source1_processesimages = Processedimage.where("file_path in (?)",v_source1_file_full_path)
                                v_source1_file_id = nil
                                if v_source1_processesimages.count <1
                                # need to collect source files, then make processedimage record
                                    v_source1_processedimage = Processedimage.new
                                    v_source1_processedimage.file_type ="ASL pproc_v5 -ASL fmap"
                                    v_source1_processedimage.file_name = v_source1_file
                                    v_source1_processedimage.file_path = v_source1_file_full_path
                                    v_source1_processedimage.scan_procedure_id = sp.id
                                    v_source1_processedimage.enrollment_id = v_enrollment.id
                                    v_source1_processedimage.save  
                                    v_source1_file_id = v_source1_processedimage.id
                                else
                                    v_source1_processesimage = v_source1_processesimages.first
                                    v_source1_file_id = v_source1_processesimage.id   
                                end
            
                                v_source1_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'processedimage'",v_final_file_id,v_source1_file_id)
                                if v_source1_processedimagesources.count < 1
                                    v_source1_processedimagesource = Processedimagessource.new
                                    v_source1_processedimagesource.file_name = v_source1_file
                                    v_source1_processedimagesource.file_path = v_source1_file_full_path
                                    v_source1_processedimagesource.source_image_id = v_source1_file_id
                                    v_source1_processedimagesource.source_image_type = 'processedimage'
                                    v_source1_processedimagesource.processedimage_id= v_final_file_id
                                    v_source1_processedimagesource.save

                                else
                                    v_source1_processedimagesource = v_source1_processedimagesources.first
                                end
                                # check for image dataset for ASL scan
                                # sp and enrollment - only one - add to processedimages status_flag - no_processedimagessource - or select all parents with no children
                                # sp.id v_enrollment.id v_asl_series_description_type_id
                                # check if v_source1_file_id in processedimagesources with image_dataset as source image
                                v_image_datasets = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%/"+v_scan_series_dir+"'",sp.id, v_enrollment.id, v_asl_series_description_type_id)
                                            # looking for ...%/003 == 003 vs ...%003 ==> 003 and 40003 - processed t1 - same type   
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_last2 = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%"+v_t1_scan_series_dir_2words+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_last2.count > 0 and v_image_datasets_last2.count < 2
                                                v_image_datasets = v_image_datasets_last2
                                             end
                                       end
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_waisman_flip = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%"+v_t1_scan_series_dir_waisman_flip+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_waisman_flip.count > 0 and v_image_datasets_waisman_flip.count < 2
                                                v_image_datasets = v_image_datasets_waisman_flip
                                             end
                                       end
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_type_limit = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_type_limit.count > 0 and v_image_datasets_type_limit.count < 2
                                                v_image_datasets = v_image_datasets_type_limit
                                             end
                                       end

                                if v_image_datasets.count > 0 and v_image_datasets.count < 2
                                   v_image_dataset = v_image_datasets.first
                                   v_source2_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'image_dataset'",v_source1_file_id,v_image_dataset.id)
                                   if v_source2_processedimagesources.count < 1
                                      v_source2_processedimagesource = Processedimagessource.new
                                      v_source2_processedimagesource.file_name = v_image_dataset.scanned_file
                                             v_source2_processedimagesource.file_path = v_image_dataset.path
                                             v_source2_processedimagesource.source_image_id = v_image_dataset.id
                                             v_source2_processedimagesource.source_image_type = 'image_dataset'
                                             v_source2_processedimagesource.processedimage_id= v_source1_file_id
                                             v_source2_processedimagesource.save

                                        else
                                            v_source2_processedimagesource = v_source2_processedimagesources.first
                                        end
                                  elsif v_image_datasets.count > 1
                                        #puts "multiples ids found"
                                        v_image_datasets.each do |ids|
                                           puts "ids multiple="+ids.id.to_s
                                        end
                                  else
                                        puts " ids not found"
                                  end 
                             end # end of ASL_fmap loop
                             # get the T1 y_o<subjectid>_<series descriptionish>_<dirname>.nii
                             Dir.glob(v_preprocessed_full_path+v_subjectid+v_asl_subpath+'y_o'+v_subjectid+'_*.nii').each do|source1_f|
                                v_t1_scan_series_dir = ""
                                v_source1_file_full_path = source1_f 
                                v_source1_file = File.basename(source1_f)
                                v_source1_file_array = v_source1_file.split('_')
                                v_t1_scan_series_dir = (v_source1_file_array.last).gsub(".nii","")
                                v_t1_scan_series_dir_2words = (v_source1_file_array.last(2).join("_")).gsub(".nii","")
                                v_source1_file_array.drop(1)
                                v_last_item = (v_source1_file_array.last).gsub(".nii","")
                                v_source1_file_array.pop
                                v_t1_scan_series_dir_waisman_flip = v_last_item+"."+(v_source1_file_array.join("_")).gsub("-","_")

                                v_source1_processesimages = Processedimage.where("file_path in (?)",v_source1_file_full_path)
                                v_source1_file_id = nil
                                if v_source1_processesimages.count <1
                                # need to collect source files, then make processedimage record
                                    v_source1_processedimage = Processedimage.new
                                    v_source1_processedimage.file_type ="y_acpc T1"
                                    v_source1_processedimage.file_name = v_source1_file
                                    v_source1_processedimage.file_path = v_source1_file_full_path
                                    v_source1_processedimage.scan_procedure_id = sp.id
                                    v_source1_processedimage.enrollment_id = v_enrollment.id
                                    v_source1_processedimage.save  
                                    v_source1_file_id = v_source1_processedimage.id
                                else
                                    v_source1_processesimage = v_source1_processesimages.first
                                    v_source1_file_id = v_source1_processesimage.id   
                                end
         
                                v_source1_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'processedimage'",v_final_file_id,v_source1_file_id)
                                if v_source1_processedimagesources.count < 1
                                    v_source1_processedimagesource = Processedimagessource.new
                                    v_source1_processedimagesource.file_name = v_source1_file
                                    v_source1_processedimagesource.file_path = v_source1_file_full_path
                                    v_source1_processedimagesource.source_image_id = v_source1_file_id
                                    v_source1_processedimagesource.source_image_type = 'processedimage'
                                    v_source1_processedimagesource.processedimage_id= v_final_file_id
                                    v_source1_processedimagesource.save

                                else
                                    v_source1_processedimagesource = v_source1_processedimagesources.first
                                end
                                # get the mo<subjectid> from tissue_seg
                                Dir.glob(v_preprocessed_full_path+v_subjectid+v_tissue_seg_subpath+'mo'+v_subjectid+'_*_'+v_t1_scan_series_dir+'.nii').each do|source2_f|
                                   v_source2_file_full_path = source2_f 
                                   v_source2_file = File.basename(source2_f)
                                   #v_source2_file_array = v_source2_file.split('_')
                                   #v_t1_scan_series_dir = (v_source2_file_array.last).gsub(".nii","")
                                   v_source2_processesimages = Processedimage.where("file_path in (?)",v_source2_file_full_path)
                                   v_source2_file_id = nil
                                   if v_source2_processesimages.count <1
                                # need to collect source files, then make processedimage record
                                       v_source2_processedimage = Processedimage.new
                                       v_source2_processedimage.file_type ="m_acpc T1"
                                       v_source2_processedimage.file_name = v_source2_file
                                       v_source2_processedimage.file_path = v_source2_file_full_path
                                       v_source2_processedimage.scan_procedure_id = sp.id
                                       v_source2_processedimage.enrollment_id = v_enrollment.id
                                       v_source2_processedimage.save  
                                       v_source2_file_id = v_source2_processedimage.id
                                   else
                                       v_source2_processesimage = v_source2_processesimages.first
                                       v_source2_file_id = v_source2_processesimage.id   
                                   end

                                   v_source2_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'processedimage'",v_source1_file_id,v_source2_file_id)
                                   if v_source2_processedimagesources.count < 1
                                       v_source2_processedimagesource = Processedimagessource.new
                                       v_source2_processedimagesource.file_name = v_source2_file
                                       v_source2_processedimagesource.file_path = v_source2_file_full_path
                                       v_source2_processedimagesource.source_image_id = v_source2_file_id
                                       v_source2_processedimagesource.source_image_type = 'processedimage'
                                       v_source2_processedimagesource.processedimage_id= v_source1_file_id
                                       v_source2_processedimagesource.save

                                   else
                                       v_source2_processedimagesource = v_source2_processedimagesources.first
                                   end
                                   # get the o<subjectid> from unknown
                                   Dir.glob(v_preprocessed_full_path+v_subjectid+v_unknown_subpath+'o'+v_subjectid+'_*_'+v_t1_scan_series_dir+'.nii').each do|source3_f|
                                      v_source3_file_full_path = source3_f 
                                      v_source3_file = File.basename(source3_f)
                                      #v_source3_file_array = v_source3_file.split('_')
                                      #v_t1_scan_series_dir = (v_source3_file_array.last).gsub(".nii","")
                                      v_source3_processesimages = Processedimage.where("file_path in (?)",v_source3_file_full_path)
                                      v_source3_file_id = nil
                                      if v_source3_processesimages.count <1
                                      # need to collect source files, then make processedimage record
                                          v_source3_processedimage = Processedimage.new
                                          v_source3_processedimage.file_type ="o_acpc T1"
                                          v_source3_processedimage.file_name = v_source3_file
                                          v_source3_processedimage.file_path = v_source3_file_full_path
                                          v_source3_processedimage.scan_procedure_id = sp.id
                                          v_source3_processedimage.enrollment_id = v_enrollment.id
                                          v_source3_processedimage.save  
                                          v_source3_file_id = v_source3_processedimage.id
                                      else
                                          v_source3_processesimage = v_source3_processesimages.first
                                          v_source3_file_id = v_source3_processesimage.id   
                                      end
          
                                      v_source3_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'processedimage'",v_source2_file_id,v_source3_file_id)
                                      if v_source3_processedimagesources.count < 1
                                          v_source3_processedimagesource = Processedimagessource.new
                                          v_source3_processedimagesource.file_name = v_source3_file
                                          v_source3_processedimagesource.file_path = v_source3_file_full_path
                                          v_source3_processedimagesource.source_image_id = v_source3_file_id
                                          v_source3_processedimagesource.source_image_type = 'processedimage'
                                          v_source3_processedimagesource.processedimage_id= v_source2_file_id
                                          v_source3_processedimagesource.save

                                      else
                                          v_source3_processedimagesource = v_source3_processedimagesources.first
                                      end
                                      # get the image_dataset of the T1 CHANGE THE IMAGE TYPE / look in LOG   T1 vs T2??? 
                                      v_image_datasets = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%/"+v_t1_scan_series_dir+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                            # looking for ...%/003 == 003 vs ...%003 ==> 003 and 40003 - processed t1 - same type   
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_last2 = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%"+v_t1_scan_series_dir_2words+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_last2.count > 0 and v_image_datasets_last2.count < 2
                                                v_image_datasets = v_image_datasets_last2
                                             end
                                       end
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_waisman_flip = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))
                                                              and image_datasets.path like '%"+v_t1_scan_series_dir_waisman_flip+"'",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_waisman_flip.count > 0 and v_image_datasets_waisman_flip.count < 2
                                                v_image_datasets = v_image_datasets_waisman_flip
                                             end
                                       end
                                      if v_image_datasets.count > 1  or v_image_datasets.count < 1 # try last 2 parts of array
                                             v_image_datasets_type_limit = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits, appointments, enrollment_vgroup_memberships, scan_procedures_vgroups 
                                                             where visits.appointment_id = appointments.id 
                                                             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.vgroup_id = appointments.vgroup_id
                                                             and scan_procedures_vgroups.scan_procedure_id in (?) 
                                                             and enrollment_vgroup_memberships.enrollment_id in (?) )
                                                             and image_datasets.series_description in 
                                                              (select series_description_maps.series_description from series_description_maps where 
                                                                   series_description_maps.series_description_type_id in (?))",sp.id, v_enrollment.id, v_t1_series_description_type_id)
                                             if v_image_datasets_type_limit.count > 0 and v_image_datasets_type_limit.count < 2
                                                v_image_datasets = v_image_datasets_type_limit
                                             end
                                       end

                                      if v_image_datasets.count > 0 and v_image_datasets.count < 2
                                         v_image_dataset = v_image_datasets.first
                                         v_source4_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'image_dataset'",v_source3_file_id,v_image_dataset.id)
                                         if v_source4_processedimagesources.count < 1
                                             v_source4_processedimagesource = Processedimagessource.new
                                             v_source4_processedimagesource.file_name = v_image_dataset.scanned_file
                                             v_source4_processedimagesource.file_path = v_image_dataset.path
                                             v_source4_processedimagesource.source_image_id = v_image_dataset.id
                                             v_source4_processedimagesource.source_image_type = 'image_dataset'
                                             v_source4_processedimagesource.processedimage_id= v_source3_file_id
                                             v_source4_processedimagesource.save

                                        else
                                            v_source4_processedimagesource = v_source4_processedimagesources.first
                                        end
                                      elsif v_image_datasets.count > 1
                                        #puts "multiples ids found"
                                        v_image_datasets.each do |ids|
                                           puts "t1 ids multiple="+ids.id.to_s
                                        end
                                      else
                                        puts " ids not found"
                                      end 
                                   end # unknown o loop
                                end # tissue seg mo loop
                             end # loop thru y_o in asl dir
                          end # loop thru swrASL_fmap files - this is the final ASL processing product
                      end # check if this subjectid proprocessed exists and that subjectid is an enumber
                  ####end # TEMPORARY LIMIT TO one subjectid
                end # loop thru all subjectid in raw -- used to look at preporcessed
              end #check if preprocessed exists
          end #check if raw exists                      
      end # sp loop                          

      if !v_comment.include?("ERROR")
            @schedulerun.status_flag ="Y"
      else
          @schedulerun.comment ="Suceess ;"+@schedulerun.comment
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save
  end
 
  # data request from seller, wrap , resting bold/fmri and t1 volumetric,pib, fdg johnson.prodict.visit1
  # from cg_selley_pdt_pet_mri 
  # done_flag = Y means the files has been uploaded
  # status_flag = N means do not upload this subjectid
  def run_selley_20130906_upload
    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "selley_20130906_upload"
    process_logs_delete_old( v_process_name, v_log_base)
     @schedule = Schedule.where("name in ('selley_20130906_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting selley_20130906_upload -MOVED TO SHARED_RETIRED.rb"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
     
  end
 
 # messy - a series_description table with id- legacy, and a series_description_maps table with just description
  def run_series_description
      v_base_path = Shared.get_base_path()
      @schedule = Schedule.where("name in ('series_description')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting series_description"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_computer = "kanga"
      sql_insert_base = "Insert into series_description_maps(series_description) values("
      sql = "select distinct image_datasets.series_description from image_datasets 
           where image_datasets.series_description not in (select series_description_maps.series_description from series_description_maps)"
      connection = ActiveRecord::Base.connection();        
      results = connection.execute(sql)
      v_cnt = 0
      v_series_description_listing = ""
      results.each do |r|
          v_cnt = v_cnt + 1
          v_series_description_listing  = v_series_description_listing +r[0]+"\n"
          sql_insert = sql_insert_base+"'"+r[0]+"')"
          results_insert = connection.execute(sql_insert)
      end
      if v_cnt > 0
          v_comment = v_comment + "There were "+v_cnt.to_s+" new series descriptions\n"+v_series_description_listing
      else
          v_comment = v_comment + "There were "+v_cnt.to_s+" new series descriptions\n"
      end
            sql_insert_base = "Insert into series_descriptions(long_description) values("
      sql = "select distinct image_datasets.series_description from image_datasets 
           where image_datasets.series_description not in (select series_descriptions.long_description from series_descriptions)"
      connection = ActiveRecord::Base.connection();        
      results = connection.execute(sql)
      v_cnt = 0
      v_series_description_listing = ""
      results.each do |r|
          v_cnt = v_cnt + 1
          v_series_description_listing  = v_series_description_listing +r[0]+"\n"
          sql_insert = sql_insert_base+"'"+r[0]+"')"
          results_insert = connection.execute(sql_insert)
      end
      
      sql = "select count(distinct image_datasets.series_description) from image_datasets 
           where image_datasets.series_description not in (select series_description_maps.series_description from series_description_maps where series_description_maps.series_description_type_id is NULL)"
      results = connection.execute(sql)
      v_comment = "\n"+results.first.to_s+" un-categorized series descriptions \n"+v_comment
      puts "successful finish series_description harvest' "+v_comment[0..1459]
      @schedulerun.comment =("successful finish series_description harvest, starting count harvest' "+v_comment[0..1459])
      # exclduing pfiles
       sql = "select spvg.scan_procedure_id, series_descriptions.id series_description_id, count(ids.id),count(distinct a.vgroup_id)
            from series_descriptions , scan_procedures_vgroups spvg, image_datasets ids, visits v, appointments a,
            vgroups vg
            where a.id = v.appointment_id  and v.id = ids.visit_id  and a.vgroup_id = vg.id
            and vg.transfer_mri ='yes' and a.appointment_type = 'mri' and ids.scanned_file not like 'P%'
            and a.vgroup_id = spvg.vgroup_id and trim(series_descriptions.long_description) = trim(ids.series_description)
            group by spvg.scan_procedure_id, series_description_id"
      results = connection.execute(sql)
      if results.count > 0  
          sql_truncate = "truncate table series_description_scan_procedures"
          results_truncate = connection.execute(sql_truncate)
          results.each do |r|
             v_new = SeriesDescriptionScanProcedure.new
             v_new.scan_procedure_id = r[0]
             v_new.series_description_id = r[1]
             v_new.scan_count = r[2]
             v_new.scan_count_all = r[3]
             v_new.scan_count_last_20 = 0
             v_new.scan_count_last_5 = 0
             # run scan_count_20
            sql_20 = "select a_spvg.scan_procedure_id, series_descriptions.id series_description_id, count(distinct a_spvg.vgroup_id)
            from series_descriptions , image_datasets ids, visits v, 
            ( SELECT appointments.vgroup_id, appointments.id, scan_procedures_vgroups.scan_procedure_id FROM appointments, scan_procedures_vgroups ,vgroups vg 
             where  appointments.vgroup_id =  scan_procedures_vgroups.vgroup_id and appointments.vgroup_id = vg.id
            and vg.transfer_mri ='yes' and appointments.appointment_type = 'mri'
             and scan_procedures_vgroups.scan_procedure_id = "+r[0].to_s+"
             ORDER BY appointments.appointment_date  DESC LIMIT 20) a_spvg
              where a_spvg.id = v.appointment_id and v.id = ids.visit_id
              and series_descriptions.id ="+r[1].to_s+"
              and trim(series_descriptions.long_description) = trim(ids.series_description)
                group by a_spvg.scan_procedure_id, series_description_id"
             results_20 = connection.execute(sql_20)
             results_20.each do |r_20|
                    v_new.scan_count_last_20 = r_20[2]
             end
             #run scan_count_5
          sql_5 = "select a_spvg.scan_procedure_id, series_descriptions.id series_description_id, count(distinct a_spvg.vgroup_id)
            from series_descriptions , image_datasets ids, visits v, 
            ( SELECT appointments.vgroup_id, appointments.id, scan_procedures_vgroups.scan_procedure_id FROM appointments, scan_procedures_vgroups,vgroups vg  
             where  appointments.vgroup_id =  scan_procedures_vgroups.vgroup_id  and appointments.vgroup_id = vg.id
            and vg.transfer_mri ='yes' and appointments.appointment_type = 'mri'
             and scan_procedures_vgroups.scan_procedure_id = "+r[0].to_s+"
             ORDER BY appointments.appointment_date  DESC LIMIT 5) a_spvg
              where a_spvg.id = v.appointment_id and v.id = ids.visit_id
              and series_descriptions.id ="+r[1].to_s+"
              and trim(series_descriptions.long_description) = trim(ids.series_description)
                group by a_spvg.scan_procedure_id, series_description_id"
             results_5 = connection.execute(sql_5)
             results_5.each do |r_5|
                    v_new.scan_count_last_5 = r_5[2]
             end
             v_new.save
          end
      end

      if !v_comment.include?("ERROR")
            @schedulerun.status_flag ="Y"
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save

   end   

   def run_test
          v_return = self.check_ids_for_severe_or_incomplete(10708)
          puts "aaaaaaa vid=894, ids=10708 "+v_return

        v_return = self.check_ids_for_severe_or_incomplete(49790)
          puts "bbb vid=2861, ids=49790 "+v_return



   end  
          
   # generates sp|scanner_protocol file for use in transfer_process.py
   # reads dicom headers from scanns in last 400 days, excludes - hard codes- some erroneous pairs
   def run_sp_scanner_protocol
     
     v_shared = Shared.new
     v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('sp_scanner_protocol')").first
     @schedulerun = Schedulerun.new
     @schedulerun.schedule_id = @schedule.id
     @schedulerun.comment ="starting sp_scanner_protocol"
     @schedulerun.save
     @schedulerun.start_time = @schedulerun.created_at
     @schedulerun.save    
     v_insert_codename_scanner_protocol_base ="insert into t_sp_scanner_protocol(codename,scanner_protocol)" 
     v_dir_path = v_base_path+"/analyses/panda/sp_scanner_protocol/" 
     v_comment = ""
     v_comment_error = ""  
     v_computer = "kanga" 
     # tried to use cg_table with cg_edit, but think there are subjectid/key etc issues
     # would use cg_edit to delete bad sp/scanner_protocol
     v_bad_sp_scanner_protocol_pair_array = ["asthana.adrc-clinical-core.visit2|ADNI2_GE_3T_22.0_E_DTI","bendlin.dzne.visit1|PREDICT-2"]
     connection = ActiveRecord::Base.connection();
     begin   # catch all exception and put error in comment 
       # truncate and populate table
         v_t_sp_scanner_protocol_cnt_old = 1  
         sql = "select count(*) from t_sp_scanner_protocol" 
         results = connection.execute(sql)   
         results.each do |r|
              v_t_sp_scanner_protocol_cnt_old =  r[0]
         end
         sql = "truncate table t_sp_scanner_protocol"       
         results = connection.execute(sql)  
        sql = "select distinct sp.codename,  vg2.id vg_id, v.id visit_id
        from scan_procedures sp, scan_procedures_vgroups spg,  vgroups vg2 , appointments a, visits v
        where sp.id = spg.scan_procedure_id
        and  vg2.id = spg.vgroup_id
        and vg2.transfer_mri ='yes' 
        and vg2.id = a.vgroup_id
        and a.id = v.appointment_id  
        and vg2.vgroup_date >  adddate(curdate(),'-400') 
        and spg.scan_procedure_id in (select spg2.scan_procedure_id from scan_procedures_vgroups spg2, vgroups vg
                                          where vg.id=spg2.vgroup_id and vg.vgroup_date >  adddate(curdate(),'-400') )
        order by sp.codename, visit_id"        
        results = connection.execute(sql)  

       #0018,1030	Protocol Name
       v_codename = "" 
       v_scanner_protocol_array = []
       # loop thru mri visits
       # each new codename, insert old v_scanner_protocol_array, start new v_scanner_protocol_array
       results.each do |r| 
           #puts " visit codename="+r[0]+"visit_id="+r[2].to_s
           if v_codename != r[0]
               if  v_scanner_protocol_array.length > 0  
                    v_scanner_protocol_array.each do |scanner_protocol|
                         v_insert_codename_scanner_protocol = v_insert_codename_scanner_protocol_base +"values('"+v_codename+"','"+scanner_protocol+"')"
                         results_insert = connection.execute(v_insert_codename_scanner_protocol) 
                    end
               end 
               v_codename = r[0] 
               #puts "NEW v_codename ="+v_codename
               v_scanner_protocol_array.clear
            end
            image_datasets = ImageDataset.where("image_datasets.visit_id in (?)",r[2])   
            v_scanner_protocol = ""
            image_datasets.each do |dataset|
 	             if tags = dataset.dicom_taghash and v_scanner_protocol =="" and  !tags['0018,1030'].blank? and tags['0018,1030'] != '0018,1030' 
 	               begin
 	                v_scanner_protocol = tags['0018,1030'][:value] unless tags['0018,1030'][:value].blank? 
 	                #puts "scanner_protocol ="+v_scanner_protocol 
 	                rescue Exception => msg 
 	                   v_error = msg.to_s 
 	                   puts "ERROR ids !!!!!!!"+"visit_id="+r[2].to_s
                     puts v_error
 	                end
 	             end
 	           end  
 	           if !v_scanner_protocol_array.include?(v_scanner_protocol) and  !v_bad_sp_scanner_protocol_pair_array.include?(v_codename+"|"+v_scanner_protocol)
 	             v_scanner_protocol_array.push(v_scanner_protocol)
 	           end
         end  
         sql = "select count(*) from t_sp_scanner_protocol" 
         results = connection.execute(sql) 
         v_t_sp_scanner_protocol_cnt_new = 0  
         results.each do |r|
              v_t_sp_scanner_protocol_cnt_new =  r[0]
         end  
         if (v_t_sp_scanner_protocol_cnt_new*2) >v_t_sp_scanner_protocol_cnt_old
            sql = "select codename, scanner_protocol from t_sp_scanner_protocol order by codename"   
            results = connection.execute(sql) 
            v_file = v_dir_path+"sp_scanner_protocol.txt"
            File.open(v_file, "w+") do |f|   
                results.each do |rc|
                  f.write(rc[0]+"|"+rc[1]+"\n")
               # write a tab separated row
                end
              end 
          else
              @schedulerun.status_flag ="E"
              v_comment_error ="New scanner protocol list is too small!!! "
          end
         @schedulerun.comment =v_comment_error+" successful finish sp_scanner_protocol"
         @schedulerun.status_flag ="Y"
         @schedulerun.save
         @schedulerun.end_time = @schedulerun.updated_at      
         @schedulerun.save
       rescue Exception => msg
          v_error = msg.to_s
          puts "ERROR !!!!!!!"
          puts v_error
           @schedulerun.comment =v_error[0..499]
           @schedulerun.status_flag="E"
           @schedulerun.save
       end     
     
   end
   
    
  # to add columns --
  # change sql_base insert statement
  # change  sql = sql_base+  insert statement with values
  # change  self.move_present_to_old_new_to_present  
  # getting t1_seg seg totals 
  # also getting first calculated volumes into cg_first_calculated_volumes
  def run_t1seg_status
        v_base_path = Shared.get_base_path()
         @schedule = Schedule.where("name in ('t1seg_status')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting t1seg_status and first calculated volumes"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_computer = "kanga"
          v_comment = ""
    ####    begin   # catch all exception and put error in comment    
            sql = "truncate table cg_t1seg_status_new"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)
            sql = "truncate table cg_t1seg_status_new"
            connection = ActiveRecord::Base.connection();   
            sql = "truncate table cg_first_calculated_volumes_new"
            connection = ActiveRecord::Base.connection();       
            results = connection.execute(sql)
            v_comment_base = @schedulerun.comment
            sql_base = "insert into cg_t1seg_status_new(t1seg_subjectid, t1seg_general_comment,t1seg_smoothed_and_warped_flag,o_star_nii_flag,multiple_o_star_nii_flag,enrollment_id, scan_procedure_id,gm,wm,csf,secondary_key)values("  
            sql_first_base = "insert into cg_first_calculated_volumes_new(subjectid,general_comment,enrollment_id, scan_procedure_id,secondary_key,l_accu_mm_cube,l_amyg_mm_cube,l_caud_mm_cube,l_hipp_mm_cube,l_pall_mm_cube,l_puta_mm_cube,l_thal_mm_cube,r_accu_mm_cube,r_amyg_mm_cube,r_caud_mm_cube,r_hipp_mm_cube,r_pall_mm_cube,r_puta_mm_cube,r_thal_mm_cube)values("  
            v_raw_path = v_base_path+"/raw"
            v_mri = "/mri"
            no_mri_path_sp_list =['asthana.adrc-clinical-core.visit1',
            'bendlin.mets.visit1','bendlin.tami.visit1','bendlin.wmad.visit1','carlson.sharp.visit1','carlson.sharp.visit2',
            'carlson.sharp.visit3','carlson.sharp.visit4','dempsey.plaque.visit1','dempsey.plaque.visit2','gleason.falls.visit1',
            'johnson.merit220.visit1','johnson.merit220.visit2','johnson.tbi.aware.visit3','johnson.tbi-va.visit1','ries.aware.visit1','wrap140']

            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            # get list of scan_procedure codename -- exclude 4, 10, 15, 19, 32, 
                # ??? johnson.pc vs johnsonpc4000.visit1 vs pc_4000
                # ??? johnson.tbi10000 vs johnson.tbiaware vs tbi_1000
                # ??? johnson.wrap140.visit1 vs wrap140.visit1 vs wrap140
                # NOT exists /Volumes/team-1/raw/carlson.esprit/mri
                # NOT exists /Volumes/team-1/raw/johnson.wrap140.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbiaware.visit3/mri
                # NOT exists /Volumes/team-1/raw/johnson.tbi1000.visit2/mri
                # NOT exists /Volumes/team-1/raw/johnnson.alz.repsup.visit1/mri
                # NOT exists /Volumes/team-1/raw/johnson.pc4000.visit1/mri
            v_exclude_sp =[4,10,15,19,32,53,54,55,56,57]
            @scan_procedures = ScanProcedure.where("id not in (?)",v_exclude_sp)
            @scan_procedures.each do |sp|
              @schedulerun.comment = "start "+sp.codename+" "+v_comment_base
              @schedulerun.save
              v_visit_number =""
              if sp.codename.include?("visit2")
                v_visit_number ="_v2"
              elsif sp.codename.include?("visit3")
                v_visit_number ="_v3"
              elsif sp.codename.include?("visit4")
                v_visit_number ="_v4"
              elsif sp.codename.include?("visit5")
                v_visit_number ="_v5"
              end
               if no_mri_path_sp_list.include?(sp.codename)
                 v_mri = ""
                else
                  v_mri = "/mri"
                end
                v_raw_full_path = v_raw_path+"/"+sp.codename+v_mri
                v_preprocessed_full_path = v_preprocessed_path+sp.codename
                if File.directory?(v_raw_full_path)
                    if !File.directory?(v_preprocessed_full_path)
                        puts "preprocessed path NOT exists "+v_preprocessed_full_path
                     end
                    Dir.entries(v_raw_full_path).select { |file| File.directory? File.join(v_raw_full_path, file)}.each do |dir|
                      dir_name_array = dir.split('_')
                      if dir_name_array.size == 3 
                         enrollment = Enrollment.where("enumber in (?)",dir_name_array[0])
                         if !enrollment.blank?
                             @schedulerun.comment = "start "+dir_name_array[0]+" "+sp.codename+" "+v_comment_base
                             @schedulerun.save
                             v_subjectid_t1seg = v_preprocessed_full_path+"/"+dir_name_array[0]+"/t1_aligned_newseg"
                             v_subjectid_first = v_preprocessed_full_path+"/"+dir_name_array[0]+"/first"
                             v_subjectid_unknown = v_preprocessed_full_path+"/"+dir_name_array[0]+"/unknown"
                             if File.directory?(v_subjectid_first)
                                  v_first_volume_hash = {}
                                  v_dir_array = Dir.entries(v_subjectid_first)
                                  v_dir_array.each do |f|
                                     if f == dir_name_array[0]+"_first_roi_vol.csv"  #  two row in file, comma sep, first row header
                                         v_tmp_data = "" 
                                         v_tmp_header_data = ""
                                         v_tmp_data_array = []  
                                         v_tmp_header_data_array = []
                                         ftxt = File.open(v_subjectid_first+"/"+dir_name_array[0]+"_first_roi_vol.csv", "r") 
                                         v_tmp_cnt = 0
                                         ftxt.each_line do |line|
                                              if v_tmp_cnt < 1
                                                  v_tmp_header_data = line
                                              else
                                                  v_tmp_data += line
                                              end
                                              v_tmp_cnt = v_tmp_cnt + 1
                                         end
                                         ftxt.close
                                         v_tmp_header_data_array = v_tmp_header_data.strip.split(",")
                                         v_tmp_data_array = v_tmp_data.strip.split(",")
                                         if v_tmp_data_array.length >2 and v_tmp_header_data_array.length > 2
                                             v_tmp_cnt = 0
                                             v_tmp_header_data_array.each do |hdr|
                                               v_first_volume_hash[hdr.downcase] = v_tmp_data_array[v_tmp_cnt]
                                               v_tmp_cnt = v_tmp_cnt + 1
                                             end 
                                  #l_accu_mm_cube,  l_amyg_mm_cube,l_caud_mm_cube ,l_hipp_mm_cube,l_pall_mm_cube,l_puta_mm_cube,  l_thal_mm_cube ,r_accu_mm_cube ,r_amyg_mm_cube,r_caud_mm_cube, r_hipp_mm_cube,r_pall_mm_cube,    r_puta_mm_cube,r_thal_mm_cube
                                           sql = sql_first_base+"'"+dir_name_array[0]+v_visit_number+"','',"+enrollment[0].id.to_s+","+sp.id.to_s+",null
                                             ,'"+v_first_volume_hash["l_accu"]+"','"+v_first_volume_hash["l_amyg"]+"','"+v_first_volume_hash["l_caud"]+"','"+v_first_volume_hash["l_hipp"]+"','"+v_first_volume_hash["l_pall"]+"'
                                            ,'"+v_first_volume_hash["l_puta"]+"','"+v_first_volume_hash["l_thal"]+"','"+v_first_volume_hash["r_accu"]+"','"+v_first_volume_hash["r_amyg"]+"','"+v_first_volume_hash["r_caud"]+"'
                                            ,'"+v_first_volume_hash["r_hipp"]+"','"+v_first_volume_hash["r_pall"]+"','"+v_first_volume_hash["r_puta"]+"','"+v_first_volume_hash['r_thal']+"')"
                                            results = connection.execute(sql)
                                          end

                                     end
                                  end
                                  if v_first_volume_hash.length < 1
                                       sql = sql_first_base+"'"+dir_name_array[0]+v_visit_number+"','no calculated volumes in first directory',"+enrollment[0].id.to_s+","+sp.id.to_s+",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)"
                                       results = connection.execute(sql)
                                  end
                             else
                               sql = sql_first_base+"'"+dir_name_array[0]+v_visit_number+"','no first calculated volumes directory',"+enrollment[0].id.to_s+","+sp.id.to_s+",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)"
                                 results = connection.execute(sql)
                             end


                             v_o_star_nii_flag ="N"
                             v_multiple_o_star_nii_flag ="N"
                             v_gm =""
                             v_wm = ""
                             v_csf = ""
                             if File.directory?(v_subjectid_t1seg)
                                  v_dir_array = Dir.entries(v_subjectid_t1seg)   # need to get date for specific files
                                  # evalute for t1seg_ac_pc_flag = rFS_t1seg_[subjectid]_fmap.nii ,
                                  # t1seg_smoothed_and_warped_flag = swrFS_t1seg_[subjectid]_fmap.nii,
                                  # t1seg_fmap_flag = [t1seg_[subjectid]_[sdir]_fmap.nii or t1seg_[subjectid]_fmap.nii],
                                  # t1seg_fmap_single = t1seg_[subjectid]_fmap.nii
                                v_t1seg_ac_pc_flag ="N"
                                v_t1seg_smoothed_and_warped_flag = "N"
                                v_dir_array.each do |f|
                                  if f.start_with?("smwc1o"+dir_name_array[0])  and f.end_with?(".nii")
                                    v_t1seg_smoothed_and_warped_flag = "Y"
                                  end
                                  if f == "segtotals.txt"  #  one row in file, comma sep
                                     v_tmp_data = "" 
                                     v_tmp_data_array = []  
                                     ftxt = File.open(v_subjectid_t1seg+"/segtotals.txt", "r") 
                                     ftxt.each_line do |line|
                                        v_tmp_data += line
                                     end
                                     ftxt.close

                                     v_tmp_data_array = v_tmp_data.strip.split(",")
                                     if v_tmp_data_array.length >2
                                        v_gm =v_tmp_data_array[0]
                                        v_wm  = v_tmp_data_array[1]
                                        v_csf = v_tmp_data_array[2]
                                     end
                                  end
                                end
                                if File.directory?(v_subjectid_unknown)
                                  v_dir_array = Dir.entries(v_subjectid_unknown)
                                  v_o_star_nii_flag ="N"
                                  v_multiple_o_star_nii_flag ="N"
                                  v_o_star_cnt = 0
                                  v_dir_array.each do |f|
                                    if f.start_with?("o") and f.end_with?(".nii")
                                      v_o_star_nii_flag = "Y"
                                      v_o_star_cnt = v_o_star_cnt+ 1
                                      if v_o_star_cnt > 1
                                        v_multiple_o_star_nii_flag ="Y"
                                      end
                                    end
                                  end
                                end
                                
                                sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','','"+v_t1seg_smoothed_and_warped_flag+"','"+ v_o_star_nii_flag+"','"+v_multiple_o_star_nii_flag+"',"+enrollment[0].id.to_s+","+sp.id.to_s+",'"+v_gm+"','"+v_wm+"','"+v_csf+"',null)"
                                 results = connection.execute(sql)
                             else
                              if File.directory?(v_subjectid_unknown)
                                  v_dir_array = Dir.entries(v_subjectid_unknown)
                                  v_o_star_nii_flag ="N"
                                  v_multiple_o_star_nii_flag ="N"
                                  v_o_star_cnt = 0
                                  v_dir_array.each do |f|
                                    if f.start_with?("o") and f.end_with?(".nii")
                                      v_o_star_nii_flag = "Y"
                                      v_o_star_cnt = v_o_star_cnt+ 1
                                      if v_o_star_cnt > 1
                                        v_multiple_o_star_nii_flag ="Y"
                                      end
                                    end
                                  end
                                  sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','no t1_aligned_newseg dir','N','"+ v_o_star_nii_flag+"','N',"+enrollment[0].id.to_s+","+sp.id.to_s+",NULL,NULL,NULL,NULL)"
                                 results = connection.execute(sql)
                                else
                                 sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','no t1_aligned_newseg dir','N','N','N',"+enrollment[0].id.to_s+","+sp.id.to_s+",NULL,NULL,NULL,NULL)"
                                 results = connection.execute(sql)
                                end
                             end # check for subjectid t1 dir

                         else
                           #puts "no enrollment "+dir_name_array[0]
                         end # check for enrollment
                         ### GO BACK FOR THE .R, b, c, d, e's
                         enrollment = Enrollment.where("concat(enumber,'.R') in (?) or concat(enumber,'a') in (?) or concat(enumber,'b') in (?) or concat(enumber,'c') in (?) or concat(enumber,'d') in (?) or concat(enumber,'e') in (?)",dir_name_array[0],dir_name_array[0],dir_name_array[0],dir_name_array[0],dir_name_array[0],dir_name_array[0])
                         if !enrollment.blank?
                             v_secondary_key = dir_name_array[0]
                             v_secondary_key = v_secondary_key.tr(enrollment[0].enumber, "") 
                             v_subjectid_t1seg = v_preprocessed_full_path+"/"+dir_name_array[0]+"/t1_aligned_newseg"
                             v_subjectid_first = v_preprocessed_full_path+"/"+dir_name_array[0]+"/first"
                             v_subjectid_unknown = v_preprocessed_full_path+"/"+dir_name_array[0]+"/unknown"
                             v_o_star_nii_flag ="N"
                             v_multiple_o_star_nii_flag ="N"
                             v_gm =""
                             v_wm = ""
                             v_csf = ""
                             if File.directory?(v_subjectid_first)
                                  v_first_volume_hash = {}
                                  v_dir_array = Dir.entries(v_subjectid_first)
                                  v_dir_array.each do |f|
                                     if f == dir_name_array[0]+"_first_roi_vol.csv"  #  two row in file, comma sep, first row header
                                         v_tmp_data = "" 
                                         v_tmp_header_data = ""
                                         v_tmp_data_array = []  
                                         v_tmp_header_data_array = []
                                         ftxt = File.open(v_subjectid_first+"/"+dir_name_array[0]+"_first_roi_vol.csv", "r") 
                                         v_tmp_cnt = 0
                                         ftxt.each_line do |line|
                                              if v_tmp_cnt < 1
                                                  v_tmp_header_data = line
                                              else
                                                  v_tmp_data += line
                                              end
                                              v_tmp_cnt = v_tmp_cnt + 1
                                         end
                                         ftxt.close
                                         v_tmp_header_data_array = v_tmp_header_data.strip.split(",")
                                         v_tmp_data_array = v_tmp_data.strip.split(",")
                                         if v_tmp_data_array.length >2 and v_tmp_header_data_array.length > 2
                                             v_tmp_cnt = 0
                                             v_tmp_header_data_array.each do |hdr|
                                               v_first_volume_hash[hdr.downcase] = v_tmp_data_array[v_tmp_cnt]
                                               v_tmp_cnt = v_tmp_cnt + 1
                                             end
                                  #l_accu,  l_amyg,l_caud ,l_hipp,l_pall,l_puta,  l_thal ,r_accu ,r_amyg,r_caud, r_hipp,r_pall,    r_puta,r_thal
                                            sql = sql_first_base+"'"+enrollment[0].enumber+v_visit_number+"','',"+enrollment[0].id.to_s+","+sp.id.to_s+",'"+v_secondary_key+"'
                                             ,'"+v_first_volume_hash["l_accu"]+"','"+v_first_volume_hash["l_amyg"]+"','"+v_first_volume_hash["l_caud"]+"','"+v_first_volume_hash["l_hipp"]+"','"+v_first_volume_hash["l_pall"]+"'
                                             ,'"+v_first_volume_hash["l_puta"]+"','"+v_first_volume_hash["l_thal"]+"','"+v_first_volume_hash["r_accu"]+"','"+v_first_volume_hash["r_amyg"]+"','"+v_first_volume_hash["r_caud"]+"'
                                            ,'"+v_first_volume_hash["r_hipp"]+"','"+v_first_volume_hash["r_pall"]+"','"+v_first_volume_hash["r_puta"]+"','"+v_first_volume_hash["r_thal"]+"')"
                                            results = connection.execute(sql)
                                          end

                                     end
                                  end
                                  if v_first_volume_hash.length < 1
                                       sql = sql_first_base+"'"+enrollment[0].enumber+v_visit_number+"','no calculated volumes in first directory',"+enrollment[0].id.to_s+","+sp.id.to_s+",'"+v_secondary_key+"',null,null,null,null,null,null,null,null,null,null,null,null,null,null)"
                                       results = connection.execute(sql)
                                  end
                             else
                               sql = sql_first_base+"'"+enrollment[0].enumber+v_visit_number+"','no first calculated volumes directory',"+enrollment[0].id.to_s+","+sp.id.to_s+",'"+v_secondary_key+"',null,null,null,null,null,null,null,null,null,null,null,null,null,null)"
                                 results = connection.execute(sql)
                             end
                             if File.directory?(v_subjectid_t1seg)
                                  v_dir_array = Dir.entries(v_subjectid_t1seg)   # need to get date for specific files
                                  # evalute for t1seg_ac_pc_flag = rFS_t1seg_[subjectid]_fmap.nii ,
                                  # t1seg_smoothed_and_warped_flag = swrFS_t1seg_[subjectid]_fmap.nii,
                                  # t1seg_fmap_flag = [t1seg_[subjectid]_[sdir]_fmap.nii or t1seg_[subjectid]_fmap.nii],
                                  # t1seg_fmap_single = t1seg_[subjectid]_fmap.nii
                                v_t1seg_ac_pc_flag ="N"
                                v_t1seg_smoothed_and_warped_flag = "N"
                                v_dir_array.each do |f|
                                  if f.start_with?("smwc1o"+dir_name_array[0])  and f.end_with?(".nii")
                                    v_t1seg_smoothed_and_warped_flag = "Y"
                                  end
                                  if f == "segtotals.txt"  #  one row in file, comma sep
                                     v_tmp_data = "" 
                                     v_tmp_data_array = []  
                                     ftxt = File.open(v_subjectid_t1seg+"/segtotals.txt", "r") 
                                     ftxt.each_line do |line|
                                        v_tmp_data += line
                                     end
                                     ftxt.close

                                     v_tmp_data_array = v_tmp_data.strip.split(",")
                                     if v_tmp_data_array.length >2
                                        v_gm =v_tmp_data_array[0]
                                        v_wm  = v_tmp_data_array[1]
                                        v_csf = v_tmp_data_array[2]
                                     end
                                  end
                                end
                                if File.directory?(v_subjectid_unknown)
                                  v_dir_array = Dir.entries(v_subjectid_unknown)
                                  v_o_star_nii_flag ="N"
                                  v_multiple_o_star_nii_flag ="N"
                                  v_o_star_cnt = 0
                                  v_dir_array.each do |f|
                                    if f.start_with?("o") and f.end_with?(".nii")
                                      v_o_star_nii_flag = "Y"
                                      v_o_star_cnt = v_o_star_cnt+ 1
                                      if v_o_star_cnt > 1
                                        v_multiple_o_star_nii_flag ="Y"
                                      end
                                    end
                                  end
                                end
                                
                                sql = sql_base+"'"+enrollment[0].enumber+v_visit_number+"','','"+v_t1seg_smoothed_and_warped_flag+"','"+ v_o_star_nii_flag+"','"+v_multiple_o_star_nii_flag+"',"+enrollment[0].id.to_s+","+sp.id.to_s+",'"+v_gm+"','"+v_wm+"','"+v_csf+"','"+v_secondary_key+"')"
                                 results = connection.execute(sql)
                             else
                              if File.directory?(v_subjectid_unknown)
                                  v_dir_array = Dir.entries(v_subjectid_unknown)
                                  v_o_star_nii_flag ="N"
                                  v_multiple_o_star_nii_flag ="N"
                                  v_o_star_cnt = 0
                                  v_dir_array.each do |f|
                                    if f.start_with?("o") and f.end_with?(".nii")
                                      v_o_star_nii_flag = "Y"
                                      v_o_star_cnt = v_o_star_cnt+ 1
                                      if v_o_star_cnt > 1
                                        v_multiple_o_star_nii_flag ="Y"
                                      end
                                    end
                                  end
                                  sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','no t1_aligned_newseg dir','N','"+ v_o_star_nii_flag+"','N',"+enrollment[0].id.to_s+","+sp.id.to_s+",NULL,NULL,NULL,'"+v_secondary_key+"')"
                                 results = connection.execute(sql)
                                else
                                 sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','no t1_aligned_newseg dir','N','N','N',"+enrollment[0].id.to_s+","+sp.id.to_s+",NULL,NULL,NULL,'"+v_secondary_key+"')"
                                 results = connection.execute(sql)
                                end
                             end # check for subjectid asl dir
                         else
                           #puts "no enrollment "+dir_name_array[0]
                         end # check for enrollment
                      end # check that dir name is in expected format [subjectid]_exam#_MMDDYY - just test size of array
                    end # loop thru the subjectids
                 else
                        #puts "               # NOT exists "+v_raw_full_path
                 end # check if raw dir exisits
            end            
            # check move cg_ to cg_old
            # v_shared = Shared.new 
             # move from new to present table -- made into a function  in shared model
             v_comment = self.move_present_to_old_new_to_present("cg_t1seg_status",
             "t1seg_subjectid, t1seg_general_comment, t1seg_smoothed_and_warped_flag, t1seg_smoothed_and_warped_comment, t1seg_smoothed_and_warped_global_quality,o_star_nii_flag,multiple_o_star_nii_flag,enrollment_id,scan_procedure_id,gm,wm,csf,secondary_key",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)
             # apply edits  -- made into a function  in shared model
             self.apply_cg_edits('cg_t1seg_status')

             # not sure why blank rows accumulating 
             sql = "delete from cg_first_calculated_volumes where l_accu_mm_cube is null and subjectid in 
                        (select subjectid from cg_first_calculated_volumes_new where l_accu_mm_cube is not null)"
             results = connection.execute(sql)

             v_comment = self.move_present_to_old_new_to_present("cg_first_calculated_volumes",
             "subjectid, general_comment,enrollment_id,scan_procedure_id,secondary_key,l_accu_mm_cube,l_amyg_mm_cube,l_caud_mm_cube,l_hipp_mm_cube,l_pall_mm_cube,l_puta_mm_cube,l_thal_mm_cube,r_accu_mm_cube,r_amyg_mm_cube,r_caud_mm_cube,r_hipp_mm_cube,r_pall_mm_cube,r_puta_mm_cube,r_thal_mm_cube",
                            "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)
             # apply edits  -- made into a function  in shared model
             self.apply_cg_edits('cg_first_calculated_volumes')

             puts "successful finish t1seg_status and first calculated volumes"+v_comment[0..459]
              @schedulerun.comment =("successful finish t1seg_status  and first calculated volumes"+v_comment[0..459])
              if !v_comment.include?("ERROR")
                 @schedulerun.status_flag ="Y"
               end
               @schedulerun.save
               @schedulerun.end_time = @schedulerun.updated_at      
               @schedulerun.save
    ####    rescue Exception => msg
    ####         v_error = msg.to_s
    ####         puts "ERROR !!!!!!!"
    ####         puts v_error
    ####         v_error = v_error+"\n"+v_comment
    ####          @schedulerun.comment =v_error[0..499]
    ####          @schedulerun.status_flag="E"
    ####    end
    
    
  end
  
  def run_fs_Y_N_manual_edits
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('fs_Y_N_manual_edits')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting fs_Y_N_manual_edits"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
    begin   # catch all exception and put error in comment
       v_fs_path = v_base_path+"/preprocessed/modalities/freesurfer/manual_edits/"
      # ls the dirs and links
      v_dir_skip =  ['QA', 'fsaverage', 'fsaverage_bkup20121114', '.', '..', 'lh.EC_average','rh.EC_average','qdec','surfer.log']
      # 'tmp*'  --- just keep dir cleaner
      # ??? 'pdt00020.long.pdt00020_base',      'pdt00020_base',       'pdt00020_v2.long.pdt00020_base', plq20018.R, plq20024.R
      # _v2, _v3, _v4 --> visit2,3,4
      connection = ActiveRecord::Base.connection();
      v_sp_visit1_array = []
      v_sp_visit2_array = []
      v_sp_visit3_array = []
      v_sp_visit4_array = []

      (v_sp_visit1_array,v_sp_visit2_array,v_sp_visit3_array,v_sp_visit4_array)  = get_sp_visit_num_array()
            
      # check for enumber in enrollment, link to enrollment_vgroup_memberships, appointments, visits
      # limit by _v2, _v3, _v4 in sp via scan_procedures_vgroups , scan_procedures like 'visit2, visit3, visit4
      # works for when all the processed files in one directory
      dir_list = Dir.entries(v_fs_path).select { |file| File.directory? File.join(v_fs_path, file)}
      link_list = Dir.entries(v_fs_path).select { |file| File.symlink? File.join(v_fs_path, file)}
      dir_list.concat(link_list)
      v_cnt = 0
      # need to reset everything -- dirs moved from manual_edit 
      v_sql = "update vgroups set fs_manual_edits_flag = 'N'"
      results = connection.execute(v_sql)
      dir_list.each do |dirname|
        if !v_dir_skip.include?(dirname) and !dirname.start_with?('tmp')
          if dirname.include?('_v2')
            dirname = dirname.gsub(/_v2/,'') # subjectid without the v#
            v_dirname_chop = dirname.gsub(/[0123456789]/,'') # get start of subjectid
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit2_array,v_dirname_chop)                                                                      
            vgroups.each do |v|
              if v.fs_manual_edits_flag != "Y"
                 v.fs_manual_edits_flag ="Y"
                 v.save
                 v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v3')
            dirname = dirname.gsub(/_v3/,'')
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit3_array,v_dirname_chop) 
            vgroups.each do |v|
              if v.fs_manual_edits_flag != "Y"
                 v.fs_manual_edits_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v4')
            dirname = dirname.gsub(/_v4/,'')
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit4_array,v_dirname_chop) 
            vgroups.each do |v|
              if v.fs_manual_edits_flag != "Y"
                 v.fs_manual_edits_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          else
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit1_array,v_dirname_chop) 
            vgroups.each do |v|
              if v.fs_manual_edits_flag != "Y"
                 v.fs_manual_edits_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          end
        end
      end
 
        @schedulerun.comment ="successful finish fs_manual_edits_Y_N ===set = Y "+v_cnt.to_s
        @schedulerun.status_flag ="Y"
        @schedulerun.save
        @schedulerun.end_time = @schedulerun.updated_at      
        @schedulerun.save
      puts " successful finish fs_manual_edits_Y_N flag set = Y "+v_cnt.to_s
      rescue Exception => msg
         v_error = msg.to_s
         puts "ERROR !!!!!!!"
         puts v_error
          @schedulerun.comment =v_error[0..499]
          @schedulerun.status_flag="E"
          @schedulerun.save
      end
    
  end
  
    def run_fs_Y_N_donebutbad
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('fs_Y_N_donebutbad')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting fs_iY_N_donebutbad"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
    begin   # catch all exception and put error in comment
       v_fs_path = v_base_path+"/preprocessed/modalities/freesurfer/donebutbad/"
      # ls the dirs and links
      v_dir_skip =  ['QA', 'fsaverage', 'fsaverage_bkup20121114', '.', '..', 'lh.EC_average','rh.EC_average','qdec','surfer.log']
      # 'tmp*'  --- just keep dir cleaner
      # ??? 'pdt00020.long.pdt00020_base',      'pdt00020_base',       'pdt00020_v2.long.pdt00020_base', plq20018.R, plq20024.R
      # _v2, _v3, _v4 --> visit2,3,4
      connection = ActiveRecord::Base.connection();
      v_sp_visit1_array = []
      v_sp_visit2_array = []
      v_sp_visit3_array = []
      v_sp_visit4_array = []

      (v_sp_visit1_array,v_sp_visit2_array,v_sp_visit3_array,v_sp_visit4_array)  = get_sp_visit_num_array()
            
      # check for enumber in enrollment, link to enrollment_vgroup_memberships, appointments, visits
      # limit by _v2, _v3, _v4 in sp via scan_procedures_vgroups , scan_procedures like 'visit2, visit3, visit4
      # works for when all the processed files in one directory
      dir_list = Dir.entries(v_fs_path).select { |file| File.directory? File.join(v_fs_path, file)}
      link_list = Dir.entries(v_fs_path).select { |file| File.symlink? File.join(v_fs_path, file)}
      dir_list.concat(link_list)
      v_cnt = 0
            # need to reset everything -- dirs moved from donebutbad 
      v_sql = "update vgroups set fs_donebutbad_flag = 'N'"
      results = connection.execute(v_sql)
      dir_list.each do |dirname|
        if !v_dir_skip.include?(dirname) and !dirname.start_with?('tmp')
          if dirname.include?('_v2')
            dirname = dirname.gsub(/_v2/,'') # subjectid without the v#
            v_dirname_chop = dirname.gsub(/[0123456789]/,'') # get start of subjectid
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit2_array,v_dirname_chop)                                                                      
            vgroups.each do |v|
              if v.fs_donebutbad_flag != "Y"
                 v.fs_donebutbad_flag ="Y"
                 v.save
                 v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v3')
            dirname = dirname.gsub(/_v3/,'')
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit3_array,v_dirname_chop) 
            vgroups.each do |v|
              if v.fs_donebutbad_flag != "Y"
                 v.fs_donebutbad_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v4')
            dirname = dirname.gsub(/_v4/,'')
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit4_array,v_dirname_chop) 
            vgroups.each do |v|
              if v.fs_donebutbad_flag != "Y"
                 v.fs_donebutbad_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          else
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit1_array,v_dirname_chop) 
            vgroups.each do |v|
              if v.fs_donebutbad_flag != "Y"
                 v.fs_donebutbad_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          end
        end
      end
 
        @schedulerun.comment ="successful finish fs_donebutbad_Y_N ===set = Y "+v_cnt.to_s
        @schedulerun.status_flag ="Y"
        @schedulerun.save
        @schedulerun.end_time = @schedulerun.updated_at      
        @schedulerun.save
      puts " successful finish fs_donebutbad_Y_N flag set = Y "+v_cnt.to_s
      rescue Exception => msg
         v_error = msg.to_s
         puts "ERROR !!!!!!!"
         puts v_error
          @schedulerun.comment =v_error[0..499]
          @schedulerun.status_flag="E"
          @schedulerun.save
      end
    
  end

  def run_fs_Y_N_good2go
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('fs_Y_N_good2go')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting fs_iY_N_good2go"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
    begin   # catch all exception and put error in comment
       v_fs_path = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"
      # ls the dirs and links
      v_dir_skip =  ['QA', 'fsaverage', 'fsaverage_bkup20121114', '.', '..', 'lh.EC_average','rh.EC_average','qdec','surfer.log']
      # 'tmp*'  --- just keep dir cleaner
      # ??? 'pdt00020.long.pdt00020_base',      'pdt00020_base',       'pdt00020_v2.long.pdt00020_base', plq20018.R, plq20024.R
      # _v2, _v3, _v4 --> visit2,3,4
      connection = ActiveRecord::Base.connection();
      v_sp_visit1_array = []
      v_sp_visit2_array = []
      v_sp_visit3_array = []
      v_sp_visit4_array = []

      (v_sp_visit1_array,v_sp_visit2_array,v_sp_visit3_array,v_sp_visit4_array)  = get_sp_visit_num_array()
            
      # check for enumber in enrollment, link to enrollment_vgroup_memberships, appointments, visits
      # limit by _v2, _v3, _v4 in sp via scan_procedures_vgroups , scan_procedures like 'visit2, visit3, visit4
      # works for when all the processed files in one directory
      dir_list = Dir.entries(v_fs_path).select { |file| File.directory? File.join(v_fs_path, file)}
      link_list = Dir.entries(v_fs_path).select { |file| File.symlink? File.join(v_fs_path, file)}
      dir_list.concat(link_list)
      v_cnt = 0
            # need to reset everything -- dirs moved from good2go 
      v_sql = "update vgroups set fs_good2go_flag = 'N'"
      results = connection.execute(v_sql)
      dir_list.each do |dirname|
        if !v_dir_skip.include?(dirname) and !dirname.start_with?('tmp')
          if dirname.include?('_v2')
            dirname = dirname.gsub(/_v2/,'') # subjectid without the v#
            v_dirname_chop = dirname.gsub(/[0123456789]/,'') # get start of subjectid
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit2_array,v_dirname_chop)                                                                      
            vgroups.each do |v|
              if v.fs_good2go_flag != "Y"
                 v.fs_good2go_flag ="Y"
                 v.save
                 v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v3')
            dirname = dirname.gsub(/_v3/,'')
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit3_array,v_dirname_chop) 
            vgroups.each do |v|
              if v.fs_good2go_flag != "Y"
                 v.fs_good2go_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v4')
            dirname = dirname.gsub(/_v4/,'')
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit4_array,v_dirname_chop) 
            vgroups.each do |v|
              if v.fs_good2go_flag != "Y"
                 v.fs_good2go_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          else
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit1_array,v_dirname_chop) 
            vgroups.each do |v|
              if v.fs_good2go_flag != "Y"
                 v.fs_good2go_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          end
        end
      end
 
        @schedulerun.comment ="successful finish fs_good2go_Y_N ===set = Y "+v_cnt.to_s
        @schedulerun.status_flag ="Y"
        @schedulerun.save
        @schedulerun.end_time = @schedulerun.updated_at      
        @schedulerun.save
      puts " successful finish fs_good2go_Y_N flag set = Y "+v_cnt.to_s
      rescue Exception => msg
         v_error = msg.to_s
         puts "ERROR !!!!!!!"
         puts v_error
          @schedulerun.comment =v_error[0..499]
          @schedulerun.status_flag="E"
          @schedulerun.save
      end
    
  end
  
  
  def run_fs_Y_N
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('fs_Y_N')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting fs_Y_N"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
    begin   # catch all exception and put error in comment
       v_fs_path = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
      # ls the dirs and links
      v_dir_skip =  ['QA', 'fsaverage', 'fsaverage_bkup20121114', '.', '..', 'lh.EC_average','rh.EC_average','qdec','surfer.log']
      # 'tmp*'  --- just keep dir cleaner
      # ??? 'pdt00020.long.pdt00020_base',      'pdt00020_base',       'pdt00020_v2.long.pdt00020_base', plq20018.R, plq20024.R
      # _v2, _v3, _v4 --> visit2,3,4
      connection = ActiveRecord::Base.connection();
      v_sp_visit1_array = []
      v_sp_visit2_array = []
      v_sp_visit3_array = []
      v_sp_visit4_array = []
      (v_sp_visit1_array,v_sp_visit2_array,v_sp_visit3_array,v_sp_visit4_array)  = get_sp_visit_num_array()
      
      #puts "aaaaaaa v_sp_visit2_array ="+v_sp_visit2_array.to_s
      
      # check for enumber in enrollment, link to enrollment_vgroup_memberships, appointments, visits
      # limit by _v2, _v3, _v4 in sp via scan_procedures_vgroups , scan_procedures like 'visit2, visit3, visit4
      dir_list = Dir.entries(v_fs_path).select { |file| File.directory? File.join(v_fs_path, file)}
      link_list = Dir.entries(v_fs_path).select { |file| File.symlink? File.join(v_fs_path, file)}
      dir_list.concat(link_list)
      v_cnt = 0
      dir_list.each do |dirname|
        if !v_dir_skip.include?(dirname) and !dirname.start_with?('tmp')
          if dirname.include?('_v2')
  #puts "aaaaaa _v2= "+dirname
            dirname = dirname.gsub(/_v2/,'') # subectid without v#
            v_dirname_chop = dirname.gsub(/[0123456789]/,'') # start of subjectid
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit2_array,v_dirname_chop)                                                                             
            vgroups.each do |v|
              if v.fs_flag != "Y"
                 v.fs_flag ="Y"
                 v.save
                 v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v3')
            dirname = dirname.gsub(/_v3/,'')
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit3_array,v_dirname_chop)
            vgroups.each do |v|
              if v.fs_flag != "Y"
                 v.fs_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v4')
            dirname = dirname.gsub(/_v4/,'')
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit4_array,v_dirname_chop)
            vgroups.each do |v|
              if v.fs_flag != "Y"
                 v.fs_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          else
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = get_vgroups_from_enumber_sp(dirname,v_sp_visit1_array,v_dirname_chop)
            vgroups.each do |v|
              if v.fs_flag != "Y"
                 v.fs_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          end
        end
      end
 
        @schedulerun.comment ="successful finish fs_Y_N ===set = Y "+v_cnt.to_s
        @schedulerun.status_flag ="Y"
        @schedulerun.save
        @schedulerun.end_time = @schedulerun.updated_at      
        @schedulerun.save
      puts " successful finish  fs_flag set = Y "+v_cnt.to_s
      rescue Exception => msg
         v_error = msg.to_s
         puts "ERROR !!!!!!!"
         puts v_error
          @schedulerun.comment =v_error[0..499]
          @schedulerun.status_flag="E"
          @schedulerun.save
      end
    
    
  end
  
end
