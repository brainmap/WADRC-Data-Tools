# encoding: utf-8
require 'visit'
require 'image_dataset'
require 'shared' # this contains functions --- not sure where else to make functions accessible to this class
# require 'open4'

class CronInterface < ActiveRecord::Base
  v_value_1 = ARGV[0]
  puts "AAAAAAAAAAA in CronInterface"+v_value_1.to_s+"="
  v_shared = Shared.new
  v_base_path = Shared.get_base_path()
  puts v_base_path

  if v_value_1 == "test"
    v_shared = Shared.new
    v_flag =""
    v_comment =""
#    sql = "select subjectid from cg_aseg"
#    connection = ActiveRecord::Base.connection();        
#    results = connection.execute(sql)
#    results.each do |r|
#        v_comment =v_shared.get_sp_id_from_subjectid_v(r[0])
#       if v_comment.blank?
#         puts r[0]
#       end
#    end
    v_path = v_base_path+"/preprocessed/visits/johnson.merit220.visit2/mrt00064/asl"
    v_dir_array = Dir.entries(v_path)
    v_dir_array.each do |f|
      puts "aaaaa"+f
    end
    
  end  # end test

# NEED TO BE IN FOR CRON !!!!!!
v_username_list = ['admin','panda_admin','panda_user']  
sql = "select users.username from users where role in ('Admin_High','Admin_Low')"
results = connection.execute(sql)
results.each do |r|
      v_username_list.push(r[0])
