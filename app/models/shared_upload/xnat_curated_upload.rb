class SharedUpload::XnatCuratedUpload < SharedUpload::SharedUploadBase

  def self.default_params
	  params = { schedule_name: 'xnat_curated_upload',
				base_path: Shared.get_base_path(), 
    			computer: "merida",
    			comment: [],
    			comment_warning: "",
    			log_base: "/mounts/data/preprocessed/logs/",
    			process_name: "xnat_curated",
    			stop_file_name: "xnat_curated_file_stop",
      			stop_file_path: "/mounts/data/preprocessed/logs/xnat_curated_file_stop",

      			project: nil,

              #usually this script will grab the project from the driver table along with imageset ids,
              # and upload anything that isn't already on xnat. If we specify a project on params, it 
              # will only look for new entries under that project.

      			xnat_participant_tn: "xnat_curated_participants",
      			xnat_appointment_mri_tn: "xnat_curated_mri_appointment",
            xnat_ids_tn: "xnat_curated_image_datasets",
            xnat_driver_tn: "xnat_curated_driver",
      			working_directory: "/tmp",
      			rm_endings: ["json","pickle","yaml","txt","xml","doc","xls","xlsx"],
            default_xnat_run_upload_flag: 'R'}

      params[:xnat_script_dir] = params[:base_path]+"/analyses/rpcary/xnat/scripts/"
      params[:script_dicom_clean] =  params[:xnat_script_dir]+"xnat_dicom_upload_cleaner.rb"
      params[:xnat_address] = 'xnat.medicine.wisc.edu'
      params
    end

    def run(p=@params)
    	#This xnat upload job is controlled by special curated image dataset lists. As such, we can do some pretty easy joins to 
      # get everything we need to run a normal xnat upload job. This job will still run each time the cron calls it, but
      # unless there are additions to the driver table, this script won't upload anything on a regular basis.

      #we start with image dataset ids on the driver table, and find participants/appointments/vgroups from there

    	#add to this job only the participant ids that:
    	# => aren't alreay in the table
    	# => pilot_flag == 'N'
    	# => show up in the driver table

		  sql = "insert into #{ p[:xnat_participant_tn] } (project, participant_id, xnat_exists_flag, xnat_do_not_share_flag, xnat_run_upload_flag) 
               select #{ p[:xnat_driver_tn] }.project, enrollments.participant_id, 'N', enrollments.do_not_share_scans_flag, '#{ p[:default_xnat_run_upload_flag] }'
                  from #{ p[:xnat_driver_tn] } 
                  join image_datasets on #{ p[:xnat_driver_tn] }.image_dataset_id = image_datasets.id 
                  join visits on image_datasets.visit_id = visits.id 
                  join enrollment_visit_memberships on visits.id = enrollment_visit_memberships.visit_id
                  join enrollments on enrollment_visit_memberships.enrollment_id = enrollments.id
                where enrollments.do_not_share_scans_flag = 'N'
                  and (enrollments.participant_id, #{ p[:xnat_driver_tn] }.project) not in (select participant_id, project from #{ p[:xnat_participant_tn] }) "

      if !p[:project].nil?
        sql += " and #{ p[:xnat_driver_tn] }.project = '#{ p[:project] }'"
      end

      sql += ' group by enrollments.participant_id, xnat_curated_driver.project'

		  results = @connection.execute(sql)

		  #then get the list of those new ids, and 
      sql = "select export_id from #{ p[:xnat_participant_tn] } where export_id is NOT NULL"
      v_exportid_results = @connection.execute(sql)
      v_exportid_array = []
      v_exportid_results.each { |r| v_exportid_array << r }

      #for the records without export ids, loop over them and assign a unique, random value to each row as export_id
      v_null_check_sql = "select participant_id, project from #{ p[:xnat_participant_tn] } where export_id is NULL and participant_id is not NULL"
      v_results = @connection.execute(v_null_check_sql)
      v_participants_without_export_ids = []
      v_results.each { |r| v_participants_without_export_ids << {id:r[0],project:r[1]} }
      v_null_check_cnt = v_participants_without_export_ids.count

      #get a list of random numbers that's:
      # => unique within the list
      # => has no overlap with our existing export_ids
      # => is zero-padded to make a 10-digit string

      r = Random.new
      candidate_export_ids = Array.new(v_null_check_cnt) {|i| r.rand(1000..9999999999).to_s.rjust(10,'0')}

      #while there's overlap between our candidate ids and the ids currently in use,
      # drop the overlap, and replace with new random ids.
      while !(candidate_export_ids & v_exportid_array).empty? or (candidate_export_ids.count != candidate_export_ids.uniq.count)
        #make the ids unique within the array
        temp_candidate_export_ids = candidate_export_ids.uniq

        #remove any ids that overlap with our used ids
        temp_candidate_export_ids -= v_exportid_array

        #then add some new ids to make up the difference
        #how many do we need?
        v_difference = candidate_export_ids.count - temp_candidate_export_ids.count
        temp_candidate_export_ids += Array.new(v_difference) {|i| r.rand(1000..9999999999).to_s.rjust(10,'0')}
        candidate_export_ids = temp_candidate_export_ids
      end

      #then assign those export ids to the new participants
      v_participants_without_export_ids.each do |part|
        #each part is a hash like [:id, :project]
        v_new_export_id = candidate_export_ids.pop
        sql = "update #{ p[:xnat_participant_tn] } set export_id = '#{ part[:project] }_#{ v_new_export_id }' where participant_id = #{ part[:id] } and project = '#{ part[:project] }'"
        results = @connection.execute(sql)
      end

      #add to xnat_curated_mri_appointment only those appointment_ids that:
      # => have a vgroup we can share
      # => have a vgroup.pilot_flag = 'N'
      # => are somewhere on the driver table
      # => aren't already in the xnat_curated_mri_appointment table

      sql = "insert into #{ p[:xnat_appointment_mri_tn] } (appointment_id, participant_id, project, visit_id,xnat_exists_flag,secondary_key)
              select appointments.id, enrollments.participant_id, #{ p[:xnat_driver_tn] }.project, visits.id, 'N', appointments.secondary_key
              from #{ p[:xnat_driver_tn] } 
              join image_datasets on #{ p[:xnat_driver_tn] }.image_dataset_id = image_datasets.id 
              join visits on image_datasets.visit_id = visits.id 
              join enrollment_visit_memberships on visits.id = enrollment_visit_memberships.visit_id
              join enrollments on enrollment_visit_memberships.enrollment_id = enrollments.id
              join appointments on visits.appointment_id = appointments.id
              where enrollments.do_not_share_scans_flag = 'N'
              and (appointments.id, #{ p[:xnat_driver_tn] }.project) not in (select appointment_id, project from #{ p[:xnat_appointment_mri_tn] })
              and (visits.id, #{ p[:xnat_driver_tn] }.project) not in (select visit_id, project from #{ p[:xnat_appointment_mri_tn] })"

      if !p[:project].nil?
        sql += " and #{ p[:xnat_driver_tn] }.project = '#{ p[:project] }'"
      end

      sql += " group by #{ p[:xnat_driver_tn] }.project, appointments.id"

      results = @connection.execute(sql)

      #make sure our appointments table gets the session_id, which is built with our export_id
      # get path from appointment_id , get codename/sp , get start , update xnat_session_id  <sp enum start>_export_id_<v#>

      sql = "select #{ p[:xnat_appointment_mri_tn] }.appointment_id, #{ p[:xnat_participant_tn] }.export_id, visits.path, #{ p[:xnat_appointment_mri_tn] }.secondary_key, #{ p[:xnat_appointment_mri_tn] }.project
       from #{ p[:xnat_appointment_mri_tn] } join visits on #{ p[:xnat_appointment_mri_tn] }.visit_id = visits.id 
          join appointments on #{ p[:xnat_appointment_mri_tn] }.appointment_id = appointments.id 
          join #{ p[:xnat_participant_tn] } on #{ p[:xnat_appointment_mri_tn] }.participant_id = #{ p[:xnat_participant_tn] }.participant_id and #{ p[:xnat_appointment_mri_tn] }.project = #{ p[:xnat_participant_tn] }.project

        where (#{ p[:xnat_appointment_mri_tn] }.xnat_session_id is null or #{ p[:xnat_appointment_mri_tn] }.xnat_session_id = '') 
        and visits.path is not null and visits.path > ''"

      if !p[:project].nil?
        sql += " and #{ p[:xnat_appointment_mri_tn] }.project = '#{ p[:project] }'"
      end

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

        v_project = v_val[4]
        if !v_secondary_key.blank?
             v_secondary_key = v_secondary_key.gsub(".","")
        end
        v_xnat_session_id = ""
        sp_array = ScanProcedure.where("codename in (?)",v_codename)
        if sp_array.count> 0
             v_prepend = "_"+sp_array.first.subjectid_base
             v_number = sp_array.first.visit_abbr("_v1")
             # issue with secondary scans into one session

             v_xnat_session_id = v_export_id.to_s+v_prepend+v_number
             if !v_secondary_key.blank?
                 v_xnat_session_id += "_sk"+v_secondary_key
              end

             sql_update = "update #{ p[:xnat_appointment_mri_tn] } set xnat_session_id = '#{ v_xnat_session_id }'
             where #{ p[:xnat_appointment_mri_tn] }.appointment_id = #{ v_appt_id.to_s }
             and (#{ p[:xnat_appointment_mri_tn] }.xnat_session_id is null or #{ p[:xnat_appointment_mri_tn] }.xnat_session_id = '') 
             and #{ p[:xnat_appointment_mri_tn] }.project = '#{ v_project }'"
             results = @connection.execute(sql_update)
        end
      end

      # set the xnat_do_not_share based on pilot and enumber/study consent forms
      #set xnat_exists_flag = 'Y' after upload to xnat
      sql = "insert into #{ p[:xnat_ids_tn] } (visit_id,image_dataset_id,xnat_exists_flag,file_path, project)
          select visits.id, image_datasets.id, 'N', image_datasets.path, #{ p[:xnat_driver_tn] }.project
          from #{ p[:xnat_driver_tn] } 
            join image_datasets on #{ p[:xnat_driver_tn] }.image_dataset_id = image_datasets.id 
            join visits on image_datasets.visit_id = visits.id 
            join enrollment_visit_memberships on visits.id = enrollment_visit_memberships.visit_id
            join enrollments on enrollment_visit_memberships.enrollment_id = enrollments.id
          where (image_datasets.do_not_share_scans_flag is null or image_datasets.do_not_share_scans_flag != 'Y')
            and (enrollments.do_not_share_scans_flag is null or enrollments.do_not_share_scans_flag != 'Y')
            and (image_datasets.visit_id, image_datasets.id,  #{ p[:xnat_driver_tn] }.project) not in (select visit_id, image_dataset_id, project from xnat_curated_image_datasets) "

      if !p[:project].nil?
        sql += " and #{ p[:xnat_driver_tn] }.project = '#{ p[:project] }'"
      end

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
        #{ p[:xnat_participant_tn] }.export_id, #{ p[:xnat_participant_tn] }.xnat_exists_flag,  #{ p[:xnat_ids_tn] }.project
        from #{ p[:xnat_participant_tn] } join #{ p[:xnat_appointment_mri_tn] } on #{ p[:xnat_participant_tn] }.participant_id = #{ p[:xnat_appointment_mri_tn] }.participant_id and #{ p[:xnat_participant_tn] }.project = #{ p[:xnat_appointment_mri_tn] }.project
          join #{ p[:xnat_ids_tn] } on #{ p[:xnat_appointment_mri_tn] }.visit_id = #{ p[:xnat_ids_tn] }.visit_id and #{ p[:xnat_appointment_mri_tn] }.project = #{ p[:xnat_ids_tn] }.project
        where #{ p[:xnat_ids_tn] }.xnat_do_not_share_flag = 'N' 
          and #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'N' 
          and #{ p[:xnat_participant_tn] }.participant_id = #{ p[:xnat_appointment_mri_tn] }.participant_id
          and #{ p[:xnat_appointment_mri_tn] }.visit_id = #{ p[:xnat_ids_tn] }.visit_id
          and #{ p[:xnat_participant_tn] }.xnat_run_upload_flag = 'R'"

      if !p[:project].nil?
        sql += " and #{ p[:xnat_ids_tn] }.project = '#{ p[:project] }'"
      end

      sql += " order by #{ p[:xnat_appointment_mri_tn] }.xnat_session_id "

      #puts "selecting for our export: " + sql

      results = @connection.execute(sql)

      v_xnat_session ="zzzzz"
      v_target_dir = ""
      v_cnt_ids = 0
      v_path_array = []
      v_path_full_list_array = []
      v_visit_id = ""
      results.each do |scan|

        v_cnt_ids = v_cnt_ids + 1
        v_visit_id = scan[1]
        v_xnat_session = scan[2]
        v_xnat_project = scan[6]
        v_xnat_export_id = scan[4]
        v_file_path = scan[0]
        v_path_full_list_array.push(v_file_path)

        #make a working dir for this session
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'cd #{ p[:working_directory] }; mkdir #{ v_xnat_session }'"
        puts cmd
        response = r_call cmd

        #first, we need to make a dummy .zip file for this export_id, to establish a person in xnat for these scans to attach to
        #cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] };zip -r  #{ v_xnat_session }.zip  #{ v_xnat_session }\""
        #puts cmd
        #response = r_call cmd

        v_log_file_path = "#{ p[:working_directory] }/#{ v_xnat_session }.log"
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }; curl --netrc -o #{ v_log_file_path } -w \\\"%{http_code}\\\" -X PUT https://#{ p[:xnat_address] }/data/archive/projects/#{ v_xnat_project }/subjects/#{ v_xnat_export_id }\""
        puts cmd
        response = r_call cmd
        puts response

        #run the upload
        #v_log_file_path = "#{ p[:working_directory] }/#{ v_xnat_session }.log"
        #puts "log file is #{ v_log_file_path }"
        #cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }; curl --netrc -o #{ v_log_file_path } -w \\\"%{http_code}\\\" --form project=#{ v_xnat_project } --form image_archive=@#{ v_xnat_session }.zip https://#{ p[:xnat_address] }/data/services/import?format=html\""
        #puts cmd
        #response = r_call cmd
        
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

        puts v_status
        puts v_status_comment
        #clean up the log file
        response = r_call "rm -rf "+v_log_file_path

        sql_update = "update #{ p[:xnat_ids_tn] } set #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'Y' 
          where #{ p[:xnat_ids_tn] }.visit_id = #{ v_visit_id.to_s } and #{ p[:xnat_ids_tn] }.xnat_exists_flag in ('N','Q')
          and #{ p[:xnat_ids_tn] }.file_path in('#{ v_path_full_list_array.join("','") }') and #{ p[:xnat_ids_tn] }.project = '#{ v_xnat_project }'"
       
        if v_status == "D"
          results_update = @connection.execute(sql_update)
        elsif v_status == "F"        
          sql_update = "update #{ p[:xnat_ids_tn] } set #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'Q' 
            where #{ p[:xnat_ids_tn] }.visit_id = #{ v_visit_id.to_s } and #{ p[:xnat_ids_tn] }.xnat_exists_flag in ('N','Q')
            and #{ p[:xnat_ids_tn] }.file_path in('#{ v_path_full_list_array.join("','") }') and #{ p[:xnat_ids_tn] }.project = '#{ v_xnat_project }' "
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
          #puts cmd
          response = r_call cmd
        end

        #strip dicom headers from the uploadable stuff
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"#{ p[:script_dicom_clean] } '#{ p[:working_directory] }/#{ v_xnat_session }/#{ v_path_array.last }' '#{ scan[4].to_s }' '#{ v_xnat_project }' '#{ v_xnat_session }' \" "
        puts cmd
        response = r_call cmd

        #compress the result
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/;zip -r  #{ v_xnat_session }.zip  #{ v_xnat_session }\""
        puts cmd
        response = r_call cmd

        #run the upload

        v_log_file_path = "#{ p[:working_directory] }/#{ v_xnat_session }.log"
        puts "log file is #{ v_log_file_path }"
        cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/; curl --netrc -o #{ v_xnat_session }.log -w \\\"%{http_code}\\\" --form project=#{ v_xnat_project } --form image_archive=@#{ v_xnat_session }.zip https://#{ p[:xnat_address] }/data/services/import?format=html\""
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

        puts v_status
        puts v_status_comment

        #clean up the log file
        response = r_call "rm -rf "+v_log_file_path

        sql_update = "update #{ p[:xnat_ids_tn] } set #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'Y' 
          where #{ p[:xnat_ids_tn] }.visit_id = #{ v_visit_id.to_s } and #{ p[:xnat_ids_tn] }.xnat_exists_flag in ('N','Q')
          and #{ p[:xnat_ids_tn] }.file_path in('#{ v_path_full_list_array.join("','") }') and #{ p[:xnat_ids_tn] }.project = '#{ v_xnat_project }'"
       
        if v_status == "D"
          results_update = @connection.execute(sql_update)
          
          sql_update = "update #{ p[:xnat_participant_tn] } set xnat_exists_flag = 'Y', xnat_run_upload_flag = 'D' where project = '#{ v_xnat_project }' and export_id = '#{ v_xnat_export_id }'"
          results_update = @connection.execute(sql_update)
        elsif v_status == "F"        
          sql_update = "update #{ p[:xnat_ids_tn] } set #{ p[:xnat_ids_tn] }.xnat_exists_flag = 'Q' 
            where #{ p[:xnat_ids_tn] }.visit_id = #{ v_visit_id.to_s } and #{ p[:xnat_ids_tn] }.xnat_exists_flag in ('N','Q')
            and #{ p[:xnat_ids_tn] }.file_path in('#{ v_path_full_list_array.join("','") }') and #{ p[:xnat_ids_tn] }.project = '#{ v_xnat_project }'"
            results_update = @connection.execute(sql_update)
        end

        @params[:comment].push v_status_comment
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