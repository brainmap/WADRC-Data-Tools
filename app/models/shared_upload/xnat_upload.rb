class SharedUpload::XnatUpload < SharedUpload::SharedUploadBase

  def self.default_params
	  params = { schedule_name: 'xnat_upload',
				base_path: Shared.get_base_path(), 
    			computer: "merida",
    			comment: [],
    			comment_warning: "",
    			log_base: "/mounts/data/preprocessed/logs/",
    			process_name: "xnat_file",
    			stop_file_name: "xnat_file_stop",
      			stop_file_path: "/mounts/data/preprocessed/logs/xnat_file_stop",

      			scan_procedure_array: [26,41,77,91], #pdt's and mk
      			series_description_category_array: ['T1_Volumetric','T2'], # mpnrage?
	      		series_description_category_id_array: [19, 20, 5], #,1 ]
      			project: "wbbsp",  #"wadrc_sp" #"up-test"

      			xnat_participant_tn: "xnat_participants",
      			xnat_appointment_mri_tn: "xnat_mri_appointment",
      			xnat_ids_tn: "xnat_image_datasets",
      			working_directory: "/tmp",
      			rm_endings: ["json","pickle","yaml","txt","xml","doc","xls","xlsx"],
            default_xnat_run_upload_flag: 'R',
            days_back: '15'}

      params[:xnat_script_dir] = params[:base_path]+"/analyses/rpcary/xnat/scripts/"
      params[:script_dicom_clean] =  params[:xnat_script_dir]+"xnat_dicom_upload_cleaner.rb"
      params[:xnat_address] = 'xnat.medicine.wisc.edu'
      params
    end

    def run(p=@params)
    	#typically only look pay attention to the participants with a handful of scan procedures and series descriptions

    	#add to this job only the participant ids that:
    	# => aren't alreay in the table
    	# => pilot_flag == 'N'
    	# => have a scan procedure from our array of interested procedures
    	# => have series_description_type_id in our array of special series_description_type_ids
    	#then get the list of those new ids, and 

		  sql = "insert into #{ p[:xnat_participant_tn] } (participant_id,xnat_exists_flag,xnat_run_upload_flag) 
               select distinct vgroups.participant_id,'N','#{ p[:default_xnat_run_upload_flag] }' from vgroups 
               where vgroups.participant_id not in ( select #{ p[:xnat_participant_tn] }.participant_id from #{ p[:xnat_participant_tn] } )
               and vgroups.pilot_flag = 'N'
               and vgroups.id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups 
                                    where scan_procedures_vgroups.scan_procedure_id in (#{ p[:scan_procedure_array].join(',') }))
        		and vgroups.id in (select appointments.vgroup_id from appointments, visits, image_datasets, series_description_maps
                  where appointments.id = visits.appointment_id 
                    and visits.id = image_datasets.visit_id
                    and image_datasets.series_description = series_description_maps.series_description 
                    and series_description_maps.series_description_type_id in (#{ p[:series_description_category_id_array].join(',') }) )" 
		  results = @connection.execute(sql)

		  #then get the list of those new ids, and 
      sql = "select export_id from #{ p[:xnat_participant_tn] } where export_id is NOT NULL"
      v_exportid_results = @connection.execute(sql)
      v_exportid_array = []
      v_exportid_results.each { |r| v_exportid_array << r }

      #for the records without export ids, loop over them and assign a unique, random value to each row as export_id
      v_null_check_sql = "select participant_id from #{ p[:xnat_participant_tn] } where export_id is NULL and participant_id is not NULL"
      v_null_check_cnt = 0
      v_null_cnt_threshold = 10  # repeat 10 times increasing upper range
      while v_null_check_cnt < v_null_cnt_threshold
         v_null_check_cnt = v_null_check_cnt + 1
         v_null_results = @connection.execute(v_null_check_sql)
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
               v_sql = "update #{ p[:xnat_participant_tn] } t1 
                        set t1.export_id = #{ p[:project] }_"+val.to_s+" where t1.participant_id ="+v_null_array[v_array_cnt].to_s
               v_exportid_array.push(val)
               v_update_results = @connection.execute(v_sql)
               v_array_cnt = v_array_cnt + 1
             end
           end
         end
      end

      #add to xnat_mri_appointment only those appointment_ids that:
      # => have a vgroup we can share
      # => have a vgroup.pilot_flag = 'N'
      # => have a vgroup with a scan procedure in our special list of interested scan procedures
      # => have series_description_type_id in our array of special series_description_type_ids
      # => aren't already in the table
      # => and had this appointment up to v_days_back days ago

      sql = "insert into #{ p[:xnat_appointment_mri_tn] } (appointment_id, visit_id,xnat_exists_flag,secondary_key)
        select distinct appointments.id , visits.id, 'N', appointments.secondary_key from appointments, visits
        where appointments.id = visits.appointment_id
        and appointments.vgroup_id in ( select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships, enrollments
                                        where enrollment_vgroup_memberships.enrollment_id = enrollments.id 
                                         and enrollments.do_not_share_scans_flag = 'N'  )
        and appointments.vgroup_id in ( select vgroups.id from vgroups where vgroups.pilot_flag = 'N')
        and appointments.vgroup_id in ( select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups
        where scan_procedures_vgroups.scan_procedure_id in (#{ p[:scan_procedure_array].join(',') })) 
               and visits.id in (select image_datasets.visit_id from image_datasets, series_description_maps
                  where image_datasets.series_description = series_description_maps.series_description
                    and series_description_maps.series_description_type_id in (#{ p[:series_description_category_id_array].join(',') }) )
        and (visits.appointment_id,visits.id) NOT IN (select  #{ p[:xnat_appointment_mri_tn] }.appointment_id, #{ p[:xnat_appointment_mri_tn] }.visit_id 
                                                         from  #{ p[:xnat_appointment_mri_tn] } )
        and appointments.appointment_date < ( NOW() - INTERVAL #{ p[:days_back] } DAY)"

      results = @connection.execute(sql)
      # doing full participant update - in case p.id changed - a mess either way - fixed or unfixed
      sql = "update #{ p[:xnat_appointment_mri_tn] } set participant_id = ( select vgroups.participant_id from vgroups, appointments  
                               where vgroups.id = appointments.vgroup_id and appointments.id = #{ p[:xnat_appointment_mri_tn] }.appointment_id)"
      results = @connection.execute(sql)


      # get path from appointment_id , get codename/sp , get start , update xnat_session_id  <sp enum start>_export_id_<v#>

      sql = "select #{ p[:xnat_appointment_mri_tn] }.appointment_id, #{ p[:xnat_participant_tn] }.export_id, visits.path, #{ p[:xnat_appointment_mri_tn] }.secondary_key
       from #{ p[:xnat_appointment_mri_tn] } ,#{ p[:xnat_participant_tn] }, visits 
      where (#{ p[:xnat_appointment_mri_tn] }.xnat_session_id is null or #{ p[:xnat_appointment_mri_tn] }.xnat_session_id = '') 
      and #{ p[:xnat_participant_tn] }.participant_id = #{ p[:xnat_appointment_mri_tn] }.participant_id
      and visits.appointment_id = #{ p[:xnat_appointment_mri_tn] }.appointment_id
      and visits.path is not null and visits.path > ''"

      results = @connection.execute(sql)


      #for each result (appointment_id, export_id, path to an image file, and secondary_key), make an xnat_session_id
      # (secondary key is usually NULL or blank, very rarely has a ".")
      results.each do |v_val|
        v_appt_id = v_val[0]
        v_export_id = v_val[1]
        v_path = v_val[2]
        v_path_array = v_path.split("/")
        if v_path_array.count > 4
           v_codename = v_path_array[4]
        end
        v_secondary_key = v_val[3]
        # (secondary key is usually NULL or blank, very rarely has a ".")
        if !v_secondary_key.blank?
             v_secondary_key = v_secondary_key.gsub(".","")
        end
        v_xnat_session_id = ""
        sp_array = ScanProcedure.where("codename in (?)",v_codename)
        if sp_array.count> 0
             v_prepend = "_"+sp_array.first.subjectid_base
             v_number = sp_array.first.visit_abbr("_v1")
             # issue with secondary scans into one session
             if !v_secondary_key.blank?
                 v_xnat_session_id = v_export_id.to_s+v_prepend+v_number+"_sk"+v_secondary_key
             else
                 v_xnat_session_id = v_export_id.to_s+v_prepend+v_number

             end
             sql_update = "update #{ p[:xnat_appointment_mri_tn] } set xnat_session_id = '#{ v_xnat_session_id }'
             where #{ p[:xnat_appointment_mri_tn] }.appointment_id = #{ v_appt_id.to_s }
             and (#{ p[:xnat_appointment_mri_tn] }.xnat_session_id is null or #{ p[:xnat_appointment_mri_tn] }.xnat_session_id = '') "
             results = @connection.execute(sql_update)
        end
      end

      # set the xnat_do_not_share based on pilot and enumber/study consent forms
      #set xnat_exists_flag = 'Y' after upload to xnat
      sql = "insert into #{ p[:xnat_ids_tn] } (visit_id,image_dataset_id,xnat_exists_flag,file_path)
        select distinct image_datasets.visit_id, image_datasets.id, 'N',image_datasets.path from image_datasets, visits, appointments, series_description_maps,scan_procedures_vgroups
        where image_datasets.visit_id = visits.id 
        and appointments.id = visits.appointment_id
        and (image_datasets.do_not_share_scans_flag is null or image_datasets.do_not_share_scans_flag != 'Y')
        and image_datasets.series_description = series_description_maps.series_description
        and series_description_maps.series_description_type_id in (#{ p[:series_description_category_id_array].join(',') }) 
        and appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
        and  scan_procedures_vgroups.scan_procedure_id in (#{ p[:scan_procedure_array].join(',') }) 
        and (image_datasets.visit_id, image_datasets.id ) NOT IN (select #{ p[:xnat_ids_tn] }.visit_id, #{ p[:xnat_ids_tn] }.image_dataset_id 
                                                         from #{ p[:xnat_ids_tn] } )"

      results = @connection.execute(sql)

      # set the xnat_do_not_share based on pilot and enumber/study consent forms
      sql ="update #{ p[:xnat_appointment_mri_tn] } xma set xnat_do_not_share_flag = 'Y'
        where xma.visit_id in (select v.id from visits v, enrollments e, enrollment_visit_memberships evm
        where xma.visit_id = v.id  and v.id = evm.visit_id and evm.enrollment_id = e.id  and e.do_not_share_scans_flag = 'Y')"
      results = @connection.execute(sql)
      sql ="update #{ p[:xnat_ids_tn] } xid set  xnat_do_not_share_flag = 'Y'
        where xid.visit_id in (select v.id from visits v, enrollments e, enrollment_visit_memberships evm
        where xid.visit_id = v.id   and v.id = evm.visit_id and evm.enrollment_id = e.id  and e.do_not_share_scans_flag = 'Y')"
      results = @connection.execute(sql)
      sql ="update #{ p[:xnat_appointment_mri_tn] } set xnat_do_not_share_flag = 'Y' where visit_id in 
        (select v.id from visits v, appointments a, vgroups vg where v.appointment_id = a.id and a.vgroup_id = vg.id  and vg.pilot_flag = 'Y')"
      results = @connection.execute(sql)
      sql ="update  #{ p[:xnat_ids_tn] } set xnat_do_not_share_flag = 'Y' where visit_id in 
        (select v.id from visits v, appointments a, vgroups vg where v.appointment_id = a.id and a.vgroup_id = vg.id  and vg.pilot_flag = 'Y')"
      results = @connection.execute(sql)
      
      # add file_path --
      # make session id from file_path sp --> enum start| export_id|-v#
      # add sessionid column in database
      # set xnat_do_not_share_flag
      #set xnat_exists_flag = 'Y' after upload to xnat

      # R means run, D means done
      # make participants in xnat
      sql = "select export_id, participant_id from #{ p[:xnat_participant_tn] } where xnat_do_not_share_flag = 'N' and xnat_run_upload_flag = 'R' and xnat_exists_flag = 'N' "
      results = @connection.execute(sql)
      results.each do |participant|
        # make user on xnat
        v_sql_update = "update #{ p[:xnat_participant_tn] } set xnat_run_upload_flag ='D', xnat_exists_flag = 'Y' where export_id = '#{ participant[0].to_s }' "
        ####results_update = connection.execute(v_sql_update)
      end

      #then select our set of files, visits, xnat_session_ids etc. for the uploads
      sql = "select #{ p[:xnat_ids_tn] }.file_path, #{ p[:xnat_ids_tn] }.visit_id, #{ p[:xnat_appointment_mri_tn] }.xnat_session_id, #{ p[:xnat_appointment_mri_tn] }.xnat_exists_flag,
        #{ p[:xnat_participant_tn] }.export_id, #{ p[:xnat_participant_tn] }.xnat_exists_flag 
                  from #{ p[:xnat_participant_tn] },#{ p[:xnat_ids_tn] },#{ p[:xnat_appointment_mri_tn] } where #{ p[:xnat_ids_tn] }.xnat_do_not_share_flag = 'N' 
                                  and #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'N' 
                                  and #{ p[:xnat_participant_tn] }.participant_id = #{ p[:xnat_appointment_mri_tn] }.participant_id
                                  and #{ p[:xnat_appointment_mri_tn] }.visit_id = #{ p[:xnat_ids_tn] }.visit_id
                                  and #{ p[:xnat_participant_tn] }.xnat_run_upload_flag = 'R'
                      order by #{ p[:xnat_appointment_mri_tn] }.xnat_session_id "

      puts "selecting for our export: " + sql

      results = @connection.execute(sql)

      v_xnat_session ="zzzzz"
      v_target_dir = ""
      v_cnt_ids = 0
      v_path_array = []  # the path pusghed into array is getting split on /
      v_path_full_list_array = []
      v_visit_id = ""
      results.each do |scan|

        #puts "BBBBBB=0"+scan[0]+"   1="+scan[1].to_s+"  2="+scan[2].to_s
        #if v_xnat_session != scan[2]
          # new xnat session
          #puts " new session="+v_xnat_session
          #if v_cnt_ids  > 0    #and v_xnat_session != "zzzzz"
            #puts " cnt>0"

        v_cnt_ids = v_cnt_ids + 1
        v_visit_id = scan[1]
        v_xnat_session = scan[2]
        v_file_path = scan[0]
        v_path_full_list_array.push(v_file_path)

        #make a working dir for this session
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'cd #{ p[:working_directory] }; mkdir #{ v_xnat_session }'"
        puts cmd
        response = r_call cmd

        #first, we need to make a dummy .zip file for this export_id, to establish a person in xnat for these scans to attach to
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] };zip -r  #{ v_xnat_session }.zip  #{ v_xnat_session }\""
        puts cmd
        response = r_call cmd

        #run the upload
        v_log_file_path = "#{ p[:working_directory] }/#{ v_xnat_session }.log"
        puts "log file is #{ v_log_file_path }"
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }; curl --netrc -o #{ v_log_file_path } -w \\\"%{http_code}\\\" --form project=#{ p[:project] } --form image_archive=@#{ v_xnat_session }.zip https://#{ p[:xnat_address] }/data/services/import?format=html\""
        puts cmd
        response = r_call cmd
        
        #retrieve the log
        v_status =""
        v_status_comment = ""
        cmd = "rsync -av panda_user@#{ p[:computer] }.dom.wisc.edu:#{ v_log_file_path } #{ v_log_file_path }"
        puts cmd
        response = r_call cmd

        File.foreach(v_log_file_path).detect { |line| 
          if line.include?("Session processing may already be in progress")
            v_status ='F'
            v_status_comment = "record already loaded:="+line
          elsif  line.include?("following sessions have been uploaded")
            v_status ='D'
            v_status_comment = "recordloaded:="+line
          elsif  line.include?("HTTP Status 401")
            v_status ='F'
            v_status_comment = "failed login:="+line
          elsif  line.include?("RMR")
            v_status ='F'
            v_status_comment = "failed dicom cleaning:="+line
          else  
            v_status ='F'
            v_status_comment = "something unexpected:="+line
          end
        }

        #clean up the log file
        response = r_call "rm -rf "+v_log_file_path

        sql_update = "update #{ p[:xnat_ids_tn] } set #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'Y' 
          where #{ p[:xnat_ids_tn] }.visit_id = #{ v_visit_id.to_s } and #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'N'
          and #{ p[:xnat_ids_tn] }.file_path in('#{ v_path_full_list_array.join("','") }') "
       
        if v_status == "D"
          results_update = @connection.execute(sql_update)
        elsif v_status == "F"        
          sql_update = "update #{ p[:xnat_ids_tn] } set #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'Q' 
            where #{ p[:xnat_ids_tn] }.visit_id = #{ v_visit_id.to_s } and #{ p[:xnat_ids_tn] }.xnat_exists_flag in ('N','Q')
            and #{ p[:xnat_ids_tn] }.file_path in('#{ v_path_full_list_array.join("','") }') "
            results_update = @connection.execute(sql_update)
        end

        #then clean up our dummy .zip
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'cd #{ p[:working_directory] }; rm -rf #{ p[:working_directory] }/#{ v_xnat_session }.zip'"
        puts cmd
        response = r_call cmd

        #copy the scan files to the working directory
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'rsync -av #{ scan[0] } #{ p[:working_directory] }/#{ v_xnat_session }/'"
        puts cmd
        response = r_call cmd

        #decompress the .bz2 archive
        v_path = scan[0]
        v_path_array = v_path.split("/")
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/#{ v_xnat_session }/#{ v_path_array.last };find . -name '*.bz2' -exec bunzip2 {} \\\;\" "
        puts cmd
        response = r_call cmd

        #remove any extra stuff we don't want to upload
        p[:rm_endings].each do |file_ending|
          cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/#{ v_xnat_session }/#{ v_path_array.last }/;rm -rf *.#{ file_ending } \""
          puts cmd
          response = r_call cmd
        end

        #strip dicom headers from the uploadable stuff
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"#{ p[:script_dicom_clean] } '#{ p[:working_directory] }/#{ v_xnat_session }/#{ v_path_array.last }' '#{ scan[4].to_s }' '#{ p[:project] }' '#{ v_xnat_session }' \" "
        puts cmd
        response = r_call cmd

        #compress the result
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/;zip -r  #{ v_xnat_session }.zip  #{ v_xnat_session }\""
        puts cmd
        response = r_call cmd

        #run the upload

        v_log_file_path = "#{ p[:working_directory] }/#{ v_xnat_session }.log"
        puts "log file is #{ v_log_file_path }"
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/; curl --netrc -o #{ v_xnat_session }.log -w \\\"%{http_code}\\\" --form project=#{ p[:project] } --form image_archive=@#{ v_xnat_session }.zip https://#{ p[:xnat_address] }/data/services/import?format=html\""
        puts cmd
        response = r_call cmd
        puts response
        
        #retrieve the log
        cmd = "rsync -av panda_user@#{ p[:computer] }.dom.wisc.edu:#{ v_log_file_path } #{ v_log_file_path }"
        puts cmd
        response = r_call cmd

        #then get back any log output, and search it for status of the upload
        # => "Session processing may already be in progress" -> 'F' (already in progress)
        # => "following sessions have been uploaded" -> 'D' (done)
        # => "HTTP Status 401" -> 'F' failed login
        # => "RMR" -> 'F' failed dicom cleaning
        # else: some other failure
        File.foreach(v_log_file_path).detect { |line| 
          if line.include?("Session processing may already be in progress")
            v_status ='F'
            v_status_comment = "record already loaded:="+line
          elsif  line.include?("following sessions have been uploaded")
            v_status ='D'
            v_status_comment = "recordloaded:="+line
          elsif  line.include?("HTTP Status 401")
            v_status ='F'
            v_status_comment = "failed login:="+line
          elsif  line.include?("RMR")
            v_status ='F'
            v_status_comment = "failed dicom cleaning:="+line
          else  
            v_status ='F'
            v_status_comment = "something unexpected:="+line
          end
        }

        #clean up the log file
        response = r_call "rm -rf "+v_log_file_path

        sql_update = "update #{ p[:xnat_ids_tn] } set #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'Y' 
          where #{ p[:xnat_ids_tn] }.visit_id = #{ v_visit_id.to_s } and #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'N'
          and #{ p[:xnat_ids_tn] }.file_path in('#{ v_path_full_list_array.join("','") }') "
       
        if v_status == "D"
          results_update = @connection.execute(sql_update)
        elsif v_status == "F"        
          sql_update = "update #{ p[:xnat_ids_tn] } set #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'Q' 
            where #{ p[:xnat_ids_tn] }.visit_id = #{ v_visit_id.to_s } and #{ p[:xnat_ids_tn] }.xnat_exists_flag in ('N','Q')
            and #{ p[:xnat_ids_tn] }.file_path in('#{ v_path_full_list_array.join("','") }') "
            results_update = @connection.execute(sql_update)
        end

        #clean up our working files
        #ssh panda_user@merida.dom.wisc.edu "cd /tmp/; rm -rf /tmp/{%xnat_session_id%}.zip
        response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'cd #{ p[:working_directory] }; rm -rf #{ p[:working_directory] }/#{ v_xnat_session }.zip'"

        #ssh panda_user@merida.dom.wisc.edu "cd /tmp/; rm -rf /tmp/{%xnat_session_id%}
        response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'cd #{ p[:working_directory] }; rm -rf #{ p[:working_directory] }/#{ v_xnat_session }'"
      end #looping over results

    #clean up and tell the SecheduledJob that we're done
    close
end
end