end
v_user = `echo $USER`
v_user = v_user.gsub("\n","")
 @schedule = Schedule.where("name='"+v_value_1+"'")
 sql = "select users.username from users, schedules_users where users.id =  schedules_users.user_id and schedules_users.schedule_id="+@schedule[0].id.to_s
 connection = ActiveRecord::Base.connection();        
 results = connection.execute(sql)
 results.each do |r|
       v_username_list.push(r[0])
 end

 if !v_username_list.index(v_user).blank?  # limit cron execution to panda, admins and owners
  if v_value_1 == "asl_status"
    v_shared = Shared.new
    v_shared.run_asl_status()
  
  elsif v_value_1 == "asl_sw_fs_process"
       v_shared = Shared.new
       v_shared.run_asl_sw_fs_process()
  
  elsif v_value_1 == "asl_harvest"
       v_shared = Shared.new
       v_shared.run_asl_harvest()

  elsif v_value_1 == "adrc_dti"
      v_shared = Shared.new
      v_shared.run_adrc_dti()

  elsif v_value_1 == "adrc_pcvipr"
      v_shared = Shared.new
      v_shared.run_adrc_pcvipr()       
    
 elsif v_value_1 == "adrc_upload"
      v_shared = Shared.new
      v_shared.run_adrc_upload()

  elsif v_value_1 == "adrc_wahlin_t1_asl_resting"
      v_shared = Shared.new
      v_shared.run_adrc_wahlin_t1_asl_resting()  
      
 elsif v_value_1 == "antuano_20130916_upload"
      v_shared = Shared.new
      v_shared.run_antuano_20130916_upload()  

 elsif v_value_1 == "apoe_fill"
      v_shared = Shared.new
      v_shared.run_apoe_fill()  

 elsif v_value_1 == "batch_visit_import"  
      v_shared = Shared.new
      v_shared.run_batch_visit_import() 

 elsif v_value_1 == "booked_disconnect_tracker"  
      v_shared = Shared.new
      v_shared.run_booked_disconnect_tracker() 
      
 elsif v_value_1 == "change_log"  
      v_shared = Shared.new
      v_shared.run_change_log() 
 elsif v_value_1 == "check_if_raw_dirs_exist"  
      v_shared = Shared.new
      v_shared.run_check_if_raw_dirs_exist()
      
 elsif v_value_1 == "test_sftp"
      v_shared = Shared.new
      v_shared.run_sftp()  
 
 elsif v_value_1 == "dicom_header_field_harvest"
      v_shared = Shared.new
      v_shared.run_dicom_header_field_harvest()
       
 elsif v_value_1 == "dir_size"
      v_shared = Shared.new
      v_shared.run_dir_size()
      
 elsif v_value_1 == "dti_status"
      v_shared = Shared.new
      v_shared.run_dti_status()
    
  elsif v_value_1 == "epi_rest_status"
      v_shared = Shared.new
      v_shared.run_epi_rest_status()  

   elsif v_value_1 == "error_repeat_schedulerun"
      v_shared = Shared.new
      v_shared.run_error_repeat_schedulerun()       
  
  elsif v_value_1 == "fdg_status"
      v_shared = Shared.new
      puts " before call to fdg_status"
      v_shared.run_fdg_status()
      puts " after call to fdg_status"

  elsif v_value_1 == "fjell_20140506_upload"
      v_shared = Shared.new
      v_shared.run_fjell_20140506_upload()  

  elsif v_value_1 == "fs_move_qc_pass_to_good2go"
      v_shared = Shared.new
      v_shared.run_fs_move_qc_pass_to_good2go()

  elsif v_value_1 == "fs_move_edit_file_complete_to_good2go"
      v_shared = Shared.new
      v_shared.run_fs_move_edit_file_complete_to_good2go()  

   elsif v_value_1 == "fs_Y_N_manual_edits"
      v_shared = Shared.new
      v_shared.run_fs_Y_N_manual_edits()

    elsif v_value_1 == "fsl_first_volumes"
      v_shared = Shared.new
      v_shared.run_fsl_first_volumes()  

  elsif v_value_1 == "goveas_20131031_upload"
      v_shared = Shared.new
      v_shared.run_goveas_upload()  

  elsif v_value_1 == "helpern_20151125_upload"
      v_shared = Shared.new
      v_shared.run_helpern_20151125_upload()    

  elsif v_value_1 == "hyunwoo_20140520_upload"
      v_shared = Shared.new
      v_shared.run_hyunwoo_20140520_upload()  
  elsif v_value_1 == "image_dataset_default_bravo"
      v_shared = Shared.new
      v_shared.run_image_dataset_default_bravo() 
      
  elsif v_value_1 == "lst_116_status"  # getting lst_122 and lst_116 
      v_shared = Shared.new
      v_shared.run_lst_116_status()  

  elsif v_value_1 == "lst_v3_status"  # getting lst_122 and lst_116 
      v_shared = Shared.new
      v_shared.run_lst_v3_status()   
  
  elsif v_value_1 == "lst_122_process" 
      v_shared = Shared.new
      v_shared.run_lst_122_process()

  elsif v_value_1 == "lst_v3_process" 
      v_shared = Shared.new
      v_shared.run_lst_v3_process()

  elsif v_value_1 == "mcd_harvest" 
      v_shared = Shared.new
      v_shared.run_mcd_harvest()

   elsif v_value_1 == "padi_upload"
      v_shared = Shared.new
      v_shared.run_padi_upload()

    elsif v_value_1 == "padi_upload_20170227_dicom"
      v_shared = Shared.new
      v_shared.run_padi_upload_20170227_dicom()
    elsif v_value_1 == "padi_upload_20170227_nifty"
      v_shared = Shared.new
      v_shared.run_padi_upload_20170227_nifty()

  elsif v_value_1 == "padi_dvr_acpc_ids"
      v_shared = Shared.new
      v_shared.run_padi_dvr_acpc_ids()
        
  elsif v_value_1 == "pet_path"  
      v_shared = Shared.new
      v_shared.run_pet_path()
  elsif v_value_1 == "pet_preprocessed_data"  
      v_shared = Shared.new
      v_shared.run_pet_preprocessed_data()
  elsif v_value_1 == "pcvipr_recon_and_gating_check"  
      v_shared = Shared.new
      v_shared.run_pcvipr_recon_and_gating_check()
  elsif v_value_1 == "pcvipr_recon_and_fail_list"  
      v_shared = Shared.new
      v_shared.pcvipr_recon_and_fail_list()
  elsif v_value_1 == "pcvipr_output_file"  
      v_shared = Shared.new
      v_shared.run_pcvipr_output_file()
  elsif v_value_1 == "pcvipr_output_file_rm_output"  
      v_shared = Shared.new
      v_shared.run_pcvipr_output_file_rm_output()
  elsif v_value_1 == "pcvipr_output_file_rm_output_and_log"  
      v_shared = Shared.new
      v_shared.run_pcvipr_output_file_rm_output_and_log()
  elsif v_value_1 == "pcvipr_output_file_rerun_if_no_output"  
      v_shared = Shared.new
      v_shared.run_pcvipr_output_file_rerun_if_no_output()
  elsif v_value_1 == "pcvipr_output_file_harvest"  
      v_shared = Shared.new
      v_shared.run_pcvipr_output_file_harvest()
  elsif v_value_1 == "pcvipr_html"  
      v_shared = Shared.new
      v_shared.run_pcvipr_html()
  elsif v_value_1 == "pcvipr_html_full_replace"  
      v_shared = Shared.new
      v_shared.run_pcvipr_html_full_replace()
   elsif v_value_1 == "pet_av1451_harvest"
      v_shared = Shared.new
      v_shared.run_pet_av1451_harvest()
   elsif v_value_1 == "pet_av1451_process"
      v_shared = Shared.new
      v_shared.run_pet_av1451_process()
   elsif v_value_1 == "pet_mk6240_harvest"
      v_shared = Shared.new
      v_shared.run_pet_mk6240_harvest()
   elsif v_value_1 == "pet_mk6240_process"
      v_shared = Shared.new
      v_shared.run_pet_mk6240_process()
   elsif v_value_1 == "pet_pib_suvr_harvest"
      v_shared = Shared.new
      v_shared.run_pet_pib_suvr_harvest()
   elsif v_value_1 == "pet_pib_suvr_process"
      v_shared = Shared.new
      v_shared.run_pet_pib_suvr_process()
   elsif v_value_1 == "pet_pib_dvr_harvest"
      v_shared = Shared.new
      v_shared.run_pet_pib_dvr_harvest()
   elsif v_value_1 == "pet_pib_dvr_process"
      v_shared = Shared.new
      v_shared.run_pet_pib_dvr_process()
  elsif v_value_1 == "pib_status"
      v_shared = Shared.new
      v_shared.run_pib_status()
  elsif v_value_1 == "pib_cereb_tac"
      v_shared = Shared.new
      v_shared.run_pib_cereb_tac()
  elsif v_value_1 == "processedimage_asl_harvest"
      v_shared = Shared.new
      v_shared.run_processedimage_asl_harvest()
  elsif v_value_1 == "processedimage_tissue_seg_harvest"
      v_shared = Shared.new
      v_shared.run_processedimage_tissue_seg_harvest()
  elsif v_value_1 == "processedimage_unknown_harvest"
      v_shared = Shared.new
      v_shared.run_processedimage_unknown_harvest()

  elsif v_value_1 == "selley_20130906_upload"
      v_shared = Shared.new
      v_shared.run_selley_20130906_upload()   
 
  elsif v_value_1 == "series_description"
      v_shared = Shared.new
      v_shared.run_series_description()  

  elsif v_value_1 == "sleep_t1"
      v_shared = Shared.new
      v_shared.run_sleep_t1()   
         
  elsif v_value_1 == "sp_scanner_protocol"
    v_shared = Shared.new
    v_shared.run_sp_scanner_protocol()   

  elsif v_value_1 == "table_cell_comparison" 
    v_shared = Shared.new
    v_shared.run_table_cell_comparison()   
    
  elsif v_value_1 == "t1seg_spm8_gm_wm_csf_volumes" # volumes not being harvested any more 
      v_shared = Shared.new
      v_shared.run_t1seg_spm8_gm_wm_csf_volumes()

  elsif v_value_1 == "tissueseg_spm12"
      v_shared = Shared.new
      v_shared.run_tissueseg_spm12()  

  elsif v_value_1 == "tissueseg_spm12_gm_wm_csf_volumes" # harvests
      v_shared = Shared.new
      v_shared.run_tissueseg_spm12_gm_wm_csf_volumes() 

  elsif v_value_1 == "user_networkgroup_harvest"
      v_shared = Shared.new
      v_shared.run_user_networkgroup_harvest() 

   elsif v_value_1 == "washu_upload"
      v_shared = Shared.new
      v_shared.run_washu_upload()

  elsif v_value_1 == "xnat_file"
      v_shared = Shared.new
      v_shared.run_xnat_file()  
  elsif v_value_1 == "xnat_upload"
      v_shared = Shared.new
      v_shared.run_xnat_upload()   
  elsif v_value_1 == "xnat_session"
      v_shared = Shared.new
      v_shared.run_xnat_session()

            
  elsif v_value_1 == "test_shell"
    puts "bbbbbbbbb in test shell"
    v_shared = Shared.new
    v_base_path = "/mounts/data"
     @schedule = Schedule.where("name in ('test_shell')").first
      @schedulerun = Schedulerun.new
      @schedulerun.schedule_id = @schedule.id
      @schedulerun.comment ="starting test_shell"
      @schedulerun.save
      @schedulerun.start_time = @schedulerun.created_at
      @schedulerun.save
      v_comment = ""
      v_command = v_base_path+"/data1/lab_scripts/python_dev/test_shell.sh "+v_base_path+"/preprocessed/visits/johnson.predict.visit1/pdt00126/LST_116 "+v_base_path+"/preprocessed/visits/johnson.predict.visit1/pdt00126/LST_116/watlas_wm.nii "


     # testing ids check
     v_shared.run_test()
# --- calls one gets exit status   -- test_shell calls internal function 
#       status = POpen4::popen4(v_command) do |stdout, stderr |
#           puts "stdout     : #{ stdout.read.strip }"
#           puts "stderr     : #{ stderr.read.strip }"
#         end
#           puts "status     : #{ status.inspect }"
#           puts "exitstatus : #{ status.exitstatus }"
           
# spawn   ## spawn error if return value != 0?   --- runs them one after another
      v_array=[0,1,2,3]
      # ??? open4(producer) do |pid, i, o, e|
      #producer = 'ruby -e" STDOUT.sync = true; loop{sleep(rand+rand) and puts 42} "'
#      v_array.each do |v|
#        puts 'start '+v.to_s
#       open4.spawn v_command,  :stdout=>STDOUT      #, :stdin_timeout => 1.4
#        puts 'end '+v.to_s       
#      end

