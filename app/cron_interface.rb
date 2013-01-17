require 'visit'
require 'image_dataset'
class CronInterface < ActiveRecord::Base
  v_value_1 = ARGV[0]
  puts "AAAAAAAAAAA in CronInterface"+v_value_1.to_s+"="
# calls from cron
#   sp_series_desc_count
#   fs_Y_N
#   fs_aseg_aparc

  visit = Visit.find(3)  #  need to get base path without visit
  v_base_path = visit.get_base_path()
  
  
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
   elsif v_value_1 == "fs_Y_N"  #   rails runner app/cron_interface.rb fs_Y_N 
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
    elsif v_value_1 == "fs_aseg_aparc"  #   rails runner app/cron_interface.rb fs_aseg_aparc
      @schedule = Schedule.where("name in ('fs_aseg_aparc')").first
       @schedulerun = Schedulerun.new
       @schedulerun.schedule_id = @schedule.id
       @schedulerun.comment ="starting fs_aseg_aparc"
       @schedulerun.save
       @schedulerun.start_time = @schedulerun.created_at
       @schedulerun.save
     begin  
        # to do 
          # define tables, table_edit, add to cg tables/search 
         # call fs_file.py
         # only in prod --- lots of path issues
         time = Time.now
         v_date_stamp = time.strftime("%Y%m%d")
          v_call = v_base_path+"/data1/lab_scripts/python_dev/fs_file.py Y"
          v_comment = "start "+v_call
          # v_call = v_base_path+"/data1/lab_scripts/python_dev/transfer_process.py -test_call"
          #v_return = system("export PYTHONPATH=/usr/local/bin/python/ && python "+v_call)  # return value not working
          #  its working but must be better way -- getting all the print output from the python script, 
          # exit in python script after "print" return value, loop thru to get the last line
