class Jobs::Lst::LstLpaDriver < Jobs::BaseJob

  attr_accessor :ok_paths_and_not_processed_before
  attr_accessor :total_scans_considered
  attr_accessor :selected
  attr_accessor :driver

  def self.default_params
    params = { schedule_name: 'LST/LPA Pipeline Driver',
                base_path: "/mounts/data", 
                computer: "kanga",
                dry_run: false,
                run_by_user: 'panda_user',
                exclude_sp_mri_array: [-1,100,80,76,78],
                date_cutoff: '2018-10-11',
                csv_headers: ['scan_procedure','enrollment','ACPC_T1_path','T2_FLAIR', 'FLAIR_incomplete_series',
                        'FLAIR_garbled_series_comment','FLAIR_garbled_series','FLAIR_garbled_series_comment',
                        'FLAIR_fov_cutoff', 'FLAIR_fov_cutoff_comment', 'FLAIR_field_inhomogeneity','FLAIR_field_inhomogeneity_comment',
                        'FLAIR_ghosting_wrapping', 'FLAIR_ghosting_wrapping_comment', 'FLAIR_banding','FLAIR_banding_comment',
                        'FLAIR_registration_risk', 'FLAIR_registration_risk_comment', 'FLAIR_motion_warning', 'FLAIR_motion_warning_comment',
                        'FLAIR_omnibus_f', 'FLAIR_omnibus_f_comment', 'FLAIR_spm_mask','FLAIR_spm_mask_comment', 'FLAIR_nos_concerns',
                        'FLAIR_nos_concerns_comment','FLAIR_other_issues'],
                driver_path: "/mounts/data/analyses/wbbevis/lst_lpa/",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_lst_lpa_driver.csv",
                processing_output_path: "/mounts/data/development/lstlpa/output",
                processing_input_path: "/mounts/data/development/lstlpa/input",
                processing_executable_path: "/mounts/data/development/lstlpa/src/run_lpa.sh",
              }
    params.default = ''
    params
  end

  def self.production_params
    params = { schedule_name: 'LST/LPA Pipeline Driver',
                base_path: "/mounts/data", 
                computer: "kanga",
                dry_run: false,
                run_by_user: 'panda_user',
                exclude_sp_mri_array: [-1,100,80,76,78],
                date_cutoff: '2018-10-11',
                csv_headers: ['scan_procedure','enrollment','ACPC_T1_path','T2_FLAIR', 'FLAIR_incomplete_series',
                        'FLAIR_garbled_series_comment','FLAIR_garbled_series','FLAIR_garbled_series_comment',
                        'FLAIR_fov_cutoff', 'FLAIR_fov_cutoff_comment', 'FLAIR_field_inhomogeneity','FLAIR_field_inhomogeneity_comment',
                        'FLAIR_ghosting_wrapping', 'FLAIR_ghosting_wrapping_comment', 'FLAIR_banding','FLAIR_banding_comment',
                        'FLAIR_registration_risk', 'FLAIR_registration_risk_comment', 'FLAIR_motion_warning', 'FLAIR_motion_warning_comment',
                        'FLAIR_omnibus_f', 'FLAIR_omnibus_f_comment', 'FLAIR_spm_mask','FLAIR_spm_mask_comment', 'FLAIR_nos_concerns',
                        'FLAIR_nos_concerns_comment','FLAIR_other_issues'],
                driver_path: "/mounts/data/analyses/wbbevis/lst_lpa/",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_lst_lpa_driver.csv",
                processing_output_path: "/mounts/data/pipelines/lstlpa/output",
                processing_input_path: "/mounts/data/pipelines/lstlpa/input",
                processing_executable_path: "/mounts/data/pipelines/lstlpa/src/run_lpa.sh",
              }
    params.default = ''
    params
  end

  def run(params)

    begin
      setup(params)

      selection(params)

      filter(params)

      process(params)

      final_pass(params)

      close(params)
    
    rescue StandardError => error

      self.error_log << {:message => "Error (#{error.class}): #{error.message}"}
      close_fail(params, error)

    end
  end

  def setup(params)

      @total_scans_considered = 0
      @ok_paths_and_not_processed_before = []
      @driver = []

  end

  def selection(params)
    # we're looking at all of the MRI visits from any protocol that isn't on the blacklist
    @selected = Jobs::Lst::Visit.joins("LEFT JOIN appointments on appointments.id = visits.appointment_id")
                              .joins("LEFT JOIN vgroups on appointments.vgroup_id = vgroups.id")
                              .joins("LEFT JOIN scan_procedures_vgroups ON vgroups.id = scan_procedures_vgroups.vgroup_id")
                              .where("appointments.appointment_date > ?",params[:date_cutoff])
                              .order(id: :desc)

  end

  def filter(params)

    @selected.each do |visit|

          @total_scans_considered += 1

          vgroup = visit.appointment.vgroup

          #first let's get the primary scan_procedure, and the enrollment

          scan_procedure = visit.related_scan_procedure
          if scan_procedure.nil?
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "scan procedures broken for this visit"}
            next
          end

          enrollment = visit.related_enrollment
          if enrollment.nil?
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "vgroup has no enrollments"}
            next
          end

          print "."

          # t2_candidates = visit.image_datasets.select{|image| (image.series_description =~ /ORIG/).nil? and (image.series_description =~ /FLAIR/i) and (image.series_description =~ /T2/)}

          t2_candidates = visit.image_datasets.select{|image| (image.series_description =~ /ORIG/).nil? and ((image.series_description =~ /SAG Cube T2 FLAIR/) 
                                                                                                            or (image.series_description =~ /Sag T2 FLAIR Cube/)
                                                                                                            or (image.series_description =~ /Sag CUBE T2FLAIR/)
                                                                                                            or (image.series_description =~ /Sag CUBE flair/))}
          t2_file = nil
          if t2_candidates.count == 1
            t2_file = t2_candidates.first
          elsif t2_candidates.count == 0
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "no T2 FLAIR image for this visit"}
            next
          else

            #if we've got 2, we need to see if one has been marked as the default for this visit.

            marked_as_default = t2_candidates.select{|item| item.use_as_default_scan_flag == 'Y'}
            if marked_as_default.count == 1
              t2_file = marked_as_default.first
            else
              # if we can't decide which one to use, we should fail the case
              self.exclusions << {:class => visit.class, :id => visit.id, :message => "too many T2 FLAIR images for this visit"}
            next
          end

          # Here, we actually need an nii file from preprocessed/visits. The path from the image_dataset is in raw.
          # So, let's see if we can find the .nii.

          t2_nii_path = ''
          if !t2_file.nil?

            preprocessed_path = "#{params[:base_path]}/preprocessed/visits/#{scan_procedure.codename}/#{enrollment.enumber}/unknown"
            series_description_re = Regexp.new("#{t2_file.series_description.gsub(/ /,'[-_ ]')}\\w*.nii","i")

            if !File.exist?(preprocessed_path) or !File.directory?(preprocessed_path)
              self.exclusions << {:class => visit.class, :id => visit.id, :message => "no preprocessed path, or doesn't exist"}
              next
            end

            t2_nii_candidates = Dir.entries(preprocessed_path).select{|img| (img =~ series_description_re) and !(img =~ /ORIG/)}

            if t2_nii_candidates.count == 1
              t2_nii_path = "#{preprocessed_path}/#{t2_nii_candidates.first}"
            elsif t2_nii_candidates.count == 0

              # before we give up, we should see if there are 2ndary scans for this person's visit, and look to see if there are viable scans in there
              if visit.secondary_dir_exists?

                secondaries = visit.seconday_dirs
                secondaries.each do |secondary|
                  t2_nii_candidates = Dir.entries(secondary).select{|img| (img =~ series_description_re) and !(img =~ /ORIG/)}
                  if t2_nii_candidates.count == 1
                    t2_nii_path = "#{preprocessed_path}/#{t2_nii_candidates.first}"
                  elsif t2_nii_candidates.count == 0
                    self.exclusions << {:class => visit.class, :id => visit.id, :message => "no T2 FLAIR nii for this visit in preprocessed"}
                    next
                  else
                    self.exclusions << {:class => visit.class, :id => visit.id, :message => "too many T2 FLAIR nii for this visit in preprocessed"}
                    next
                  end
                end

              else

                self.exclusions << {:class => visit.class, :id => visit.id, :message => "no T2 FLAIR nii for this visit in preprocessed"}
                next
              end
            else
              self.exclusions << {:class => visit.class, :id => visit.id, :message => "too many T2 FLAIR nii for this visit in preprocessed"}
              next
            end

          end


          acpc_path = nil
          if visit.preprocessed_dir_exists?
            acpc_candidates = Dir.entries(visit.preprocessed_dir).select { |f| f.start_with?("o") and f.end_with?(".nii") }
            if acpc_candidates.count == 1
              acpc_path = "#{visit.preprocessed_dir}/#{acpc_candidates.first}"
            elsif acpc_candidates.count == 0

              # before we give up, we should see if there are 2ndary scans for this person's visit, and look to see if there are viable scans in there
              if visit.secondary_dir_exists?

                secondaries = visit.seconday_dirs
                secondaries.each do |secondary|
                  acpc_candidates = Dir.entries(secondary).select { |f| f.start_with?("o") and f.end_with?(".nii") }
                  if acpc_candidates.count == 1
                    acpc_path = "#{preprocessed_path}/#{acpc_candidates.first}"

                  elsif acpc_candidates.count == 0
                    self.exclusions << {:class => visit.class, :id => visit.id, :message => "no o*.nii files for this visit"}
                    next
                  else
                    self.exclusions << {:class => visit.class, :id => visit.id, :message => "too many o*.nii files for this visit"}
                    next
                  end
                end

              else
                self.exclusions << {:class => visit.class, :id => visit.id, :message => "no o*.nii files for this visit"}
                next
              end
            else
              self.exclusions << {:class => visit.class, :id => visit.id, :message => "too many o*.nii files for this visit"}
              next
            end
          else
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "no proprocessed directory for this visit"}
            next
          end

          @driver << {:visit => visit, :t2_ids => t2_file, :t2_nii_path => t2_nii_path, :acpc_path => acpc_path, :scan_procedure => scan_procedure.codename, :enrollment => enrollment}

      end
  end

  def write_driver(params)

    csv = CSV.open("#{params[:processing_input_path]}/#{params[:driver_file_name]}",'wb')
    csv << params[:csv_headers]
    @driver.each do |row|

      t2_quality_check = row[:t2_ids].image_dataset_quality_checks.last

      out = [row[:scan_procedure],
              row[:enrollment].enumber,
              row[:acpc_path],
              row[:t2_nii_path],

              !t2_quality_check.nil? ? t2_quality_check.incomplete_series : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.incomplete_series_comment : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.garbled_series : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.garbled_series_comment : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.fov_cutoff : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.fov_cutoff_comment : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.field_inhomogeneity : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.field_inhomogeneity_comment : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.ghosting_wrapping : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.ghosting_wrapping_comment : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.banding : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.banding_comment : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.registration_risk : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.registration_risk_comment : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.motion_warning : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.motion_warning_comment : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.omnibus_f : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.omnibus_f_comment : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.spm_mask : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.spm_mask_comment : "NULL", 
              !t2_quality_check.nil? ? t2_quality_check.nos_concerns : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.nos_concerns_comment : "NULL",
              !t2_quality_check.nil? ? t2_quality_check.other_issues : "NULL"]

      csv << out
    end

    csv.close

  end


  def process(params)

    if params[:dry_run] == false

      require 'open3'

      # the processing script expects the directories to already be built
      @driver.each do |row|
          proto_dir = "#{params[:processing_output_path]}/#{row[:scan_procedure]}"
          if !File.directory?(proto_dir)
            Dir.mkdir(proto_dir)
          end

          visit_dir = "#{params[:processing_output_path]}/#{row[:scan_procedure]}/#{row[:enrollment].enumber}"
          if !File.directory?(visit_dir)
            Dir.mkdir(visit_dir)
          end
      end

      command = "#{params[:processing_executable_path]} #{params[:processing_input_path]}/#{params[:driver_file_name]}"
      
      processing_call =  "ssh panda_user@#{params[:computer]}.dom.wisc.edu \"#{command}\""

      self.log << {:message => processing_call}
      self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)

      begin
        stdin, stdout, stderr = Open3.popen3(processing_call)

        while !stdout.eof?
          v_output = stdout.read 1024  
          # puts v_output
          self.log << {:message => v_output.to_s}

          err_output = stderr.read 1024
          if err_output != ''
            self.error_log << {:message => err_output.to_s}
          end
            
        end

      rescue => msg  
        self.log << {:message => msg.to_s}
      end

    end
  end

end