# fork    undefined method `pfork4'
# bg    


           
        @schedulerun.comment = v_comment[0..459]
        @schedulerun.status_flag = 'E'
        @schedulerun.save
        # puts "EXIT STATUS:"+status.exitstatus.to_s

        puts "  zzzzzzzz end of test_shell"
  elsif v_value_1 == "fsl_first_value_harvester"
      v_shared = Shared.new
      v_shared.run_fsl_first_value_harvester()
      
  # dev 
  #/usr/local/bin/rails  runner /Users/caillingworth/code/WADRC-Data-Tools/app/cron_interface.rb sp_series_desc_count
  elsif v_value_1 == "sp_series_desc_count"
    
      v_shared = Shared.new
      v_base_path = Shared.get_base_path()
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
      v_end_id  = ""
      results.each do |r|
        v_end_id   = r[1].to_s
       end
     if !v_end_id.blank?
      results.each do |r|
        v_start_id =r[0].to_s
        v_end_id   = r[1].to_s
        image_dataset = ImageDataset.find(v_end_id)
        visit = Visit.find(image_dataset.visit_id)
        puts "start id = "+v_start_id+"   end id="+v_end_id
        visit.series_desc_cnt(v_start_id, v_end_id)
       end
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
      @schedulerun.comment =v_comment
      @schedulerun.save
      
      # get the nii file_count from vgroups
      sql = "select min(vgroups.id) min_id, max(vgroups.id) max_id from vgroups where ( nii_file_count is not null or nii_file_count > 0)
         and  vgroups.vgroup_date > adddate(curdate(),'-31')"      
      results = connection.execute(sql)
       v_end_id  = ""
      results.each do |r|
         v_end_id   = r[1].to_s
      end
      if !v_end_id.blank?
       results.each do |r|
          v_start_id =r[0].to_s
          v_end_id   = r[1].to_s
          puts "VGROUP start id = "+v_start_id+"   end id="+v_end_id
          vgroup = Vgroup.find(v_end_id)
          puts "VGROUP start id = "+v_start_id+"   end id="+v_end_id
          v_comment = "start nii_file_cnt "+v_comment
          @schedulerun.comment =v_comment
          @schedulerun.save
          vgroup.nii_file_cnt(v_start_id, v_end_id)  
          # alread got from visits v_base_path = vgroup.get_base_path() # happens to be in the visits model
       end
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
       @schedulerun.comment =v_comment
       @schedulerun.save
      
      
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

      # series_desc 20/5 count 
      sql = "truncate table t_sp_series_desc_vgroup_count_freq"      
      results = connection.execute(sql)
      sql = "select distinct sdsp.scan_procedure_id, sp.codename from series_description_scan_procedures sdsp, scan_procedures sp 
               where sdsp.scan_procedure_id = sp.id"
      results = connection.execute(sql)
      results.each do |r|
          v_scan_procedure_id = r[0]
          v_codename = r[1]
          sql_total = "select count(distinct vg.id) from  vgroups vg , scan_procedures_vgroups spvg 
                        where vg.id = spvg.vgroup_id and spvg.scan_procedure_id ="+v_scan_procedure_id.to_s+"
                         and vg.transfer_mri ='yes'"
          results_total = connection.execute(sql_total)
          v_sp_total = results_total.first[0]
          v_5 = 5
          v_20 = 20
          if(v_sp_total < 5 )
            v_5 = v_sp_total
            v_20 = v_sp_total
          elsif(v_sp_total < 20)
             v_20 = v_sp_total
          end
          sql_fraction = "select sd.long_description, sdsp.scan_count_all, sdsp.scan_count_last_20,sdsp.scan_count_last_5
                  from series_descriptions sd, series_description_scan_procedures sdsp
                  where  sdsp.scan_procedure_id = "+v_scan_procedure_id.to_s+"
                  and sdsp.series_description_id = sd.id "
          results_fraction = connection.execute(sql_fraction)
          #insert into t_sp_series_desc_vgroup_count_freq
          results_fraction.each do |r_fraction|
             sql_insert ="insert into t_sp_series_desc_vgroup_count_freq (codename,
              series_description,vgroup_total,vgroup_series_desc_total,vgroup_total_fraction_of_all,
vgroup_20_total,vgroup_20_fraction_of_20,vgroup_5_total,vgroup_5_fraction_of_5 ) 
      values('"+v_codename+"','"+r_fraction[0]+"',"+v_sp_total.to_s+","+r_fraction[1].to_s+",("+r_fraction[1].to_s+"/"+v_sp_total.to_s+"),"+r_fraction[2].to_s+",("+r_fraction[2].to_s+"/"+v_20.to_s+"),"+r_fraction[3].to_s+",("+r_fraction[3].to_s+"/"+v_5.to_s+"))"
            results_insert = connection.execute(sql_insert)
          end
      end
      # get sp from last month -- codename
      sql = "select distinct scan_procedures.codename from scan_procedures, scan_procedures_vgroups spg2, vgroups vg
                                        where scan_procedures.id = spg2.scan_procedure_id and vg.id=spg2.vgroup_id  and vg.vgroup_date >  adddate(curdate(),'-181')"                            
      results = connection.execute(sql)
      results.each do |r|
           puts "codename="+r[0]
           v_comment = "\n codename="+r[0]+v_comment
           sql_internal = "select codename,series_description,vgroup_total_fraction_of_all,vgroup_20_fraction_of_20,vgroup_5_fraction_of_5
                          from t_sp_series_desc_vgroup_count_freq
                         where t_sp_series_desc_vgroup_count_freq.codename='"+r[0]+"' order by series_description "
           results_internal = connection.execute(sql_internal)
           # open file for codename
           v_file = v_dir_path+r[0]+"_series_desc_vgroup_cnt.txt"
           File.open(v_file, "w+") do |f|
             results_internal.each do |rc|
               f.write(rc[0]+"\t"+rc[1]+"\t"+rc[2].to_s+"\t"+rc[3].to_s+"\t"+rc[4].to_s+"\n")
               # write a tab separated row
             end
           end
      end

       @schedulerun.comment =("successful finish sp_series_desc_count "+v_comment[0..459])
       @schedulerun.status_flag ="Y"
        @schedulerun.save
        @schedulerun.end_time = @schedulerun.updated_at      
        @schedulerun.save
        
      rescue Exception => msg
         v_error = msg.to_s
         puts "ERROR !!!!!!!"
         puts v_error
         v_error = v_error+"\n"+v_comment
          @schedulerun.comment =v_error[0..499]
          @schedulerun.status_flag="E"
          @schedulerun.save
      end
   elsif v_value_1 == "fs_Y_N"  
     v_shared = Shared.new
     v_shared.run_fs_Y_N()

  elsif v_value_1 == "fs_Y_N_donebutbad"  
     v_shared = Shared.new
     v_shared.run_fs_Y_N_donebutbad()

  elsif v_value_1 == "fs_Y_N_good2go"  
     v_shared = Shared.new
     v_shared.run_fs_Y_N_good2go()

   elsif v_value_1 == "fs_aseg_aparc"  #   rails runner app/cron_interface.rb fs_aseg_aparc
      
      @schedule = Schedule.where("name in ('fs_aseg_aparc')").first
      puts "schedule id = "+@schedule.id.to_s
       @schedulerun = Schedulerun.new
       if !@schedule.id.blank?
          @schedulerun.schedule_id = @schedule.id
       else
         @schedulerun.schedule_id = 4
      end
       @schedulerun.comment ="starting fs_aseg_aparc"
       @schedulerun.save
       @schedulerun.start_time = @schedulerun.created_at
       @schedulerun.save
       v_return_flag =""
       v_return_comment =""
       v_comment_base = @schedulerun.comment
     begin  
        # to do 
          # define tables, table_edit, add to cg tables/search 
         # call fs_file.py
         # only in prod --- lots of path issues
         time = Time.now
         v_date_stamp = time.strftime("%Y%m%d")