# problem running in dev -- need to be admin-- make file, then test rest
          v_return =  `python #{v_call}`
          v_last_return_value = ""
          v_comment = ""
          v_return.each do |line|
            v_comment = line + v_comment
            v_last_return_value = line
          end
          # evaluate return values v_return(ERROR or SUCCESS)+"|"+yyyymmdd+"|"+(/tmp/)log_file
          v_last_return_value = "SUCCESS|"+v_date_stamp+"|tmp.YYYYMMDD.txt"
          v_result_array = v_last_return_value.split("|")
          if v_result_array[0] == "SUCCESS"
            connection = ActiveRecord::Base.connection();        
  
            v_visit_array = ['2','3','4','5']
            v_file_array = ["aseg","lh.aparc.area","rh.aparc.area"]
            v_file_header_dict = {}
            v_file_header_dict['aseg'] = "Measure:volume	Left-Lateral-Ventricle	Left-Inf-Lat-Vent	Left-Cerebellum-White-Matter	Left-Cerebellum-Cortex	Left-Thalamus-Proper	Left-Caudate	Left-Putamen	Left-Pallidum	3rd-Ventricle	4th-Ventricle	Brain-Stem	Left-Hippocampus	Left-Amygdala	CSF	Left-Accumbens-area	Left-VentralDC	Left-vessel	Left-choroid-plexus	Right-Lateral-Ventricle	Right-Inf-Lat-Vent	Right-Cerebellum-White-Matter	Right-Cerebellum-Cortex	Right-Thalamus-Proper	Right-Caudate	Right-Putamen	Right-Pallidum	Right-HippocampusRight-Amygdala	Right-Accumbens-area	Right-VentralDC	Right-vessel	Right-choroid-plexus	5th-Ventricle	WM-hypointensities	Left-WM-hypointensities	Right-WM-hypointensities	non-WM-hypointensities	Left-non-WM-hypointensities	Right-non-WM-hypointensities	Optic-Chiasm	CC_Posterior	CC_Mid_Posterior	CC_Central	CC_Mid_Anterior	CC_Anterior	lhCortexVol	rhCortexVol	CortexVol	lhCorticalWhiteMatterVol	rhCorticalWhiteMatterVol	CorticalWhiteMatterVol	SubCortGrayVol	TotalGrayVol	SupraTentorialVol	IntraCranialVol"
            v_file_header_dict['lh.aparc.area'] = "lh.aparc.area	lh_bankssts_area	lh_caudalanteriorcingulate_area	lh_caudalmiddlefrontal_area	lh_cuneus_area	lh_entorhinal_area	lh_fusiform_area	lh_inferiorparietal_area	lh_inferiortemporal_area	lh_isthmuscingulate_area	lh_lateraloccipital_area	lh_lateralorbitofrontal_area	lh_lingual_area	lh_medialorbitofrontal_area	lh_middletemporal_area	lh_parahippocampal_area	lh_paracentral_area	lh_parsopercularis_area	lh_parsorbitalis_area	lh_parstriangularis_area	lh_pericalcarine_area	lh_postcentral_area	lh_posteriorcingulate_area	lh_precentral_area	lh_precuneus_area	lh_rostralanteriorcingulate_area	lh_rostralmiddlefrontal_area	lh_superiorfrontal_area	lh_superiorparietal_area	lh_superiortemporal_area	lh_supramarginal_area	lh_frontalpole_area	lh_temporalpole_area	lh_transversetemporal_area	lh_insula_area	lh_WhiteSurfArea_area"
            v_file_header_dict['rh.aparc.area'] = "rh.aparc.area	rh_bankssts_area	rh_caudalanteriorcingulate_area	rh_caudalmiddlefrontal_area	rh_cuneus_area	rh_entorhinal_area	rh_fusiform_area	rh_inferiorparietal_area	rh_inferiortemporal_area	rh_isthmuscingulate_area	rh_lateraloccipital_area	rh_lateralorbitofrontal_area	rh_lingual_area	rh_medialorbitofrontal_area	rh_middletemporal_area	rh_parahippocampal_area	rh_paracentral_area	rh_parsopercularis_area	rh_parsorbitalis_area	rh_parstriangularis_area	rh_pericalcarine_area	rh_postcentral_area	rh_posteriorcingulate_area	rh_precentral_area	rh_precuneus_area	rh_rostralanteriorcingulate_area	rh_rostralmiddlefrontal_area	rh_superiorfrontal_area	rh_superiorparietal_area	rh_superiortemporal_area	rh_supramarginal_area	rh_frontalpole_area	rh_temporalpole_area	rh_transversetemporal_area	rh_insula_area	rh_WhiteSurfArea_area"
            v_old_truncate_dict = {}
            v_old_truncate_dict['aseg'] = "truncate table cg_aseg_old"
            v_old_truncate_dict['lh.aparc.area'] = "truncate table cg_lh_aparc_area_old"
            v_old_truncate_dict['rh.aparc.area'] = "truncate table cg_rh_aparc_area_old" 
            v_truncate_dict = {}
            v_truncate_dict['aseg'] = "truncate table cg_aseg"
            v_truncate_dict['lh.aparc.area'] = "truncate table cg_lh_aparc_area"
            v_truncate_dict['rh.aparc.area'] = "truncate table cg_rh_aparc_area"
            v_new_truncate_dict = {}
            v_new_truncate_dict['aseg'] = "truncate table cg_aseg_new"
            v_new_truncate_dict['lh.aparc.area'] = "truncate table cg_lh_aparc_area_new"
            v_new_truncate_dict['rh.aparc.area'] = "truncate table cg_rh_aparc_area_new"
            v_sql_base_dict = {}
            v_sql_base_dict['aseg'] ="subjectid,left_lateral_ventricle,left_inf_lat_vent,left_cerebellum_white_matter,left_cerebellum_cortex,
            left_thalamus_proper,left_caudate,left_putamen,left_pallidum,third_ventricle,fourth_ventricle,
            brain_stem,left_hippocampus,left_amygdala,csf,left_accumbens_area,left_ventraldc,left_vessel,
            left_choroid_plexus,right_lateral_ventricle,right_inf_lat_vent,right_cerebellum_white_matter,
            right_cerebellum_cortex,right_thalamus_proper,right_caudate,right_putamen,
            right_pallidum,right_hippocampus,right_amygdala,right_accumbens_area,right_ventraldc,right_vessel,
            right_choroid_plexus,fifth_ventricle,wm_hypointensities,left_wm_hypointensities,
            right_wm_hypointensities,non_wm_hypointensities,left_non_wm_hypointensities,right_non_wm_hypointensities,
            optic_chiasm,cc_posterior,cc_mid_posterior,cc_central,cc_mid_anterior,cc_anterior,lhcortexvol,
            rhcortexvol,cortexvol,lhcorticalwhitemattervol,rhcorticalwhitemattervol,corticalwhitemattervol,
            subcortgrayvol,totalgrayvol,supratentorialvol,intracranialvol "                       
            v_sql_base_dict['lh.aparc.area'] ="subjectid,lh_bankssts_area,lh_caudalanteriorcingulate_area,lh_caudalmiddlefrontal_area,lh_cuneus_area,
            lh_entorhinal_area,lh_fusiform_area,lh_inferiorparietal_area,lh_inferiortemporal_area,lh_isthmuscingulate_area,
            lh_lateraloccipital_area,lh_lateralorbitofrontal_area,lh_lingual_area,lh_medialorbitofrontal_area,
            lh_middletemporal_area,lh_parahippocampal_area,lh_paracentral_area,lh_parsopercularis_area,lh_parsorbitalis_area,
            lh_parstriangularis_area,lh_pericalcarine_area,lh_postcentral_area,lh_posteriorcingulate_area,
            lh_precentral_area,lh_precuneus_area,lh_rostralanteriorcingulate_area,lh_rostralmiddlefrontal_area,
            lh_superiorfrontal_area,lh_superiorparietal_area,lh_superiortemporal_area,lh_supramarginal_area,
            lh_frontalpole_area,lh_temporalpole_area,lh_transversetemporal_area,
            lh_insula_area,lh_whitesurfarea_area "
            v_sql_base_dict['rh.aparc.area'] ="subjectid,rh_bankssts_area,rh_caudalanteriorcingulate_area,rh_caudalmiddlefrontal_area,rh_cuneus_area,
            rh_entorhinal_area,rh_fusiform_area,rh_inferiorparietal_area,rh_inferiortemporal_area,rh_isthmuscingulate_area,
            rh_lateraloccipital_area,rh_lateralorbitofrontal_area,rh_lingual_area,rh_medialorbitofrontal_area,
            rh_middletemporal_area,rh_parahippocampal_area,rh_paracentral_area,rh_parsopercularis_area,
            rh_parsorbitalis_area,rh_parstriangularis_area,rh_pericalcarine_area,rh_postcentral_area,
            rh_posteriorcingulate_area,rh_precentral_area,rh_precuneus_area,rh_rostralanteriorcingulate_area,
            rh_rostralmiddlefrontal_area,rh_superiorfrontal_area,rh_superiorparietal_area,rh_superiortemporal_area,
            rh_supramarginal_area,rh_frontalpole_area,rh_temporalpole_area,rh_transversetemporal_area,
            rh_insula_area,rh_whitesurfarea_area "
            
            
            # v_table_array =["cg_aseg","cg_lh_aparc_area", "cg_rh_aparc_area"]
            #v_result_array[1]+".aseg.all.txt",  v_result_array[1]+".lh.aparc.area.all.txt",   v_result_array[1]+".rh.aparc.area.all.txt"
            v_file_dir = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
            # loop thru file array
            v_file_array.each do |f|
              v_file_name = v_date_stamp+"."+f+".all.txt"
              puts "file name = "+v_file_name
              v_file_path = v_file_dir+v_file_name
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
              if v_header.gsub(/	/,"").gsub(/\n/,"") !=  v_file_header_dict[f].gsub(/	/,"").gsub(/\n/,"")
                v_comment = "ERROR!!! file header "+f+" not match expected header \n" +v_comment
                puts "ERROR!!! file header "+f+" not match expected header"                
              else
                puts " header matches expected."
                v_comment = " header matches expected."+v_comment
                v_comment = v_comment[0..499]
                sql = v_new_truncate_dict[f]
                results = connection.execute(sql)
                v_cnt = 0
                v_line_array = []
                File.open(v_file_path,'r') do |file_a|
                  while line = file_a.gets
                    if v_cnt > 0
                      sql = "insert into cg_"+f.gsub(/\./,'_')+"_new ( "+v_sql_base_dict[f]+" ) values("
                      v_line_array = []
                      line.gsub(/\n/,"").split("\t").each do |v|
                        v_line_array.push("'"+v+"'")
                      end 
                      sql = sql+v_line_array.join(",")
                      sql = sql+")"
                      results = connection.execute(sql)                    
                    end
                    v_cnt = v_cnt + 1
                  end
                end
                # update enrollment -- make into a function?
                sql = "update cg_"+f.gsub(/\./,'_')+"_new  t set t.enrollment_id = ( select e.id from enrollments e where e.enumber = replace(replace(replace(replace(t.subjectid,'_v2',''),'_v3',''),'_v4',''),'_v5',''))"
                results = connection.execute(sql)
                # need to apply in insert to cg_ tables --- multple rows --- just getting min(vgroup_id) to track unmapped rows
                # update vgroup  -- make into a function
                sql = "update cg_"+f.gsub(/\./,'_')+"_new  t set t.vgroup_id = ( select min( evm.vgroup_id) from enrollment_vgroup_memberships evm where evm.enrollment_id = t.enrollment_id
                                                                                  and evm.vgroup_id in ( select spv.vgroup_id from scan_procedures_vgroups spv, scan_procedures sp
                                                                                         where sp.id = spv.scan_procedure_id
                                                                                         and ( sp.codename like '%visit1' or sp.codename not like '%visit%')))
                      where t.subjectid not like '%_v2' and  t.subjectid not like '%_v3' and  t.subjectid not like '%_v4' and  t.subjectid not like '%_v5' " 
                results = connection.execute(sql)
                v_visit_array.each do |v_num|
                   sql = "update cg_"+f.gsub(/\./,'_')+"_new  t set t.vgroup_id = ( select  min( evm.vgroup_id) from enrollment_vgroup_memberships evm where evm.enrollment_id = t.enrollment_id
                                                                                  and evm.vgroup_id in ( select spv.vgroup_id from scan_procedures_vgroups spv, scan_procedures sp
                                                                                         where sp.id = spv.scan_procedure_id
                                                                                         and sp.codename like '%visit"+v_num+"'))
                      where t.subjectid like '%_v"+v_num+"'"
                   results = connection.execute(sql)
                 end
              
                # report on unmapped rows, not insert unmapped rows 
                sql = "select subjectid, enrollment_id from cg_"+f.gsub(/\./,'_')+"_new where vgroup_id is null order by subjectid"
                results = connection.execute(sql)
                results.each do |re|
                  v_comment = re.join(' | ')+" ,"+v_comment
                end
                if !results.blank?
                   v_comment = "cg_"+f.gsub(/\./,'_')+"_new unmapped subjectid,enrollment_id ="+v_comment
                end
                
                # check move cg_ to cg_old
                sql = "select count(*) from cg_"+f.gsub(/\./,'_')+"_old"
                results_old = connection.execute(sql)
                
                sql = "select count(*) from cg_"+f.gsub(/\./,'_')
                results = connection.execute(sql)
                v_old_cnt = results_old.first.to_s.to_i
                v_present_cnt = results.first.to_s.to_i
                v_old_minus_present =v_old_cnt-v_present_cnt
                v_present_minus_old = v_present_cnt-v_old_cnt
                if ( v_old_minus_present <= 0 or ( v_old_cnt > 0 and  (v_present_minus_old/v_old_cnt)>0.7     ) )
                  sql =  v_old_truncate_dict[f]
                  results = connection.execute(sql)
                  sql = "insert into cg_"+f.gsub(/\./,'_')+"_old select * from cg_"+f.gsub(/\./,'_')
                  results = connection.execute(sql)
                else
                  v_comment = " The cg_"+f.gsub(/\./,'_')+"_old table has 30% more rows than the present cg_"+f.gsub(/\./,'_')+"\n Not truncating cg_"+f.gsub(/\./,'_')+"_old "+v_comment 
                end
                #  truncate cg_ and insert cg_new
                sql =  v_truncate_dict[f]
                results = connection.execute(sql)
                
                sql = "insert into cg_"+f.gsub(/\./,'_')+"("+v_sql_base_dict[f]+",enrollment_id,vgroup_id) 
                select "+v_sql_base_dict[f]+",t.enrollment_id, evm.vgroup_id from cg_"+f.gsub(/\./,'_')+"_new t,enrollment_vgroup_memberships evm
                                               where t.vgroup_id is not null and t.subjectid not like '%_v%'
                                              and  evm.enrollment_id = t.enrollment_id
                                              and evm.vgroup_id in ( select spv.vgroup_id from scan_procedures_vgroups spv, scan_procedures sp
                                                                     where sp.id = spv.scan_procedure_id
                                                                   and ( sp.codename like '%visit1' or sp.codename not like '%visit%'))"
                results = connection.execute(sql)
                
                v_visit_array.each do |v_num|
                   sql = "insert into cg_"+f.gsub(/\./,'_')+"("+v_sql_base_dict[f]+",enrollment_id,vgroup_id) 
                   select "+v_sql_base_dict[f]+",t.enrollment_id, evm.vgroup_id from cg_"+f.gsub(/\./,'_')+"_new t,enrollment_vgroup_memberships evm
                                               where t.vgroup_id is not null and t.subjectid  like '%_v"+v_num+"%'
                                              and  evm.enrollment_id = t.enrollment_id
                                              and evm.vgroup_id in ( select spv.vgroup_id from scan_procedures_vgroups spv, scan_procedures sp
                                                                     where sp.id = spv.scan_procedure_id
                                                                   and ( sp.codename like '%visit"+v_num+"'))"
                   results = connection.execute(sql)
                end
                # apply edits  -- make into a function --- same as in data_searches controller
                v_tn = "cg_"+f.gsub(/\./,'_')
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
                
                 
                 v_comment = "finish loading cg_"+f.gsub(/\./,'_')+"   \n"               
              end
           end
            
          
         # load aseg, lh aparc, rh aparc files    
       
         @schedulerun.comment =("successful finish fs_aseg_aparc  values=") # +v_last_return_value+"\n"+v_comment)[0..499]
         @schedulerun.status_flag ="Y"
         
         else
           @schedulerun.comment =("error in fs_file.py fs_aseg_aparc  "+v_last_return_value+"\n"+v_comment)[0..499]
         end
         @schedulerun.save
         @schedulerun.end_time = @schedulerun.updated_at      
         @schedulerun.save
       puts " Successful fs_aseg_aparc !!"
       rescue Exception => msg
          v_error = msg.to_s
          puts "ERROR !!!!!!!"
          puts v_error
           @schedulerun.comment =(v_error[0..499]+v_comment)[0..499]
           @schedulerun.status_flag="E"
           @schedulerun.save
       end   
    
  end
  
end