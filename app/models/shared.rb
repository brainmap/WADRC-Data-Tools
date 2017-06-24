require 'visit'
require 'image_dataset'
require 'net/ssh'
require 'net/sftp'
require 'open3'
require 'metamri'
# needs ruby 2.5 require 'fileutils'
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
      v_comment =" header matches expected."
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
       @schedulerun.comment ="starting adrc_dti"
       @schedulerun.save
       @schedulerun.start_time = @schedulerun.created_at
       @schedulerun.save
       v_comment = ""
       v_comment_warning =""
    #  table cg_adrc_upload populated by run_adrc_upload function      
     connection = ActiveRecord::Base.connection();
     # get adrc subjectid to upload
     sql = "select distinct subjectid , scan_procedure_id from cg_adrc_upload where dti_sent_flag ='N' and dti_status_flag in ('Y','R') "
     results = connection.execute(sql)
     # changed to series_description_maps table
     v_folder_array = Array.new
     v_scan_desc_type_array = Array.new
     # check for dir in /tmp
     v_target_dir ="/tmp/adrc_dti"
     ###v_target_dir ="/Volumes/Macintosh_HD2/adrc_dti"
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
       sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")+"')
                                                                                          and v.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg  where spvg.scan_procedure_id ='"+r[1].to_s+"')"
     
       results_vgroup = connection.execute(sql_vgroup)

       # mkdir /tmp/adrc_dti/[subjectid]_YYYYMMDD_wisc
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
       sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                   from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                   where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                   and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                   and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                   and series_description_maps.series_description_type_id = series_description_types.id
                   and series_description_types.series_description_type in ('DTI') 
                   and image_datasets.series_description != 'DTI whole brain  2mm FATSAT ASSET'
                   and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")+"')
                   and vgroups.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg  where spvg.scan_procedure_id ='"+r[1].to_s+"')
                    order by appointments.appointment_date "
       results_dataset = connection.execute(sql_dataset)
       v_folder_array = [] # how to empty
       v_scan_desc_type_array = []
       v_cnt = 1
       results_dataset.each do |r_dataset|
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

              # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
               v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
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
             # cp path ==> /tmp/adrc_dti/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
       end

       sql_status = "select dti_status_flag from cg_adrc_upload where subjectid ='"+r[0]+"'"
       results_status = connection.execute(sql_status)
       if v_scan_desc_type_array.size < 1   and (results_status.first)[0] != "R"
         # sql_dirlist = "update cg_adrc_upload set general_comment =' NOT ALL SCAN TYPES!!!! "+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' "
         # results_dirlist = connection.execute(sql_dirlist)
         sql_status = "update cg_adrc_upload set dti_status_flag ='N' where subjectid ='"+r[0]+"' "
         results_sent = connection.execute(sql_status)
         # send email 
         v_subject = "adrc_dti "+r[0]+" is missing some scan types --- set status_flag ='R' to send  : scans ="+v_folder_array.join(", ")
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

         sql_dirlist = "update cg_adrc_upload set dti_dir_list ='"+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' "
         results_dirlist = connection.execute(sql_dirlist)
 # TURN INTO A LOOP
         v_dicom_field_array =['0010,0030','0010,0010']
         v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name'}
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
         v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/adrc_dti/"
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close

         #v_call = "zip -r "+v_target_dir+"/"+v_subject_dir+".zip  "+v_parent_dir_target
         #v_call = "cd "+v_target_dir+"; zip -r "+v_subject_dir+"  "+v_subject_dir   #  ???????    PROBLEM HERE????
         v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
         v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/adrc_dti  -zcf /home/panda_user/adrc_dti/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
         v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/adrc_dti/'+v_subject_dir+' "'
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close


          # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
          v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/adrc_dti/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
            puts stdout.read 1024    
           end
          stdin.close
          stdout.close
          stderr.close


         v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".tar.gz"
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close        

         sql_sent = "update cg_adrc_upload set dti_sent_flag ='Y' where subjectid ='"+r[0]+"' "
         results_sent = connection.execute(sql_sent)
       end
       v_comment = "end "+r[0]+","+v_comment
       @schedulerun.comment =v_comment[0..1990]
       @schedulerun.save 
     end

     @schedulerun.comment =("successful finish adrc_dti "+v_comment_warning+" "+v_comment[0..1990])
     if !v_comment.include?("ERROR")
        @schedulerun.status_flag ="Y"
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save          


   end
 
 
   # subset of adrc_upload -- just pcvipr, asl raw, asl_fmap, pdmap
      def run_adrc_pcvipr  
        v_base_path = Shared.get_base_path()
        v_preprocessed_path = v_base_path+"/preprocessed/visits/"
         @schedule = Schedule.where("name in ('adrc_pcvipr')").first
          @schedulerun = Schedulerun.new
          @schedulerun.schedule_id = @schedule.id
          @schedulerun.comment ="starting adrc_pcvipr"
          @schedulerun.save
          @schedulerun.start_time = @schedulerun.created_at
          @schedulerun.save
          v_comment = ""
          v_comment_warning =""
       #  table cg_adrc_upload populated by run_adrc_upload function      
        connection = ActiveRecord::Base.connection();
        # get adrc subjectid to upload
        sql = "select distinct subjectid , scan_procedure_id , enrollment_id from cg_adrc_upload where pcvipr_sent_flag ='N' and pcvipr_status_flag in ('U') " # ('Y','R') "
        results = connection.execute(sql)
        # changed to series_description_maps table
        v_folder_array = Array.new
        v_scan_desc_type_array = Array.new
        # check for dir in /tmp
        v_target_dir ="/tmp/adrc_pcvipr"
        #v_target_dir ="/Volumes/Macintosh_HD2/adrc_pcvipr"
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
          v_sp_id = r[1]
          v_scan_procedure = ScanProcedure.find(v_sp_id)
          v_preprocessed_path = v_preprocessed_path+v_scan_procedure.codename+"/"
          v_enumber = r[0].gsub(/_v2/,"").gsub(/_v3/,"").gsub(/_v4/,"").gsub(/_v5/,"")
# CHANGED FOR R
          v_enumber_r = v_enumber  # +".R" #".R"
          v_comment = "strt "+r[0]+","+v_comment
          @schedulerun.comment =v_comment[0..1990]
          @schedulerun.save
# CHANGED FOR R
          # update schedulerun comment - prepend 
          sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.id ='"+r[2].to_s+"')
                                                   and v.id in ( select spvg.vgroup_id from scan_procedures_vgroups spvg where spvg.scan_procedure_id = "+r[1].to_s+")
and v.id in (select a.vgroup_id from appointments a, visits where a.id = visits.appointment_id  )"

#and  visits.path like '%dempsey.plaque%' and replace(visits.path,'raw','')  like '%R%' )"
#REMOVE LAST 2 DEMPSEY LINES -- KEEPING R and not R separate
          results_vgroup = connection.execute(sql_vgroup)
          # mkdir /tmp/adrc_pcvipr/[subjectid]_YYYYMMDD_wisc
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
# CHANGED FOR R
          sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                      from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                      where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                      and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                      and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                      and series_description_maps.series_description_type_id = series_description_types.id
                      and series_description_types.series_description_type in ('PCVIPR','ASL') 
                      and image_datasets.series_description != 'SRC:PCVIPR Mag COMP'
                      and image_datasets.series_description != 'SRC:PCVIPR CD COMP'
                      and image_datasets.series_description != 'ASL CBF'
                      and image_datasets.series_description !=  'Cerebral Blood Flow'
                      and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.id ='"+r[2].to_s+"')
                      and vgroups.id in ( select spvg.vgroup_id from scan_procedures_vgroups spvg where spvg.scan_procedure_id = "+r[1].to_s+")   
                       order by appointments.appointment_date "
                       #and ( visits.path like '%dempsey.plaque%' and replace(visits.path,'raw','')  like '%R%') 
#REMOVE LAST 2 DEMPSEY LINES -- KEEPING R and not R separate
          results_dataset = connection.execute(sql_dataset)
          v_folder_array = [] # how to empty
          v_scan_desc_type_array = []
          v_cnt = 1
          results_dataset.each do |r_dataset|
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

                 # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
                 if v_series_description_type == "PCVIPR"
                    v_call = "rsync -av "+v_path+" "+v_parent_dir_target+"/"+v_dir_target
                 else
                  v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
                end 
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
                # cp path ==> /tmp/adrc_pcvipr/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)

                      # get the ASL_fmap and PDmap 
          puts "aaaaaaaaaa v_series_description_type ="+v_series_description_type
           if v_series_description_type == "ASL"
              v_asl_nii = v_preprocessed_path+v_enumber_r+"/asl/ASL_fmap_"+v_enumber_r+"_*.nii"
              v_pdmap_nii = v_preprocessed_path+v_enumber_r+"/asl/PDmap_"+v_enumber_r+"_*.nii"
              v_call = "rsync -av "+ v_asl_nii+" "+v_parent_dir_target
        puts v_call
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
              v_call = "rsync -av "+ v_pdmap_nii+" "+v_parent_dir_target
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
           # some have new asl/image structure
           if v_series_description_type == "ASL"
              v_asl_nii = v_preprocessed_path+v_enumber_r+"/asl/images/ASL_fmap_"+v_enumber_r+"_*.nii"
              v_pdmap_nii = v_preprocessed_path+v_enumber_r+"/asl/images/PDmap_"+v_enumber_r+"_*.nii"
              v_call = "rsync -av "+ v_asl_nii+" "+v_parent_dir_target
        puts v_call
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
              v_call = "rsync -av "+ v_pdmap_nii+" "+v_parent_dir_target
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
# CHANGED TO STOP R DELETE
          sql_status = "select pcvipr_status_flag from cg_adrc_upload where subjectid ='"+r[0]+"' "
          results_status = connection.execute(sql_status)
          if v_scan_desc_type_array.include?("PCVIPR")