#### v_date_stamp ="20130117"
          # no FS on adrcdv2 -- shouldn't process on web server?
          #v_call = v_base_path+"/data1/lab_scripts/python_dev/fs_file.py Y"
          #v_call = "ssh panda_user@merida.dom.wisc.edu '"+v_base_path+"/data1/lab_scripts/python_dev/fs_file.py Y'"
         # v_call = v_base_path+"/SysAdmin/production/python/fs_file.py Y"
          v_call = "ssh panda_user@merida.dom.wisc.edu '"+v_base_path+"/SysAdmin/production/python/fs_file.py Y'"
          v_comment = "start "+v_call
          @schedulerun.comment = v_comment
          @schedulerun.save
          # v_call = v_base_path+"/data1/lab_scripts/python_dev/transfer_process.py -test_call"
          #v_return = system("export PYTHONPATH=/usr/local/bin/python/ && python "+v_call)  # return value not working
          #  its working but must be better way -- getting all the print output from the python script, 
          # exit in python script after "print" return value, loop thru to get the last line
# problem running in dev -- need to be admin-- make file, then test rest

          #v_return =  `python #{v_call}`
          v_return =  `#{v_call}`

          v_last_return_value = ""

         v_return.each_line do |line|
            v_comment = line + v_comment
            v_last_return_value = line
          end

          # evaluate return values v_return(ERROR or SUCCESS)+"|"+yyyymmdd+"|"+(/tmp/)log_file
