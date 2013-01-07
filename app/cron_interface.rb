require 'visit'
require 'image_dataset'
class CronInterface < ActiveRecord::Base
  v_value_1 = ARGV[0]
  puts "AAAAAAAAAAA in CronInterface"+v_value_1.to_s
  

  # dev 
  #/usr/local/bin/rails  runner /Users/caillingworth/code/WADRC-Data-Tools/app/cron_interface.rb sp_series_desc_count
  if v_value_1 == "sp_series_desc_count"
    v_base_path = ""
     @schedule = Schedule.where("name in ('sp_series_desc_count')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting sp_series_desc_count"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
    begin   # catch all exception and put error in comment
    # move to function?
    # run visit series_desc_cnt for last month -- 
      sql = "select min(image_datasets.id) min_id, max(image_datasets.id) max_id from image_datasets where dcm_file_count is null
         and image_datasets.visit_id in (select visits.id from visits where visits.date > adddate(curdate(),'-31'))"
      connection = ActiveRecord::Base.connection();        
      results = connection.execute(sql)
      results.each do |r|
        v_start_id =r[0].to_s
        v_end_id   = r[1].to_s
        image_dataset = ImageDataset.find(v_end_id)
        visit = Visit.find(image_dataset.visit_id)
        puts "start id = "+v_start_id+"   end id="+v_end_id
        visit.series_desc_cnt(v_start_id, v_end_id)
        v_base_path = visit.get_base_path() # happens to be in the visits model
       end 

      v_dir_path = v_base_path+"/analyses/panda/sp_series_desc_cnt/summary/"
      # truncate and populate table
      sql = "truncate table t_sp_series_desc_cout_freq"
      connection = ActiveRecord::Base.connection();        
      results = connection.execute(sql)
      # ??? use sql to get series desc or hard code?
      v_excluded_series_desc = "'Apparent Diffusion Coefficient (mm','Apparent Diffusion Coefficient (mm2/s)','Apparent Diffusion Coefficient (mm?/s)',
      'ASL CBF','Axial Reformat','Cerebral Blood Flow','COL:Ax 2DTOF FSPGR','COL:Ax COW 3D mgtr fatsat',
      'COL:MRA COW MTr fat asset','COL:NK Ax 3D tof 2-3 slabs','COL:NK loc 2Dtof 6mm','Cor Reformat','FAT:mcD B0 (APS)','FieldMap:mcD B0 (APS)',
      'flow:SVD (bc)','flow:SVDbc (color)','FMT','FMT (color)','MTT(CVP)','MTT(CVP) (color)','Perfusion ROIs',
      'ph10:SUB:Adult ARCH TRICKS Cor','ph11:SUB:Adult ARCH TRICKS Cor','ph12:SUB:Adult ARCH TRICKS Cor','ph13:SUB:Adult ARCH TRICKS Cor',
      'ph14:SUB:Adult ARCH TRICKS Cor','ph15:SUB:Adult ARCH TRICKS Cor','ph16:SUB:Adult ARCH TRICKS Cor','ph17:SUB:Adult ARCH TRICKS Cor',
      'ph18:SUB:Adult ARCH TRICKS Cor','ph1:SUB:Adult ARCH TRICKS Cor','ph2:SUB:Adult ARCH TRICKS Cor','ph3:SUB:Adult ARCH TRICKS Cor',
      'ph4:SUB:Adult ARCH TRICKS Cor','ph5:SUB:Adult ARCH TRICKS Cor','ph6:SUB:Adult ARCH TRICKS Cor','ph7:SUB:Adult ARCH TRICKS Cor',
      'ph8:SUB:Adult ARCH TRICKS Cor','ph9:SUB:Adult ARCH TRICKS Cor','PJN:Ax 2DTOF FSPGR','PJN:Ax COW 3D mgtr fatsat','PJN:MRA COW MTr fat asset',
      'PJN:NK Ax 3D tof 2-3 slabs','PJN:NK loc 2Dtof 6mm','Processed Images','rCBV', 'rCBV (color)','SCREENSAVE','SRC:PCVIPR CD COMP','SRC:PCVIPR Mag COMP',
      'SUB:Adult ARCH TRICKS Cor','T2* Thick Map','Tmax','Tmax (color)'"
      
      sql = "insert into t_sp_series_desc_cout_freq (codename,series_description, dcm_file_count, frequency_count)
      select sp.codename, ids.series_description, ids.dcm_file_count, count(*) frequency_count
      from scan_procedures sp, scan_procedures_vgroups spg, appointments a, visits v, image_datasets ids
      where sp.id = spg.scan_procedure_id
      and a.vgroup_id = spg.vgroup_id
      and a.id = v.appointment_id
      and ids.visit_id = v.id
      and ids.dcm_file_count is not null
      and spg.scan_procedure_id in (select spg2.scan_procedure_id from scan_procedures_vgroups spg2, vgroups vg
                                        where vg.id=spg2.vgroup_id and vg.vgroup_date >  adddate(curdate(),'-400') )
      and ids.series_description not in ("+v_excluded_series_desc+")
      group by sp.codename, ids.series_description, ids.dcm_file_count"        
      results = connection.execute(sql)
      v_comment = "\n finish series desc cnt "+v_comment
      
      # get the nii file_count from vgroups
      sql = "select min(vgroups.id) min_id, max(vgroups.id) max_id from vgroups where ( nii_file_count is not null or nii_file_count > 0)
         and  vgroups.vgroup_date > adddate(curdate(),'-31')"      
      results = connection.execute(sql)
      results.each do |r|
        v_start_id =r[0].to_s
        v_end_id   = r[1].to_s
        vgroup = Vgroup.find(v_end_id)
        puts "VGROUP start id = "+v_start_id+"   end id="+v_end_id
        vgroup.nii_file_cnt(v_start_id, v_end_id)  
        # alread got from visits v_base_path = vgroup.get_base_path() # happens to be in the visits model
       end
      
       sql = "insert into t_sp_series_desc_cout_freq (codename,series_description, dcm_file_count, frequency_count)
       select sp.codename, 'nii_files', vg2.nii_file_count, count(*) frequency_count
       from scan_procedures sp, scan_procedures_vgroups spg,  vgroups vg2
       where sp.id = spg.scan_procedure_id
       and  vg2.id = spg.vgroup_id
       and ( vg2.nii_file_count is not null and vg2.nii_file_count > 0)
       and spg.scan_procedure_id in (select spg2.scan_procedure_id from scan_procedures_vgroups spg2, vgroups vg
                                         where vg.id=spg2.vgroup_id and vg.vgroup_date >  adddate(curdate(),'-400') )
       group by sp.codename, vg2.nii_file_count"        
       results = connection.execute(sql)      
       v_comment = "\n finish nii cnt "+v_comment
      
      
      # update fraction_of_total
      sql ="update t_sp_series_desc_cout_freq 
      set fraction_of_total =
          (select t_sp_series_desc_cout_freq.frequency_count/tot.t2_sum from 
                  (select t2.codename, t2.series_description, sum(t2.frequency_count)  t2_sum from t_sp_series_desc_cout_freq t2
                     group by codename, series_description) tot 
              where tot.codename= t_sp_series_desc_cout_freq.codename 
                 and tot.series_description = t_sp_series_desc_cout_freq.series_description)"
       results = connection.execute(sql)      
      
      # get sp from last month -- codename
      sql = "select distinct scan_procedures.codename from scan_procedures, scan_procedures_vgroups spg2, vgroups vg
                                        where scan_procedures.id = spg2.scan_procedure_id and vg.id=spg2.vgroup_id  and vg.vgroup_date >  adddate(curdate(),'-31')"                            
      results = connection.execute(sql)

      results.each do |r|
           puts "codename="+r[0]
           v_comment = "\n codename="+r[0]+v_comment
           sql_internal = "select codename,series_description,dcm_file_count,frequency_count, fraction_of_total from t_sp_series_desc_cout_freq 
                         where t_sp_series_desc_cout_freq.codename='"+r[0]+"' order by series_description, fraction_of_total desc "
           results_internal = connection.execute(sql_internal)
           # open file for codename
           v_file = v_dir_path+r[0]+"_series_desc_cnt.txt"
           File.open(v_file, "w+") do |f|
             results_internal.each do |rc|
               f.write(rc[0]+"\t"+rc[1]+"\t"+rc[2].to_s+"\t"+rc[3].to_s+"\t"+rc[4].to_s+"\n")
               # write a tab separated row
             end
           end
      end
      puts "successful finish sp_series_desc_count "+v_comment[0..459]
       @schedulerun.comment =("successful finish sp_series_desc_count "+v_comment[0..459])
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
   elsif v_value_1 == "fs_Y_N"  #   rails runner app/cron_interface.rb fs_Y_N 
     @schedule = Schedule.where("name in ('fs_Y_N')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting fs_Y_N"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
    begin   # catch all exception and put error in comment
       visit = Visit.find(3)  #  need to get base path without visit
       v_base_path = visit.get_base_path()
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
            vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollments, enrollment_vgroup_memberships 
                                                                     where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enumber in (?))
                                                            and vgroups.id in (select appointments.vgroup_id from appointments where appointment_type = 'mri' )
                                                            and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups
                                                                                             where scan_procedure_id in (?))", dirname,v_sp_visit2_array)                                                                               
            vgroups.each do |v|
              if v.fs_flag != "Y"
                 v.fs_flag ="Y"
                 v.save
                 v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v3')
            dirname = dirname.gsub(/_v3/,'')
            vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollments, enrollment_vgroup_memberships 
                                                                     where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enumber in (?))
                                                             and vgroups.id in (select appointments.vgroup_id from appointments where appointment_type = 'mri' )
                                                            and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups
                                                                                             where scan_procedure_id in (?))", dirname,v_sp_visit3_array)
            vgroups.each do |v|
              if v.fs_flag != "Y"
                 v.fs_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          elsif dirname.include?('_v4')
            dirname = dirname.gsub(/_v4/,'')
            vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollments, enrollment_vgroup_memberships 
                                                                     where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enumber in (?))
                                                             and vgroups.id in (select appointments.vgroup_id from appointments where appointment_type = 'mri' )
                                                            and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups
                                                                                             where scan_procedure_id in (?))", dirname,v_sp_visit4_array)
            vgroups.each do |v|
              if v.fs_flag != "Y"
                 v.fs_flag ="Y"
                 v.save
                  v_cnt = v_cnt + 1
              end
            end
          else
            vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollments, enrollment_vgroup_memberships 
                                                                     where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enumber in (?))
                                                             and vgroups.id in (select appointments.vgroup_id from appointments where appointment_type = 'mri' )
                                                            and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups
                                                                                             where scan_procedure_id in (?))", dirname,v_sp_visit1_array)
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