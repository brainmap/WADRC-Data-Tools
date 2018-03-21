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

class Shared_retired  < ActionController::Base

  
  
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
       v_computer = "kanga"
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
         v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/adrc_dti/"
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
         v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "  tar  -C /home/panda_user/adrc_dti  -zcf /home/panda_user/adrc_dti/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
         v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf /home/panda_user/adrc_dti/'+v_subject_dir+' "'
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close


          # did the tar.gz on "+v_computer+" to avoid mac acl PaxHeader extra directories
          v_call = "rsync -av panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/adrc_dti/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
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
          v_computer = "kanga"
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
          #  v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/adrc_pcvipr/"
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
         #   v_call =  'ssh panda_user@"+v_computer+".dom.wisc.edu "  tar  -C /home/panda_user/adrc_pcvipr  -zcf /home/panda_user/adrc_pcvipr/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
            #v_call = 'ssh panda_user@"+v_computer+".dom.wisc.edu " rm -rf /home/panda_user/adrc_pcvipr/'+v_subject_dir+' "'
          #  stdin, stdout, stderr = Open3.popen3(v_call)
          #  while !stdout.eof?
          #    puts stdout.read 1024    
          #   end
          #  stdin.close
          #  stdout.close
          #  stderr.close


             # did the tar.gz on "+v_computer+" to avoid mac acl PaxHeader extra directories
          #   v_call = "rsync -av panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/adrc_pcvipr/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
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
      v_computer = "kanga"
 
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
      v_computer = "kanga"
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


        v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_padi/"    #+v_subject_dir
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
        ## v_call =  'ssh panda_user@"+v_computer+".dom.wisc.edu "  tar  -C /home/panda_user/upload_padi  -zcf /home/panda_user/upload_padi/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '

v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu " cd /home/panda_user/upload_padi/; zip -r '+v_subject_dir+'.zip '+v_subject_dir+'  "  '      
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
        v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf /home/panda_user/upload_padi/'+v_subject_dir+' "'
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
         v_call = "rsync -av panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_padi/"+v_subject_dir+".zip "+v_target_dir+'/'+v_subject_dir+".zip"
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
        v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_padi/"    #+v_subject_dir
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
        #v_call =  'ssh panda_user@"+v_computer+".dom.wisc.edu "  tar  -C /home/panda_user/upload_padi  -zcf /home/panda_user/upload_padi/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
        v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu " cd /home/panda_user/upload_padi/; zip -r '+v_subject_dir+'.zip '+v_subject_dir+' "  '
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
        v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf /home/panda_user/upload_padi/'+v_subject_dir+' "'
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
         v_call = "rsync -av panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_padi/"+v_subject_dir+".zip "+v_target_dir+'/'+v_subject_dir+".zip"
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
      v_computer = "kanga"
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

            v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_padi/"    #+v_subject_dir
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
        ## v_call =  'ssh panda_user@"+v_computer+".dom.wisc.edu "  tar  -C /home/panda_user/upload_padi  -zcf /home/panda_user/upload_padi/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '

v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu " cd /home/panda_user/upload_padi/; zip -r '+v_subject_dir+'.zip '+v_subject_dir+'  "  '      
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
        v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf /home/panda_user/upload_padi/'+v_subject_dir+' "'
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
         v_call = "rsync -av panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_padi/"+v_subject_dir+".zip "+v_target_dir+'/'+v_subject_dir+".zip"
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
        v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_padi/"    #+v_subject_dir
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
        #v_call =  'ssh panda_user@"+v_computer+".dom.wisc.edu "  tar  -C /home/panda_user/upload_padi  -zcf /home/panda_user/upload_padi/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
        v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu " cd /home/panda_user/upload_padi/; zip -r '+v_subject_dir+'.zip '+v_subject_dir+' "  '
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
        v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf /home/panda_user/upload_padi/'+v_subject_dir+' "'
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
         v_call = "rsync -av panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_padi/"+v_subject_dir+".zip "+v_target_dir+'/'+v_subject_dir+".zip"
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
    v_computer = "kanga"

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
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
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

        v_call = "rsync -av /tmp/"+v_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:"+v_parent_dir_target 
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
      v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
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
      
      # problem that files are on "+v_computer+", but panda running from nelson
      # need to ssh to "+v_computer+" as pand_admin, then sftp
 #     v_source = "panda_user@"+v_computer+".dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"
      
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
    v_computer = "kanga"
    
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
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
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
             
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            v_scan_procedure_path = ScanProcedure.find(r[2]).codename
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/unknown/"+ v_subjectid+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
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
                v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
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
              v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av "+ v_asl_nii+" "+v_parent_dir_target+"/"+v_dir_target+"' "
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
              v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av "+ v_pdmap_nii+" "+v_parent_dir_target+"/"+v_dir_target+"' "
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
              v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av "+ v_asl_nii+" "+v_parent_dir_target+"/"+v_dir_target+"' "
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
              v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av "+ v_pdmap_nii+" "+v_parent_dir_target+"/"+v_dir_target+"' "
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
      v_call =  'ssh panda_user@"+v_computer+".dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@"+v_computer+".dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
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
      
      # problem that files are on "+v_computer+", but panda running from nelson
      # need to ssh to "+v_computer+" as pand_admin, then sftp
 #     v_source = "panda_user@"+v_computer+".dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"
      
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
      v_computer = "kanga"
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

            v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_washu/"    #+v_subject_dir
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
        v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "  tar  -C /home/panda_user/upload_washu  -zcf /home/panda_user/upload_washu/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
        v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf /home/panda_user/upload_washu/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on "+v_computer+" to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_washu
         v_call = "rsync -av panda_user@'+v_computer+'.dom.wisc.edu:/home/panda_user/upload_washu/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
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
        v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_washu/"    #+v_subject_dir
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
        v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "  tar  -C /home/panda_user/upload_washu  -zcf /home/panda_user/upload_washu/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
        v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf /home/panda_user/upload_washu/'+v_subject_dir+' "'
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
       
        
         # did the tar.gz on "+v_computer+" to avoid mac acl PaxHeader extra directories
         # not need this? 
         # could change sftp to come from ~/upload_washu
         v_call = "rsync -av panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_washu/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
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
    v_computer = "kanga"
    
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
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
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
             
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            v_scan_procedure_path = ScanProcedure.find(r[2]).codename
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/unknown/"+ v_subjectid+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
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
      v_call =  'ssh panda_user@"+v_computer+".dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
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
      
      # problem that files are on "+v_computer+", but panda running from nelson
      # need to ssh to "+v_computer+" as pand_admin, then sftp
 #     v_source = "panda_user@"+v_computer+".dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"
      
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
      v_computer = "kanga"
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
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
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
             
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
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
               v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"

               stdin, stdout, stderr = Open3.popen3(v_call)
               while !stdout.eof?
                  puts stdout.read 1024    
               end
               stdin.close
               stdout.close
               stderr.close

               # check if copied nii file is a directory -- found 2 exapmles
              v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'ls -dl "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
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

        v_call = "rsync -av /tmp/"+v_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:"+v_parent_dir_target 
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
      v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
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

            # problem that files are on "+v_computer+", but panda running from nelson
            # need to ssh to "+v_computer+" as pand_admin, then sftp
        #    v_source = "panda_admin@"+v_computer+".dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"

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
      v_computer = "kanga"
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
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
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
             
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
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
               v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid_actual+"/unknown/"+ v_subjectid_actual+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"

               stdin, stdout, stderr = Open3.popen3(v_call)
               while !stdout.eof?
                  puts stdout.read 1024    
               end
               stdin.close
               stdout.close
               stderr.close

               # check if copied nii file is a directory -- found 2 exapmles
              v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'ls -dl "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
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

        v_call = "rsync -av /tmp/"+v_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:"+v_parent_dir_target 
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
          v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
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
             v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+dir_name+"/"+ v_subjectid+v_file_name_hash[dir_name]+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+v_file_name_hash[dir_name]+"  '"
              stdin, stdout, stderr = Open3.popen3(v_call)
              while !stdout.eof?
                 puts stdout.read 1024    
              end
              stdin.close
              stdout.close
              stderr.close
              # some nii.gz
              v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+dir_name+"/"+ v_subjectid+v_file_name_hash[dir_name]+".gz  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+v_file_name_hash[dir_name]+".gz  '"
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
      v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
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

            # problem that files are on "+v_computer+", but panda running from nelson
            # need to ssh to "+v_computer+" as pand_admin, then sftp
        #    v_source = "panda_admin@"+v_computer+".dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"

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
       v_computer = "kanga"
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
       v_computer = "kanga"
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
         v_call = "rsync -av "+v_parent_dir_target+" panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_hyunwoo_20140520/"
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
         v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "  tar  -C /home/panda_user/upload_hyunwoo_20140520  -zcf /home/panda_user/upload_hyunwoo_20140520/'+v_subject_dir+'.tar.gz '+v_subject_dir+'/ "  '
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
         v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf /home/panda_user/upload_hyunwoo_20140520/'+v_subject_dir+' "'
         stdin, stdout, stderr = Open3.popen3(v_call)
         while !stdout.eof?
           puts stdout.read 1024    
          end
         stdin.close
         stdout.close
         stderr.close


          # did the tar.gz on "+v_computer+" to avoid mac acl PaxHeader extra directories
          v_call = "rsync -av panda_user@"+v_computer+".dom.wisc.edu:/home/panda_user/upload_hyunwoo_20140520/"+v_subject_dir+".tar.gz "+v_target_dir+'/'+v_subject_dir+".tar.gz"
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
      v_computer = "kanga"
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
      v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"' "
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
             
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_preprocessed_path = v_base_path+"/preprocessed/visits/"
            v_scan_procedure_path = ScanProcedure.find(r[2]).codename
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/unknown/"+ v_subjectid+"_*_"+v_dir+".nii  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_"+r_dataset[3].gsub(" ","_")+"_"+v_dir+".nii '"
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
          v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
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
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/pib/"+ v_pib_summed_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_pib_summed.nii '"
            stdin, stdout, stderr = Open3.popen3(v_call)
            while !stdout.eof?
               puts stdout.read 1024    
            end
            stdin.close
            stdout.close
            stderr.close
            v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/pib/"+ v_readme_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_pib_readme.txt '"
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
                v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/pib/"+ v_rFS_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/rFS_r"+v_export_id+"_realignPIB_DVR_HYPR.nii '"
             
              else
                v_realign_file ="r"+v_subjectid+"_realignPIB_DVR_HYPR.nii"
                 v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/pib/"+ v_realign_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/r"+v_export_id+"_realignPIB_DVR_HYPR.nii '"
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
        v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'mkdir "+v_parent_dir_target +"/"+v_dir_target+"' "
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
          v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/fdg/"+ v_fdg_summed_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_fdg_summed.nii '"
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
             puts stdout.read 1024    
          end
          stdin.close
          stdout.close
          stderr.close
          v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/fdg/"+ v_readme_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_fdg_readme.txt '"
          stdin, stdout, stderr = Open3.popen3(v_call)
          while !stdout.eof?
             puts stdout.read 1024    
          end
          stdin.close
          stdout.close
          stderr.close
        else
          v_call = "ssh panda_user@"+v_computer+".dom.wisc.edu 'rsync -av  "+v_preprocessed_path+v_scan_procedure_path+"/"+ v_subjectid+"/pet/fdg/"+ v_fdg_summed_file+"  "+v_parent_dir_target +"/"+v_dir_target+"/"+v_export_id+"_fdg_summed.nii '"
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
      v_call =  'ssh panda_user@'+v_computer+'.dom.wisc.edu "  tar  -C '+v_target_dir+'  -zcf '+v_parent_dir_target+'.tar.gz '+v_subject_dir+'/ "  '
      stdin, stdout, stderr = Open3.popen3(v_call)
      while !stdout.eof?
        puts stdout.read 1024    
       end
      stdin.close
      stdout.close
      stderr.close
      # remove subjectid dir
      v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu " rm -rf '+v_parent_dir_target+' "'
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

            # problem that files are on "+v_computer+", but panda running from nelson
            # need to ssh to "+v_computer+" as pand_admin, then sftp
     #       v_source = "panda_user@"+v_computer+".dom.wisc.edu:"+v_target_dir+'/'+v_subject_dir+".tar.gz"

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
    
  
end