#puts "BBBBBBB includes pcvipr , status = "+(results_status.first)[0]
          end

          if !v_scan_desc_type_array.include?("PCVIPR")   and  (results_status.first)[0] != "R"

            puts " aaaa no pcvipr , status ! = R"
            # sql_dirlist = "update cg_adrc_upload set general_comment =' NO PCVIPR!!!! "+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' "
            # results_dirlist = connection.execute(sql_dirlist)
            sql_status = "update cg_adrc_upload set pcvipr_status_flag ='N' where subjectid ='"+r[0]+"' "
  # CHANGED FOR R
       #     results_sent = connection.execute(sql_status)
            # send email 
            v_subject = "adrc_pcvipr "+r[0]+" is missing some scan types --- set status_flag ='R' to send  : scans ="+v_folder_array.join(", ")
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

            sql_dirlist = "update cg_adrc_upload set pcvipr_dir_list ='"+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' 
                 and pcvipr_sent_flag ='N' "
            results_dirlist = connection.execute(sql_dirlist)
    # TURN INTO A LOOP
            v_dicom_field_array =['0010,0030','0010,0010']
            v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name'}
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
        # keeping on brainapps - doing tar gz there - not has the probelm of mac adding extra directories
          #  v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/adrc_pcvipr/"
          #  stdin, stdout, stderr = Open3.popen3(v_call)
          #  while !stdout.eof?
          #    puts stdout.read 1024    
          #   end
          #  stdin.close
          #  stdout.close
          #  stderr.close

            #v_call = "zip -r "+v_target_dir+"/"+v_subject_dir+".zip  "+v_parent_dir_target
            #v_call = "cd "+v_target_dir+"; zip -r "+v_subject_dir+"  "+v_subject_dir   #  ???????    PROBLEM HERE????
         #   v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
         #   v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/adrc_pcvipr  -zcf /home/panda_user/adrc_pcvipr/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
            v_call =  "  tar  -C "+v_target_dir+"  -zcf "+v_target_dir+"/"+v_subject_dir+".tar.gz "+v_subject_dir+"/ "  
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
              puts stdout.read 1024    
             end
            stdin.close
            stdout.close
            stderr.close
            puts "bbbbbbb "+v_call

            v_call = "rm -rf "+v_target_dir+"/"+v_subject_dir
               stdin, stdout, stderr = Open3.popen3(v_call)
               while !stdout.eof?
                 puts stdout.read 1024    
                end
               stdin.close
               stdout.close
               stderr.close
            # 
            #v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/adrc_pcvipr/'+v_subject_dir+' "'
          #  stdin, stdout, stderr = Open3.popen3(v_call)
          #  while !stdout.eof?
          #    puts stdout.read 1024    
          #   end
          #  stdin.close
          #  stdout.close
          #  stderr.close


             # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
          #   v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/adrc_pcvipr/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
          #   stdin, stdout, stderr = Open3.popen3(v_call)
          #   while !stdout.eof?
          #     puts stdout.read 1024    
          #    end
          #   stdin.close
          #   stdout.close
          #   stderr.close


         #   v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".tar.gz"
         #   stdin, stdout, stderr = Open3.popen3(v_call)
         #   while !stdout.eof?
         #     puts stdout.read 1024    
         #    end
         #   stdin.close
         #   stdout.close
         #   stderr.close        

            sql_sent = "update cg_adrc_upload set pcvipr_sent_flag ='Y' where subjectid ='"+r[0]+"' and pcvipr_sent_flag ='N'"
            results_sent = connection.execute(sql_sent)
          end
          v_comment = "end "+r[0]+","+v_comment
          @schedulerun.comment =v_comment[0..1990]
          @schedulerun.save 
        end

        @schedulerun.comment =("successful finish adrc_pcvipr "+v_comment_warning+" "+v_comment[0..1990])
        if !v_comment.include?("ERROR")
           @schedulerun.status_flag ="Y"
         end
         @schedulerun.save
         @schedulerun.end_time = @schedulerun.updated_at      
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
            # needs ruby 2.5  Fileutils.cp_r(v_path,v_parent_dir_target+"/"+v_dir_target)  
             # had trouble with rsync failing in big directories
            # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"   
             #### trying to not use mise/dependencies   
             v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
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
        v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/upload_adrc/"    #+v_subject_dir
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
        v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/upload_adrc  -zcf /home/panda_user/upload_adrc/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
        v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/upload_adrc/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_adrc
         v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/upload_adrc/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
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
       v_call_sftp = 'ssh panda_user@merida.dom.wisc.edu "/home/panda_user/upload_adrc/sftp_adrc_upload.py" '
        stdin, stdout, stderr = Open3.popen3(v_call_sftp)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close 

        # need to check that file is uploaded/moved to /sent
        v_call = 'ssh panda_user@merida.dom.wisc.edu "ls /home/panda_user/upload_adrc/'+v_subject_dir+'.tar.gz"'
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

  def run_fsl_first_volumes

    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "fsl_first_volumes"
    v_script_dev = v_base_path+"/data1/lab_scripts/first_labsetup.sh"
    v_script = v_base_path+"/SysAdmin/production/first_labsetup.sh"
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
                             v_call =  'ssh panda_user@merida.dom.wisc.edu "'  +v_script+' -p '+sp.codename+'  -b '+v_subjectid+'  "  ' 
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
     v_machine ="merida" 
     # MAKE SURE panda_user is member of rvm group on machine 
     # sudo usermod -G rvm panda_user 
     v_run_status_flag = "R"
     v_generic_target_path = "/home/panda_user/upload_apoewrap/merida/" 
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
       
        
         # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
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
      @schedulerun.comment ="starting padi_dvr_acpc_ids"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_acpc_filename = ""
 
       connection = ActiveRecord::Base.connection();
       v_sql = "select vgroup_id_mri,scan_procedure_id_mri, enum_mri, protocol_mri, t_id from t_padi_dvr_20170215 where acpc_file_name is null or acpc_file_name = ''"
       # where image_dataset_id is null or image_dataset_id = '' "
      results = connection.execute(v_sql)
    results.each do |r|
        v_t_id = r[4]
        v_subjectid_unknown = v_base_path+"/preprocessed/visits/"+r[3]+"/"+r[2]+"/unknown/"
        if File.directory?(v_subjectid_unknown)
                                  #puts "unknown found"
            v_dir_array = Dir.entries(v_subjectid_unknown)   # need to get date for specific files
            v_o_star_nii_flag ="N"
            v_multiple_o_star_nii_flag ="N"
            v_o_star_cnt = 0
            v_acpc_filename = ""
            v_dir_array.each do |f|
                 if f.start_with?("o") and f.end_with?(".nii")
                       v_o_star_nii_flag = "Y"
                       v_acpc_filename = f
                       v_o_star_cnt = v_o_star_cnt+ 1
                        if v_o_star_cnt > 1
                            v_multiple_o_star_nii_flag ="Y"
                            v_acpc_filename = ""
                        end
                  end
                end
                  if(v_acpc_filename > "")
                     v_sql_update = "UPDATE t_padi_dvr_20170215 set acpc_file_name = '"+v_acpc_filename+"' where t_id ="+v_t_id.to_s
                    results_update = connection.execute(v_sql_update)
                  end
           end
        end

         v_sql = "select vgroup_id_mri,scan_procedure_id_mri, enum_mri, protocol_mri, t_id,acpc_file_name
                 from t_padi_dvr_20170215 where acpc_file_name is not null or acpc_file_name > '' "
              results = connection.execute(v_sql)
         results.each do |r|
            v_t_id = r[4]
             v_acpc_file_name = r[5]
             v_o_enum = "o"+r[2]+"_"
             v_acpc_file_name = v_acpc_file_name.gsub(v_o_enum,"")
             v_bravo_nifty_file = r[2]+"_"+v_acpc_file_name
             if v_acpc_file_name >""
                    v_sql_update = "UPDATE t_padi_dvr_20170215 set bravo_nifty_file = '"+v_bravo_nifty_file+"' where t_id ="+v_t_id.to_s
                    results_update = connection.execute(v_sql_update)
              end
          end   
          # try to get missing ids.id from bravo --- different formats -- paths
          v_sql = "select vgroup_id_mri,scan_procedure_id_mri, enum_mri, protocol_mri, t_id,acpc_file_name,bravo_nifty_file
                 from t_padi_dvr_20170215 where (bravo_nifty_file is not null or bravo_nifty_file > '') 
                 and (image_dataset_id is null or image_dataset_id = '')"
          results = connection.execute(v_sql)
         results.each do |r|
              v_vgroup_id = r[0]
              v_enum = r[2]
              v_protocol = r[3]
              v_t_id = r[4]
              v_bravo_nifty = r[6]
    puts v_bravo_nifty
               if  !v_bravo_nifty.blank? 
              v_bravo_nifty = v_bravo_nifty.gsub(".nii","")
    puts v_bravo_nifty
              v_bravo_nifty_array = v_bravo_nifty.split("_") 
            end
            if  !v_bravo_nifty.blank? and !v_bravo_nifty_array[0].nil?
              v_sql_like = "select ids.id from image_datasets ids, visits v, appointments a  
                          where  ids.visit_id = v.id and v.appointment_id = a.id
                          and a.vgroup_id ="+v_vgroup_id.to_s+" 
                          and ids.path like '%"+v_protocol+"%'
                          and ids.path like '%"+v_enum+"%' "
                if !v_bravo_nifty_array[1].nil?
                          v_sql_like = v_sql_like +" and ids.path like '%"+v_bravo_nifty_array[1].gsub("-","_")+"%' "
                    if !v_bravo_nifty_array[2].nil?
                          v_sql_like = v_sql_like +" and ids.path like '%"+v_bravo_nifty_array[2].gsub("-","_")+"%' "
                      if !v_bravo_nifty_array[3].nil?
                          v_sql_like = v_sql_like +" and ids.path like '%"+v_bravo_nifty_array[3].gsub("-","_")+"%' "
                      end
                    end
                end
               results_like = connection.execute(v_sql_like)
               v_ids_id = nil
               v_cnt_ids = 0
               results_like.each do |r2|
                    v_cnt_ids = v_cnt_ids + 1
                     v_ids_id = r2[0]
                end
                if !v_ids_id.nil? and v_cnt_ids < 2
                    v_sql_update = "UPDATE t_padi_dvr_20170215 set image_dataset_id = '"+v_ids_id.to_s+"' where t_id ="+v_t_id.to_s
                    results_update = connection.execute(v_sql_update)
                end
           end

         end

       
       

          @schedulerun.comment =("successful finish padi_dvr_acpc_ids "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
       @schedulerun.status_flag ="Y"
     end
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
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
      @schedulerun.comment ="starting padi_upload_20170227"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_wisc_siteid ="P04"
      # all _v01
      v_visit_number = "v01"  # THE$Y ARE ALL V1!!!!! 
    connection = ActiveRecord::Base.connection();
    # shp, alz, pc, adni, dodadni, lmpd
    v_scan_procedure_exclude =   [21] # [21,28,31,34,15,19,23,35,44,51,50,49]
    # just get the predicttau
     v_scan_procedures = [20,41,58,26,77,66]   #66,39,26,24,41,4,77]  #   pdt1 and pdt, tau, lead   [20,24,26,36,41,58]  # how to only get adrc impact? 
     #not limiting by protocol #scan_procedures_vgroups.scan_procedure_id in ("+v_scan_procedures.join(",")+")
     # getting adrc impact from t_adrc_impact_20150105  --- change to get from refreshing table?
     v_pet_tracer_array = [1] # just pib 1,2,7] # pib and fdg and thk5117  

     v_scan_type_limit = 1 
     v_series_desc_array =['T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','T2_Flair'] # just t1,'T2','T2 Flair','T2_Flair','T2+Flair','DTI','ASL','resting_fMRI']
     if p_dicom_nifty == "dicom"
       v_series_desc_nii_hash = {'nothing'=>"Y"}
     elsif p_dicom_nifty == "nifty"
         v_series_desc_nii_hash =   { 'T1 Volumetic'=>"Y",'T1 Volumetric'=>"Y",'T1+Volumetric'=>"Y",'T1_Volumetric'=>"Y",'T1'=>"Y",'T2_Flair'=>"Y" ,'MPNRAGE'=>"Y"}
     else
         v_series_desc_nii_hash =   { 'T1 Volumetic'=>"Y",'T1 Volumetric'=>"Y",'T1+Volumetric'=>"Y",'T1_Volumetric'=>"Y",'T1'=>"Y",'T2_Flair'=>"Y",'MPNRAGE'=>"Y"}
     end #{ 'T1 Volumetic'=>"Y",'T1 Volumetric'=>"Y",'T1+Volumetric'=>"Y",'T1_Volumetric'=>"Y",'T1'=>"Y"}
    # recruit new  scans ---   change 
    v_weeks_back = "2"  # cwant to give time for quality checks etc. 
    # NEED TO LIMIT ADRC BY LP --- NEED TO REFRESH ADRC IMPACT 
    #  t_adrc_impact_control_20150216 where participant_id is not null and lp_completed_flag ='Y')
     #(participants.wrapnum is not null and participants.wrapnum > '')
     # only want the tau  - petid=7 
     # 'pdt00150','pdt00151','pdt00152','pdt00153','pdt00154','pdt00155','pdt00156','pdt00157','pdt00158','pdt00159'
     # getting directly from t_padi_dvr_20170215 -- populated by run_padi_dvr_acpc_ids
    sql = "select distinct vgroups.id, vgroups.participant_id,
              vgroups.transfer_mri, vgroups.transfer_pet
              from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups,participants    
            where participants.id = vgroups.participant_id and
             ( 
                (vgroups.participant_id) in ( select enrollments.participant_id from enrollments where do_not_share_scans_flag ='N' and
                                               enrollments.enumber in ('pdt00178','pdt00176','pdt00175','pdt00173','pdt00172','pdt00171','pdt00169','pdt00166','pdt00168','pdt00165','pdt00167','pdt00164','pdt00162'))
              )
              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
              and vgroups.id = scan_procedures_vgroups.vgroup_id
              and scan_procedures_vgroups.scan_procedure_id in ("+v_scan_procedures.join(",")+")
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
              and vgroups.vgroup_date < DATE_SUB(curdate(), INTERVAL "+v_weeks_back+" WEEK)  
              and enrollments.do_not_share_scans_flag ='N'           
              and vgroups.id NOT IN ( select cg_padi_upload.vgroup_id from cg_padi_upload 
                                         where scan_procedure_id = scan_procedures_vgroups.scan_procedure_id )
              and ( vgroups.transfer_mri ='yes'  and vgroups.transfer_pet ='yes' and vgroups.id 
                  in ( select appointments.vgroup_id from appointments, petscans where petscans.appointment_id = appointments.id
                           and petscans.lookup_pettracer_id in (1) )
                    )"
    sql = "select t_id,bravo_nifty_file,acpc_file_name,image_dataset_id,vgroup_id_mri,vgroup_id_pib,participant_id,
    scan_procedure_id_mri,scan_procedure_id_pib,enum_mri,enum_pib,protocol_mri,protocol_pib,pib_dvr,export_id,visno
        from t_padi_dvr_20170215 where mri_status_flag ='G' or pib_status_flag = 'G' " #t_id in ( 1, 22,158)"
    results = connection.execute(sql)
    results.each do |r|
          enrollments = Enrollment.where("id in (select enrollment_id from enrollment_vgroup_memberships where vgroup_id in(?) or vgroup_id in(?))",r[4],r[5])
          enrollment_enumbers_array = []
          enrollments.each do |e|
                    enrollment_enumbers_array.push(e.enumber)
          end
          enrollment_enumbers = enrollment_enumbers_array.join(",")
          scan_procedures = ScanProcedure.where("id in (select scan_procedure_id from scan_procedures_vgroups where vgroup_id in(?) or vgroup_id in(?))",r[4], r[5])
          scan_procedure_codename_array = []
          scan_procedures.each do |e|
                    scan_procedure_codename_array.push(e.codename)
          end
          scan_procedure_codenames = scan_procedure_codename_array.join(",")
          v_mri_status_flag = "Y"
          v_pet_status_flag ="Y"
         # if (r[2].to_s == "yes")
         #      v_mri_status_flag = "Y" 
         # end
         # if (r[3].to_s == "yes")
         #      v_pet_status_flag = "Y" 
         # end
          sql2 = "insert into cg_padi_upload (vgroup_id,mri_sent_flag,mri_status_flag, pet_sent_flag,pet_status_flag,participant_id,enumbers,codenames,vgroup_id_pib) 
          values('"+r[4].to_s+"','N','"+v_mri_status_flag+"', 'N','"+v_pet_status_flag+"',"+r[6].to_s+",'"+enrollment_enumbers+"','"+scan_procedure_codenames+"',"+r[5].to_s+")"
          results2 = connection.execute(sql2)
    end
    # already made export_id
    sql = "insert into cg_padi_participants (participant_id)
              select distinct cg_padi_upload.participant_id from cg_padi_upload 
              where participant_id NOT IN ( select participant_id from cg_padi_participants)
              and participant_id is not null"

     results = connection.execute(sql)

     sql = "update cg_padi_upload 
            set cg_padi_upload.export_id = ( select cg_padi_participants.export_id from cg_padi_participants 
                                 where cg_padi_participants.participant_id = cg_padi_upload.participant_id)"
     results = connection.execute(sql)
         sql = "update t_padi_dvr_20170215 
            set t_padi_dvr_20170215.export_id = ( select cg_padi_participants.export_id from cg_padi_participants 
                                 where cg_padi_participants.participant_id = t_padi_dvr_20170215.participant_id)"
     results = connection.execute(sql)

     # add mri_visit_number  and pet_visit_number   update !!!!!!!!!!!!!!!

    v_folder_array = Array.new
    v_scan_desc_type_array = Array.new
    # check for dir in /tmp
    v_target_dir ="/tmp/padi_upload"
    # v_target_dir ="/Volumes/Macintosh_HD2/padi_upload"
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
    #PET
    sql = "select distinct vgroup_id,export_id,enumbers,cg_padi_upload.pet_visit_number from cg_padi_upload where pet_sent_flag ='N' and pet_status_flag in ('G') and pet_visit_number is not null" # ('Y','R') "
    sql = "select distinct t_id,bravo_nifty_file,acpc_file_name,image_dataset_id,
vgroup_id_mri,vgroup_id_pib,participant_id,scan_procedure_id_mri,scan_procedure_id_pib,enum_mri,enum_pib,protocol_mri,protocol_pib,pib_dvr,
export_id, visno  
     from t_padi_dvr_20170215 where pib_status_flag ='G' and pib_sent_flag ='N' "
    results = connection.execute(sql)

    v_comment = " :list of vgroupids"+v_comment
    results.each do |r|

      v_comment = r[5].to_s+","+v_comment
    end
    @schedulerun.comment =v_comment[0..1990]
    @schedulerun.save
    results.each do |r|
      v_vgroup_id = r[5].to_s
      v_export_id = v_wisc_siteid+r[14].to_s.rjust(4,padstr='0')
      v_visit_number =  "v"+r[15].to_s.rjust(2,padstr='0')
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
      # switching from age_at_appt , to v#, and somehow also passing age_at_appt linked to file name
      ####v_age = (results_vgroup.first)[0].to_s
      ####v_subject_dir = v_export_id+"_"+v_age.gsub(/\./,"")+"_pet"
      v_subject_dir = v_export_id+"_PIB_"+v_visit_number
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "mkdir "+v_parent_dir_target   # in tmp
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close 
      v_petfile_path = r[13]
      v_petfile_target_name = v_subject_dir+".v" # ecat nii"  # all nii

      v_call = "rsync -av "+v_petfile_path+" "+v_parent_dir_target+"/"+v_petfile_target_name             
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


        v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/upload_padi/"    #+v_subject_dir
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
        ## switch to zop for xnat 
        ## v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/upload_padi  -zcf /home/panda_user/upload_padi/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '

v_call =  'ssh panda_user@merida.dom.wisc.edu " cd /home/panda_user/upload_padi/; zip -r '+v_subject_dir+'.zip '+v_subject_dir+'  "  '      
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
        v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/upload_padi/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_padi
         v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/upload_padi/"+v_subject_dir+".zip "+v_target_dir+'/'+v_subject_dir+".zip"
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
        v_source = v_target_dir+'/'+v_subject_dir+".zip"
        v_target = v_subject_dir+".zip"

 

####        Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
####            sftp.upload!(v_source, v_target)
####        end
# WANT TO CHECK TRANSFERS
        v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".zip"
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close        
        
        sql_sent = "update cg_padi_upload set pet_sent_flag ='Y' where vgroup_id_pib ='"+r[5].to_s+"'  "
        results_sent = connection.execute(sql_sent) 
          sql_sent = "update t_padi_dvr_20170215 set pib_sent_flag ='Y' where vgroup_id_pib ='"+r[5].to_s+"'  "
        results_sent = connection.execute(sql_sent)   

    end

    # get  subjectid to upload    # USING G AS LIMIT FOR TESTING
    #MRI  switching to appointment
    sql = "select distinct cg_padi_upload.vgroup_id,export_id,appointments.id,cg_padi_upload.mri_visit_number from cg_padi_upload,appointments 
     where appointments.vgroup_id = cg_padi_upload.vgroup_id and
            appointments.appointment_type = 'mri'
            and    mri_sent_flag ='N' and mri_status_flag in ('G') and mri_visit_number is not null " # ('Y','R') "
    
sql = "select distinct t_id,bravo_nifty_file,acpc_file_name,image_dataset_id,
vgroup_id_mri,vgroup_id_pib,participant_id,scan_procedure_id_mri,scan_procedure_id_pib,enum_mri,enum_pib,protocol_mri,protocol_pib,pib_dvr,
export_id,visno  
     from t_padi_dvr_20170215 where mri_status_flag ='G' and mri_sent_flag ='N' "
    
    results = connection.execute(sql)

    v_comment = " :list of vgroupid "+v_comment
    results.each do |r|
      v_comment = r[4].to_s+","+v_comment
    end
    @schedulerun.comment =v_comment[0..1990]
    @schedulerun.save
    v_past_vgroup_id = "0"
    v_cnt = 1
    results.each do |r|
      v_dirlist =""
      v_vgroup_id = r[4].to_s
      v_ids_id = r[3] # use to get path
      v_bravo_nifty_file = r[1]
      if v_vgroup_id  != v_past_vgroup_id
            v_past_vgroup_id = v_vgroup_id
            v_cnt = 1
      else
            v_cnt = v_cnt + 1
      end
      v_export_id = v_wisc_siteid+r[14].to_s.rjust(4,padstr='0')
      v_visit_number =  "v"+r[15].to_s.rjust(2,padstr='0')
      
      v_comment = "strt "+v_vgroup_id+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      # just using appt date
      #sql_vgroup = "select round((DATEDIFF(a.appointment_date,p.dob)/365.25),2),
      #round((DATEDIFF(v.vgroup_date,p.dob)/365.25),2),
      #a.id from appointments a,vgroups v,participants p where v.id = "+v_vgroup_id+" 
      #                    and v.id = a.vgroup_id and a.id = "+v_appointment_id+"
      #                    and v.participant_id = p.id
      #                     and v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e,scan_procedures_vgroups spvg where spvg.vgroup_id = evm.vgroup_id and 
      #                                                      evm.enrollment_id = e.id  and e.do_not_share_scans_flag ='N')"
#puts "PPPPP = apptid="+v_appointment_id+"  sql="+sql_vgroup      
    #     results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/padi_upload/[subjectid]_YYYYMMDD_wisc
       # just using appt age "_"+(results_vgroup.first)[1].to_s+
       # switching from age_at_appt to v#, and somehow also send the age_appt to link up with file name
      #####v_age = ((results_vgroup.first)[0].to_s).gsub(/\./,"")
      ####v_subject_dir = v_export_id+"_"+((results_vgroup.first)[0].to_s).gsub(/\./,"")+"_"+v_cnt.to_s+"_mri"
      v_subject_dir = v_export_id+"_MR_"+v_visit_number
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "mkdir "+v_parent_dir_target
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close   
      # p_dicom_nifty == "dicom"  == "nifty"
# UP TO HERE   -- use the   bravo_nifty_file r[1] and  image_dataset_id  r[3] for T1 
            # use this for the T2 FLAIR
     v_series_desc_array = ['T2_Flair']
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                  from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                  and vgroups.id = "+v_vgroup_id+"
                  and (image_datasets.do_not_share_scans_flag is NULL or image_datasets.do_not_share_scans_flag ='N')
                  and ( (image_datasets.id ="+r[3].to_s+" and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','MPnRAGE')  )
                        or ((image_datasets.lock_default_scan_flag != 'Y' or image_datasets.lock_default_scan_flag  is NULL)
                  and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('T2_Flair') 
                  and image_datasets.series_description != 'DTI whole brain  2mm FATSAT ASSET'
                     ) )
                   order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_folder_array = [] # how to empty
      v_scan_desc_type_array = []
      v_cnt = 1
      results_dataset.each do |r_dataset|
         v_ids_ok_flag = "Y"
         v_ids_id = r_dataset[2]
         puts " series desc ="+r_dataset[3]
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
  ####          v_nii_file_name =  [subjectid]_[series_description /replace " " with -] , _[] , path- split / , last value]
            v_path_dir_array = r_dataset[4].split("/")
            #v_path_dir_array[5]= sp
            
            v_subject_id_vgroup_array = v_path_dir_array[5].split("_")
            v_subject_id = v_subject_id_vgroup_array[0] 
            if v_subject_id == "mri"
                   v_subject_id_vgroup_array = v_path_dir_array[6].split("_")
            v_subject_id = v_subject_id_vgroup_array[0]
            end 

            v_last_dir_array = (v_path_dir_array.last).split(".")
            v_nii_file_name = v_subject_id+"_"+r_dataset[3].gsub(/ /,"-").gsub(":","-")+"_"+v_last_dir_array[0]+".nii"
            if r[3] == v_ids_id
              v_nii_file_name = r[1]
            end
            v_dirlist = v_dirlist +", "+v_nii_file_name
            v_nii_file_path = v_base_path+"/preprocessed/visits/"+v_path_dir_array[4].to_s+"/"+v_subject_id+"/unknown/"+v_nii_file_name
             puts "eeeeee v_nii_file_path="+v_nii_file_path
            if(v_series_desc_nii_hash[r_dataset[5]] == "Y")
                v_nii_flag = "Y"
                v_call = "rsync -av "+v_nii_file_path+" "+v_parent_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(/ /,"-").gsub(":","-")+"_"+v_last_dir_array[0]+".nii"                
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
             # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
             if p_dicom_nifty == "dicom"
              v_dirlist = v_dirlist+", "+v_path
              v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
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
             v_delete_file_array = ["yaml","pickle","json"]
             v_delete_file_array.each do |file_end|
             v_call = "rm "+v_parent_dir_target+"/"+v_dir_target+"/*."+file_end
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
              v_call = "rm "+v_parent_dir_target+"/"+v_dir_target+"/*/*."+file_end
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
              v_call = "rm "+v_parent_dir_target+"/"+v_dir_target+"/*/*/*."+file_end
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
              v_call = "rm "+v_parent_dir_target+"/"+v_dir_target+"/*/*/*/*."+file_end
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
             # temp - replace /Volumes/team/ and /Data/vtrak1/ with /Volumes/team-1 in dev
            # split on / --- get the last dir
            # make new dir name dir_series_description_type 
            # check if in v_folder_array , if in v_folder_array , dir_series_description_type => dir_series_description_type_2
            # add  dir, dir_series_description_type to v_folder_array
            # cp path ==> /tmp/padi_upload/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
         end # skipping if qc severe or incomplete    
      end

      if p_dicom_nifty == "nifty" or p_dicom_nifty == "dicom" #skipping dcm
          puts "the partial set scan types notification"

      # run it always
         puts "AAAAAAAAA DCM PATH TMP ="+v_parent_dir_target+"/*/*/*.dcm"
#         /tmp/padi_upload/adrc00045_20130920_wisc/008_DTI/008

        sql_dirlist = "update cg_padi_upload set mri_dir_list =concat('"+v_dirlist+"',mri_dir_list) where vgroup_id ='"+r[0].to_s+"' "
        results_dirlist = connection.execute(sql_dirlist)
# TURN INTO A LOOP -- need to get rid of dates 
        v_dicom_field_array =['0010,0030','0010,0010','0008,0050','0008,1030','0010,0020','0040,0254','0008,0080','0008,1010','0009,1002','0009,1030','0018,1000',
                        '0025,101A','0040,0242','0040,0243','0008,0020','0008,0021','0008,0022','0008,0023','0040,0244']
        v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>v_export_id,'0008,0050'=>'Accession Number',
                           '0008,1030'=>'Study Description', '0010,0020'=>v_visit_number,'0040,0254'=>'Performed Proc Step Desc',
                            '0008,0080'=>'Institution Name','0008,1010'=>'Station Name','0009,1002'=>'Private',
                            '0009,1030'=>'Private','0018,1000'=>'Device Serial Number','0025,101A'=>'Private',
                            '0040,0242'=>'Performed Station Name','0040,0243'=>'Performed Location',
                            '0008,0020'=>'19720101','0008,0021'=>'19720101','0008,0022'=>'19720101',   
                            '0008,0023'=>'19720101','0040,0244'=>'19720101'}
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
              Dir.glob(v_parent_dir_target+'/*/*/*.4*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
              Dir.glob(v_parent_dir_target+'/*/*/*.5*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
              Dir.glob(v_parent_dir_target+'/*/*/*.6*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
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
        v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/upload_padi/"    #+v_subject_dir
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
        #v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/upload_padi  -zcf /home/panda_user/upload_padi/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
        v_call =  'ssh panda_user@merida.dom.wisc.edu " cd /home/panda_user/upload_padi/; zip -r '+v_subject_dir+'.zip '+v_subject_dir+' "  '
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
        v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/upload_padi/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_padi
         v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/upload_padi/"+v_subject_dir+".zip "+v_target_dir+'/'+v_subject_dir+".zip"
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
        v_source = v_target_dir+'/'+v_subject_dir+".zip"
        v_target = v_subject_dir+".tar.gz"

 

####        Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
####            sftp.upload!(v_source, v_target)
####        end
# WANT TO CHECK TRANSFERS
        v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".zip"
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close        
        
        sql_sent = "update t_padi_dvr_20170215 set mri_sent_flag ='Y',dirlist ='"+v_dirlist+"',
        target_dir ='"+v_parent_dir_target+"' where VGROUP_id_mri ='"+r[4].to_s+"'  "
        results_sent = connection.execute(sql_sent)
      end
      v_comment = "end "+r[0].to_s+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save 
    end
              
    @schedulerun.comment =("successful finish padi_upload "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
       @schedulerun.status_flag ="Y"
     end
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save          
      
    
  end


  # for the scan share consortium - upload to padi
  def run_padi_upload   # CHNAGE _STATUS_FLAG = Y !!!!!!!  ## add mri_visit_number????
    v_base_path = Shared.get_base_path()
     @schedule = Schedule.where("name in ('padi_upload')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting padi_upload"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_wisc_siteid ="P04"
    connection = ActiveRecord::Base.connection();
    # shp, alz, pc, adni, dodadni, lmpd
    v_scan_procedure_exclude =   [21,28,31,34,15,19,23,35,44,51,50,49,20,24,36] # [21,28,31,34,15,19,23,35,44,51,50,49]
    # just get the predicttau
     v_scan_procedures = [26,41]  #   pdt1 and pdt   [20,24,26,36,41,58]  # how to only get adrc impact? 
     #not limiting by protocol #scan_procedures_vgroups.scan_procedure_id in ("+v_scan_procedures.join(",")+")
     # getting adrc impact from t_adrc_impact_20150105  --- change to get from refreshing table?
     v_pet_tracer_array = [1] # just pib 1,2,7] # pib and fdg and thk5117  

     v_scan_type_limit = 1 
     v_series_desc_array =['T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1'] # just t1,'T2','T2 Flair','T2_Flair','T2+Flair','DTI','ASL','resting_fMRI']
     v_series_desc_nii_hash = {'nothing'=>"Y"} #{ 'T1 Volumetic'=>"Y",'T1 Volumetric'=>"Y",'T1+Volumetric'=>"Y",'T1_Volumetric'=>"Y",'T1'=>"Y"}
    # recruit new  scans ---   change 
    v_weeks_back = "2"  # cwant to give time for quality checks etc. 
    # NEED TO LIMIT ADRC BY LP --- NEED TO REFRESH ADRC IMPACT 
    #  t_adrc_impact_control_20150216 where participant_id is not null and lp_completed_flag ='Y')
     #(participants.wrapnum is not null and participants.wrapnum > '')
     # only want the tau  - petid=7 
     # 'pdt00150','pdt00151','pdt00152','pdt00153','pdt00154','pdt00155','pdt00156','pdt00157','pdt00158','pdt00159'

    sql = "select distinct vgroups.id, vgroups.participant_id,
              vgroups.transfer_mri, vgroups.transfer_pet
              from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups,participants    
            where participants.id = vgroups.participant_id and
             ( 
                (vgroups.participant_id) in ( select enrollments.participant_id from enrollments where do_not_share_scans_flag ='N' and
                                               enrollments.enumber in ('pdt00178','pdt00176','pdt00175','pdt00173','pdt00172','pdt00171','pdt00169','pdt00166','pdt00168','pdt00165','pdt00167','pdt00164','pdt00162'))
              )
              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
              and vgroups.id = scan_procedures_vgroups.vgroup_id
              and scan_procedures_vgroups.scan_procedure_id in ("+v_scan_procedures.join(",")+")
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
              and vgroups.vgroup_date < DATE_SUB(curdate(), INTERVAL "+v_weeks_back+" WEEK)  
              and enrollments.do_not_share_scans_flag ='N'           
              and vgroups.id NOT IN ( select cg_padi_upload.vgroup_id from cg_padi_upload 
                                         where scan_procedure_id = scan_procedures_vgroups.scan_procedure_id )
              and ( vgroups.transfer_mri ='yes'  and vgroups.transfer_pet ='yes' and vgroups.id 
                  in ( select appointments.vgroup_id from appointments, petscans where petscans.appointment_id = appointments.id
                           and petscans.lookup_pettracer_id in (1) )
                    )"
    results = connection.execute(sql)
    results.each do |r|
          enrollments = Enrollment.where("id in (select enrollment_id from enrollment_vgroup_memberships where vgroup_id in(?))",r[0])
          enrollment_enumbers_array = []
          enrollments.each do |e|
                    enrollment_enumbers_array.push(e.enumber)
          end
          enrollment_enumbers = enrollment_enumbers_array.join(",")
          scan_procedures = ScanProcedure.where("id in (select scan_procedure_id from scan_procedures_vgroups where vgroup_id in(?))",r[0])
          scan_procedure_codename_array = []
          scan_procedures.each do |e|
                    scan_procedure_codename_array.push(e.codename)
          end
          scan_procedure_codenames = scan_procedure_codename_array.join(",")
          v_mri_status_flag = "N"
          v_pet_status_flag ="N"
          if (r[2].to_s == "yes")
               v_mri_status_flag = "Y" 
          end
          if (r[3].to_s == "yes")
               v_pet_status_flag = "Y" 
          end
          sql2 = "insert into cg_padi_upload (vgroup_id,mri_sent_flag,mri_status_flag, pet_sent_flag,pet_status_flag,participant_id,enumbers,codenames) 
          values('"+r[0].to_s+"','N','"+v_mri_status_flag+"', 'N','"+v_pet_status_flag+"',"+r[1].to_s+",'"+enrollment_enumbers+"','"+scan_procedure_codenames+"')"
          results2 = connection.execute(sql2)
    end

    sql = "insert into cg_padi_participants (participant_id)
              select distinct cg_padi_upload.participant_id from cg_padi_upload 
              where participant_id NOT IN ( select participant_id from cg_padi_participants)
              and participant_id is not null"

     results = connection.execute(sql)

     sql = "update cg_padi_upload 
            set cg_padi_upload.export_id = ( select cg_padi_participants.export_id from cg_padi_participants 
                                 where cg_padi_participants.participant_id = cg_padi_upload.participant_id)"
     results = connection.execute(sql)

     # add mri_visit_number  and pet_visit_number   update !!!!!!!!!!!!!!!

    v_folder_array = Array.new
    v_scan_desc_type_array = Array.new
    # check for dir in /tmp
    v_target_dir ="/tmp/padi_upload"
    # v_target_dir ="/Volumes/Macintosh_HD2/padi_upload"
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
    #PET
    sql = "select distinct vgroup_id,export_id,enumbers,cg_padi_upload.pet_visit_number from cg_padi_upload where pet_sent_flag ='N' and pet_status_flag in ('G') and pet_visit_number is not null" # ('Y','R') "
    results = connection.execute(sql)

    v_comment = " :list of vgroupids"+v_comment
    results.each do |r|

      v_comment = r[0].to_s+","+v_comment
    end
    @schedulerun.comment =v_comment[0..1990]
    @schedulerun.save
    results.each do |r|
      v_vgroup_id = r[0].to_s
      v_export_id = v_wisc_siteid+r[1].to_s.rjust(4,padstr='0')
      v_visit_number = "v"+r[3].to_s
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
      # switching from age_at_appt , to v#, and somehow also passing age_at_appt linked to file name
      ####v_age = (results_vgroup.first)[0].to_s
      ####v_subject_dir = v_export_id+"_"+v_age.gsub(/\./,"")+"_pet"
      v_subject_dir = v_export_id+"_"+v_visit_number+"_pet"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "mkdir "+v_parent_dir_target
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
          if  v_pettracer_id.to_s == "1"
            v_petfile_target_name = v_tracer+"_"+v_petfile_name
            v_call = "rsync -av "+v_petfile_path+" "+v_parent_dir_target+"/"+v_petfile_target_name             
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

            v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/upload_padi/"    #+v_subject_dir
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
        ## switch to zop for xnat 
        ## v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/upload_padi  -zcf /home/panda_user/upload_padi/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '

v_call =  'ssh panda_user@merida.dom.wisc.edu " cd /home/panda_user/upload_padi/; zip -r '+v_subject_dir+'.zip '+v_subject_dir+'  "  '      
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
        v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/upload_padi/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_padi
         v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/upload_padi/"+v_subject_dir+".zip "+v_target_dir+'/'+v_subject_dir+".zip"
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
        v_source = v_target_dir+'/'+v_subject_dir+".zip"
        v_target = v_subject_dir+".zip"

 

####        Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
####            sftp.upload!(v_source, v_target)
####        end
# WANT TO CHECK TRANSFERS
        v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".zip"
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close        
        
        sql_sent = "update cg_padi_upload set pet_sent_flag ='Y' where vgroup_id ='"+r[0].to_s+"'  "
        results_sent = connection.execute(sql_sent)   

    end

    # get  subjectid to upload    # USING G AS LIMIT FOR TESTING
    #MRI  switching to appointment
    sql = "select distinct cg_padi_upload.vgroup_id,export_id,appointments.id,cg_padi_upload.mri_visit_number from cg_padi_upload,appointments 
     where appointments.vgroup_id = cg_padi_upload.vgroup_id and
            appointments.appointment_type = 'mri'
            and    mri_sent_flag ='N' and mri_status_flag in ('G') and mri_visit_number is not null " # ('Y','R') "
    results = connection.execute(sql)

    v_comment = " :list of vgroupid "+v_comment
    results.each do |r|
      v_comment = r[0].to_s+","+v_comment
    end
    @schedulerun.comment =v_comment[0..1990]
    @schedulerun.save
    v_past_vgroup_id = "0"
    v_cnt = 1
    results.each do |r|
      v_vgroup_id = r[0].to_s
      if v_vgroup_id  != v_past_vgroup_id
            v_past_vgroup_id = v_vgroup_id
            v_cnt = 1
      else
            v_cnt = v_cnt + 1
      end
      v_export_id  =v_wisc_siteid+r[1].to_s.rjust(4,padstr='0')
      v_appointment_id = r[2].to_s
      v_visit_number = "v"+r[3].to_s
      v_comment = "strt "+v_vgroup_id+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      # just using appt date
      sql_vgroup = "select round((DATEDIFF(a.appointment_date,p.dob)/365.25),2),
      round((DATEDIFF(v.vgroup_date,p.dob)/365.25),2),
      a.id from appointments a,vgroups v,participants p where v.id = "+v_vgroup_id+" 
                          and v.id = a.vgroup_id and a.id = "+v_appointment_id+"
                          and v.participant_id = p.id
                           and v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e,scan_procedures_vgroups spvg where spvg.vgroup_id = evm.vgroup_id and 
                                                            evm.enrollment_id = e.id  and e.do_not_share_scans_flag ='N')"
puts "PPPPP = apptid="+v_appointment_id+"  sql="+sql_vgroup      
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/padi_upload/[subjectid]_YYYYMMDD_wisc
       # just using appt age "_"+(results_vgroup.first)[1].to_s+
       # switching from age_at_appt to v#, and somehow also send the age_appt to link up with file name
      #####v_age = ((results_vgroup.first)[0].to_s).gsub(/\./,"")
      ####v_subject_dir = v_export_id+"_"+((results_vgroup.first)[0].to_s).gsub(/\./,"")+"_"+v_cnt.to_s+"_mri"
      v_subject_dir = v_export_id+"_"+v_visit_number+"_"+v_cnt.to_s+"_mri"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "mkdir "+v_parent_dir_target
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
      v_folder_array = [] # how to empty
      v_scan_desc_type_array = []
      v_cnt = 1
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
  ####          v_nii_file_name =  [subjectid]_[series_description /replace " " with -] , _[] , path- split / , last value]
            v_path_dir_array = r_dataset[4].split("/")
            #/mounts/data/raw/wrap140/wrp002_5938_03072008/001
            v_subject_vgroup_array = v_path_dir_array[4].split("_")
            v_subject_id = v_subject_vgroup_array[0]
            v_nii_file_name = v_subject_id+"_"+r_dataset[3].gsub(/ /,"-")+"_"+v_path_dir_array.last+".nii"
            v_nii_file_path = v_base_path+"/preprocessed/visits/"+v_path_dir_array[4].to_s+"/"+v_subject_id+"/unknown/"+v_nii_file_name

            if(v_series_desc_nii_hash[r_dataset[5]] == "Y")
                v_nii_flag = "Y"
                v_call = "rsync -av "+v_nii_file_path+" "+v_parent_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(/ /,"-")+"_"+v_path_dir_array.last+".nii"                
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
             # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
              v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
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
            # cp path ==> /tmp/padi_upload/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
         end # skipping if qc severe or incomplete    
      end

      sql_status = "select mri_status_flag from cg_padi_upload where vgroup_id ='"+r[0].to_s+"' "
      results_status = connection.execute(sql_status)
      if v_scan_desc_type_array.size < v_scan_type_limit   and (results_status.first)[0] != "R"
    puts "bbbbb !R or not enough scan types "
        sql_dirlist = "update cg_padi_upload set general_comment =' NOT ALL SCAN TYPES!!!! "+v_folder_array.join(", ")+"' where vgroup_id ='"+r[0].to_s+"' "
        results_dirlist = connection.execute(sql_dirlist)
        # send email 
        v_subject = "padi_upload "+r[0].to_s+" is missing some scan types --- set mri_status_flag ='R' to send  : scans ="+v_folder_array.join(", ")
        v_email = "noreply_johnson_lab@medicine.wisc.edu"
        PandaMailer.schedule_notice(v_subject,{:send_to => v_email}).deliver

        # mail(
        #   :from => "noreply_johnson_lab@medicine.wisc.edu"
        #   :to => "noreply_johnson_lab@medicine.wisc.edu", 
        #   :subject => v_subject
        # )
        PandaMailer.schedule_notice(v_subject,{:send_to => "noreply_johnson_lab@medicine.wisc.edu"}).deliver
         v_comment_warning = v_comment_warning+"  "+v_scan_desc_type_array.size.to_s+" scan type "+r[0].to_s+" sp"+r[1].to_s
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
#         /tmp/padi_upload/adrc00045_20130920_wisc/008_DTI/008

        sql_dirlist = "update cg_padi_upload set mri_dir_list =concat('"+v_folder_array.join(", ")+"',mri_dir_list) where vgroup_id ='"+r[0].to_s+"' "
        results_dirlist = connection.execute(sql_dirlist)
# TURN INTO A LOOP -- need to get rid of dates 
        v_dicom_field_array =['0010,0030','0010,0010','0008,0050','0008,1030','0010,0020','0040,0254','0008,0080','0008,1010','0009,1002','0009,1030','0018,1000',
                        '0025,101A','0040,0242','0040,0243','0008,0020','0008,0021','0008,0022','0008,0023','0040,0244']
        v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>v_export_id,'0008,0050'=>'Accession Number',
                           '0008,1030'=>'Study Description', '0010,0020'=>v_visit_number,'0040,0254'=>'Performed Proc Step Desc',
                            '0008,0080'=>'Institution Name','0008,1010'=>'Station Name','0009,1002'=>'Private',
                            '0009,1030'=>'Private','0018,1000'=>'Device Serial Number','0025,101A'=>'Private',
                            '0040,0242'=>'Performed Station Name','0040,0243'=>'Performed Location',
                            '0008,0020'=>'19720101','0008,0021'=>'19720101','0008,0022'=>'19720101',   
                            '0008,0023'=>'19720101','0040,0244'=>'19720101'}
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
              Dir.glob(v_parent_dir_target+'/*/*/*.4*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
              Dir.glob(v_parent_dir_target+'/*/*/*.5*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
              Dir.glob(v_parent_dir_target+'/*/*/*.6*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
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
        v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/upload_padi/"    #+v_subject_dir
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
        #v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/upload_padi  -zcf /home/panda_user/upload_padi/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
        v_call =  'ssh panda_user@merida.dom.wisc.edu " cd /home/panda_user/upload_padi/; zip -r '+v_subject_dir+'.zip '+v_subject_dir+' "  '
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
        v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/upload_padi/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_padi
         v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/upload_padi/"+v_subject_dir+".zip "+v_target_dir+'/'+v_subject_dir+".zip"
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
        v_source = v_target_dir+'/'+v_subject_dir+".zip"
        v_target = v_subject_dir+".tar.gz"

 

####        Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
####            sftp.upload!(v_source, v_target)
####        end
# WANT TO CHECK TRANSFERS
        v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".zip"
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close        
        
        sql_sent = "update cg_padi_upload set mri_sent_flag ='Y' where VGROUP_id ='"+r[0].to_s+"'  "
        results_sent = connection.execute(sql_sent)
      end
      v_comment = "end "+r[0].to_s+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save 
    end
              
    @schedulerun.comment =("successful finish padi_upload "+v_comment_warning+" "+v_comment[0..1990])
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
      @schedulerun.comment ="starting sleep_t1"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
    connection = ActiveRecord::Base.connection();

    # fill in missing enrollmentid/scan_procedure_id
    sql = "select distinct subjectid from cg_sleep_t1 where enrollment_id is NULL or scan_procedure_id is NULL"
    results_blanks = connection.execute(sql)
    results_blanks.each do |r|
       v_subjectid_visit_num = r[0]
       v_subjectid = r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
       v_scan_procedure_id = get_sp_id_from_subjectid_v(v_subjectid_visit_num)
       v_enrollment_id = get_enrollment_id_from_subjectid_v(v_subjectid_visit_num)
       sql_update = "update cg_sleep_t1 set enrollment_id = "+v_enrollment_id.to_s+", 
                       scan_procedure_id = "+v_scan_procedure_id.to_s+" 
                       where subjectid ='"+v_subjectid_visit_num+"'"
       if !v_scan_procedure_id.blank? and !v_enrollment_id.blank?
          results = connection.execute(sql_update)
       end
    end
    
    # t1 and resting bold from /unknown   asl from /asl
    v_target_dir = "/home/panda_user/upload_sleep_t1"
    v_final_target = "ftp directory tbd"
    v_series_description_category_array = ['T1_Volumetric'] #,'ASL']
    v_series_description_category_id_array = [19] #,1]
    sql = "select distinct subjectid, enrollment_id, scan_procedure_id from cg_sleep_t1
           where ( sleep_sent_flag != 'Y' or sleep_sent_flag is NULL)
           and ( sleep_status_flag != 'N' or sleep_status_flag is NULL)
           and enrollment_id is not NULL 
           and scan_procedure_id is not NULL
           "
    results = connection.execute(sql)
    # get each subject , make target dir 
    # get each series decription / file name / nii file based on series_description_category
    # mkdir with series_description_category, # of scan - e.g. 3rd T1
    # copy over the .nii file, r
    # bzip2 each subjectid dir
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
      
      v_comment = "strt "+r[0]+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0]+"')
       and v.id in ( select scvg.vgroup_id from scan_procedures_vgroups scvg where scvg.scan_procedure_id  in ("+r[2].to_s+"))"
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/adrc_upload/[subjectid]_YYYYMMDD_wisc
      v_export_id = (@schedule.id).to_s+"_"+r[0].to_s
      v_subject_dir = v_export_id+"_"+(results_vgroup.first)[0].to_s+"_wisc"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      v_subjectid = r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                  from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                  and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1') 
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   order by appointments.appointment_date "

      results_dataset = connection.execute(sql_dataset)
      v_cnt = 1
      v_dir_target = ""
      v_scan_desc_type_array = []
      v_folder_array = [] # how to empty
      results_dataset.each do |r_dataset|
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
  puts "aaaaaa v_dir_target = "+v_dir_target
             v_folder_array.push(v_dir_target)

              # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
               v_tmp = "/tmp/"+v_dir_target 
               v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
               v_call = "mise "+v_path+" "+v_tmp 
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
             # cp path ==> /tmp/adrc_dti/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
       end


       if v_scan_desc_type_array.size > 0   
puts "dddddd in ids dicoms"
puts " /tmp dir = "+"/tmp/"+v_dir_target+"/*/*.*  0. 1. 2. *.dcm" 
 # TURN INTO A LOOP   
        v_dicom_field_array =['0010,0030','0010,0010','0008,0050','0008,1030','0010,0020','0040,0254','0008,0080','0008,1010','0009,1002','0009,1030','0018,1000',
                        '0025,101A','0040,0242','0040,0243']
        v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name','0008,0050'=>'Accession Number',
                           '0008,1030'=>'Study Description', '0010,0020'=>'Patient ID','0040,0254'=>'Performed Proc Step Desc',
                            '0008,0080'=>'Institution Name','0008,1010'=>'Station Name','0009,1002'=>'Private',
                            '0009,1030'=>'Private','0018,1000'=>'Device Serial Number','0025,101A'=>'Private',
                            '0040,0242'=>'Performed Station Name','0040,0243'=>'Performed Location'}


        # v_dicom_field_array =['0010,0030']
        # v_dicom_field_value_hash ={'0010,0030'=>'DOB'}
      ####  v_dicom_field_array.each do |dicom_key|
                Dir.glob('/tmp/'+v_dir_target+'/*/*.dcm').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                      v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                                  d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                             end 
                                                                                       end }

                                                                               
               Dir.glob('/tmp/'+v_dir_target+'/*/*.0*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }

              Dir.glob('/tmp/'+v_dir_target+'/*/*.1*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm)
                                                                                            end 
                                                                                         end }   
             Dir.glob('/tmp/'+v_dir_target+'/*/*.2*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }   
             Dir.glob('/tmp/'+v_dir_target+'/*/*.3*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }                                                                               

        v_call = "rsync -av /tmp/"+v_dir_target+" panda_user@merida.dom.wisc.edu:"+v_parent_dir_target 
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close

         v_call = "rm -rf /tmp/"+v_dir_target
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close


        end                            


     
      #tar.gz subjectid dir
      v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
      v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      
      # fsftp dir when set -- not practical - not using auto move
      # sftp -- shared helper hasthe username /password and address
 #     v_username = Shared.panda_admin_sftp_username # get from shared helper -- leaving as panda_admin
 #     v_passwrd = Shared.panda_admin_sftp_password   # get from shared helperwhich is not on github
      # switch on new platform
      #v_username = Shared.panda_user_sftp_username # get from shared helper
      #v_passwrd = Shared.panda_user_sftp_password   # get from shared helperwhich is not on github
 #     v_ip = Shared.dom_sftp_host_address # get from shared helper
 #     v_sftp_dir = Shared.antuano_target_path
      
      # problem that files are on merida, but panda running from nelson
      # need to ssh to merida as pand_admin, then sftp
 #     v_source = "panda_user@merida.dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"
      
 #     v_target = v_sftp_dir+"/"   #+v_subject_dir+".tar.gz"
      
# puts "aaaaaa v_source = "+v_source
# puts "bbbbbb v_target = "+v_target
#       Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
#           sftp.upload!(v_source, v_target)
#       end
#       
      
      sql_done = "update cg_sleep_t1 set sleep_sent_flag ='Y', sleep_dir_list = '"+ v_folder_array.join(",")+"' where subjectid = '"+r[0]+"'"
      results_done = connection.execute(sql_done)
  
    end # results
    
    @schedulerun.comment =("successful finish sleep_t1_upload "+v_comment_warning+" "+v_comment[0..1990])
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
                             v_call =  'ssh panda_user@merida.dom.wisc.edu "'  +v_script+' -p '+sp.codename+'  -b '+v_subjectid+' --all "  ' 
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
      @schedulerun.comment ="starting wahlin_t1_asl_resting_upload"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
    connection = ActiveRecord::Base.connection();
    
    # t1 and resting bold from /unknown   asl from /asl
    v_target_dir = "/home/panda_user/wahlin_t1_asl_resting"
    v_final_target = "ftp directory tbd"
    v_series_description_category_array = ['T1_Volumetric','resting_fMRI'] #,'ASL']
    v_series_description_category_id_array = [19, 17] #,1]
    sql = "select distinct subjectid, enrollment_id, scan_procedure_id from cg_adrc_upload
           where ( wahlin_t1_asl_resting_sent_flag != 'Y' or wahlin_t1_asl_resting_sent_flag is NULL)
           and ( wahlin_t1_asl_resting_status_flag != 'N' or wahlin_t1_asl_resting_status_flag is NULL)
           "
    results = connection.execute(sql)
    
    # get each subject , make target dir 
    # get each series decription / file name / nii file based on series_description_category
    # mkdir with series_description_category, # of scan - e.g. 3rd T1
    # copy over the .nii file, r
    # bzip2 each subjectid dir
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
      
      v_comment = "strt "+r[0]+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0]+"')
       and v.id in ( select scvg.vgroup_id from scan_procedures_vgroups scvg where scvg.scan_procedure_id  in (22))"
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/adrc_upload/[subjectid]_YYYYMMDD_wisc
      v_export_id = (@schedule.id).to_s+"_"+r[0].to_s
      v_subject_dir = v_export_id+"_"+(results_vgroup.first)[0].to_s+"_wisc"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      v_subjectid = r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                  from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                  and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','resting_fMRI','resting fMRI','resting+fMRI') 
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_folder_array = [] # how to empty
      v_scan_desc_type_array = []
      v_cnt = 1
      results_dataset.each do |r_dataset|
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
             
            v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            v_scan_procedure_path = ScanProcedure.find(r[2]).codename
            v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/unknown/"+ v_subjectid+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
        
      end

      # get asl
      v_series_description_category_array = ['ASL']
      v_series_description_category_id_array = [1]
      # from the adrc_pcvipr
                sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                      from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                      where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                      and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                      and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                      and series_description_maps.series_description_type_id = series_description_types.id
                      and series_description_types.series_description_type in ('ASL') 
                      and image_datasets.series_description != 'ASL CBF'
                      and image_datasets.series_description !=  'Cerebral Blood Flow'
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                       order by appointments.appointment_date "
          results_dataset = connection.execute(sql_dataset)
          # v_preprocessed_path = v_base_path+"/preprocessed/visits/asthana.adrc-clinical-core.visit1/"
           v_preprocessed_path = v_base_path+"/preprocessed/visits/"
          v_scan_procedure_path = ScanProcedure.find(r[2]).codename
          v_preprocessed_path  = v_preprocessed_path +v_scan_procedure_path+"/"
          v_cnt = 1
          results_dataset.each do |r_dataset|
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
                v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
            stdin, stdout, stderr = Open3.popen3(v_call)
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
                # cp path ==> /tmp/adrc_pcvipr/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)

                      # get the ASL_fmap and PDmap 
          puts "aaaaaaaaaa v_series_description_type ="+v_series_description_type
           if v_series_description_type == "ASL"
              v_asl_nii = v_preprocessed_path+r[0]+"/asl/ASL_fmap_"+r[0]+"_*.nii"
              v_pdmap_nii = v_preprocessed_path+r[0]+"/asl/PDmap_"+r[0]+"_*.nii"
              v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av "+ v_asl_nii+" "+v_parent_dir_target+"/"+v_dir_target+"' "
        puts "ASL ="+v_call
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
              v_call = "rsync -av "+ v_pdmap_nii+" "+v_parent_dir_target
              v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av "+ v_pdmap_nii+" "+v_parent_dir_target+"/"+v_dir_target+"' "
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
            if v_series_description_type == "ASL"
              v_asl_nii = v_preprocessed_path+r[0]+"/asl/images/ASL_fmap_"+r[0]+"_*.nii"
              v_pdmap_nii = v_preprocessed_path+r[0]+"/asl/images/PDmap_"+r[0]+"_*.nii"
              v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av "+ v_asl_nii+" "+v_parent_dir_target+"/"+v_dir_target+"' "
        puts "ASL ="+v_call
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
              v_call = "rsync -av "+ v_pdmap_nii+" "+v_parent_dir_target
              v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av "+ v_pdmap_nii+" "+v_parent_dir_target+"/"+v_dir_target+"' "
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
      
      #tar.gz subjectid dir
      v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
      v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      
      # fsftp dir when set -- not practical - not using auto move
      # sftp -- shared helper hasthe username /password and address
 #     v_username = Shared.panda_admin_sftp_username # get from shared helper -- leaving as panda_admin
 #     v_passwrd = Shared.panda_admin_sftp_password   # get from shared helperwhich is not on github
      # switch on new platform
      #v_username = Shared.panda_user_sftp_username # get from shared helper
      #v_passwrd = Shared.panda_user_sftp_password   # get from shared helperwhich is not on github
 #     v_ip = Shared.dom_sftp_host_address # get from shared helper
 #     v_sftp_dir = Shared.antuano_target_path
      
      # problem that files are on merida, but panda running from nelson
      # need to ssh to merida as pand_admin, then sftp
 #     v_source = "panda_user@merida.dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"
      
 #     v_target = v_sftp_dir+"/"   #+v_subject_dir+".tar.gz"
      
# puts "aaaaaa v_source = "+v_source
# puts "bbbbbb v_target = "+v_target
#       Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
#           sftp.upload!(v_source, v_target)
#       end
#       
      
      sql_done = "update cg_adrc_upload set wahlin_t1_asl_resting_sent_flag ='Y', wahlin_t1_asl_resting_dir_list = '"+ v_folder_array.join(",")+"' where subjectid = '"+r[0]+"'"
      results_done = connection.execute(sql_done)
  
    end # results
    
    @schedulerun.comment =("successful finish wahlin_t1_asl_resting_upload "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
  
  end

  def run_tissueseg_spm12

    v_base_path = Shared.get_base_path()
    v_log_base ="/mounts/data/preprocessed/logs/"
    v_process_name = "tissueseg_spm12"
    v_script_dev = v_base_path+"/data1/lab_scripts/T1SegProc/v5/t1segproc.sh"
    v_script = v_base_path+"/SysAdmin/production/T1SegProc/v5/t1segproc.sh"
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
                        v_comment = "str "+v_subjectid_v_num+";"+v_comment
#puts " RUN t1segproc.sh for "+f+"    "+v_subjectid_v_num+"  "+v_subjectid_tissue_seg
                        v_call =  'ssh panda_user@merida.dom.wisc.edu "'  +v_script+' -p '+sp.codename+'  -b '+v_subjectid+' " ' 
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
                    if (f.start_with?("o") and f.end_with?(".nii") ) # or v_subjectid_actual.include?("shp")
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
                             v_call =  'ssh panda_user@merida.dom.wisc.edu "'  +v_script+' -p '+sp.codename+'  -b '+v_subjectid+'"' 
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
      @schedulerun.comment ="starting washu_upload"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
    connection = ActiveRecord::Base.connection();
    # shp, alz, pc, adni, dodadni, lmpd
    v_scan_procedure_exclude =   [21,28,31,34,15,19,23,35,44,51,50,49,20,24,26,36,41] # [21,28,31,34,15,19,23,35,44,51,50,49]
    # just get the predicttau
     v_scan_procedures = [58]  #[20,24,26,36,41,58]  # how to only get adrc impact? 
     #not limiting by protocol #scan_procedures_vgroups.scan_procedure_id in ("+v_scan_procedures.join(",")+")
     # getting adrc impact from t_adrc_impact_20150105  --- change to get from refreshing table?
     v_pet_tracer_array = [7] #1,2] # pib and fdg and thk5117  

     v_scan_type_limit = 1 
     v_series_desc_array =['T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','T2','T2 Flair','T2_Flair','T2+Flair','DTI','ASL','resting_fMRI']
     v_series_desc_nii_hash = {'nothing'=>"Y"} #{ 'T1 Volumetic'=>"Y",'T1 Volumetric'=>"Y",'T1+Volumetric'=>"Y",'T1_Volumetric'=>"Y",'T1'=>"Y"}
    # recruit new  scans ---   change 
    v_weeks_back = "2"  # cwant to give time for quality checks etc. 
    # NEED TO LIMIT ADRC BY LP --- NEED TO REFRESH ADRC IMPACT 
    #  t_adrc_impact_control_20150216 where participant_id is not null and lp_completed_flag ='Y')
     #(participants.wrapnum is not null and participants.wrapnum > '')
     # only want the tau  - petid=7 
    sql = "select distinct vgroups.id, vgroups.participant_id,
              vgroups.transfer_mri, vgroups.transfer_pet
              from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups,participants    
            where participants.id = vgroups.participant_id and
             ( 
                (vgroups.participant_id*-1) in ( select t_washu_adrc_20150215.participant_id from t_washu_adrc_20150215)
               or vgroups.participant_id in ( select t_washu_predicttau_20150909.participant_id from t_washu_predicttau_20150909)
              )
              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
              and vgroups.id = scan_procedures_vgroups.vgroup_id
              and scan_procedures_vgroups.scan_procedure_id not in ("+v_scan_procedure_exclude.join(",")+")
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
              and vgroups.vgroup_date < DATE_SUB(curdate(), INTERVAL "+v_weeks_back+" WEEK)  
              and enrollments.do_not_share_scans_flag ='N'           
              and vgroups.id NOT IN ( select cg_washu_upload.vgroup_id from cg_washu_upload 
                                         where scan_procedure_id = scan_procedures_vgroups.scan_procedure_id )
              and ( ( (vgroups.transfer_mri ='yes' or vgroups.transfer_mri !='yes') and vgroups.transfer_pet ='yes' and vgroups.id 
                  in ( select appointments.vgroup_id from appointments, petscans where petscans.appointment_id = appointments.id
                           and petscans.lookup_pettracer_id in (7) )
                       )  
                  or 
                 (vgroups.transfer_mri ='yesSKIP'  and enrollments.id in ( select enrollment_id from cg_csf) 
                         and vgroups.participant_id in (select p.id from participants p where wrapnum is not null and wrapnum > ''))
                 or 
                 (vgroups.transfer_mri ='yesSKIP'  and vgroups.participant_id in (  select t_washu_predicttau_20150909.participant_id from t_washu_predicttau_20150909) )
                 or 
                 (vgroups.transfer_mri ='yesSKIP' and vgroups.completedlumbarpuncture = 'yes' 
                  and vgroups.participant_id in (select p.id from participants p where wrapnum is not null and wrapnum > '')
                  and vgroups.id 
                  in ( select appointments.vgroup_id from appointments, lumbarpunctures where lumbarpunctures.appointment_id = appointments.id 
                  and lumbarpunctures.lpsuccess = 1) ) )"
    results = connection.execute(sql)
    results.each do |r|
          enrollments = Enrollment.where("id in (select enrollment_id from enrollment_vgroup_memberships where vgroup_id in(?))",r[0])
          enrollment_enumbers_array = []
          enrollments.each do |e|
                    enrollment_enumbers_array.push(e.enumber)
          end
          enrollment_enumbers = enrollment_enumbers_array.join(",")
          scan_procedures = ScanProcedure.where("id in (select scan_procedure_id from scan_procedures_vgroups where vgroup_id in(?))",r[0])
          scan_procedure_codename_array = []
          scan_procedures.each do |e|
                    scan_procedure_codename_array.push(e.codename)
          end
          scan_procedure_codenames = scan_procedure_codename_array.join(",")
          v_mri_status_flag = "N"
          v_pet_status_flag ="N"
          if (r[2].to_s == "yes")
               v_mri_status_flag = "Y" 
          end
          if (r[3].to_s == "yes")
               v_pet_status_flag = "Y" 
          end
          sql2 = "insert into cg_washu_upload (vgroup_id,mri_sent_flag,mri_status_flag, pet_sent_flag,pet_status_flag,participant_id,enumbers,codenames) 
          values('"+r[0].to_s+"','N','"+v_mri_status_flag+"', 'N','"+v_pet_status_flag+"',"+r[1].to_s+",'"+enrollment_enumbers+"','"+scan_procedure_codenames+"')"
          results2 = connection.execute(sql2)
    end

    sql = "insert into cg_washu_participants (participant_id)
              select distinct cg_washu_upload.participant_id from cg_washu_upload 
              where participant_id NOT IN ( select participant_id from cg_washu_participants)
              and participant_id is not null"

     results = connection.execute(sql)

     sql = "update cg_washu_upload 
            set cg_washu_upload.export_id = ( select cg_washu_participants.export_id from cg_washu_participants 
                                 where cg_washu_participants.participant_id = cg_washu_upload.participant_id)"
     results = connection.execute(sql)

    v_folder_array = Array.new
    v_scan_desc_type_array = Array.new
    # check for dir in /tmp
    v_target_dir ="/tmp/washu_upload"
    # v_target_dir ="/Volumes/Macintosh_HD2/washu_upload"
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
    #PET
    sql = "select distinct vgroup_id,export_id,enumbers from cg_washu_upload where pet_sent_flag ='N' and pet_status_flag in ('G') " # ('Y','R') "
    results = connection.execute(sql)

    v_comment = " :list of vgroupids"+v_comment
    results.each do |r|

      v_comment = r[0].to_s+","+v_comment
    end
    @schedulerun.comment =v_comment[0..1990]
    @schedulerun.save
    results.each do |r|
      v_vgroup_id = r[0].to_s
      v_export_id = r[1]
      v_comment = "strt "+v_vgroup_id+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
    
      sql_vgroup = "select round((DATEDIFF(max(v.vgroup_date),p.dob)/365.25),2) from vgroups v, participants p where 
                 v.participant_id = p.id
                and v.id = "+v_vgroup_id+" and v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e,scan_procedures_vgroups spvg where spvg.vgroup_id = evm.vgroup_id and 
                                                            evm.enrollment_id = e.id and  e.do_not_share_scans_flag ='N')"
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/washu_upload/[subjectid]_YYYYMMDD_wisc
      v_subject_dir = v_export_id.to_s+"_"+(results_vgroup.first)[0].to_s+"_pet_wisc"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "mkdir "+v_parent_dir_target
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
               v_petfile_name = v_petfile_name.gsub(v_subject_id,v_export_id.to_s )
         end
          if 1 == 2 and v_pettracer_id.to_s != "7"
            v_petfile_target_name = v_tracer+"_"+v_petfile_name
            v_call = "rsync -av "+v_petfile_path+" "+v_parent_dir_target+"/"+v_petfile_target_name               
puts("this petid= "+v_pettracer_id.to_s )
puts(v_call)
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
          # tau 
          if v_pettracer_id.to_s == "7"    # only want tau
             v_processed_path = v_base_path+"/preprocessed/outside_batches/TauPredict/20150811_TauPredict/"
             v_enumbers_array.each do |e|
               v_subject_id = e
               v_source_file = v_subject_id+"_T1_FS.nii"
               v_export_file_name = v_export_id.to_s+"_T1_FS_"+v_tracer+".nii"
               v_check_path = v_processed_path+v_subject_id+"/"+v_source_file
               # check if exisits
               if(File.file?v_check_path)
                   v_call = "rsync -av "+v_check_path+" "+v_parent_dir_target+"/"+v_export_file_name               
puts(v_call)
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

       
               v_source_file = "Coreg_"+v_subject_id+"HYPR_DVR.nii"
               v_export_file_name = "Coreg_"+v_export_id.to_s+"HYPR_DVR_"+v_tracer+".nii"
               v_check_path = v_processed_path+v_subject_id+"/"+v_source_file
               # check if exisits
               if(File.file?v_check_path)
                   v_call = "rsync -av "+v_check_path+" "+v_parent_dir_target+"/"+v_export_file_name               
puts( v_call)
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
          end

       end

            v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/upload_washu/"    #+v_subject_dir
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
        v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/upload_washu  -zcf /home/panda_user/upload_washu/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
        v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/upload_washu/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_washu
         v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/upload_washu/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close

####        # sftp -- shared helper hasthe username /password and address
####        v_username = Shared.washu_sftp_username # get from shared helper
####        v_passwrd = Shared.washu_sftp_password   # get from shared helperwhich is not on github
####        v_ip = Shared.washu_sftp_host_address # get from shared helper
        v_source = v_target_dir+'/'+v_subject_dir+".tar.gz"
        v_target = v_subject_dir+".tar.gz"

 

####        Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
####            sftp.upload!(v_source, v_target)
####        end
# WANT TO CHECK TRANSFERS
        v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".tar.gz"
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close        
        
        sql_sent = "update cg_washu_upload set pet_sent_flag ='Y' where vgroup_id ='"+r[0].to_s+"'  "
        results_sent = connection.execute(sql_sent)   

    end

    # get  subjectid to upload    # USING G AS LIMIT FOR TESTING
    #MRI  switching to appointment
    sql = "select distinct cg_washu_upload.vgroup_id,export_id,appointments.id from cg_washu_upload,appointments 
     where appointments.vgroup_id = cg_washu_upload.vgroup_id and
            appointments.appointment_type = 'mri'
            and    mri_sent_flag ='N' and mri_status_flag in ('G') " # ('Y','R') "
    results = connection.execute(sql)

    v_comment = " :list of vgroupid "+v_comment
    results.each do |r|
      v_comment = r[0].to_s+","+v_comment
    end
    @schedulerun.comment =v_comment[0..1990]
    @schedulerun.save
    v_past_vgroup_id = "0"
    v_cnt = 1
    results.each do |r|
      v_vgroup_id = r[0].to_s
      if v_vgroup_id  != v_past_vgroup_id
            v_past_vgroup_id = v_vgroup_id
            v_cnt = 1
      else
            v_cnt = v_cnt + 1
      end
      v_export_id = r[1].to_s
      v_appointment_id = r[2].to_s
      v_comment = "strt "+v_vgroup_id+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 

      sql_vgroup = "select round((DATEDIFF(a.appointment_date,p.dob)/365.25),2),
      round((DATEDIFF(v.vgroup_date,p.dob)/365.25),2),
      a.id from appointments a,vgroups v,participants p where v.id = "+v_vgroup_id+" 
                          and v.id = a.vgroup_id and a.id = "+v_appointment_id+"
                          and v.participant_id = p.id
                           and v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e,scan_procedures_vgroups spvg where spvg.vgroup_id = evm.vgroup_id and 
                                                            evm.enrollment_id = e.id  and e.do_not_share_scans_flag ='N')"
puts "PPPPP = apptid="+v_appointment_id+"  sql="+sql_vgroup      
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/washu_upload/[subjectid]_YYYYMMDD_wisc
      v_subject_dir = v_export_id.to_s+"_"+(results_vgroup.first)[1].to_s+"_"+(results_vgroup.first)[0].to_s+"_"+v_cnt.to_s+"_mri_wisc"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "mkdir "+v_parent_dir_target
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
                  and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('"+v_series_desc_array.join("','")+"') 
                  and image_datasets.series_description != 'DTI whole brain  2mm FATSAT ASSET'
                  and vgroups.id = "+v_vgroup_id+"  and appointments.id = "+v_appointment_id+"
                   order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_folder_array = [] # how to empty
      v_scan_desc_type_array = []
      v_cnt = 1
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
  ####          v_nii_file_name =  [subjectid]_[series_description /replace " " with -] , _[] , path- split / , last value]
            v_path_dir_array = r_dataset[4].split("/")
            #/mounts/data/raw/wrap140/wrp002_5938_03072008/001
            v_subject_vgroup_array = v_path_dir_array[4].split("_")
            v_subject_id = v_subject_vgroup_array[0]
            v_nii_file_name = v_subject_id+"_"+r_dataset[3].gsub(/ /,"-")+"_"+v_path_dir_array.last+".nii"
            v_nii_file_path = v_base_path+"/preprocessed/visits/"+v_path_dir_array[4].to_s+"/"+v_subject_id+"/unknown/"+v_nii_file_name

            if(v_series_desc_nii_hash[r_dataset[5]] == "Y")
                v_nii_flag = "Y"
                v_call = "rsync -av "+v_nii_file_path+" "+v_parent_dir_target+"/"+v_export_id.to_s+"_"+r_dataset[3].gsub(/ /,"-")+"_"+v_path_dir_array.last+".nii"                
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
             # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
              v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
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
            # cp path ==> /tmp/washu_upload/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
         end # skipping if qc severe or incomplete    
      end

      sql_status = "select mri_status_flag from cg_washu_upload where vgroup_id ='"+r[0].to_s+"' "
      results_status = connection.execute(sql_status)
      if v_scan_desc_type_array.size < v_scan_type_limit   and (results_status.first)[0] != "R"
    puts "bbbbb !R or not enough scan types "
        sql_dirlist = "update cg_washu_upload set general_comment =' NOT ALL SCAN TYPES!!!! "+v_folder_array.join(", ")+"' where vgroup_id ='"+r[0].to_s+"' "
        results_dirlist = connection.execute(sql_dirlist)
        # send email 
        v_subject = "washu_upload "+r[0].to_s+" is missing some scan types --- set mri_status_flag ='R' to send  : scans ="+v_folder_array.join(", ")
        v_email = "noreply_johnson_lab@medicine.wisc.edu"
        PandaMailer.schedule_notice(v_subject,{:send_to => v_email}).deliver

        # mail(
        #   :from => "noreply_johnson_lab@medicine.wisc.edu"
        #   :to => "noreply_johnson_lab@medicine.wisc.edu", 
        #   :subject => v_subject
        # )
        PandaMailer.schedule_notice(v_subject,{:send_to => "noreply_johnson_lab@medicine.wisc.edu"}).deliver
         v_comment_warning = v_comment_warning+"  "+v_scan_desc_type_array.size.to_s+" scan type "+r[0].to_s+" sp"+r[1].to_s
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
#         /tmp/washu_upload/adrc00045_20130920_wisc/008_DTI/008

        sql_dirlist = "update cg_washu_upload set mri_dir_list =concat('"+v_folder_array.join(", ")+"',mri_dir_list) where vgroup_id ='"+r[0].to_s+"' "
        results_dirlist = connection.execute(sql_dirlist)
# TURN INTO A LOOP -- need to get rid of dates 
        v_dicom_field_array =['0010,0030','0010,0010','0008,0050','0008,1030','0010,0020','0040,0254','0008,0080','0008,1010','0009,1002','0009,1030','0018,1000',
                        '0025,101A','0040,0242','0040,0243','0008,0020','0008,0021','0008,0022','0008,0023','0040,0244']
        v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name','0008,0050'=>'Accession Number',
                           '0008,1030'=>'Study Description', '0010,0020'=>'Patient ID','0040,0254'=>'Performed Proc Step Desc',
                            '0008,0080'=>'Institution Name','0008,1010'=>'Station Name','0009,1002'=>'Private',
                            '0009,1030'=>'Private','0018,1000'=>'Device Serial Number','0025,101A'=>'Private',
                            '0040,0242'=>'Performed Station Name','0040,0243'=>'Performed Location',
                            '0008,0020'=>'Study Date','0008,0021'=>'Series Date','0008,0022'=>'Acquisition Date',   
                            '0008,0023'=>'Content Date','0040,0244'=>'Performed Procedure Step Start Date'}
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
              Dir.glob(v_parent_dir_target+'/*/*/*.4*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
              Dir.glob(v_parent_dir_target+'/*/*/*.5*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                        v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                              d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                           end 
                                                                                        end }
              Dir.glob(v_parent_dir_target+'/*/*/*.6*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
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
        v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/upload_washu/"    #+v_subject_dir
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
        v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/upload_washu  -zcf /home/panda_user/upload_washu/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
        v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/upload_washu/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_washu
         v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/upload_washu/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close

####        # sftp -- shared helper hasthe username /password and address
####        v_username = Shared.washu_sftp_username # get from shared helper
####        v_passwrd = Shared.washu_sftp_password   # get from shared helperwhich is not on github
####        v_ip = Shared.washu_sftp_host_address # get from shared helper
        v_source = v_target_dir+'/'+v_subject_dir+".tar.gz"
        v_target = v_subject_dir+".tar.gz"

 

####        Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
####            sftp.upload!(v_source, v_target)
####        end
# WANT TO CHECK TRANSFERS
        v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".tar.gz"
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close        
        
        sql_sent = "update cg_washu_upload set mri_sent_flag ='Y' where VGROUP_id ='"+r[0].to_s+"'  "
        results_sent = connection.execute(sql_sent)
      end
      v_comment = "end "+r[0].to_s+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save 
    end
              
    @schedulerun.comment =("successful finish washu_upload "+v_comment_warning+" "+v_comment[0..1990])
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
      @schedulerun.comment ="starting antuano_20130916_upload"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_comment_warning =""
      v_stop_file_name = v_process_name+"_stop"
      v_stop_file_path = v_log_base+v_stop_file_name
    connection = ActiveRecord::Base.connection();
    
    v_target_dir = "/home/panda_user/upload_antuano_20130916"
    v_final_target = "ftp directory tbd"
    v_series_description_category_array = ['T1_Volumetric','resting_fMRI']
    v_series_description_category_id_array = [19, 17]
    sql = "select distinct subjectid, enrollment_id, scan_procedure_id, export_id from cg_antuano_20130916
           where ( done_flag != 'Y' or done_flag is NULL)
           and ( status_flag != 'N' or status_flag is NULL)
           and resting_fmri_flag ='Y'
           and t1_volumetric_flag = 'Y' "
    results = connection.execute(sql)
    
    # get each subject , make target dir with export id
    # get each series decription / file name / nii file based on series_description_category
    # mkdir with series_description_category, # of scan - e.g. 3rd T1
    # copy over the .nii file, replace subjectid with export_id
    # bzip2 each subjectid dir
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
      
      v_comment = "strt "+r[0]+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0]+"')
       and v.id in ( select scvg.vgroup_id from scan_procedures_vgroups scvg where scvg.scan_procedure_id  in (26,24))"
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/adrc_upload/[subjectid]_YYYYMMDD_wisc
      v_export_id = (@schedule.id).to_s+"_"+r[3].to_s
      v_subject_dir = v_export_id+"_"+(results_vgroup.first)[0].to_s+"_wisc"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      v_subjectid = r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                  from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                  and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','resting_fMRI','resting fMRI','resting+fMRI') 
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_folder_array = [] # how to empty
      v_scan_desc_type_array = []
      v_cnt = 1
      results_dataset.each do |r_dataset|
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
             
            v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            v_scan_procedure_path = ScanProcedure.find(r[2]).codename
            v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/unknown/"+ v_subjectid+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
        
      end
      
      #tar.gz subjectid dir
      v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
      v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      
      # fsftp dir when set -- not practical - not using auto move
      # sftp -- shared helper hasthe username /password and address
 #     v_username = Shared.panda_admin_sftp_username # get from shared helper -- leaving as panda_admin
 #     v_passwrd = Shared.panda_admin_sftp_password   # get from shared helperwhich is not on github
      # switch on new platform
      #v_username = Shared.panda_user_sftp_username # get from shared helper
      #v_passwrd = Shared.panda_user_sftp_password   # get from shared helperwhich is not on github
 #     v_ip = Shared.dom_sftp_host_address # get from shared helper
 #     v_sftp_dir = Shared.antuano_target_path
      
      # problem that files are on merida, but panda running from nelson
      # need to ssh to merida as pand_admin, then sftp
 #     v_source = "panda_user@merida.dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"
      
 #     v_target = v_sftp_dir+"/"   #+v_subject_dir+".tar.gz"
      
# puts "aaaaaa v_source = "+v_source
# puts "bbbbbb v_target = "+v_target
#       Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
#           sftp.upload!(v_source, v_target)
#       end
#       
      
      sql_done = "update cg_antuano_20130916 set done_flag ='Y' where subjectid = '"+r[0]+"'"
      results_done = connection.execute(sql_done)
  
    end # results
    
    @schedulerun.comment =("successful finish antuano_20130916_upload "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
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
                # call processing script- ARE THERE ANY THING WHICH IS REQUIRED ON merida, edna, gru
                v_coreg_t1 = v_fs_subjects_dir+"/"+v_subjectid_v_num+"/mri/T1_FS.nii"
                v_asl_dir_array = (r[4].gsub(" ","")).split(",")
                #asl_fmap_file_to_use split into an array --- define loc --- move the loc from above
                v_asl_dir_array.each do |d|    
                    v_dir_name_array = d.split("_") # sometimes just want first part of dir name   # -c '+v_coreg_t1+'   --- not specifying
                    v_call =  'ssh panda_user@merida.dom.wisc.edu "'+v_script+' -p '+v_sp_loc+'  -b '+v_subjectid+' -s1  '+v_dir_name_array[0] +'  --fsdir '+v_fs_subjects_dir +' " ' 
                    @schedulerun.comment ="str "+r[2]+"/"+d+"; "+v_comment[0..1990]
                    @schedulerun.save
                    v_comment = "str "+r[2]+"/"+d+"; "+v_comment
                    puts "rrrrrrr "+v_call
                    v_log = v_log + v_call+"\n"
                # end
                    begin
                        stdin, stdout, stderr = Open3.popen3(v_call)
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
      @schedulerun.comment ="starting fjell_20140506_upload"
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
    
    v_target_dir = "/home/panda_user/upload_fjell_20140506"
    v_final_target = "ftp directory tbd"
    v_series_description_category_array = ['T1_Volumetric','resting_fMRI', 'T2','T2_Flair','DTI']
    v_series_description_category_id_array = [19, 17, 20, 23,4]
    sql = "select distinct subjectid, enrollment_id, scan_procedure_id, export_id from cg_fjell_20140507
           where ( done_flag != 'Y' or done_flag is NULL)
           and ( status_flag = 'Y' or status_flag is NULL) 
           and export_id is not null" #  and subjectid in ('mrt00097', 'pdt00034','pdt00035')"  # sending ppt with incomplete sets
    results = connection.execute(sql)
    
    # get each subject , make target dir with export id
    # get each series decription / file name / nii file based on series_description_category
    # mkdir with series_description_category, # of scan - e.g. 3rd T1
    # copy over the .nii file, replace subjectid with export_id
    # bzip2 each subjectid dir
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
      
      v_comment = "strt "+r[0]+","+v_comment
      @schedulerun.comment =v_comment_warning +"; "+v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      sql_vgroup = "select distinct DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0]+"')
                                          and v.id in ( select scvg.vgroup_id from scan_procedures_vgroups scvg where scvg.scan_procedure_id  in (37) and scvg.scan_procedure_id in ("+r[2].to_s+")) "
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/adrc_upload/[subjectid]_YYYYMMDD_wisc
      v_export_id = (@schedule.id).to_s+"_"+r[3].to_s
      v_subject_dir = v_export_id+"_"+(results_vgroup.first)[0].to_s+"_wisc"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      v_subjectid = r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                  from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                  and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','resting_fMRI','resting fMRI','resting+fMRI','T2','T2_Flair','T2+Flair') 
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_folder_array = [] # how to empty
      v_scan_desc_type_array = []
      v_cnt = 1
      results_dataset.each do |r_dataset|
            v_series_description_type = r_dataset[5].gsub(" ","_")
            if !v_scan_desc_type_array.include?(v_series_description_type)
                 v_scan_desc_type_array.push(v_series_description_type)
            end
            # for dual enrollments need ids path to get to unknown path/nii
            v_path = r_dataset[4]
            v_dir_array = v_path.split("/")
            v_actual_scan_procedure = v_dir_array[4]
            v_subjectid_date_actual =v_subjectid
            if v_dir_array[5] == "mri"
              v_subjectid_date_actual = v_dir_array[6]
            else
                v_subjectid_date_actual = v_dir_array[5]  
            end
            v_subject_date_actual_array = v_subjectid_date_actual.split("_")
            v_subjectid_actual = v_subject_date_actual_array[0]

            v_dir = v_dir_array[(v_dir_array.size - 1)]
            v_dir_target = v_dir+"_"+v_series_description_type
            v_path = v_path.gsub("/Volumes/team/","").gsub("/Volumes/team-1/","").gsub("/Data/vtrak1/","")  #v_base_path+"/"+
            if v_folder_array.include?(v_dir_target)
              v_dir_target = v_dir_target+"_"+v_cnt.to_s
              v_cnt = v_cnt +1
              # might get weird if multiple types have dups - only expect T1/Bravo
            end
            v_folder_array.push(v_dir_target)   
             
            v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            v_scan_procedure_path = v_actual_scan_procedure # ScanProcedure.find(r[2]).codename
            # check if nii file exists
            if !Dir.glob(v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii").empty?
               puts "FOUND "+v_subjectid_actual+"_*_"+v_dir+".nii "
               v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"

               stdin, stdout, stderr = Open3.popen3(v_call)
               while !stdout.eof?
                  puts stdout.read 1024    
               end
               stdin.close
               stdout.close
               stderr.close

               # check if copied nii file is a directory -- found 2 exapmles
              v_call = "ssh panda_user@merida.dom.wisc.edu 'ls -dl "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
              puts v_call
              stdin, stdout, stderr = Open3.popen3(v_call)
               while !stdout.eof?
                  v_return = stdout.read 1024  
                  v_return_array = v_return.split(' ')
                  if v_return_array[1] == "2"
                     puts " its a DIRECTORY!!!!!"
                     @schedulerun.comment = "IT IS A DIRECTORY "+v_subjectid_actual+"_*_"+v_dir+".nii; "+@schedulerun.comment
                     @schedulerun.save
                     v_comment_warning = "IT IS A DIRECTORY "+v_subjectid_actual+"_*_"+v_dir+".nii;" +v_comment_warning
                  end

               end
               stdin.close
               stdout.close
               stderr.close


            else
              # nii not exists
              @schedulerun.comment = "MISSING "+v_subjectid_actual+"_*_"+v_dir+".nii; "+@schedulerun.comment
               @schedulerun.save
              puts "MISSIING "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii"
              v_comment_warning = "MISSIING "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii" +v_comment_warning
            end 
        
      end

      # get dti raw dicom for this subjectid/sp
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                   from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                   where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                   and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                   and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                   and series_description_maps.series_description_type_id = series_description_types.id
                   and series_description_types.series_description_type in ('DTI') 
                   and image_datasets.series_description != 'DTI whole brain  2mm FATSAT ASSET'
                   and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                    order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_cnt = 1
      v_dir_target = ""
      v_scan_desc_type_array = []
      results_dataset.each do |r_dataset|
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
  puts "aaaaaa v_dir_target = "+v_dir_target
             v_folder_array.push(v_dir_target)

              # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
               v_tmp = "/tmp/"+v_dir_target 
               v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
               v_call = "mise "+v_path+" "+v_tmp 
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
             # cp path ==> /tmp/adrc_dti/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
       end


       if v_scan_desc_type_array.size > 0   
puts "dddddd in ids dicoms"
puts " /tmp dir = "+"/tmp/"+v_dir_target+"/*/*.*  0. 1. 2. *.dcm" 
 # TURN INTO A LOOP   
        v_dicom_field_array =['0010,0030','0010,0010','0008,0050','0008,1030','0010,0020','0040,0254','0008,0080','0008,1010','0009,1002','0009,1030','0018,1000',
                        '0025,101A','0040,0242','0040,0243']
        v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name','0008,0050'=>'Accession Number',
                           '0008,1030'=>'Study Description', '0010,0020'=>'Patient ID','0040,0254'=>'Performed Proc Step Desc',
                            '0008,0080'=>'Institution Name','0008,1010'=>'Station Name','0009,1002'=>'Private',
                            '0009,1030'=>'Private','0018,1000'=>'Device Serial Number','0025,101A'=>'Private',
                            '0040,0242'=>'Performed Station Name','0040,0243'=>'Performed Location'}


        # v_dicom_field_array =['0010,0030']
        # v_dicom_field_value_hash ={'0010,0030'=>'DOB'}
      ####  v_dicom_field_array.each do |dicom_key|
                Dir.glob('/tmp/'+v_dir_target+'/*/*.dcm').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                      v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                                  d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                             end 
                                                                                       end }

                                                                               
               Dir.glob('/tmp/'+v_dir_target+'/*/*.0*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }

              Dir.glob('/tmp/'+v_dir_target+'/*/*.1*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm)
                                                                                            end 
                                                                                         end }   
             Dir.glob('/tmp/'+v_dir_target+'/*/*.2*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }   
             Dir.glob('/tmp/'+v_dir_target+'/*/*.3*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }                                                                               

        v_call = "rsync -av /tmp/"+v_dir_target+" panda_user@merida.dom.wisc.edu:"+v_parent_dir_target 
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close

         v_call = "rm -rf /tmp/"+v_dir_target
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close


        end                            

 #                             
 # # #puts "bbbbb dicom clean "+v_parent_dir_target+"/*/"
 # Dir.glob(v_parent_dir_target+'/*/*/*.dcm').each {|dcm| puts d = DICOM::DObject.read(dcm); if !d["0010,0030"].nil? 
 #                                                                                           d["0010,0030"].value = "DOB"; d.write(dcm) 
 #                                                                                               end } 
        
        sql_dir_list = "update cg_fjell_20140507 set dir_list ='"+v_folder_array.join(',')+"' where subjectid = '"+r[0]+"'"
        results_done = connection.execute(sql_dir_list)

      #tar.gz subjectid dir
      v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
      v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      
            # fsftp dir when set
            # sftp -- shared helper hasthe username /password and address
        #    v_username = Shared.panda_admin_sftp_username # get from shared helper
        #    v_passwrd = Shared.panda_admin_sftp_password   # get from shared helperwhich is not on github
            # switch on new platform
            #v_username = Shared.panda_user_sftp_username # get from shared helper
            #v_passwrd = Shared.panda_user_sftp_password   # get from shared helperwhich is not on github
        #    v_ip = Shared.dom_sftp_host_address # get from shared helper
        #    v_sftp_dir = Shared.goveas_target_path

            # problem that files are on merida, but panda running from nelson
            # need to ssh to merida as pand_admin, then sftp
        #    v_source = "panda_admin@merida.dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"

        #    v_target = v_sftp_dir+"/"   #+v_subject_dir+".tar.gz"

      # puts "aaaaaa v_source = "+v_source
      # puts "bbbbbb v_target = "+v_target
      #       Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
      #           sftp.upload!(v_source, v_target)
      #       end
      #
      sql_done = "update cg_fjell_20140507 set done_flag ='Y' where subjectid = '"+r[0]+"'"
      results_done = connection.execute(sql_done)
  
    end # results
    
    @schedulerun.comment =("successful finish fjell_20140506_upload "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
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
      @schedulerun.comment ="starting goveas_20131031_upload"
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
    
    v_target_dir = "/home/panda_user/upload_goveas_20131031"
    v_final_target = "ftp directory tbd"
    v_series_description_category_array = ['T1_Volumetric','resting_fMRI', 'T2','T2_Flair']
    v_series_description_category_id_array = [19, 17]
    sql = "select distinct subjectid, enrollment_id, scan_procedure_id, export_id from cg_goveas_20131031
           where ( done_flag != 'Y' or done_flag is NULL)
           and ( status_flag = 'Y' or status_flag is NULL) 
           and export_id is not null" #  and subjectid in ('mrt00097', 'pdt00034','pdt00035')"  # sending ppt with incomplete sets
    results = connection.execute(sql)
    
    # get each subject , make target dir with export id
    # get each series decription / file name / nii file based on series_description_category
    # mkdir with series_description_category, # of scan - e.g. 3rd T1
    # copy over the .nii file, replace subjectid with export_id
    # bzip2 each subjectid dir
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
      
      v_comment = "strt "+r[0]+","+v_comment
      @schedulerun.comment =v_comment_warning +"; "+v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0]+"')
                                          and v.id in ( select scvg.vgroup_id from scan_procedures_vgroups scvg where scvg.scan_procedure_id  in (37,26,24) and scvg.scan_procedure_id in ("+r[2].to_s+")) "
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/adrc_upload/[subjectid]_YYYYMMDD_wisc
      v_export_id = (@schedule.id).to_s+"_"+r[3].to_s
      v_subject_dir = v_export_id+"_"+(results_vgroup.first)[0].to_s+"_wisc"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      v_subjectid = r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                  from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                  and LOWER(image_datasets.series_description)=   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','resting_fMRI','resting fMRI','resting+fMRI','T2','T2_Flair','T2+Flair') 
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_folder_array = [] # how to empty
      v_scan_desc_type_array = []
      v_cnt = 1
      results_dataset.each do |r_dataset|
            v_series_description_type = r_dataset[5].gsub(" ","_")
            if !v_scan_desc_type_array.include?(v_series_description_type)
                 v_scan_desc_type_array.push(v_series_description_type)
            end
            # for dual enrollments need ids path to get to unknown path/nii
            v_path = r_dataset[4]
            v_dir_array = v_path.split("/")
            v_actual_scan_procedure = v_dir_array[4]
            v_subjectid_date_actual =v_subjectid
            if v_dir_array[5] == "mri"
              v_subjectid_date_actual = v_dir_array[6]
            else
                v_subjectid_date_actual = v_dir_array[5]  
            end
            v_subject_date_actual_array = v_subjectid_date_actual.split("_")
            v_subjectid_actual = v_subject_date_actual_array[0]

            v_dir = v_dir_array[(v_dir_array.size - 1)]
            v_dir_target = v_dir+"_"+v_series_description_type
            v_path = v_path.gsub("/Volumes/team/","").gsub("/Volumes/team-1/","").gsub("/Data/vtrak1/","")  #v_base_path+"/"+
            if v_folder_array.include?(v_dir_target)
              v_dir_target = v_dir_target+"_"+v_cnt.to_s
              v_cnt = v_cnt +1
              # might get weird if multiple types have dups - only expect T1/Bravo
            end
            v_folder_array.push(v_dir_target)   
             
            v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            v_scan_procedure_path = v_actual_scan_procedure # ScanProcedure.find(r[2]).codename
            # check if nii file exists
            if !Dir.glob(v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii").empty?
               puts "FOUND "+v_subjectid_actual+"_*_"+v_dir+".nii "
               v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"

               stdin, stdout, stderr = Open3.popen3(v_call)
               while !stdout.eof?
                  puts stdout.read 1024    
               end
               stdin.close
               stdout.close
               stderr.close

               # check if copied nii file is a directory -- found 2 exapmles
              v_call = "ssh panda_user@merida.dom.wisc.edu 'ls -dl "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
              puts v_call
              stdin, stdout, stderr = Open3.popen3(v_call)
               while !stdout.eof?
                  v_return = stdout.read 1024  
                  v_return_array = v_return.split(' ')
                  if v_return_array[1] == "2"
                     puts " its a DIRECTORY!!!!!"
                     @schedulerun.comment = "IT IS A DIRECTORY "+v_subjectid_actual+"_*_"+v_dir+".nii; "+@schedulerun.comment
                     @schedulerun.save
                     v_comment_warning = "IT IS A DIRECTORY "+v_subjectid_actual+"_*_"+v_dir+".nii;" +v_comment_warning
                  end

               end
               stdin.close
               stdout.close
               stderr.close


            else
              # nii not exists
              @schedulerun.comment = "MISSING "+v_subjectid_actual+"_*_"+v_dir+".nii; "+@schedulerun.comment
               @schedulerun.save
              puts "MISSIING "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii"
              v_comment_warning = "MISSIING "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii" +v_comment_warning
            end 
        
      end

      # get dti raw dicom for this subjectid/sp
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                   from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                   where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                   and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                   and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                   and series_description_maps.series_description_type_id = series_description_types.id
                   and series_description_types.series_description_type in ('DTI') 
                   and image_datasets.series_description != 'DTI whole brain  2mm FATSAT ASSET'
                   and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                    order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_cnt = 1
      v_dir_target = ""
      v_scan_desc_type_array = []
      results_dataset.each do |r_dataset|
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
  puts "aaaaaa v_dir_target = "+v_dir_target
             v_folder_array.push(v_dir_target)

              # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
               v_tmp = "/tmp/"+v_dir_target 
               v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
               v_call = "mise "+v_path+" "+v_tmp 
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
             # cp path ==> /tmp/adrc_dti/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
       end


       if v_scan_desc_type_array.size > 0   
puts "dddddd in ids dicoms"
puts " /tmp dir = "+"/tmp/"+v_dir_target+"/*/*.*  0. 1. 2. *.dcm" 
 # TURN INTO A LOOP   
        v_dicom_field_array =['0010,0030','0010,0010','0008,0050','0008,1030','0010,0020','0040,0254','0008,0080','0008,1010','0009,1002','0009,1030','0018,1000',
                        '0025,101A','0040,0242','0040,0243']
        v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name','0008,0050'=>'Accession Number',
                           '0008,1030'=>'Study Description', '0010,0020'=>'Patient ID','0040,0254'=>'Performed Proc Step Desc',
                            '0008,0080'=>'Institution Name','0008,1010'=>'Station Name','0009,1002'=>'Private',
                            '0009,1030'=>'Private','0018,1000'=>'Device Serial Number','0025,101A'=>'Private',
                            '0040,0242'=>'Performed Station Name','0040,0243'=>'Performed Location'}


        # v_dicom_field_array =['0010,0030']
        # v_dicom_field_value_hash ={'0010,0030'=>'DOB'}
      ####  v_dicom_field_array.each do |dicom_key|
                Dir.glob('/tmp/'+v_dir_target+'/*/*.dcm').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                      v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                                  d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                             end 
                                                                                       end }

                                                                               
               Dir.glob('/tmp/'+v_dir_target+'/*/*.0*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }

              Dir.glob('/tmp/'+v_dir_target+'/*/*.1*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm)
                                                                                            end 
                                                                                         end }   
             Dir.glob('/tmp/'+v_dir_target+'/*/*.2*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }   
             Dir.glob('/tmp/'+v_dir_target+'/*/*.3*').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }                                                                               

        v_call = "rsync -av /tmp/"+v_dir_target+" panda_user@merida.dom.wisc.edu:"+v_parent_dir_target 
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close

         v_call = "rm -rf /tmp/"+v_dir_target
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close


        end                            

 #                             
 # # #puts "bbbbb dicom clean "+v_parent_dir_target+"/*/"
 # Dir.glob(v_parent_dir_target+'/*/*/*.dcm').each {|dcm| puts d = DICOM::DObject.read(dcm); if !d["0010,0030"].nil? 
 #                                                                                           d["0010,0030"].value = "DOB"; d.write(dcm) 
 #                                                                                               end } 

      # get dti from nagesh - FA, MD, L1, L2, L3  cg_dti_status  -- only some processed - and registerred to a common space 

      # get pib and rename
      # dvd in subject space , use  rFS_r<enum>_realignPIB_DVR_HYPR.nii if exists, else use r<enum>_realignPIB_DVR_HYPR.nii
      # exceptions- pdt00038, pdt00129,pdt00137,pdt00161 - readme describes slices used

      # cg_dti_status only has visit1 -- now 
      sql_dti = "select distinct appointments.appointment_date, visits.id visit_id 
                  from vgroups , appointments, visits 
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id 
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e, cg_dti_status where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"' 
                           and cg_dti_status.enrollment_id = e.id and dti_fa_flag = 'Y')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )            
                   order by appointments.appointment_date "
        results_dataset = connection.execute(sql_dti)
        v_dir_target = "dti"
        v_dti_array =[]
        results_dataset.each do |r_dataset|
          v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
             puts stdout.read 1024    
          end
          stdin.close
          stdout.close
          stderr.close
          v_preprocessed_path = v_base_path+"/preprocessed/modalities/dti/adluru_pipeline/"
          v_dir_array = ['FA','MD','L1','L2','L3']
          v_file_name_hash ={'FA'=>'_combined_fa.nii','MD'=>'_combined_md.nii','L1'=>'_combined_L1.nii','L2'=>'_combined_L2.nii','L3'=>'_combined_L3.nii'}
          v_dir_array.each do |dir_name|
            v_dti_array.push('dti-'+dir_name)
             v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+dir_name+"/"+ v_subjectid+v_file_name_hash[dir_name]+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+v_file_name_hash[dir_name]+"  '"
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                 puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
              # some nii.gz
              v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+dir_name+"/"+ v_subjectid+v_file_name_hash[dir_name]+".gz  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+v_file_name_hash[dir_name]+".gz  '"
               stdin, stdout, stderr = Open3.popen3(v_call)
               while !stdout.eof?
                  puts stdout.read 1024    
               end
               stdin.close
               stdout.close
               stderr.close
           end
        end
        
        sql_dir_list = "update cg_goveas_20131031 set dir_list ='"+v_folder_array.join(',')+","+v_dti_array.join(',')+"' where subjectid = '"+r[0]+"'"
        results_done = connection.execute(sql_dir_list)

      #tar.gz subjectid dir
      v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
      v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      
            # fsftp dir when set
            # sftp -- shared helper hasthe username /password and address
        #    v_username = Shared.panda_admin_sftp_username # get from shared helper
        #    v_passwrd = Shared.panda_admin_sftp_password   # get from shared helperwhich is not on github
            # switch on new platform
            #v_username = Shared.panda_user_sftp_username # get from shared helper
            #v_passwrd = Shared.panda_user_sftp_password   # get from shared helperwhich is not on github
        #    v_ip = Shared.dom_sftp_host_address # get from shared helper
        #    v_sftp_dir = Shared.goveas_target_path

            # problem that files are on merida, but panda running from nelson
            # need to ssh to merida as pand_admin, then sftp
        #    v_source = "panda_admin@merida.dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"

        #    v_target = v_sftp_dir+"/"   #+v_subject_dir+".tar.gz"

      # puts "aaaaaa v_source = "+v_source
      # puts "bbbbbb v_target = "+v_target
      #       Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
      #           sftp.upload!(v_source, v_target)
      #       end
      #
      sql_done = "update cg_goveas_20131031 set done_flag ='Y' where subjectid = '"+r[0]+"'"
      results_done = connection.execute(sql_done)
  
    end # results
    
    @schedulerun.comment =("successful finish goveas_20131031_upload "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
    @schedulerun.save
    
    
    
  end



   def run_helpern_20151125_upload  
     v_base_path = Shared.get_base_path()
      @schedule = Schedule.where("name in ('helpern_20151125_upload')").first
       @schedulerun = Schedulerun.new
       @schedulerun.schedule_id = @schedule.id
       @schedulerun.comment ="starting helpern_20151125_upload"
       @schedulerun.save
       @schedulerun.start_time = @schedulerun.created_at
       @schedulerun.save
       v_comment = ""
       v_comment_warning =""
    #  table cg_helpern_20151125 populated with HYDI groups  
     connection = ActiveRecord::Base.connection();
     # get adrc subjectid to upload
     sql = "select distinct subjectid , scan_procedure_id,export_id from cg_helpern_20151125 where done_flag ='N' and status_flag in ('Y','R') "
     results = connection.execute(sql)
     # changed to series_description_maps table
     v_folder_array = Array.new
     v_scan_desc_type_array = Array.new
     # check for dir in /tmp
     v_target_dir ="/tmp/helpern_20151125_upload"
     if Rails.env=="production" 
        v_final_dir = "/home/panda_user/"
     else
        v_final_dir = "~/"
     end

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
     v_cnt_subject = 0 # using instead of date stamp
     results.each do |r|
       v_cnt_subject = v_cnt_subject+1
       v_comment = "strt "+r[0]+","+v_comment
       @schedulerun.comment =v_comment[0..1990]
       @schedulerun.save
       # update schedulerun comment - prepend 
       sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")+"')
                                                                                          and v.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg  where spvg.scan_procedure_id ='"+r[1].to_s+"')"
     
       results_vgroup = connection.execute(sql_vgroup)
       v_subjectid = r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
       v_export_id = "exportid_"+r[2].to_s
       # mkdir /tmp/helpern_20151125_upload/[exportid]_YYYYMMDD_wisc
       #v_cnt_subject  -- instead of date
       #### v_subject_dir = v_export_id+"_"+(results_vgroup.first)[0].to_s+"_wisc"
       v_subject_dir = v_export_id+"_"+v_cnt_subject.to_s+"_wisc"
       v_parent_dir_target =v_target_dir+"/"+v_subject_dir
       v_call = "mkdir "+v_parent_dir_target
       stdin, stdout, stderr = Open3.popen3(v_call)
       while !stdout.eof?
         puts stdout.read 1024    
        end
       stdin.close
       stdout.close
       stderr.close
       # 'T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1',
       #HYDI
       sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                   from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                   where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                   and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                   and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                   and series_description_maps.series_description_type_id = series_description_types.id
                   and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1') 
                   and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")+"')
                   and vgroups.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg  where spvg.scan_procedure_id ='"+r[1].to_s+"')
                    order by appointments.appointment_date "
       results_dataset = connection.execute(sql_dataset)
       v_folder_array = [] # how to empty
       v_scan_desc_type_array = []
       v_cnt = 1
       results_dataset.each do |r_dataset|
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

              # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
               v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
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
             # cp path ==> /tmp/hyunwoo_20140520_upload/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
       end

       sql_status = "select status_flag from cg_helpern_20151125 where subjectid ='"+r[0]+"'"
       results_status = connection.execute(sql_status)
       if v_scan_desc_type_array.size < 1   and (results_status.first)[0] != "R"
         # sql_dirlist = "update cg_hyunwoo_20140520 set general_comment =' NOT ALL SCAN TYPES!!!! "+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' "
         # results_dirlist = connection.execute(sql_dirlist)
         sql_status = "update cg_helpern_20151125 set status_flag ='N' where subjectid ='"+r[0]+"' "
         results_sent = connection.execute(sql_status)
         # send email 
         v_subject = "helpern_20151125_upload "+r[0]+" is missing some scan types --- set status_flag ='R' to send  : scans ="+v_folder_array.join(", ")
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

         sql_dirlist = "update cg_helpern_20151125 set dir_list ='"+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' "
         results_dirlist = connection.execute(sql_dirlist)
 # TURN INTO A LOOP
         v_dicom_field_array =['0010,0030','0010,0010','0008,0050','0008,1030','0010,0020','0010,21b0','0040,0254','0008,0020','0008,0021','0008,0022','0008,0023','0008,0030','0040,0244','0040,0245']
         v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name','0008,0050'=>'RMR','0008,1030'=>'ID','0010,0020'=>'ID','0010,21b0'=>'ID','0040,0254'=>'ID','0008,0020'=>'date','0008,0021'=>'date','0008,0022'=>'date','0008,0023'=>'date','0008,0030'=>'date','0040,0244'=>'date','0040,0245'=>'date'}
      ####  v_dicom_field_array.each do |dicom_key|
                Dir.glob(v_parent_dir_target+'/*/*/*.dcm').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                      v_dicom_field_array.each do |dicom_key|
                                                                                            if !d[dicom_key].nil? 
                                                                                                  d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                             end 
                                                                                       end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*0').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*1').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*2').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*3').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*4').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*5').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*6').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*7').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*8').each {|dcm| puts d = DICOM::DObject.read(dcm); 
                                                                                         v_dicom_field_array.each do |dicom_key|
                                                                                             if !d[dicom_key].nil? 
                                                                                               d[dicom_key].value = v_dicom_field_value_hash[dicom_key]; d.write(dcm) 
                                                                                            end 
                                                                                         end }
               Dir.glob(v_parent_dir_target+'/*/*/*.*9').each {|dcm| puts d = DICOM::DObject.read(dcm); 
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

         #v_call = "zip -r "+v_target_dir+"/"+v_subject_dir+".zip  "+v_parent_dir_target
         #v_call = "cd "+v_target_dir+"; zip -r "+v_subject_dir+"  "+v_subject_dir   #  ???????    PROBLEM HERE????
         v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close
         puts "bbbbbbb "+v_call

         v_call = "rsync -av "+v_target_dir+"/"+v_subject_dir+".tar.gz "+v_final_dir+"upload_helpern_20151125/"
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
        puts "bbbbbbb "+v_call


         sql_sent = "update cg_helpern_20151125 set done_flag ='Y' where subjectid ='"+r[0]+"' "
         results_sent = connection.execute(sql_sent)
       end
       v_comment = "end "+r[0]+","+v_comment
       @schedulerun.comment =v_comment[0..1990]
       @schedulerun.save 
     end

     @schedulerun.comment =("successful finish helpern_20151125_upload "+v_comment_warning+" "+v_comment[0..1990])
     if !v_comment.include?("ERROR")
        @schedulerun.status_flag ="Y"
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
      @schedulerun.save          


   end

##################################################################
    
 # starting with pet with v1/v2 -- just T1_Volumetric
   def run_hyunwoo_20140520_upload  
     v_base_path = Shared.get_base_path()
      @schedule = Schedule.where("name in ('hyunwoo_20140520_upload')").first
       @schedulerun = Schedulerun.new
       @schedulerun.schedule_id = @schedule.id
       @schedulerun.comment ="starting hyunwoo_20140520_upload"
       @schedulerun.save
       @schedulerun.start_time = @schedulerun.created_at
       @schedulerun.save
       v_comment = ""
       v_comment_warning =""
    #  table cg_hyunwoo_20140520 populated by  pet with v1/v2     
     connection = ActiveRecord::Base.connection();
     # get adrc subjectid to upload
     sql = "select distinct subjectid , scan_procedure_id from cg_hyunwoo_20140520 where done_flag ='N' and status_flag in ('Y','R') "
     results = connection.execute(sql)
     # changed to series_description_maps table
     v_folder_array = Array.new
     v_scan_desc_type_array = Array.new
     # check for dir in /tmp
     v_target_dir ="/tmp/hyunwoo_20140520_upload"
     ###v_target_dir ="/Volumes/Macintosh_HD2/hyunwoo_20140520_upload"
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
       sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")+"')
                                                                                          and v.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg  where spvg.scan_procedure_id ='"+r[1].to_s+"')"
     
       results_vgroup = connection.execute(sql_vgroup)

       # mkdir /tmp/hyunwoo_20140520_upload/[subjectid]_YYYYMMDD_wisc
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
       sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                   from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                   where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                   and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                   and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                   and series_description_maps.series_description_type_id = series_description_types.id
                   and series_description_types.series_description_type in ('T1_Volumetric') 
                   and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")+"')
                   and vgroups.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg  where spvg.scan_procedure_id ='"+r[1].to_s+"')
                    order by appointments.appointment_date "
       results_dataset = connection.execute(sql_dataset)
       v_folder_array = [] # how to empty
       v_scan_desc_type_array = []
       v_cnt = 1
       results_dataset.each do |r_dataset|
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

              # v_call = "/usr/bin/bunzip2 "+v_parent_dir_target+"/"+v_dir_target+"/*.bz2"
               v_call = "mise "+v_path+" "+v_parent_dir_target+"/"+v_dir_target   # works where bunzip2 cmd after rsync not work
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
             # cp path ==> /tmp/hyunwoo_20140520_upload/[subjectid]_yyymmdd_wisc/dir_series_description_type(_2)
       end

       sql_status = "select status_flag from cg_hyunwoo_20140520 where subjectid ='"+r[0]+"'"
       results_status = connection.execute(sql_status)
       if v_scan_desc_type_array.size < 1   and (results_status.first)[0] != "R"
         # sql_dirlist = "update cg_hyunwoo_20140520 set general_comment =' NOT ALL SCAN TYPES!!!! "+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' "
         # results_dirlist = connection.execute(sql_dirlist)
         sql_status = "update cg_hyunwoo_20140520 set status_flag ='N' where subjectid ='"+r[0]+"' "
         results_sent = connection.execute(sql_status)
         # send email 
         v_subject = "hyunwoo_20140520_upload "+r[0]+" is missing some scan types --- set status_flag ='R' to send  : scans ="+v_folder_array.join(", ")
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

         sql_dirlist = "update cg_hyunwoo_20140520 set dir_list ='"+v_folder_array.join(", ")+"' where subjectid ='"+r[0]+"' "
         results_dirlist = connection.execute(sql_dirlist)
 # TURN INTO A LOOP
         v_dicom_field_array =['0010,0030','0010,0010']
         v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name'}
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
         v_call = "rsync -av "+v_parent_dir_target+" panda_user@merida.dom.wisc.edu:/home/panda_user/upload_hyunwoo_20140520/"
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close

         #v_call = "zip -r "+v_target_dir+"/"+v_subject_dir+".zip  "+v_parent_dir_target
         #v_call = "cd "+v_target_dir+"; zip -r "+v_subject_dir+"  "+v_subject_dir   #  ???????    PROBLEM HERE????
         v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
         v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C /home/panda_user/upload_hyunwoo_20140520  -zcf /home/panda_user/upload_hyunwoo_20140520/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
         v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf /home/panda_user/upload_hyunwoo_20140520/'+v_subject_dir+' "'
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close


          # did the tar.gz on merida to avoid mac acl PaxHeader extra directories
          v_call = "rsync -av panda_user@merida.dom.wisc.edu:/home/panda_user/upload_hyunwoo_20140520/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
            puts stdout.read 1024    
           end
          stdin.close
          stdout.close
          stderr.close


         v_call = " rm -rf "+v_target_dir+'/'+v_subject_dir+".tar.gz"
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close        

         sql_sent = "update cg_hyunwoo_20140520 set done_flag ='Y' where subjectid ='"+r[0]+"' "
         results_sent = connection.execute(sql_sent)
       end
       v_comment = "end "+r[0]+","+v_comment
       @schedulerun.comment =v_comment[0..1990]
       @schedulerun.save 
     end

     @schedulerun.comment =("successful finish hyunwoo_20140520_upload "+v_comment_warning+" "+v_comment[0..1990])
     if !v_comment.include?("ERROR")
        @schedulerun.status_flag ="Y"
      end
      @schedulerun.save
      @schedulerun.end_time = @schedulerun.updated_at      
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
      v_machine ="merida"  # change to merida once set up
      #   v_script_only_tlv = v_script+" --only_tlv"  # running whole thing -- just use v_script in call
      (v_error_comment,v_comment) =get_file_diff(v_script,v_script_dev,v_error_comment,v_comment)
      v_comment_base = @schedulerun.comment
      connection = ActiveRecord::Base.connection();  

      # THIS IS THE MAIN RUN
      # do_not_run_process_wlesion_030 == Y means do not run
      sql = "select distinct enrollment_id, scan_procedure_id, lst_subjectid,multiple_o_star_nii_flag,o_star_nii_file_to_use, multiple_sag_cube_flair_flag, sag_cube_flair_to_use from cg_lst_v3_status where if(do_not_run_process_wlesion_030 is NULL,'N',do_not_run_process_wlesion_030) != 'Y' and wlesion_030_flag = 'N' and o_star_nii_flag ='Y' and ( multiple_o_star_nii_flag = 'N' or (multiple_o_star_nii_flag = 'Y' and o_star_nii_file_to_use is not null)   ) and sag_cube_flair_flag = 'Y' and (multiple_sag_cube_flair_flag ='N' or (multiple_sag_cube_flair_flag ='Y' and sag_cube_flair_to_use is not null) ) and (  lst_subjectid not like 'shp%') " #  or lst_subjectid like 'lead%' or  lst_subjectid like 'adrc%' or  lst_subjectid like 'pdt%'  or lst_subjectid like 'tami%'  or lst_subjectid like 'awr%'  or lst_subjectid like 'wmad%'  or lst_subjectid like 'plq%'  )"  #no acpcY, flairY fal, alz, tbi ;  problems 'shp%' 'pipr%' '
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
              # call processing script- need to have LST toolbox on gru, merida or edna
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
      sql = "select distinct enrollment_id, scan_procedure_id, lst_subjectid,multiple_o_star_nii_flag,o_star_nii_file_to_use, multiple_sag_cube_flair_flag, sag_cube_flair_to_use from cg_lst_116_status where lst_subjectid='DO NOT RUN THIS' and if(do_not_run_process_wlesion_030 is NULL,'N',do_not_run_process_wlesion_030) != 'Y'  and o_star_nii_flag ='Y' and ( multiple_o_star_nii_flag = 'N' or (multiple_o_star_nii_flag = 'Y' and o_star_nii_file_to_use is not null)   ) and sag_cube_flair_flag = 'Y' and (multiple_sag_cube_flair_flag ='N' or (multiple_sag_cube_flair_flag ='Y' and sag_cube_flair_to_use is not null) ) and (  lst_subjectid not like 'shp%') and (  lst_subjectid not like 'plq%')  " #  or lst_subjectid like 'lead%' or  lst_subjectid like 'adrc%' or  lst_subjectid like 'pdt%'  or lst_subjectid like 'tami%'  or lst_subjectid like 'awr%'  or lst_subjectid like 'wmad%'  or lst_subjectid like 'plq%'  )"  #no acpcY, flairY fal, alz, tbi ;  problems 'shp%' 'pipr%' '
     
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
              # call processing script- need to have LST toolbox on gru, merida or edna
              # v_call =  v_script+" -p "+v_o_star_nii_sp_loc+"  -b "+v_subjectid
              @schedulerun.comment ="str "+r[2]+"; "+v_comment[0..1990]
              @schedulerun.save
              v_multiple_o_star_nii_flag = r[3]
              v_o_star_nii_file_to_use = r[4]
              v_multiple_sag_cube_flair_flag = r[5]
              v_sag_cube_flair_to_use = r[6]
              # need to change script to accept v_o_star_nii_file_to_use and v_sag_cube_flair_to_use
              v_call =  'ssh panda_user@merida.dom.wisc.edu "'  +v_script_only_tlv+' -p '+v_o_star_nii_sp_loc+'  -b '+v_subjectid+' "  ' 
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
 

      # THIS IS THE MAIN RUN
      # do_not_run_process_wlesion_030 == Y means do not run
      sql = "select distinct enrollment_id, scan_procedure_id, lst_subjectid,multiple_o_star_nii_flag,o_star_nii_file_to_use, multiple_sag_cube_flair_flag, sag_cube_flair_to_use from cg_lst_116_status where if(do_not_run_process_wlesion_030 is NULL,'N',do_not_run_process_wlesion_030) != 'Y' and wlesion_030_flag = 'N' and o_star_nii_flag ='Y' and ( multiple_o_star_nii_flag = 'N' or (multiple_o_star_nii_flag = 'Y' and o_star_nii_file_to_use is not null)   ) and sag_cube_flair_flag = 'Y' and (multiple_sag_cube_flair_flag ='N' or (multiple_sag_cube_flair_flag ='Y' and sag_cube_flair_to_use is not null) ) and (  lst_subjectid not like 'shp%') " #  or lst_subjectid like 'lead%' or  lst_subjectid like 'adrc%' or  lst_subjectid like 'pdt%'  or lst_subjectid like 'tami%'  or lst_subjectid like 'awr%'  or lst_subjectid like 'wmad%'  or lst_subjectid like 'plq%'  )"  #no acpcY, flairY fal, alz, tbi ;  problems 'shp%' 'pipr%' '
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

          
          if v_o_star_nii_sp_loc > "" and v_tlv_lesion_txt != "not blank"
              # call processing script- need to have LST toolbox on gru, merida or edna
              # v_call =  v_script+" -p "+v_o_star_nii_sp_loc+"  -b "+v_subjectid
              @schedulerun.comment ="str "+r[2]+"; "+v_comment[0..1990]
              @schedulerun.save
              v_multiple_o_star_nii_flag = r[3]
              v_o_star_nii_file_to_use = r[4]
              v_multiple_sag_cube_flair_flag = r[5]
              v_sag_cube_flair_to_use = r[6]
              # need to change script to accept v_o_star_nii_file_to_use and v_sag_cube_flair_to_use
              v_call =  'ssh panda_user@merida.dom.wisc.edu "'  +v_script+' -p '+v_o_star_nii_sp_loc+'  -b '+v_subjectid+' "  ' 
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
      @schedulerun.comment ="starting selley_20130906_upload"
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
    
    v_target_dir = "/home/panda_user/upload_selley_20130906"
    v_final_target = "ftp directory tbd"
    v_series_description_category_array = ['T1_Volumetric','resting_fMRI']
    v_series_description_category_id_array = [19, 17]
    sql = "select distinct subjectid, enrollment_id, scan_procedure_id, export_id from cg_selley_pdt_pet_mri
           where ( done_flag != 'Y' or done_flag is NULL)
           and ( status_flag != 'N' or status_flag is NULL)
           and scan_category_resting_fmri ='Y'
           and scan_category_t1_volumetric = 'Y' 
           and pib_dvr_hypr_flag = 'Y'
           and fdg_summed_flag = 'Y'
          and global_quality = 'Pass' " # and subjectid in ('pdt00038', 'pdt00067','pdt00166') "
    results = connection.execute(sql)
    
    # get each subject , make target dir with export id
    # get each series decription / file name / nii file based on series_description_category
    # mkdir with series_description_category, # of scan - e.g. 3rd T1
    # copy over the .nii file, replace subjectid with export_id
    # bzip2 each subjectid dir
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
      
      v_comment = "strt "+r[0]+","+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
      # update schedulerun comment - prepend 
      sql_vgroup = "select DATE_FORMAT(max(v.vgroup_date),'%Y%m%d' ) from vgroups v where v.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+r[0]+"')
       and v.id in ( select scvg.vgroup_id from scan_procedures_vgroups scvg where scvg.scan_procedure_id  in (26))"
      results_vgroup = connection.execute(sql_vgroup)
      # mkdir /tmp/adrc_upload/[subjectid]_YYYYMMDD_wisc
      v_export_id = (@schedule.id).to_s+"_"+r[3].to_s
      v_subject_dir = v_export_id+"_"+(results_vgroup.first)[0].to_s+"_wisc"
      v_parent_dir_target =v_target_dir+"/"+v_subject_dir
      v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      v_subjectid = r[0].gsub("_v2","").gsub("_v3","").gsub("_v4","").gsub("_v5","")
      sql_dataset = "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
                  from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
                  where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
                  and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
                  and series_description_maps.series_description_type_id = series_description_types.id
                  and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','resting_fMRI','resting fMRI','resting+fMRI') 
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   order by appointments.appointment_date "
      results_dataset = connection.execute(sql_dataset)
      v_folder_array = [] # how to empty
      v_scan_desc_type_array = []
      v_cnt = 1
      results_dataset.each do |r_dataset|
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
             
            v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            v_scan_procedure_path = ScanProcedure.find(r[2]).codename
            v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/unknown/"+ v_subjectid+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
        
      end

      # get pib and rename
      # dvd in subject space , use  rFS_r<enum>_realignPIB_DVR_HYPR.nii if exists, else use r<enum>_realignPIB_DVR_HYPR.nii
      # exceptions- pdt00038, pdt00129,pdt00137,pdt00161 - readme describes slices used
      sql_pib = "select distinct appointments.appointment_date, petscans.id petscan_id 
                  from vgroups , appointments, petscans 
                  where vgroups.transfer_pet = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = petscans.appointment_id and petscans.lookup_pettracer_id = 1
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   order by appointments.appointment_date "
        results_dataset = connection.execute(sql_pib)
        v_dir_target = "pib"
        results_dataset.each do |r_dataset|
          v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
             puts stdout.read 1024    
          end
          stdin.close
          stdout.close
          stderr.close
          v_preprocessed_path = v_base_path+"/preprocessed/visits/"
          v_scan_procedure_path = ScanProcedure.find(r[2]).codename
          if v_subjectid == "pdt00038" or v_subjectid == "pdt00129" or v_subjectid == "pdt00137" or v_subjectid == "pdt00161"
            v_pib_summed_file = v_subjectid+"_pib_summed.nii"
            v_readme_file = "README"
            v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/pib/"+ v_pib_summed_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_pib_summed.nii '"
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/pib/"+ v_readme_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_pib_readme.txt '"
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
          else
             v_rFS_file ="rFS_r"+v_subjectid+"_realignPIB_DVR_HYPR.nii"
             v_file_name = v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/pib/"+ v_rFS_file
             if File.exist?(v_file_name)
                v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/pib/"+ v_rFS_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/rFS_r"+v_export_id+"_realignPIB_DVR_HYPR.nii '"
             
              else
                v_realign_file ="r"+v_subjectid+"_realignPIB_DVR_HYPR.nii"
                 v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/pib/"+ v_realign_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/r"+v_export_id+"_realignPIB_DVR_HYPR.nii '"
              end
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                 puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
          end
        end

      # get fdg and rename  petscans.lookup_pettracer_id = 2
      # summed img in subj space, <enum>_fdg_summed.nii
      # exception - pdt00067   <enum>_fdg_summed.nii , readme describes slice used
      sql_fdg = "select distinct appointments.appointment_date, petscans.id petscan_id 
                  from vgroups , appointments, petscans 
                  where vgroups.transfer_pet = 'yes' and vgroups.id = appointments.vgroup_id 
                  and appointments.id = petscans.appointment_id and petscans.lookup_pettracer_id = 2
                  and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = "+r[1].to_s+" and evm.enrollment_id = e.id and e.enumber ='"+ v_subjectid+"')
                  and vgroups.id in (select spv.vgroup_id from scan_procedures_vgroups spv where spv.scan_procedure_id = "+r[2].to_s+" )
                   order by appointments.appointment_date "
      results_dataset = connection.execute(sql_fdg)
      v_dir_target = "fdg"
      results_dataset.each do |r_dataset|
        v_call = "ssh panda_user@merida.dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
           puts stdout.read 1024    
        end
        stdin.close
        stdout.close
        stderr.close
        v_preprocessed_path = v_base_path+"/preprocessed/visits/"
        v_scan_procedure_path = ScanProcedure.find(r[2]).codename
        v_fdg_summed_file = v_subjectid+"_fdg_summed.nii"
        if v_subjectid == "pdt00067" 
          v_fdg_summed_file = v_subjectid+"_fdg_summed.nii"
          v_readme_file = "README"
          v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/fdg/"+ v_fdg_summed_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_fdg_summed.nii '"
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
             puts stdout.read 1024    
          end
          stdin.close
          stdout.close
          stderr.close
          v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/fdg/"+ v_readme_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_fdg_readme.txt '"
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
             puts stdout.read 1024    
          end
          stdin.close
          stdout.close
          stderr.close
        else
          v_call = "ssh panda_user@merida.dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/fdg/"+ v_fdg_summed_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_fdg_summed.nii '"
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
              puts stdout.read 1024    
          end
          stdin.close
          stdout.close
          stderr.close
        end
      end
      
      #tar.gz subjectid dir
      v_call = "cd "+v_target_dir+";  /bin/tar -zcf "+v_subject_dir+".tar.gz "+v_subject_dir+"/"
      v_call =  'ssh panda_user@merida.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@merida.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      
            # fsftp dir when set - not practical - not using
            # sftp -- shared helper hasthe username /password and address
    #        v_username = Shared.panda_admin_sftp_username # get from shared helper
    #        v_passwrd = Shared.panda_admin_sftp_password   # get from shared helperwhich is not on github
            # switch on new platform
            #v_username = Shared.panda_user_sftp_username # get from shared helper
            #v_passwrd = Shared.panda_user_sftp_password   # get from shared helperwhich is not on github
    #        v_ip = Shared.dom_sftp_host_address # get from shared helper
    #        v_sftp_dir = Shared.selley_target_path

            # problem that files are on merida, but panda running from nelson
            # need to ssh to merida as pand_admin, then sftp
     #       v_source = "panda_user@merida.dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"

    #      v_target = v_sftp_dir+"/"   #+v_subject_dir+".tar.gz"

      # puts "aaaaaa v_source = "+v_source
      # puts "bbbbbb v_target = "+v_target
      #       Net::SFTP.start(v_ip, v_username, :password => v_passwrd) do |sftp|
      #           sftp.upload!(v_source, v_target)
      #       end
      #
      sql_done = "update cg_selley_pdt_pet_mri set done_flag ='Y' where subjectid = '"+r[0]+"'"
      results_done = connection.execute(sql_done)
  
    end # results
    
    @schedulerun.comment =("successful finish selley_20130906_upload "+v_comment_warning+" "+v_comment[0..1990])
    if !v_comment.include?("ERROR")
          @schedulerun.status_flag ="Y"
    end
    @schedulerun.save
    @schedulerun.end_time = @schedulerun.updated_at      
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
