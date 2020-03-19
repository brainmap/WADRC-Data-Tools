class Pet::ParallelPetPibPostQcProcess < Pet::ParallelPetProcess

  # In this specific case, we're trying to process PiB SUVR for people who already have PiB DVR done, and where
  #   those PiB DVR scans have passed QC. If they're eligible, we should use the same T1 and multispectral file
  #   that was used for the DVR processing (if it's available). So, once we've got our first select returned back
  #   to us, our paths are good, and we don't have prior SUVR processing, then we should test each case for prior 
  #   DVR in the trackers, and a "Pass" qc_value. If those are good, then we should look for the log output from 
  #   DVR processing, and borrow the T1 & multispectral paths for the new driver. If the DVR is there, there should
  #   be a log for it, so the only other differences between this and the normal parallel script should be 
  #   error buckets for "didn't have PiB DVR", and "PiB DVR failed QC".

    def self.default_params
      # - set up params
      params = { schedule_name: 'parallel_pet_pib_suvr_process',
                 base_path: Shared.get_base_path(), 
                 computer: "kanga",
                 comment: [],
                 dry_run: false,
                 tracer_id: "1",
                 comment_warning: "",
                 method: "suvr",
                 exclude_sp_pet_array: [-1,80,115,100] # excluding adcp
                }

      params
    end

    def add_to_error_report(error_report_hash, pet_appointment)
      if !pet_appointment.related_enumber.nil?

        if !error_report_hash.keys.include?(pet_appointment.related_scan_procedure.codename)
          error_report_hash[pet_appointment.related_scan_procedure.codename] = {}
        end
        if !error_report_hash[pet_appointment.related_scan_procedure.codename].keys.include?(pet_appointment.related_enumber.enumber)
          error_report_hash[pet_appointment.related_scan_procedure.codename][pet_appointment.related_enumber.enumber] = {}
        end

      else

      end
    end

    def run(p=@params)

      v_comment = ""
      v_comment_warning ="" 

      v_days_mri_pet_diff_limit = "730"
      v_exclude_sp_mri_array = [-1,100,80,76,78]
      v_exclude_sp_pet_array = [-1,100]

      #good pet scans
      v_petscan_normal_run = []
      v_petscan_nearby_t1 = []

      ok_paths_and_not_processed_before = []

      #bad pet scans
      v_error_no_recent_acpc = []
      v_error_no_multispectral = []
      v_error_bad_uptake_duration = []
      v_error_multiple_t1 = []
      v_error_no_ecats = []
      v_error_too_many_ecats = []
      v_error_no_panda_log = []
      v_error_just_weird = []

      v_error_report = {}
      v_error_report.default = {}
      v_error_appt_weirdness = []
      bad_paths = []
      already_processed = []
      #this will eventually be populated with the petscans that we can't process, organized by scan_procedure.codename, and subject_id

      v_pettracer = LookupPettracer.where("id = ?",p[:tracer_id]).first

      v_preprocessed_tracer_path = "/pet/#{v_pettracer.name.downcase}/#{p[:method]}/code_ver2b"
      v_neighbor_dvr_tracer_path = "/pet/#{v_pettracer.name.downcase}/dvr/code_ver2b"
      v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)

      v_total_scans_considered = 0

  		# - grab all petscan records from the panda database that:
  		# 	- have the particular tracer we're processing right now
  		# 	- have been marked "good to process"
  		# 	- have an appointment whose vgroup has "transfer_pet in ('yes', 'no')"
  		# 	- and the appointment's scan procedures aren't in the excluded list

		  v_pib_petscans = Petscan.where("petscans.lookup_pettracer_id in (?) 
                   and petscans.good_to_process_flag = 'Y'
                   and petscans.appointment_id in 
                     ( select appointments.id from appointments, vgroups 
                        where appointments.vgroup_id = vgroups.id 
                         and vgroups.transfer_pet in ('no','yes') )
                  and petscans.appointment_id not in (select appointments.id from appointments, scan_procedures_vgroups
                  where appointments.vgroup_id = scan_procedures_vgroups.vgroup_id
                  and scan_procedures_vgroups.scan_procedure_id in (?))",p[:tracer_id],p[:exclude_sp_pet_array])

  		# - for each petscan on that list, do:

      v_pib_petscans.each do |pet_appt|

          v_total_scans_considered += 1
          v_enumber = ""
          v_scan_procedure = ""
          v_subjectid = ""
          v_scan_procedure_codename = ""

          v_pet_preprocessed_dir_exists = false
          v_multiple_petfiles = false
          v_petfile_exists = false
          v_pet_path_ok = false

          v_pet_appointment = Appointment.find(pet_appt.appointment_id)
          v_pet_date_string =(v_pet_appointment.appointment_date).to_s
          v_participant = Participant.find(Vgroup.find(v_pet_appointment.vgroup_id).participant_id)
          puts "v_participant.id="+v_participant.id.to_s

          orig_t1_mri_path = ''
          multispectral_file_path = ''
          
          # the existence of a preprocessed dir for this tracer/method/subject is what we use to determine if this scan
          # already has processing done. We don't reprocess unless we really need to.
          if pet_appt.paths_ok? and !pet_appt.preprocessed_dir_exists?(v_preprocessed_tracer_path)
            if pet_appt.related_enumber.nil? or pet_appt.related_scan_procedure.nil?
              v_error_appt_weirdness << {:pet_id => pet_appt.id}
              next
            end

            ok_paths_and_not_processed_before << [:protocol => pet_appt.related_scan_procedure.codename, :subject_id => pet_appt.related_enumber.enumber]

            # first, see if there's an adjcent DVR PiB directory, and if so find the "panda-log" inside it.
            if pet_appt.preprocessed_dir_exists?(v_neighbor_dvr_tracer_path)
              #find any tracker records for files in the DVR dir 
              neighbor_dvr_images = Processedimage.where("file_path like ?","%#{pet_appt.preprocessed_dir(v_neighbor_dvr_tracer_path)}%")

              if neighbor_dvr_images.count > 0
                tracker = Trfileimage.where(:image_id => neighbor_dvr_images.first.id, :image_category => 'processedimage')
                qc_value = tracker.first.trfile.qc_value

                if qc_value == "Pass"

                  pet_dvr_directory = File.dirname(neighbor_dvr_images.first.file_path)

                  log_file_name = Dir.entries(pet_dvr_directory).select{|entry| entry =~ /panda-log/}.first

                  if log_file_name.nil?
                    #there's no log file in this dir? make an error

                    add_to_error_report(v_error_report,pet_appt)
                    v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_dvr_panda_log"] = pet_appt
                    v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id

                  else

                    log_file_path = pet_dvr_directory + '/' + log_file_name

                    log_file_data = Hash.new("")
                    CSV.foreach(log_file_path, :headers => true) do |row|
                      log_file_data[row["Description"]] = row["Value"].to_s.strip
                    end

                    orig_t1_mri_path = log_file_data['original t1 MRI file']
                    multispectral_file_path = log_file_data['multispectral file']


                  end
                end
              else
                #there were no neighboring dvr images, so let's no process this person.

                add_to_error_report(v_error_report,pet_appt)
                v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_dvr_no_suvr"] = pet_appt
                v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id
              
              end
            else
              #record that this subject doesn't have DVR. Skip this person.

              add_to_error_report(v_error_report,pet_appt)
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_dvr_no_suvr"] = pet_appt
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id
              
            end

            if p[:method] == 'suvr'

              if !orig_t1_mri_path.blank? && !multispectral_file_path.blank? && !pet_appt.scanstarttime.nil? && !pet_appt.injecttiontime.nil?
                v_uptake_duration = ((pet_appt.scanstarttime - pet_appt.injecttiontime)/60).floor
                # puts "uptake duration = (start time #{pet_appt.scanstarttime} - injection time #{pet_appt.injecttiontime}) / 60 = #{v_uptake_duration}"
                # if (v_uptake_duration.to_i).between?(65,75)

                  # In the case of PiB, uptake duration can be zero, no prob. We don't want to exclude these people in that case.

                  # we're finally happy with all of the params we need, and we can make a csv for parallel processing

                  proto = pet_appt.related_scan_procedure.protocol.path.split('.')[0..1].join('.')
                  #visit = pet_appt.related_scan_procedure.codename.remove(pet_appt.related_scan_procedure.protocol.path)
                  visit = pet_appt.related_scan_procedure.codename.remove(proto).remove(".")

                  v_petscan_normal_run << {:proto => proto, :visit => visit, :enum => pet_appt.related_enumber.enumber, :t_uptake => v_uptake_duration, :file_t1 => orig_t1_mri_path, :file_mult => multispectral_file_path, :norm_samp => 1.0}

                # else
                #   v_error_bad_uptake_duration << {:scan => pet_appt, :message => " ERROR bad uptake duration "+pet_appt.related_scan_procedure.codename+' --brain '+pet_appt.related_enumber.enumber, :update_duration => v_uptake_duration.to_i }

                #   add_to_error_report(v_error_report,pet_appt)
                #   v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["bad_uptake_duration"] = pet_appt
                #   v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["uptake_duration"] = v_uptake_duration.to_i
                #   v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id
                # end
              end
            end

          else
            if !pet_appt.paths_ok?
              bad_paths << {:pet_id => pet_appt.id}
            elsif pet_appt.preprocessed_dir_exists?(v_preprocessed_tracer_path)
              already_processed << {:pet_id => pet_appt.id}
            end
            #try paths_ok!, and catch errors to categorize our petfile failures
            if pet_appt.related_scan_procedure.nil? or pet_appt.related_enumber.nil?
              #v_error_appt_weirdness << {:pet_id => pet_appt.id}
              next
            end
            begin
              pet_appt.paths_ok!
            rescue Exceptions::PetscanNoEcatsError => e
              v_error_no_ecats << {:scan => pet_appt, :message => e.message}

              add_to_error_report(v_error_report,pet_appt)
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_ecat_files"] = pet_appt
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_ecat_files_message"] = e.message
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id

            rescue Exceptions::PetscanTooManyEcatsError => e
              v_error_too_many_ecats << {:scan => pet_appt, :message => e.message}

              add_to_error_report(v_error_report,pet_appt)
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["too_many_ecat_files"] = pet_appt
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["too_many_ecat_files_message"] = e.message
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id

            rescue Exceptions::PetscanError, Exceptions::PetscanPathError => e
              v_error_just_weird << {:scan => pet_appt, :message => e.message}

              add_to_error_report(v_error_report,pet_appt)
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["black_swan"] = pet_appt
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["black_swan_message"] = e.message
              v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id
            end
          end
      end


      # puts "there were #{ok_paths_and_not_processed_before.length} subjects with OK paths who hadn't been processed before.: "
      # puts ok_paths_and_not_processed_before.to_s

      puts "total number of scans considered: #{v_total_scans_considered}"
      puts "ok_paths_and_not_processed_before: #{ok_paths_and_not_processed_before.length}"
      puts "bad paths: #{bad_paths.length} (ids: #{bad_paths.to_s})"
      puts "already processed: #{already_processed.length}"

      puts "appointment weirdness: #{v_error_appt_weirdness.length} (ids: #{v_error_appt_weirdness.to_s})"

      #write out the csv
      require 'csv'
      filename_suffix = p[:dry_run] ? "_dry_run" : ""
      pet_csv = "/mounts/data/preprocessed/logs/parallel_driver/#{Date.today.strftime("%Y-%m-%d")}_parallel_pet_#{v_pettracer.name.downcase}_#{p[:method].downcase}_driver#{filename_suffix}.csv"
      CSV.open(pet_csv, 'wb', row_sep: "\n", encoding: "UTF-8") do |writer|


        if p[:method] == 'suvr'
          #header
          writer << ["protocol", "visit", "enum", "t_uptake","file_t1", "file_mult", "norm_samp"].map{|s| s.encode("UTF-8")}

          #data
          v_petscan_normal_run.each do |row|
            writer << [row[:proto], row[:visit], row[:enum], row[:t_uptake], row[:file_t1], row[:file_mult], row[:norm_samp]].map{|s| s.to_s.encode("UTF-8")}
          end
        elsif p[:method] == 'dvr'
          writer << ["protocol", "visit", "enum", "file_t1", "file_mult", "norm_samp"].map{|s| s.encode("UTF-8")}

          #data
          #v_petscan_normal_run.each do |row|
          v_petscan_normal_run.each do |row|
            writer << [row[:proto], row[:visit], row[:enum], row[:file_t1], row[:file_mult], row[:norm_samp]].map{|s| s.to_s.encode("UTF-8")}
          end
        end
      end

      #run the processing, and pass the csv name as a param

      #report this run in the email
      v_send_email = false
      v_email_body = ""

      pet_mri_overdue = []

      v_error_report.keys.each do |scan_procedure|
        v_error_report[scan_procedure].keys.each do |subject_id|
          
          if v_error_report[scan_procedure][subject_id].keys.include?("no_recent_acpc")
            pet_appt = v_error_report[scan_procedure][subject_id]["no_recent_acpc"]

            all_mri_visits = Visit.where("visits.appointment_id in (select appointments.id from appointments join vgroups on appointments.vgroup_id = vgroups.id 
                  where vgroups.participant_id in (?)
                  and vgroups.transfer_mri = 'yes' and appointments.appointment_type = 'mri'
                  and vgroups.id not in 
                  (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups 
                     where scan_procedures_vgroups.scan_procedure_id in (?)) )", pet_appt.related_participant.id,v_exclude_sp_mri_array).order("date desc")

            if pet_appt.recent_o_acpc_file_exists?(all_mri_visits)
              o_acpc_file_visit = pet_appt.get_recent_o_acpc_visit(all_mri_visits)
              o_acpc_file_path = pet_appt.get_recent_o_acpc_file(all_mri_visits)
              visit_date = o_acpc_file_visit.appointment.appointment_date
              pet_appt_date = pet_appt.related_appointment.appointment_date
              

              pet_mri_overdue << {:participant_id => v_error_report[scan_procedure][subject_id]["participant_id"], 
                                  :scan_procedure => scan_procedure, 
                                  :enumber => subject_id, 
                                  :age_at_appt => pet_appt.related_appointment.age_at_appointment.to_s, 
                                  :closest_mri_protocol => o_acpc_file_visit.scan_procedures.first.codename,
                                  :closest_mri_enumber => o_acpc_file_visit.appointment.vgroup.enrollments.first.enumber,
                                  :closest_mri_age_at_appt => o_acpc_file_visit.appointment.age_at_appointment.to_s,
                                  :pet_mri_time_gap => (pet_appt_date - visit_date).to_i
                                  }
            else

              pet_mri_overdue << {:participant_id => v_error_report[scan_procedure][subject_id]["participant_id"], 
                                  :scan_procedure => scan_procedure, 
                                  :enumber => subject_id, 
                                  :age_at_appt => pet_appt.related_appointment.age_at_appointment.to_s, 
                                  :closest_mri_protocol => "Not found",
                                  :closest_mri_enumber => "Not found",
                                  :closest_mri_age_at_appt => "Not found",
                                  :pet_mri_time_gap => "n/a"
                                  }
            end
          end
        end
      end

      #write out the time gap failures

      headers = ["participant id", "PET scan procedure", "enumber", "age at appointment", "closest MRI scan procedure", "closest MRI enumber", "closest MRI age at appointment", "PET / MRI time gap (days)"]

      filename_suffix = p[:dry_run] ? "_dry_run" : ""
      pet_failed_csv = "/mounts/data/preprocessed/logs/parallel_driver/#{Date.today.strftime("%Y-%m-%d")}_pet_mri_time_gap_failures_#{v_pettracer.name}#{filename_suffix}.csv"
      CSV.open(pet_failed_csv, 'wb', row_sep: "\n", encoding: "UTF-8") do |csv|
        csv << headers
        pet_mri_overdue.each do |line|
          csv << [line[:participant_id], line[:scan_procedure], line[:enumber], line[:age_at_appt], line[:closest_mri_protocol], line[:closest_mri_enumber], line[:closest_mri_age_at_appt], line[:pet_mri_time_gap]]
        end
      end

      if p[:dry_run]

        if v_petscan_normal_run.length > 0
          puts "\n\nnormal pet_pib_suvr_processing: "
          v_petscan_normal_run.each do |val|
            puts "#{val[:proto]}, #{val[:visit]}, #{val[:enum]}, #{val[:t_uptake]}, #{val[:file_t1]}, #{val[:file_mult]}, #{val[:norm_samp]}"
          end
        else
          puts "\nwe didn't find any normal pet scans"
        end

        if v_error_no_recent_acpc.length > 0
          puts "\n\nerrors: no recent acpc file: "
          v_error_no_recent_acpc.each do |val|
            puts "#{val.path}"
          end
        else
          puts "\nno scans were without recent acpc files"
        end

        if v_error_no_multispectral.length > 0
          puts "\n\nerrors: no multispectral file: "
          v_error_no_multispectral.each do |val|
            puts "#{val.path}"
          end
        else
          puts "\nno scans were without multispectral files"
        end

        if v_error_bad_uptake_duration.length > 0
          puts "\n\nerrors: bad uptake duration: "
          v_error_bad_uptake_duration.each do |val|
            puts "#{val[:scan].path} (uptake duration was #{val[:uptake_duration]})"
          end
        else
          puts "\nno scans had bad uptake duration"
        end

        if v_error_multiple_t1.length > 0
          puts "\n\nerrors: too many T1 (o_acpc.nii) files: "
          v_error_multiple_t1.each do |val|
            puts "#{val.path}"
          end
        else
          puts "\nno scans with too many o_acpc.nii files"
        end

        if v_error_no_ecats.length > 0
          puts "\n\nerrors: no ecat files: "
          v_error_no_ecats.each do |val|
            puts "#{val[:scan].path} (#{val[:message]})"
          end
        else
          puts "\neverybody had ecat files"
        end

        if v_error_too_many_ecats.length > 0
          puts "\n\nerrors: too many ecat files: "
          v_error_too_many_ecats.each do |val|
            puts "#{val[:scan].path} (#{val[:message]})"
          end
        else
          puts "\neverybody had the right number of ecat files"
        end

        if v_error_just_weird.length > 0
          puts "\n\nerrors: oddballs: "
          v_error_just_weird.each do |val|
            puts "#{val[:scan].path} (#{val[:message]})"
          end
        else
          puts "\nno oddballs"
        end

      else
        #actually run the parallel script

        pet_scripts_dir="/mounts/data/analyses/tjbetthauser/MATLAB_Mac/pet_proc_v2b/batch_parallel"

        #for each of the subjects we're about to process, make a directory for that subject_id under the right study in preprocessed
        v_petscan_normal_run.each do |row|
          visit_dir = "#{p[:base_path]}/preprocessed/visits/#{row[:proto]}.#{row[:visit]}/#{row[:enum]}"
          if !File.directory?(visit_dir)
            Dir.mkdir(visit_dir)
          end
        end

        matlab_template = "export MATLABPATH=$MATLABPATH:#{pet_scripts_dir}" + " && matlab -nodesktop -nosplash -r \\\"try %{command}; catch exception; display(getReport(exception)); pause(1); end; exit;\\\""
        matlab_command = matlab_template % {command: "batch_pet_parallel_auto('#{pet_csv}',12,'#{v_pettracer.name.downcase}','#{p[:method]}')"}
        v_computer = p[:computer]
        v_call =  "ssh panda_user@#{v_computer}.dom.wisc.edu \"#{matlab_command}\""

        v_comment = v_comment + v_call+"\n"
        @schedulerun.comment = v_comment
        @schedulerun.save
        begin
          stdin, stdout, stderr = Open3.popen3(v_call)
          rescue => msg  
          v_comment = v_comment + msg.to_s + "\n"  
        end
        # v_success ="N"
        while !stdout.eof?
          v_output = stdout.read 1024 
          #  v_comment = v_comment + v_output  
          puts v_output  
        end

       if v_send_email
          v_schedule_owner_email_array.each do |e|
              v_subject = "Runs:"+@schedule.name 
              PandaMailer.send_email(v_subject,{:send_to => e},v_email_body).deliver
           end
       end 
     end

    	close
    end
end
