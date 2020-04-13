class Jobs::Pet::ParallelPetPibPostQc < Jobs::Pet::ParallelPetPibSuvr

  attr_accessor :petscan_normal_run
  attr_accessor :petscan_nearby_t1
  attr_accessor :ok_paths_and_not_processed_before
  attr_accessor :pettracer
  attr_accessor :preprocessed_tracer_path
  attr_accessor :neighbor_dvr_tracer_path
  attr_accessor :total_scans_considered
  attr_accessor :petscans
  attr_accessor :error_no_recent_acpc
  attr_accessor :time_gap_failures
  attr_accessor :driver

  def self.default_params
  	params = { schedule_name: 'parallel_pet_pib_suvr_process',
  				      base_path: "/mounts/data", 
                computer: "kanga",
                comment: [],
                dry_run: false,
                tracer_id: "1",
                method: "suvr",
                comment_warning: "",
                run_by_user: 'panda_user',
                days_mri_pet_diff_limit: "730",
                exclude_sp_mri_array: [-1,100,80,76,78],
                exclude_sp_pet_array: [-1,100] 
              }
    params.default = ''
    params
  end

  def setup(params)


      #this will eventually be populated with the petscans that we can't process, organized by scan_procedure.codename, and subject_id

      @pettracer = LookupPettracer.where("id = ?",params[:tracer_id]).first

      @preprocessed_tracer_path = "/pet/#{@pettracer.name.downcase}/#{params[:method]}/code_ver2b"
      # @schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
      @neighbor_dvr_tracer_path = "/pet/#{@pettracer.name.downcase}/dvr/code_ver2b"

      @total_scans_considered = 0
      @ok_paths_and_not_processed_before = []
      @error_no_recent_acpc = []
      @driver = []

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

          v_participant = nil
          if !v_pet_appointment.vgroup_id.nil?
            vgroup = Vgroup.find(v_pet_appointment.vgroup_id)
            if !vgroup.participant_id.nil?
              v_participant = Participant.find(vgroup.participant_id)

            else
              self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"vgroup had a broken participant_id\"}"
              next
            end
          else
            self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"appointment had a broken vgroup_id\"}"
            next
          end


          print "."

          orig_t1_mri_path = ''
          multispectral_file_path = ''
          
          if pet_appt.paths_ok? and !pet_appt.preprocessed_dir_exists?(@preprocessed_tracer_path)
            if pet_appt.related_enumber.nil? or pet_appt.related_scan_procedure.nil?
              self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"appointment had broken relations to enrollment or scan procedures\"}"
              next
            end

            @ok_paths_and_not_processed_before << [:protocol => pet_appt.related_scan_procedure.codename, :subject_id => pet_appt.related_enumber.enumber]
            #first check under this visit's preprocessed/visits folder to see if an o_acpc.nii file exits
            if pet_appt.preprocessed_dir_exists?(@neighbor_dvr_tracer_path)
              #find any tracker records for files in the DVR dir 
              neighbor_dvr_images = Processedimage.where("file_path like ?","%#{pet_appt.preprocessed_dir(@neighbor_dvr_tracer_path)}%")

              if neighbor_dvr_images.count > 0
                tracker = Trfileimage.where(:image_id => neighbor_dvr_images.first.id, :image_category => 'processedimage')
                qc_value = tracker.first.trfile.qc_value

                if qc_value == "Pass"

                  pet_dvr_directory = File.dirname(neighbor_dvr_images.first.file_path)

                  log_file_name = Dir.entries(pet_dvr_directory).select{|entry| entry =~ /panda-log/}.first

                  if log_file_name.nil?
                    #there's no log file in this dir? make an error

                    # add_to_error_report(v_error_report,pet_appt)
                    # v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["no_dvr_panda_log"] = pet_appt
                    # v_error_report[pet_appt.related_scan_procedure.codename][pet_appt.related_enumber.enumber]["participant_id"] = pet_appt.related_participant.id

                    self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"no dvr panda-log for this petscan\"}"
                    next
                  else

                    log_file_path = pet_dvr_directory + '/' + log_file_name

                    log_file_data = Hash.new("")
                    CSV.foreach(log_file_path, :headers => true) do |row|
                      log_file_data[row["Description"]] = row["Value"].to_s.strip
                    end

                    orig_t1_mri_path = log_file_data['original t1 MRI file']
                    multispectral_file_path = log_file_data['multispectral file']

                  end
                else
                  self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"dvr didnt pass QC\"}"
                  next
                end
              else
                self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"no dvr, no suvr\"}"
                next
              end
            else
              self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"no dvr, no suvr\"}"
              next
            end

            if params[:method] == 'suvr'

              if !orig_t1_mri_path.blank? && !multispectral_file_path.blank? && !pet_appt.scanstarttime.nil? && !pet_appt.injecttiontime.nil?
                v_uptake_duration = ((pet_appt.scanstarttime - pet_appt.injecttiontime)/60).floor
                # puts "uptake duration = (start time #{pet_appt.scanstarttime} - injection time #{pet_appt.injecttiontime}) / 60 = #{v_uptake_duration}"
                # if (v_uptake_duration.to_i).between?(65,75)

                  # In the case of PiB, uptake duration can be zero, no prob. We don't want to exclude these people in that case.

                  # we're finally happy with all of the params we need, and we can make a csv for parallel processing

                  proto = pet_appt.related_scan_procedure.protocol.path.split('.')[0..1].join('.')
                  #visit = pet_appt.related_scan_procedure.codename.remove(pet_appt.related_scan_procedure.protocol.path)
                  visit = pet_appt.related_scan_procedure.codename.remove(proto).remove(".")

                  @driver << {:proto => proto, :visit => visit, :enum => pet_appt.related_enumber.enumber, :t_uptake => v_uptake_duration, :file_t1 => orig_t1_mri_path, :file_mult => multispectral_file_path, :norm_samp => 1.0}
                  self.outputs << "{\"class\":\"#{pet_appt.class}\", \"id\":\"#{pet_appt.id}\", \"t_uptake\":\"#{v_uptake_duration}\", \"file_t1\":\"#{orig_t1_mri_path}\", \"file_mult\":\"#{multispectral_file_path}\", \"norm_samp\":\"1.0\"}"
              end
            end

          else
            if !pet_appt.paths_ok?
              self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"paths not ok\"}"
              next
            elsif pet_appt.preprocessed_dir_exists?(@preprocessed_tracer_path)
              self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"already processed\"}"
              next
            end
            #try paths_ok!, and catch errors to categorize our petfile failures
            if pet_appt.related_scan_procedure.nil? or pet_appt.related_enumber.nil?
              #@error_appt_weirdness << {:pet_id => pet_appt.id}
              self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"Just weird: #{e.message}\"}"
              next
            end
            begin
              pet_appt.paths_ok!
            rescue Exceptions::PetscanNoEcatsError => e

              self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"no ecat files\"}"
              next
            rescue Exceptions::PetscanTooManyEcatsError => e

              self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"too many ecat files\"}"
              next
            rescue Exceptions::PetscanError, Exceptions::PetscanPathError => e

              self.exclusions << "{\"class\":\"#{pet_appt.class}\",\"id\":\"#{pet_appt.id}\",\"message\":\"Just weird: #{e.message}\"}"
              next
            end
          end
      end
  end

end