####  added temp row
        #### v_last_return_value = "SUCCESS|"+v_date_stamp+"|tmp.YYYYMMDD.txt"
          v_comment = "after python call "+v_last_return_value + " \n "+v_comment
          @schedulerun.comment = v_comment
          @schedulerun.save
          v_result_array = v_last_return_value.split("|")
          if v_result_array[0] == "SUCCESS"
            connection = ActiveRecord::Base.connection();        
  
            # want to get orig_recon and good2go
            v_visit_array = ['2','3','4','5']
            v_file_array = ["aseg","lh.aparc.area","rh.aparc.area","lh.aparc.volume","rh.aparc.volume","lh.aparc.thickness","rh.aparc.thickness","aseg.good2go","lh.aparc.area.good2go","rh.aparc.area.good2go","lh.aparc.volume.good2go","rh.aparc.volume.good2go","lh.aparc.thickness.good2go","rh.aparc.thickness.good2go", ]
            v_file_dir_dict = {}
            v_file_dir_dict['aseg'] = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
            v_file_dir_dict['lh.aparc.area'] = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
            v_file_dir_dict['rh.aparc.area'] = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
            v_file_dir_dict['lh.aparc.volume'] = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
            v_file_dir_dict['rh.aparc.volume'] = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
            v_file_dir_dict['lh.aparc.thickness'] = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
            v_file_dir_dict['rh.aparc.thickness'] = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
            v_file_dir_dict['aseg.good2go'] = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"
            v_file_dir_dict['lh.aparc.area.good2go'] = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"
            v_file_dir_dict['rh.aparc.area.good2go'] = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"
            v_file_dir_dict['lh.aparc.volume.good2go'] = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"
            v_file_dir_dict['rh.aparc.volume.good2go'] = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"
            v_file_dir_dict['lh.aparc.thickness.good2go'] = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"
            v_file_dir_dict['rh.aparc.thickness.good2go'] = v_base_path+"/preprocessed/modalities/freesurfer/good2go/"

            v_file_header_dict = {}   # cannot just copy header -- need to preserve tabs   !!!!!!!
            v_file_header_dict['aseg'] = "Measure:volume	Left-Lateral-Ventricle	Left-Inf-Lat-Vent	Left-Cerebellum-White-Matter	Left-Cerebellum-Cortex	Left-Thalamus-Proper	Left-Caudate	Left-Putamen	Left-Pallidum	3rd-Ventricle	4th-Ventricle	Brain-Stem	Left-Hippocampus	Left-Amygdala	CSF	Left-Accumbens-area	Left-VentralDC	Left-vessel	Left-choroid-plexus	Right-Lateral-Ventricle	Right-Inf-Lat-Vent	Right-Cerebellum-White-Matter	Right-Cerebellum-Cortex	Right-Thalamus-Proper	Right-Caudate	Right-Putamen	Right-Pallidum	Right-HippocampusRight-Amygdala	Right-Accumbens-area	Right-VentralDC	Right-vessel	Right-choroid-plexus	5th-Ventricle	WM-hypointensities	Left-WM-hypointensities	Right-WM-hypointensities	non-WM-hypointensities	Left-non-WM-hypointensities	Right-non-WM-hypointensities	Optic-Chiasm	CC_Posterior	CC_Mid_Posterior	CC_Central	CC_Mid_Anterior	CC_Anterior	lhCortexVol	rhCortexVol	CortexVol	lhCorticalWhiteMatterVol	rhCorticalWhiteMatterVol	CorticalWhiteMatterVol	SubCortGrayVol	TotalGrayVol	SupraTentorialVol	IntraCranialVol"
            v_file_header_dict['lh.aparc.area'] = "lh.aparc.area	lh_bankssts_area	lh_caudalanteriorcingulate_area	lh_caudalmiddlefrontal_area	lh_cuneus_area	lh_entorhinal_area	lh_fusiform_area	lh_inferiorparietal_area	lh_inferiortemporal_area	lh_isthmuscingulate_area	lh_lateraloccipital_area	lh_lateralorbitofrontal_area	lh_lingual_area	lh_medialorbitofrontal_area	lh_middletemporal_area	lh_parahippocampal_area	lh_paracentral_area	lh_parsopercularis_area	lh_parsorbitalis_area	lh_parstriangularis_area	lh_pericalcarine_area	lh_postcentral_area	lh_posteriorcingulate_area	lh_precentral_area	lh_precuneus_area	lh_rostralanteriorcingulate_area	lh_rostralmiddlefrontal_area	lh_superiorfrontal_area	lh_superiorparietal_area	lh_superiortemporal_area	lh_supramarginal_area	lh_frontalpole_area	lh_temporalpole_area	lh_transversetemporal_area	lh_insula_area	lh_WhiteSurfArea_area"
            v_file_header_dict['rh.aparc.area'] = "rh.aparc.area	rh_bankssts_area	rh_caudalanteriorcingulate_area	rh_caudalmiddlefrontal_area	rh_cuneus_area	rh_entorhinal_area	rh_fusiform_area	rh_inferiorparietal_area	rh_inferiortemporal_area	rh_isthmuscingulate_area	rh_lateraloccipital_area	rh_lateralorbitofrontal_area	rh_lingual_area	rh_medialorbitofrontal_area	rh_middletemporal_area	rh_parahippocampal_area	rh_paracentral_area	rh_parsopercularis_area	rh_parsorbitalis_area	rh_parstriangularis_area	rh_pericalcarine_area	rh_postcentral_area	rh_posteriorcingulate_area	rh_precentral_area	rh_precuneus_area	rh_rostralanteriorcingulate_area	rh_rostralmiddlefrontal_area	rh_superiorfrontal_area	rh_superiorparietal_area	rh_superiortemporal_area	rh_supramarginal_area	rh_frontalpole_area	rh_temporalpole_area	rh_transversetemporal_area	rh_insula_area	rh_WhiteSurfArea_area"
            v_file_header_dict['lh.aparc.thickness'] = "lh.aparc.thickness	lh_bankssts_thickness	lh_caudalanteriorcingulate_thickness	lh_caudalmiddlefrontal_thickness	lh_cuneus_thickness	lh_entorhinal_thickness	lh_fusiform_thickness	lh_inferiorparietal_thickness	lh_inferiortemporal_thickness	lh_isthmuscingulate_thickness	lh_lateraloccipital_thickness	lh_lateralorbitofrontal_thickness	lh_lingual_thickness	lh_medialorbitofrontal_thickness	lh_middletemporal_thickness	lh_parahippocampal_thickness	lh_paracentral_thickness	lh_parsopercularis_thickness	lh_parsorbitalis_thickness	lh_parstriangularis_thickness	lh_pericalcarine_thickness	lh_postcentral_thickness	lh_posteriorcingulate_thickness	lh_precentral_thickness	lh_precuneus_thickness	lh_rostralanteriorcingulate_thickness	lh_rostralmiddlefrontal_thickness	lh_superiorfrontal_thickness	lh_superiorparietal_thickness	lh_superiortemporal_thickness	lh_supramarginal_thickness	lh_frontalpole_thickness	lh_temporalpole_thickness	lh_transversetemporal_thickness	lh_insula_thickness"
            v_file_header_dict['rh.aparc.thickness'] = "rh.aparc.thickness	rh_bankssts_thickness	rh_caudalanteriorcingulate_thickness	rh_caudalmiddlefrontal_thickness	rh_cuneus_thickness	rh_entorhinal_thickness	rh_fusiform_thickness	rh_inferiorparietal_thickness	rh_inferiortemporal_thickness	rh_isthmuscingulate_thickness	rh_lateraloccipital_thickness	rh_lateralorbitofrontal_thickness	rh_lingual_thickness	rh_medialorbitofrontal_thickness	rh_middletemporal_thickness	rh_parahippocampal_thickness	rh_paracentral_thickness	rh_parsopercularis_thickness	rh_parsorbitalis_thickness	rh_parstriangularis_thickness	rh_pericalcarine_thickness	rh_postcentral_thickness	rh_posteriorcingulate_thickness	rh_precentral_thickness	rh_precuneus_thickness	rh_rostralanteriorcingulate_thickness	rh_rostralmiddlefrontal_thickness	rh_superiorfrontal_thickness	rh_superiorparietal_thickness	rh_superiortemporal_thickness	rh_supramarginal_thickness	rh_frontalpole_thickness	rh_temporalpole_thickness	rh_transversetemporal_thickness	rh_insula_thickness"
            v_file_header_dict['lh.aparc.volume'] ="lh.aparc.volume	lh_bankssts_volume	lh_caudalanteriorcingulate_volume	lh_caudalmiddlefrontal_volume	lh_cuneus_volume	lh_entorhinal_volume	lh_fusiform_volume	lh_inferiorparietal_volume	lh_inferiortemporal_volume	lh_isthmuscingulate_volume	lh_lateraloccipital_volume	lh_lateralorbitofrontal_volume	lh_lingual_volume	lh_medialorbitofrontal_volume	lh_middletemporal_volume	lh_parahippocampal_volume	lh_paracentral_volume	lh_parsopercularis_volume	lh_parsorbitalis_volume	lh_parstriangularis_volume	lh_pericalcarine_volume	lh_postcentral_volume	lh_posteriorcingulate_volume	lh_precentral_volume	lh_precuneus_volume	lh_rostralanteriorcingulate_volume	lh_rostralmiddlefrontal_volume	lh_superiorfrontal_volume	lh_superiorparietal_volume	lh_superiortemporal_volume	lh_supramarginal_volume	lh_frontalpole_volume	lh_temporalpole_volume	lh_transversetemporal_volume	lh_insula_volume"
            v_file_header_dict['rh.aparc.volume'] ="rh.aparc.volume	rh_bankssts_volume	rh_caudalanteriorcingulate_volume	rh_caudalmiddlefrontal_volume	rh_cuneus_volume	rh_entorhinal_volume	rh_fusiform_volume	rh_inferiorparietal_volume	rh_inferiortemporal_volume	rh_isthmuscingulate_volume	rh_lateraloccipital_volume	rh_lateralorbitofrontal_volume	rh_lingual_volume	rh_medialorbitofrontal_volume	rh_middletemporal_volume	rh_parahippocampal_volume	rh_paracentral_volume	rh_parsopercularis_volume	rh_parsorbitalis_volume	rh_parstriangularis_volume	rh_pericalcarine_volume	rh_postcentral_volume	rh_posteriorcingulate_volume	rh_precentral_volume	rh_precuneus_volume	rh_rostralanteriorcingulate_volume	rh_rostralmiddlefrontal_volume	rh_superiorfrontal_volume	rh_superiorparietal_volume	rh_superiortemporal_volume	rh_supramarginal_volume	rh_frontalpole_volume	rh_temporalpole_volume	rh_transversetemporal_volume	rh_insula_volume" 

            v_file_header_dict['aseg.good2go'] =  v_file_header_dict['aseg']  #"Measure:volume Left-Lateral-Ventricle  Left-Inf-Lat-Vent Left-Cerebellum-White-Matter  Left-Cerebellum-Cortex  Left-Thalamus-Proper  Left-Caudate  Left-Putamen  Left-Pallidum 3rd-Ventricle 4th-Ventricle Brain-Stem  Left-Hippocampus  Left-Amygdala CSF Left-Accumbens-area Left-VentralDC  Left-vessel Left-choroid-plexus Right-Lateral-Ventricle Right-Inf-Lat-Vent  Right-Cerebellum-White-Matter Right-Cerebellum-Cortex Right-Thalamus-Proper Right-Caudate Right-Putamen Right-Pallidum  Right-HippocampusRight-Amygdala Right-Accumbens-area  Right-VentralDC Right-vessel  Right-choroid-plexus  5th-Ventricle WM-hypointensities  Left-WM-hypointensities Right-WM-hypointensities  non-WM-hypointensities  Left-non-WM-hypointensities Right-non-WM-hypointensities  Optic-Chiasm  CC_Posterior  CC_Mid_Posterior  CC_Central  CC_Mid_Anterior CC_Anterior lhCortexVol rhCortexVol CortexVol lhCorticalWhiteMatterVol  rhCorticalWhiteMatterVol  CorticalWhiteMatterVol  SubCortGrayVol  TotalGrayVol  SupraTentorialVol IntraCranialVol"
            v_file_header_dict['lh.aparc.area.good2go'] = v_file_header_dict['lh.aparc.area']    #  "lh.aparc.area  lh_bankssts_area  lh_caudalanteriorcingulate_area lh_caudalmiddlefrontal_area lh_cuneus_area  lh_entorhinal_area  lh_fusiform_area  lh_inferiorparietal_area  lh_inferiortemporal_area  lh_isthmuscingulate_area  lh_lateraloccipital_area  lh_lateralorbitofrontal_area  lh_lingual_area lh_medialorbitofrontal_area lh_middletemporal_area  lh_parahippocampal_area lh_paracentral_area lh_parsopercularis_area lh_parsorbitalis_area lh_parstriangularis_area  lh_pericalcarine_area lh_postcentral_area lh_posteriorcingulate_area  lh_precentral_area  lh_precuneus_area lh_rostralanteriorcingulate_area  lh_rostralmiddlefrontal_area  lh_superiorfrontal_area lh_superiorparietal_area  lh_superiortemporal_area  lh_supramarginal_area lh_frontalpole_area lh_temporalpole_area  lh_transversetemporal_area  lh_insula_area  lh_WhiteSurfArea_area"
            v_file_header_dict['rh.aparc.area.good2go'] = v_file_header_dict['rh.aparc.area']   #  "rh.aparc.area  rh_bankssts_area  rh_caudalanteriorcingulate_area rh_caudalmiddlefrontal_area rh_cuneus_area  rh_entorhinal_area  rh_fusiform_area  rh_inferiorparietal_area  rh_inferiortemporal_area  rh_isthmuscingulate_area  rh_lateraloccipital_area  rh_lateralorbitofrontal_area  rh_lingual_area rh_medialorbitofrontal_area rh_middletemporal_area  rh_parahippocampal_area rh_paracentral_area rh_parsopercularis_area rh_parsorbitalis_area rh_parstriangularis_area  rh_pericalcarine_area rh_postcentral_area rh_posteriorcingulate_area  rh_precentral_area  rh_precuneus_area rh_rostralanteriorcingulate_area  rh_rostralmiddlefrontal_area  rh_superiorfrontal_area rh_superiorparietal_area  rh_superiortemporal_area  rh_supramarginal_area rh_frontalpole_area rh_temporalpole_area  rh_transversetemporal_area  rh_insula_area  rh_WhiteSurfArea_area"
            v_file_header_dict['lh.aparc.thickness.good2go'] = v_file_header_dict['lh.aparc.thickness'] # "lh.aparc.thickness lh_bankssts_thickness lh_caudalanteriorcingulate_thickness  lh_caudalmiddlefrontal_thickness  lh_cuneus_thickness lh_entorhinal_thickness lh_fusiform_thickness lh_inferiorparietal_thickness lh_inferiortemporal_thickness lh_isthmuscingulate_thickness lh_lateraloccipital_thickness lh_lateralorbitofrontal_thickness lh_lingual_thickness  lh_medialorbitofrontal_thickness  lh_middletemporal_thickness lh_parahippocampal_thickness  lh_paracentral_thickness  lh_parsopercularis_thickness  lh_parsorbitalis_thickness  lh_parstriangularis_thickness lh_pericalcarine_thickness  lh_postcentral_thickness  lh_posteriorcingulate_thickness lh_precentral_thickness lh_precuneus_thickness  lh_rostralanteriorcingulate_thickness lh_rostralmiddlefrontal_thickness lh_superiorfrontal_thickness  lh_superiorparietal_thickness lh_superiortemporal_thickness lh_supramarginal_thickness  lh_frontalpole_thickness  lh_temporalpole_thickness lh_transversetemporal_thickness lh_insula_thickness"
            v_file_header_dict['rh.aparc.thickness.good2go'] = v_file_header_dict['rh.aparc.thickness'] #{}"rh.aparc.thickness rh_bankssts_thickness rh_caudalanteriorcingulate_thickness  rh_caudalmiddlefrontal_thickness  rh_cuneus_thickness rh_entorhinal_thickness rh_fusiform_thickness rh_inferiorparietal_thickness rh_inferiortemporal_thickness rh_isthmuscingulate_thickness rh_lateraloccipital_thickness rh_lateralorbitofrontal_thickness rh_lingual_thickness  rh_medialorbitofrontal_thickness  rh_middletemporal_thickness rh_parahippocampal_thickness  rh_paracentral_thickness  rh_parsopercularis_thickness  rh_parsorbitalis_thickness  rh_parstriangularis_thickness rh_pericalcarine_thickness  rh_postcentral_thickness  rh_posteriorcingulate_thickness rh_precentral_thickness rh_precuneus_thickness  rh_rostralanteriorcingulate_thickness rh_rostralmiddlefrontal_thickness rh_superiorfrontal_thickness  rh_superiorparietal_thickness rh_superiortemporal_thickness rh_supramarginal_thickness  rh_frontalpole_thickness  rh_temporalpole_thickness rh_transversetemporal_thickness rh_insula_thickness"
            v_file_header_dict['lh.aparc.volume.good2go'] = v_file_header_dict['lh.aparc.volume']  # "lh.aparc.volume  lh_bankssts_volume  lh_caudalanteriorcingulate_volume lh_caudalmiddlefrontal_volume lh_cuneus_volume  lh_entorhinal_volume  lh_fusiform_volume  lh_inferiorparietal_volume  lh_inferiortemporal_volume  lh_isthmuscingulate_volume  lh_lateraloccipital_volume  lh_lateralorbitofrontal_volume  lh_lingual_volume lh_medialorbitofrontal_volume lh_middletemporal_volume  lh_parahippocampal_volume lh_paracentral_volume lh_parsopercularis_volume lh_parsorbitalis_volume lh_parstriangularis_volume  lh_pericalcarine_volume lh_postcentral_volume lh_posteriorcingulate_volume  lh_precentral_volume  lh_precuneus_volume lh_rostralanteriorcingulate_volume  lh_rostralmiddlefrontal_volume  lh_superiorfrontal_volume lh_superiorparietal_volume  lh_superiortemporal_volume  lh_supramarginal_volume lh_frontalpole_volume lh_temporalpole_volume  lh_transversetemporal_volume  lh_insula_volume"
            v_file_header_dict['rh.aparc.volume.good2go'] = v_file_header_dict['rh.aparc.volume']  #{}"rh.aparc.volume  rh_bankssts_volume  rh_caudalanteriorcingulate_volume rh_caudalmiddlefrontal_volume rh_cuneus_volume  rh_entorhinal_volume  rh_fusiform_volume  rh_inferiorparietal_volume  rh_inferiortemporal_volume  rh_isthmuscingulate_volume  rh_lateraloccipital_volume  rh_lateralorbitofrontal_volume  rh_lingual_volume rh_medialorbitofrontal_volume rh_middletemporal_volume  rh_parahippocampal_volume rh_paracentral_volume rh_parsopercularis_volume rh_parsorbitalis_volume rh_parstriangularis_volume  rh_pericalcarine_volume rh_postcentral_volume rh_posteriorcingulate_volume  rh_precentral_volume  rh_precuneus_volume rh_rostralanteriorcingulate_volume  rh_rostralmiddlefrontal_volume  rh_superiorfrontal_volume rh_superiorparietal_volume  rh_superiortemporal_volume  rh_supramarginal_volume rh_frontalpole_volume rh_temporalpole_volume  rh_transversetemporal_volume  rh_insula_volume"

           
            v_old_truncate_dict = {}
            v_old_truncate_dict['aseg'] = "truncate table cg_aseg_old"
            v_old_truncate_dict['lh.aparc.area'] = "truncate table cg_lh_aparc_area_old"
            v_old_truncate_dict['rh.aparc.area'] = "truncate table cg_rh_aparc_area_old"
            v_old_truncate_dict['lh.aparc.volume'] = "truncate table cg_lh_aparc_volume_old"
            v_old_truncate_dict['rh.aparc.volume'] = "truncate table cg_rh_aparc_volume_old" 
            v_old_truncate_dict['lh.aparc.thickness'] = "truncate table cg_lh_aparc_thickness_old"
            v_old_truncate_dict['rh.aparc.thickness'] = "truncate table cg_rh_aparc_thickness_old"  
            v_old_truncate_dict['aseg.good2go'] = "truncate table cg_aseg_good2go_old"
            v_old_truncate_dict['lh.aparc.area.good2go'] = "truncate table cg_lh_aparc_area_good2go_old"
            v_old_truncate_dict['rh.aparc.area.good2go'] = "truncate table cg_rh_aparc_area_good2go_old" 
            v_old_truncate_dict['lh.aparc.volume.good2go'] = "truncate table cg_lh_aparc_volume_good2go_old"
            v_old_truncate_dict['rh.aparc.volume.good2go'] = "truncate table cg_rh_aparc_volume_good2go_old" 
            v_old_truncate_dict['lh.aparc.thickness.good2go'] = "truncate table cg_lh_aparc_thickness_good2go_old"
            v_old_truncate_dict['rh.aparc.thickness.good2go'] = "truncate table cg_rh_aparc_thickness_good2go_old" 
            v_truncate_dict = {}
            v_truncate_dict['aseg'] = "truncate table cg_aseg"
            v_truncate_dict['lh.aparc.area'] = "truncate table cg_lh_aparc_area"
            v_truncate_dict['rh.aparc.area'] = "truncate table cg_rh_aparc_area"
            v_truncate_dict['lh.aparc.volume'] = "truncate table cg_lh_aparc_volume"
            v_truncate_dict['rh.aparc.volume'] = "truncate table cg_rh_aparc_volume"
            v_truncate_dict['lh.aparc.thickness'] = "truncate table cg_lh_aparc_thickness"
            v_truncate_dict['rh.aparc.thickness'] = "truncate table cg_rh_aparc_thickness"
            v_truncate_dict['aseg.good2go'] = "truncate table cg_aseg_good2go"
            v_truncate_dict['lh.aparc.area.good2go'] = "truncate table cg_lh_aparc_area_good2go"
            v_truncate_dict['rh.aparc.area.good2go'] = "truncate table cg_rh_aparc_area_good2go"
            v_truncate_dict['lh.aparc.volume.good2go'] = "truncate table cg_lh_aparc_volume_good2go"
            v_truncate_dict['rh.aparc.volume.good2go'] = "truncate table cg_rh_aparc_volume_good2go"
            v_truncate_dict['lh.aparc.thickness.good2go'] = "truncate table cg_lh_aparc_thickness_good2go"
            v_truncate_dict['rh.aparc.thickness.good2go'] = "truncate table cg_rh_aparc_thickness_good2go"
            v_new_truncate_dict = {}
            v_new_truncate_dict['aseg'] = "truncate table cg_aseg_new"
            v_new_truncate_dict['lh.aparc.area'] = "truncate table cg_lh_aparc_area_new"
            v_new_truncate_dict['rh.aparc.area'] = "truncate table cg_rh_aparc_area_new"
            v_new_truncate_dict['lh.aparc.volume'] = "truncate table cg_lh_aparc_volume_new"
            v_new_truncate_dict['rh.aparc.volume'] = "truncate table cg_rh_aparc_volume_new"
            v_new_truncate_dict['lh.aparc.thickness'] = "truncate table cg_lh_aparc_thickness_new"
            v_new_truncate_dict['rh.aparc.thickness'] = "truncate table cg_rh_aparc_thickness_new"
            v_new_truncate_dict['aseg.good2go'] = "truncate table cg_aseg_good2go_new"
            v_new_truncate_dict['lh.aparc.area.good2go'] = "truncate table cg_lh_aparc_area_good2go_new"
            v_new_truncate_dict['rh.aparc.area.good2go'] = "truncate table cg_rh_aparc_area_good2go_new"
            v_new_truncate_dict['lh.aparc.volume.good2go'] = "truncate table cg_lh_aparc_volume_good2go_new"
            v_new_truncate_dict['rh.aparc.volume.good2go'] = "truncate table cg_rh_aparc_volume_good2go_new"
            v_new_truncate_dict['lh.aparc.thickness.good2go'] = "truncate table cg_lh_aparc_thickness_good2go_new"
            v_new_truncate_dict['rh.aparc.thickness.good2go'] = "truncate table cg_rh_aparc_thickness_good2go_new"
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
            v_sql_base_dict['lh.aparc.thickness']="subjectid,lh_bankssts_thickness,lh_caudalanteriorcingulate_thickness,lh_caudalmiddlefrontal_thickness,lh_cuneus_thickness,lh_entorhinal_thickness,lh_fusiform_thickness,lh_inferiorparietal_thickness,lh_inferiortemporal_thickness,lh_isthmuscingulate_thickness,lh_lateraloccipital_thickness,lh_lateralorbitofrontal_thickness,lh_lingual_thickness,lh_medialorbitofrontal_thickness,lh_middletemporal_thickness,lh_parahippocampal_thickness,lh_paracentral_thickness,lh_parsopercularis_thickness,lh_parsorbitalis_thickness,lh_parstriangularis_thickness,lh_pericalcarine_thickness,lh_postcentral_thickness,lh_posteriorcingulate_thickness,lh_precentral_thickness,lh_precuneus_thickness,lh_rostralanteriorcingulate_thickness,lh_rostralmiddlefrontal_thickness,lh_superiorfrontal_thickness,lh_superiorparietal_thickness,lh_superiortemporal_thickness,lh_supramarginal_thickness,lh_frontalpole_thickness,lh_temporalpole_thickness,lh_transversetemporal_thickness,lh_insula_thickness"
            v_sql_base_dict['rh.aparc.thickness']="subjectid,rh_bankssts_thickness,rh_caudalanteriorcingulate_thickness,rh_caudalmiddlefrontal_thickness,rh_cuneus_thickness,rh_entorhinal_thickness,rh_fusiform_thickness,rh_inferiorparietal_thickness,rh_inferiortemporal_thickness,rh_isthmuscingulate_thickness,rh_lateraloccipital_thickness,rh_lateralorbitofrontal_thickness,rh_lingual_thickness,rh_medialorbitofrontal_thickness,rh_middletemporal_thickness,rh_parahippocampal_thickness,rh_paracentral_thickness,rh_parsopercularis_thickness,rh_parsorbitalis_thickness,rh_parstriangularis_thickness,rh_pericalcarine_thickness,rh_postcentral_thickness,rh_posteriorcingulate_thickness,rh_precentral_thickness,rh_precuneus_thickness,rh_rostralanteriorcingulate_thickness,rh_rostralmiddlefrontal_thickness,rh_superiorfrontal_thickness,rh_superiorparietal_thickness,rh_superiortemporal_thickness,rh_supramarginal_thickness,rh_frontalpole_thickness,rh_temporalpole_thickness,rh_transversetemporal_thickness,rh_insula_thickness"
            v_sql_base_dict['lh.aparc.volume']="subjectid,lh_bankssts_volume,lh_caudalanteriorcingulate_volume,lh_caudalmiddlefrontal_volume,lh_cuneus_volume,lh_entorhinal_volume,lh_fusiform_volume,lh_inferiorparietal_volume,lh_inferiortemporal_volume,lh_isthmuscingulate_volume,lh_lateraloccipital_volume,lh_lateralorbitofrontal_volume,lh_lingual_volume,lh_medialorbitofrontal_volume,lh_middletemporal_volume,lh_parahippocampal_volume,lh_paracentral_volume,lh_parsopercularis_volume,lh_parsorbitalis_volume,lh_parstriangularis_volume,lh_pericalcarine_volume,lh_postcentral_volume,lh_posteriorcingulate_volume,lh_precentral_volume,lh_precuneus_volume,lh_rostralanteriorcingulate_volume,lh_rostralmiddlefrontal_volume,lh_superiorfrontal_volume,lh_superiorparietal_volume,lh_superiortemporal_volume,lh_supramarginal_volume,lh_frontalpole_volume,lh_temporalpole_volume,lh_transversetemporal_volume,lh_insula_volume"
            v_sql_base_dict['rh.aparc.volume']="subjectid,rh_bankssts_volume,rh_caudalanteriorcingulate_volume,rh_caudalmiddlefrontal_volume,rh_cuneus_volume,rh_entorhinal_volume,rh_fusiform_volume,rh_inferiorparietal_volume,rh_inferiortemporal_volume,rh_isthmuscingulate_volume,rh_lateraloccipital_volume,rh_lateralorbitofrontal_volume,rh_lingual_volume,rh_medialorbitofrontal_volume,rh_middletemporal_volume,rh_parahippocampal_volume,rh_paracentral_volume,rh_parsopercularis_volume,rh_parsorbitalis_volume,rh_parstriangularis_volume,rh_pericalcarine_volume,rh_postcentral_volume,rh_posteriorcingulate_volume,rh_precentral_volume,rh_precuneus_volume,rh_rostralanteriorcingulate_volume,rh_rostralmiddlefrontal_volume,rh_superiorfrontal_volume,rh_superiorparietal_volume,rh_superiortemporal_volume,rh_supramarginal_volume,rh_frontalpole_volume,rh_temporalpole_volume,rh_transversetemporal_volume,rh_insula_volume"
            v_sql_base_dict['aseg.good2go'] = v_sql_base_dict['aseg']
            v_sql_base_dict['lh.aparc.area.good2go'] = v_sql_base_dict['lh.aparc.area']
            v_sql_base_dict['rh.aparc.area.good2go'] = v_sql_base_dict['rh.aparc.area']
            v_sql_base_dict['lh.aparc.volume.good2go'] = v_sql_base_dict['lh.aparc.volume']
            v_sql_base_dict['rh.aparc.volume.good2go'] = v_sql_base_dict['rh.aparc.volume']
            v_sql_base_dict['lh.aparc.thickness.good2go'] = v_sql_base_dict['lh.aparc.thickness']
            v_sql_base_dict['rh.aparc.thickness.good2go'] = v_sql_base_dict['rh.aparc.thickness']
            
            
            # v_table_array =["cg_aseg","cg_lh_aparc_area", "cg_rh_aparc_area"]
            #v_result_array[1]+".aseg.all.txt",  v_result_array[1]+".lh.aparc.area.all.txt",   v_result_array[1]+".rh.aparc.area.all.txt"
            v_file_dir = v_base_path+"/preprocessed/modalities/freesurfer/orig_recon/"
            # loop thru file array
            v_file_array.each do |f|
              v_file_dir = v_file_dir_dict[f]
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
              v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_dict[f])
              if v_return_flag == "N" 
                v_comment = v_return_comment+" \n"+v_comment
                puts v_return_comment               
              else
                puts v_return_comment
                v_comment = v_return_comment+v_comment
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
                # secondary key
                # select all where enrollment_id is null
                # match enumber plus .R, b, c, d , 
                # set secondary key
                sql = "select subjectid from cg_"+f.gsub(/\./,'_')+"_new where enrollment_id is null order by subjectid"
                results = connection.execute(sql)
                results.each do |re|
                    enrollment = Enrollment.where("concat(enumber,'.R') in (?) or concat(enumber,'a') in (?) or concat(enumber,'b') in (?) or concat(enumber,'c') in (?) or concat(enumber,'d') in (?) or concat(enumber,'e') in (?)",re[0],re[0],re[0],re[0],re[0],re[0])
                    if !enrollment.blank?
                             v_secondary_key = re[0]
                             v_secondary_key = v_secondary_key.tr(enrollment[0].enumber, "") 
                             sql = "update cg_"+f.gsub(/\./,'_')+"_new  t set t.enrollment_id = "+enrollment[0].id.to_s+", secondary_key='"+v_secondary_key+"', subjectid='"+enrollment[0].enumber+"' where subjectid='"+re[0]+"'"
                             results = connection.execute(sql)
                    end
                end

                

                sql = "select subjectid from cg_"+f.gsub(/\./,'_')+"_new"
                results = connection.execute(sql)
                results.each do |r|
                  v_sp_id = v_shared.get_sp_id_from_subjectid_v(r[0])
                  if !v_sp_id.blank?
                    sql = "update cg_"+f.gsub(/\./,'_')+"_new  t set t.scan_procedure_id = "+v_sp_id.to_s+" where subjectid ='"+r[0]+"'"
                    results = connection.execute(sql)
                  end
                end



                # report on unmapped rows, not insert unmapped rows 

                sql = "select subjectid, enrollment_id from cg_"+f.gsub(/\./,'_')+"_new where scan_procedure_id is null order by subjectid"
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

                sql = "insert into cg_"+f.gsub(/\./,'_')+"("+v_sql_base_dict[f]+",enrollment_id,scan_procedure_id,secondary_key) 
                select distinct "+v_sql_base_dict[f]+",t.enrollment_id, scan_procedure_id,secondary_key from cg_"+f.gsub(/\./,'_')+"_new t
                                               where t.scan_procedure_id is not null  and t.enrollment_id is not null "
                results = connection.execute(sql)

                # apply edits  -- made into a function  in shared model
              
                v_shared.apply_cg_edits(f)
                 
                 v_comment = "finish loading cg_"+f.gsub(/\./,'_')+"   \n"+ v_comment               
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
  
end
