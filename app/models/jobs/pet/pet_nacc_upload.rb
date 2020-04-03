class Jobs::Pet::PetNaccUpload < Jobs::Pet::PetBase


  def self.default_params
  	params = { schedule_name: 'pet_nacc_upload',
  				      base_path: Shared.get_base_path(), 
                computer: "kanga",
                comment: [],
                dry_run: false,
                tracer_id: "1",
                comment_warning: "",
                days_mri_pet_diff_limit: "730",
                exclude_sp_mri_array: [-1,100,80,76,78],
                exclude_sp_pet_array: [-1,100] 
              }
    params.default = ''
    params
  end

  def setup(params)


      #good pet scans
      @petscan_normal_run = []
      @petscan_nearby_t1 = []

      @ok_paths_and_not_processed_before = []

      #bad pet scans
      @error_no_recent_acpc = []
      @error_no_multispectral = []
      @error_bad_uptake_duration = []
      @error_multiple_t1 = []
      @error_no_ecats = []
      @error_too_many_ecats = []
      @error_just_weird = []

      @error_report = {}
      @error_report.default = {}
      @error_appt_weirdness = []
      # bad_paths = []
      # already_processed = []
      #this will eventually be populated with the petscans that we can't process, organized by scan_procedure.codename, and subject_id

      @pettracer = LookupPettracer.where("id = ?",params[:tracer_id]).first

      @preprocessed_tracer_path = "/pet/#{@pettracer.name.downcase}/#{params[:method]}/code_ver2b"
      # @schedule_owner_email_array = get_schedule_owner_email(@schedule.id)

      @total_scans_considered = 0

  end

  def selection(params)

      @petscans = Jobs::Pet::Petscan.where("petscans.lookup_pettracer_id in (?) 
                   and petscans.good_to_process_flag = 'Y'
                   and petscans.appointment_id in 
                     ( select appointments.id from appointments, vgroups 
                        where appointments.vgroup_id = vgroups.id 
                         and vgroups.transfer_pet in ('no','yes') )
                  and petscans.appointment_id not in (select appointments.id from appointments, scan_procedures_vgroups
                  where appointments.vgroup_id = scan_procedures_vgroups.vgroup_id
                  and scan_procedures_vgroups.scan_procedure_id in (?))",params[:tracer_id],params[:exclude_sp_pet_array])

      @petscans.each do |pet_appt|
        self.inputs << "< #{pet_appt.class} id:#{pet_appt.id} >"
      end

  end
  
  def filter(params)

    @petscans.each do |pet_appt|

          @total_scans_considered += 1
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

          o_acpc_file_path = ''
          multispectral_file_path = ''
          
          if pet_appt.paths_ok? and !pet_appt.preprocessed_dir_exists?(v_preprocessed_tracer_path)
            if pet_appt.related_enumber.nil? or pet_appt.related_scan_procedure.nil?
              @error_appt_weirdness << {:pet_id => pet_appt.id}
              next
            end

            ok_paths_and_not_processed_before << [:protocol => pet_appt.related_scan_procedure.codename, :subject_id => pet_appt.related_enumber.enumber]
            #first check under this visit's preprocessed/visits folder to see if an o_acpc.nii file exits
            if pet_appt.o_acpc_file_exists?
              o_acpc_file_path = pet_appt.get_o_acpc_file
            else 
              #then look around in nearby visits for this participant for an o_acpc.nii file
              recent_mri_visits = Visit.where("visits.appointment_id in (select appointments.id from appointments join vgroups on appointments.vgroup_id = vgroups.id 
                  where vgroups.participant_id in (?)
                  and vgroups.transfer_mri = 'yes' and appointments.appointment_type = 'mri'
                  and abs(datediff(appointments.appointment_date,?))  < "+v_days_mri_pet_diff_limit+"
                  and vgroups.id not in 
                  (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups 
                     where scan_procedures_vgroups.scan_procedure_id in (?)) )", pet_appt.related_participant.id,pet_appt.related_appointment.appointment_date.to_s,v_exclude_sp_mri_array).order("date desc")

              #puts "looking around for other o_acpc.nii files, we got #{recent_mri_visits.length} other visits"

              if pet_appt.recent_o_acpc_file_exists?(recent_mri_visits)
                o_acpc_file_path = pet_appt.get_recent_o_acpc_file(recent_mri_visits)
              else
                @error_no_recent_acpc << pet_appt
                add_to_error_report(@error_report,pet_appt)
                @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_recent_acpc"] = pet_appt
                @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id
              end
            end

            if pet_appt.multispectral_file_exists?
              multispectral_file_path = pet_appt.get_multispectral_file
            else

              recent_mri_visits = Visit.where("visits.appointment_id in (select appointments.id from appointments join vgroups on appointments.vgroup_id = vgroups.id 
                  where vgroups.participant_id in (?)
                  and vgroups.transfer_mri = 'yes' and appointments.appointment_type = 'mri'
                  and abs(datediff(appointments.appointment_date,?))  < "+v_days_mri_pet_diff_limit+"
                  and vgroups.id not in 
                  (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups 
                     where scan_procedures_vgroups.scan_procedure_id in (?)) )", pet_appt.related_participant.id,pet_appt.related_appointment.appointment_date.to_s,v_exclude_sp_mri_array).order("date desc")


              if pet_appt.recent_multispectral_file_exists?(recent_mri_visits)
                multispectral_file_path = pet_appt.get_recent_multispectral_file(recent_mri_visits)
              else
                @error_no_multispectral << pet_appt
                add_to_error_report(@error_report,pet_appt)
                @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_recent_multispectral"] = pet_appt
                @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id
              end
            end

            if params[:method] == 'suvr'

              if !o_acpc_file_path.blank? && !multispectral_file_path.blank? && !pet_appt.scanstarttime.nil? && !pet_appt.injecttiontime.nil?
                v_uptake_duration = ((pet_appt.scanstarttime - pet_appt.injecttiontime)/60).floor
                if (v_uptake_duration.to_i).between?(65,75)

                  # we're finally happy with all of the params we need, and we can make a csv for parallel processing

                  proto = pet_appt.related_scan_procedure.protocol.path.split('.')[0..1].join('.')
                  #visit = pet_appt.related_scan_procedure.codename.remove(pet_appt.related_scan_procedure.protocol.path)
                  visit = pet_appt.related_scan_procedure.codename.remove(proto).remove(".")

                  v_petscan_normal_run << {:proto => proto, :visit => visit, :enum => pet_appt.related_enumber.enumber, :t_uptake => v_uptake_duration, :file_t1 => o_acpc_file_path, :file_mult => multispectral_file_path, :norm_samp => 1.0}

                else
                  @error_bad_uptake_duration << {:scan => pet_appt, :message => " ERROR bad uptake duration "+pet_appt.related_scan_procedure.codename+' --brain '+pet_appt.related_enumber.enumber, :update_duration => v_uptake_duration.to_i }

                  add_to_error_report(@error_report,pet_appt)
                  @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["bad_uptake_duration"] = pet_appt
                  @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["uptake_duration"] = v_uptake_duration.to_i
                  @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id
                end
              end
            elsif params[:method] == 'dvr'

              if !o_acpc_file_path.blank? && !multispectral_file_path.blank?
                # we're finally happy with all of the params we need, and we can make a csv for parallel processing

                proto = pet_appt.related_scan_procedure.protocol.path.split('.')[0..1].join('.')
                visit = pet_appt.related_scan_procedure.codename.remove(proto).remove(".")

                v_petscan_normal_run << {:proto => proto, :visit => visit, :enum => pet_appt.related_enumber.enumber, :file_t1 => o_acpc_file_path, :file_mult => multispectral_file_path, :norm_samp => 1.0}

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
              #@error_appt_weirdness << {:pet_id => pet_appt.id}
              next
            end
            begin
              pet_appt.paths_ok!
            rescue Exceptions::PetscanNoEcatsError => e
              @error_no_ecats << {:scan => pet_appt, :message => e.message}

              add_to_error_report(@error_report,pet_appt)
              @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_ecat_files"] = pet_appt
              @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_ecat_files_message"] = e.message
              @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id

            rescue Exceptions::PetscanTooManyEcatsError => e
              @error_too_many_ecats << {:scan => pet_appt, :message => e.message}

              add_to_error_report(@error_report,pet_appt)
              @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["too_many_ecat_files"] = pet_appt
              @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["too_many_ecat_files_message"] = e.message
              @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id

            rescue Exceptions::PetscanError, Exceptions::PetscanPathError => e
              @error_just_weird << {:scan => pet_appt, :message => e.message}

              add_to_error_report(@error_report,pet_appt)
              @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["black_swan"] = pet_appt
              @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["black_swan_message"] = e.message
              @error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id
            end
          end
      end


      # puts "there were #{ok_paths_and_not_processed_before.length} subjects with OK paths who hadn't been processed before.: "
      # puts ok_paths_and_not_processed_before.to_s

      puts "total number of scans considered: #{v_total_scans_considered}"
      puts "ok_paths_and_not_processed_before: #{ok_paths_and_not_processed_before.length}"
      puts "bad paths: #{bad_paths.length} (ids: #{bad_paths.to_s})"
      puts "already processed: #{already_processed.length}"

      puts "appointment weirdness: #{@error_appt_weirdness.length} (ids: #{@error_appt_weirdness.to_s})"

  end
  
  def matlab_call(params)


      #write out the csv
      require 'csv'
      filename_suffix = params[:dry_run] ? "_dry_run" : ""
      pet_csv = "/mounts/data/preprocessed/logs/parallel_driver/#{Date.today.strftime("%Y-%m-%d")}_parallel_pet_#{@pettracer.name}_driver#{filename_suffix}.csv"
      CSV.open(pet_csv, 'wb', row_sep: "\n", encoding: "UTF-8") do |writer|


        if params[:method] == 'suvr'
          #header
          writer << ["protocol", "visit", "enum", "t_uptake","file_t1", "file_mult", "norm_samp"].map{|s| s.encode("UTF-8")}

          #data
          v_petscan_normal_run.each do |row|
            writer << [row[:proto], row[:visit], row[:enum], row[:t_uptake], row[:file_t1], row[:file_mult], row[:norm_samp]].map{|s| s.to_s.encode("UTF-8")}
          end
        elsif params[:method] == 'dvr'
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

      @error_report.keys.each do |scan_procedure|
        @error_report[scan_procedure].keys.each do |subject_id|
          
          if @error_report[scan_procedure][subject_id].keys.include?("no_recent_acpc")
            pet_appt = @error_report[scan_procedure][subject_id]["no_recent_acpc"]

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
              

              pet_mri_overdue << {:participant_id => @error_report[scan_procedure][subject_id]["participant_id"], 
                                  :scan_procedure => scan_procedure, 
                                  :enumber => subject_id, 
                                  :age_at_appt => pet_appt.related_appointment.age_at_appointment.to_s, 
                                  :closest_mri_protocol => o_acpc_file_visit.scan_procedures.first.codename,
                                  :closest_mri_enumber => o_acpc_file_visit.appointment.vgroup.enrollments.first.enumber,
                                  :closest_mri_age_at_appt => o_acpc_file_visit.appointment.age_at_appointment.to_s,
                                  :pet_mri_time_gap => (pet_appt_date - visit_date).to_i
                                  }
            else

              pet_mri_overdue << {:participant_id => @error_report[scan_procedure][subject_id]["participant_id"], 
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

      filename_suffix = params[:dry_run] ? "_dry_run" : ""
      pet_failed_csv = "/mounts/data/preprocessed/logs/parallel_driver/#{Date.today.strftime("%Y-%m-%d")}_pet_mri_time_gap_failures_#{@pettracer.name}#{filename_suffix}.csv"
      CSV.open(pet_failed_csv, 'wb', row_sep: "\n", encoding: "UTF-8") do |csv|
        csv << headers
        pet_mri_overdue.each do |line|
          csv << [line[:participant_id], line[:scan_procedure], line[:enumber], line[:age_at_appt], line[:closest_mri_protocol], line[:closest_mri_enumber], line[:closest_mri_age_at_appt], line[:pet_mri_time_gap]]
        end
      end

      if !params[:dry_run]
        #actually run the parallel script

        pet_scripts_dir="/mounts/data/analyses/tjbetthauser/MATLAB_Mac/pet_proc_v2b/batch_parallel"

        #for each of the subjects we're about to process, make a directory for that subject_id under the right study in preprocessed
        v_petscan_normal_run.each do |row|
          visit_dir = "#{params[:base_path]}/preprocessed/visits/#{row[:proto]}.#{row[:visit]}/#{row[:enum]}"
          if !File.directory?(visit_dir)
            Dir.mkdir(visit_dir)
          end
        end

        matlab_template = "export MATLABPATH=$MATLABPATH:#{pet_scripts_dir}" + " && matlab -nodesktop -nosplash -r \\\"try %{command}; catch exception; display(getReport(exception)); pause(1); end; exit;\\\""
        matlab_command = matlab_template % {command: "batch_pet_parallel_auto('#{pet_csv}',12,'#{@pettracer.name.downcase}','#{params[:method]}')"}
        v_computer = params[:computer]
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

       # if v_send_email
       #    v_schedule_owner_email_array.each do |e|
       #        v_subject = "Runs:"+@schedule.name 
       #        PandaMailer.send_email(v_subject,{:send_to => e},v_email_body).deliver
       #     end
       # end 
     end
  end
  
  def harvest(params)
  end
  
  def post_harvest(params)
  end

end