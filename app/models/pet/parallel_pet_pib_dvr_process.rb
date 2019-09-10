class Pet::ParallelPetPibDvrProcess < Pet::PetBase

    attr_accessor :petscan_normal_run

    def self.default_params
  	  # - set up params
  	  params = { schedule_name: 'parallel_pet_pib_dvr_process',
  				       base_path: Shared.get_base_path(), 
      			     computer: "kanga",
      			     comment: [],
              	 dry_run: false,
                 tracer_id: "1",
                 comment_warning: "",
                 preprocessed_tracer_path: "/pet/pib/dvr/code_ver2b",
                 reprocessing: false,
                 initial_processing: true
                }
      params.default = ''
      params
    end

    def run(p=@params)

      v_comment = ""
      v_comment_warning ="" 

      v_days_mri_pet_diff_limit = "730"
      v_exclude_sp_mri_array = [-1,100,80,76,78]
      v_exclude_sp_pet_array = [80,100,115]

      #good pet scans
      v_petscan_normal_run = []
      v_petscan_nearby_t1 = []

      #bad pet scans
      v_error_no_recent_acpc = []
      v_error_no_multispectral = []
      v_error_bad_uptake_duration = []
      v_error_multiple_t1 = []
      v_error_no_ecats = []
      v_error_too_many_ecats = []
      v_error_just_weird = []

      v_pettracer = LookupPettracer.where("id = ?",p[:tracer_id]).first
      v_pet_processing_wrapper = "/mounts/data/analyses/tjbetthauser/MATLAB_Mac/pet_proc_v2b/batch_parallel/batch_pet_parallel_auto.m"

      v_schedule_owner_email_array = get_schedule_owner_email(@schedule.id)

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
                  and scan_procedures_vgroups.scan_procedure_id in (?))",p[:tracer_id],v_exclude_sp_pet_array)

  		# - for each petscan on that list, do:

      v_pib_petscans.each do |pet_appt|
          v_enumber = ""
          v_scan_procedure = ""
          v_subjectid = ""
          v_scan_procedure_codename = ""
          v_subjectid_pet_pib_processed_path = ""

          v_multiple_petfiles = false
          v_petfile_exists = false
          v_pet_path_ok = false

          v_pet_appointment = Appointment.find(pet_appt.appointment_id)
          v_pet_date_string =(v_pet_appointment.appointment_date).to_s
          v_participant = Participant.find(Vgroup.find(v_pet_appointment.vgroup_id).participant_id)
          v_pib_petfiles = Petfile.where("petscan_id in (?)",pet_appt.id)
          puts "v_participant.id="+v_participant.id.to_s

          o_acpc_file_path = ''
          multispectral_file_path = ''
          
          #we want to be sure that the paths are ok, and:
          # if we're initial_processing that our preprocessed dir doesn't exist, or
          # if we're reprocessing, that our preprocessed dir does exist
          #if pet_appt.paths_ok? and ((p[:initial_processing] == true and !pet_appt.preprocessed_dir_exists?(p[:preprocessed_tracer_path])) or (p[:reprocessing] == true and pet_appt.preprocessed_dir_exists?(p[:preprocessed_tracer_path])))
          if pet_appt.paths_ok? and !pet_appt.preprocessed_dir_exists?(p[:preprocessed_tracer_path])
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
                v_error_no_recent_acpc << pet_appt
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
                v_error_no_multispectral << pet_appt
              end
            end

            if !o_acpc_file_path.blank? && !multispectral_file_path.blank?
              # we're finally happy with all of the params we need, and we can make a csv for parallel processing

              proto = pet_appt.related_scan_procedure.protocol.path.split('.')[0..1].join('.')
              visit = pet_appt.related_scan_procedure.codename.remove(proto+'.visit')

              v_petscan_normal_run << {:proto => proto, :visit => visit, :enum => pet_appt.related_enumber.enumber, :file_t1 => o_acpc_file_path, :file_mult => multispectral_file_path, :norm_samp => 1.0}

            end

          else
            #try paths_ok!, and catch errors to categorize our petfile failures
            begin
              pet_appt.paths_ok!
            rescue Exceptions::PetscanNoEcatsError => e
              v_error_no_ecats << {:scan => pet_appt, :message => e.message}
            rescue Exceptions::PetscanTooManyEcatsError => e
              v_error_too_many_ecats << {:scan => pet_appt, :message => e.message}
            rescue Exceptions::PetscanError, Exceptions::PetscanPathError => e
              v_error_just_weird << {:scan => pet_appt, :message => e.message}
            end
          end
      end


      #write out the csv
      require 'csv'
      pet_csv = "/mounts/data/preprocessed/logs/parallel_driver/#{Date.today.strftime("%Y-%m-%d")}_parallel_pet_pib_dvr_driver.csv"
      CSV.open(pet_csv, 'wb', row_sep: "\r\n", encoding: "UTF-8") do |writer|
        #header
        writer << ["protocol", "visit", "enum", "file_t1", "file_mult", "norm_samp"].map{|s| s.encode("UTF-8")}

        #data
        #v_petscan_normal_run.each do |row|
        v_petscan_normal_run.each do |row|
          writer << [row[:proto], row[:visit], row[:enum], row[:file_t1], row[:file_mult], row[:norm_samp]].map{|s| s.to_s.encode("UTF-8")}
        end
      end

      #run the processing, and pass the csv name as a param

      #report this run in the email
      v_send_email = false
      v_email_body = ""

      if p[:dry_run]

        @petscan_normal_run = v_petscan_normal_run

        if v_petscan_normal_run.length > 0
          puts "\n\nnormal pet_pib_suvr_processing: "
          v_petscan_normal_run.each do |val|
            puts "#{val[:proto]}, #{val[:visit]}, #{val[:enum]}, #{val[:file_t1]}, #{val[:file_mult]}, #{val[:norm_samp]}"
          end
        else
          puts "\nwe didn't find any normal pet scans"
        end

        if v_error_no_recent_acpc.length > 0
          puts "\n\nerrors: no recent acpc file: "
          v_error_no_recent_acpc.each do |val|
            puts "#{val.pet_path}"
          end
        else
          puts "\nno scans were without recent acpc files"
        end

        if v_error_no_multispectral.length > 0
          puts "\n\nerrors: no multispectral file: "
          v_error_no_multispectral.each do |val|
            puts "#{val.pet_path}"
          end
        else
          puts "\nno scans were without multispectral files"
        end

        if v_error_bad_uptake_duration.length > 0
          puts "\n\nerrors: bad uptake duration: "
          v_error_bad_uptake_duration.each do |val|
            puts "#{val[:scan].pet_path}"
          end
        else
          puts "\nno scans had bad uptake duration"
        end

        if v_error_multiple_t1.length > 0
          puts "\n\nerrors: too many T1 (o_acpc.nii) files: "
          v_error_multiple_t1.each do |val|
            puts "#{val.pet_path}"
          end
        else
          puts "\nno scans with too many o_acpc.nii files"
        end

        if v_error_no_ecats.length > 0
          puts "\n\nerrors: no ecat files: "
          v_error_no_ecats.each do |val|
            puts "#{val[:scan].pet_path} (#{val[:message]})"
          end
        else
          puts "\neverybody had ecat files"
        end

        if v_error_too_many_ecats.length > 0
          puts "\n\nerrors: too many ecat files: "
          v_error_too_many_ecats.each do |val|
            puts "#{val[:scan].pet_path} (#{val[:message]})"
          end
        else
          puts "\neverybody had the right number of ecat files"
        end

        if v_error_just_weird.length > 0
          puts "\n\nerrors: oddballs: "
          v_error_just_weird.each do |val|
            puts "#{val[:scan].pet_path} (#{val[:message]})"
          end
        else
          puts "\nno oddballs"
        end



      else
        #actually run the parallel script

        pet_scripts_dir="/mounts/data/analyses/tjbetthauser/MATLAB_Mac/pet_proc_v2b/batch_parallel"

        #for each of the subjects we're about to process, make a directory for that subject_id under the right study in preprocessed
        v_petscan_normal_run.each do |row|
          visit_dir = "#{p[:base_path]}/preprocessed/visits/#{row[:proto]}.visit#{row[:visit]}/#{row[:enum]}"
          if !File.directory?(visit_dir)
            Dir.mkdir(visit_dir)
          end
        end

        matlab_template = "export MATLABPATH=$MATLABPATH:#{pet_scripts_dir}" + " && matlab -nodesktop -nosplash -r \\\"try %{command}; catch exception; display(getReport(exception)); pause(1); end; exit;\\\""
        matlab_command = matlab_template % {command: "batch_pet_parallel_auto('#{pet_csv}',12,'pib','dvr')"}
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
