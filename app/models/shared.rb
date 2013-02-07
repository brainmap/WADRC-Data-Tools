require 'visit'
require 'image_dataset'
class Shared  < ActionController::Base
  

  
  def test_return( p_var)
    return "AAAAAAAAAAAAA"+p_var
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
    
    scan_procedures.each do |sp|
      # puts sp.codename+"= codename"
      return sp.id
    end
    
    return nil
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
    if ( v_old_minus_present <= 0 or ( v_old_cnt > 0 and  (v_present_minus_old/v_old_cnt)>0.7     ) )
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
  
  def run_asl_status
        visit = Visit.find(3)  #  need to get base path without visit
        v_base_path = visit.get_base_path()
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

            sql_base = "insert into cg_asl_status_new(asl_subjectid, asl_general_comment,asl_registered_to_fs_flag,asl_smoothed_and_warped_flag,asl_fmap_flag,asl_fmap_single,enrollment_id, scan_procedure_id)values("  
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
            v_exclude_sp =[4,10,15,19,32]
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
                             v_subjectid_asl = v_preprocessed_full_path+"/"+dir_name_array[0]+"/asl"
                             if File.directory?(v_subjectid_asl)
                                # get filename/date from dir
                                # evalute for asl_registered_to_fs_flag = rFS_ASL_[subjectid]_fmap.nii ,
                                  # asl_smoothed_and_warped_flag = swrFS_ASL_[subjectid]_fmap.nii,
                                  # asl_fmap_flag = [ASL_[subjectid]_[sdir]_fmap.nii or ASL_[subjectid]_fmap.nii],
                                  # asl_fmap_single = ASL_[subjectid]_fmap.nii
                                v_asl_registered_to_fs_flag ="N"
                                v_asl_smoothed_and_warped_flag = "N"
                                v_asl_fmap_flag = "N"
                                v_asl_fmap_single ="N"
                                if File.exist?(v_subjectid_asl+"/swrFS_ASL_"+dir_name_array[0]+"_fmap.nii") 
                                  sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','Y','completed swrFS_ASL_"+dir_name_array[0]+"_fmap.nii',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                  results = connection.execute(sql)                              
                                else
                                  sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','N','no swrFS_ASL_"+dir_name_array[0]+"_fmap.nii',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
                                  results = connection.execute(sql)                              
                                end # check for the asl file 
                             else
                                 sql = sql_base+"'"+dir_name_array[0]+v_visit_number+"','no ASL dir','N','N','N','N',"+enrollment[0].id.to_s+","+sp.id.to_s+")"
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
             v_comment = self.move_present_to_old_new_to_present("cg_asl_status","asl_subjectid, asl_status_flag,asl_status, enrollment_id, scan_procedure_id",
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
  
  def run_fs_Y_N
    visit = Visit.find(3)  #  need to get base path without visit
    v_base_path = visit.get_base_path()
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
      
      
      
      # check for enumber in enrollment, link to enrollment_vgroup_memberships, appointments, visits
      # limit by _v2, _v3, _v4 in sp via scan_procedures_vgroups , scan_procedures like 'visit2, visit3, visit4
      dir_list = Dir.entries(v_fs_path).select { |file| File.directory? File.join(v_fs_path, file)}
      link_list = Dir.entries(v_fs_path).select { |file| File.symlink? File.join(v_fs_path, file)}
      dir_list.concat(link_list)
      v_cnt = 0
      dir_list.each do |dirname|
        if !v_dir_skip.include?(dirname) and !dirname.start_with?('tmp')
          if dirname.include?('_v2')
            dirname = dirname.gsub(/_v2/,'')
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollments, enrollment_vgroup_memberships 
                                                                     where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enumber in (?))
                                                            and vgroups.id in (select appointments.vgroup_id from appointments where appointment_type = 'mri' )
                                                            and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups,scan_procedures
                                                                                             where scan_procedures_vgroups.scan_procedure_id in (?)
                                                                                              and scan_procedures.id = scan_procedures_vgroups.scan_procedure_id 
                                                                                              and scan_procedures.subjectid_base in (?))", dirname,v_sp_visit2_array,v_dirname_chop)                                                                               
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
            vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollments, enrollment_vgroup_memberships 
                                                                     where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enumber in (?))
                                                             and vgroups.id in (select appointments.vgroup_id from appointments where appointment_type = 'mri' )
                                                            and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups,scan_procedures
                                                                                             where scan_procedures_vgroups.scan_procedure_id in (?)
                                                                                              and scan_procedures.id = scan_procedures_vgroups.scan_procedure_id 
                                                                                              and scan_procedures.subjectid_base in (?))", dirname,v_sp_visit3_array,v_dirname_chop)
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
            vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollments, enrollment_vgroup_memberships 
                                                                     where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enumber in (?))
                                                             and vgroups.id in (select appointments.vgroup_id from appointments where appointment_type = 'mri' )
                                                            and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups,scan_procedures
                                                                                             where scan_procedures_vgroups.scan_procedure_id in (?)
                                                                                              and scan_procedures.id = scan_procedures_vgroups.scan_procedure_id 
                                                                                              and scan_procedures.subjectid_base in (?))", dirname,v_sp_visit4_array,v_dirname_chop)
            vgroups.each do |v|
              if v.fs_flag != "Y"
                 v.fs_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          else
            v_dirname_chop = dirname.gsub(/[0123456789]/,'')
            vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollments, enrollment_vgroup_memberships 
                                                                     where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enumber in (?))
                                                             and vgroups.id in (select appointments.vgroup_id from appointments where appointment_type = 'mri' )
                                                            and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups,scan_procedures
                                                                                             where scan_procedures_vgroups.scan_procedure_id in (?)
                                                                                             and scan_procedures.id = scan_procedures_vgroups.scan_procedure_id 
                                                                                             and scan_procedures.subjectid_base in (?))", dirname,v_sp_visit1_array,v_dirname_chop)
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
      puts " fs_flag set = Y "+v_cnt.to_s
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