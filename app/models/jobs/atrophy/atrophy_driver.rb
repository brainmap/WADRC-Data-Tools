class Jobs::Atrophy::AtrophyDriver < Jobs::BaseJob

  attr_accessor :ok_paths_and_not_processed_before
  attr_accessor :total_scans_considered
  attr_accessor :selected
  attr_accessor :driver

  def self.default_params
    params = { schedule_name: 'CAT12 Atrophy Pipeline Driver',
                base_path: "/mounts/data", 
                computer: "kanga",
                dry_run: false,
                run_by_user: 'panda_user',
                code_ver: 'b42e83aa',
                exclude_sp_mri_array: [-1,100,80,76,78],
                date_cutoff: '2018-10-11',
                csv_headers: ['scan_procedure','enrollment','ACPC_T1_path', 'processing_flag'],
                driver_path: "/mounts/data/analyses/wbbevis/atrophy/",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_atrophy_driver.csv",
                processing_output_path: "/mounts/data/development/atrophy/output",
                processing_input_path: "/mounts/data/development/atrophy/input",
                processing_executable_path: "/mounts/data/development/atrophy/src/run_atrophy.sh",
                special_flag: nil
              }
    params.default = ''
    params
  end

  def self.production_params
    params = { schedule_name: 'CAT12 Atrophy Pipeline Driver',
                base_path: "/mounts/data", 
                computer: "moana",
                dry_run: false,
                run_by_user: 'panda_user',
                code_ver: 'b42e83aa',
                exclude_sp_mri_array: [-1,100,80,76,78],
                date_cutoff: '2015-06-01',
                csv_headers: ['scan_procedure','enrollment','ACPC_T1_path', 'processing_flag'],
                driver_path: "/mounts/data/analyses/wbbevis/atrophy/",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_atrophy_driver.csv",
                processing_output_path: "/mounts/data/pipelines/atrophy/output",
                processing_input_path: "/mounts/data/pipelines/atrophy/input",
                processing_executable_path: "/mounts/data/pipelines/atrophy/src/run_atrophy.sh",
                special_flag: nil
              }
    params.default = ''
    params
  end

  def run(params)

    begin
      setup(params)

      selection(params)

      filter(params)

      write_driver(params)

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
    @selected = Jobs::Atrophy::Visit.joins("LEFT JOIN appointments on appointments.id = visits.appointment_id")
                              .joins("LEFT JOIN vgroups on appointments.vgroup_id = vgroups.id")
                              .joins("LEFT JOIN scan_procedures_vgroups ON vgroups.id = scan_procedures_vgroups.vgroup_id")
                              .where("scan_procedures_vgroups.scan_procedure_id not in (?)", params[:exclude_sp_mri_array])
                              .where("appointments.appointment_date > ?",params[:date_cutoff])
                              .order(id: :desc).uniq

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

          acpc_path = nil
          if visit.preprocessed_dir_exists?
            acpc_candidates = Dir.entries(visit.preprocessed_dir).select { |f| f.start_with?("o") and f.end_with?(".nii") }
            if acpc_candidates.count == 1
              acpc_path = "#{visit.preprocessed_dir}/#{acpc_candidates.first}"
            elsif acpc_candidates.count == 0

              # before we give up, we should see if there are 2ndary scans for this person's visit, and look to see if there are viable scans in there
              if visit.secondary_dir_exists?

                secondaries = visit.secondary_dirs
                secondaries.each do |secondary|
                  acpc_candidates = Dir.entries(secondary).select { |f| f.start_with?("o") and f.end_with?(".nii") }
                  if acpc_candidates.count == 1
                    acpc_path = "#{preprocessed_path}/#{acpc_candidates.first}"

                  elsif acpc_candidates.count == 0
                    self.exclusions << {:scan_procedures => visit.appointment.vgroup.scan_procedures.map(&:codename).join(','), :enrollments => visit.appointment.vgroup.enrollments.map(&:enumber).join(','), :id => visit.id, :message => "no o*.nii files for this visit"}
                    next
                  else
                    self.exclusions << {:scan_procedures => visit.appointment.vgroup.scan_procedures.map(&:codename).join(','), :enrollments => visit.appointment.vgroup.enrollments.map(&:enumber).join(','), :id => visit.id, :message => "too many o*.nii files for this visit"}
                    next
                  end
                end

              else
                self.exclusions << {:scan_procedures => visit.appointment.vgroup.scan_procedures.map(&:codename).join(','), :enrollments => visit.appointment.vgroup.enrollments.map(&:enumber).join(','), :id => visit.id, :message => "no o*.nii files for this visit"}
                next
              end
            else
              self.exclusions << {:scan_procedures => visit.appointment.vgroup.scan_procedures.map(&:codename).join(','), :enrollments => visit.appointment.vgroup.enrollments.map(&:enumber).join(','), :id => visit.id, :message => "too many o*.nii files for this visit"}
              next
            end
          else
            self.exclusions << {:scan_procedures => visit.appointment.vgroup.scan_procedures.map(&:codename).join(','), :enrollments => visit.appointment.vgroup.enrollments.map(&:enumber).join(','), :id => visit.id, :message => "no proprocessed directory for this visit"}
            next
          end

          #finally, if this case has already been run, don't rerun it.
          processing_path = "#{params[:processing_output_path]}/#{scan_procedure.codename}/#{enrollment.enumber}/"
          if File.exists?(processing_path) and File.directory?(processing_path) and Dir.entries(processing_path).select{|item| item =~ /^[^.]/}.count > 0
            self.exclusions << {:scan_procedures => visit.appointment.vgroup.scan_procedures.map(&:codename).join(','), :enrollments => visit.appointment.vgroup.enrollments.map(&:enumber).join(','), :id => visit.id, :message => "already processed"}
            next
          end

          if acpc_path.nil?
            self.exclusions << {:scan_procedures => visit.appointment.vgroup.scan_procedures.map(&:codename).join(','), :enrollments => visit.appointment.vgroup.enrollments.map(&:enumber).join(','), :id => visit.id, :message => "failed to find an acpc file for this case. does one exist?"}
            next
          end

          # dereference the paths, in case I've actually found symlinks
          if File.symlink?(acpc_path)
            acpc_path = File.realpath(acpc_path)
            if !File.exists?(acpc_path)
              self.exclusions << {:scan_procedures => visit.appointment.vgroup.scan_procedures.map(&:codename).join(','), :enrollments => visit.appointment.vgroup.enrollments.map(&:enumber).join(','), :id => visit.id, :message => "symlink to acpc file is broken"}
              next
            end
          end

          @driver << {:visit => visit, :acpc_path => acpc_path, :scan_procedure => scan_procedure.codename, :enrollment => enrollment}

      end
  end

  def write_driver(params)

    csv = CSV.open("#{params[:processing_input_path]}/#{params[:driver_file_name]}",'wb')
    csv << params[:csv_headers]
    @driver.each do |row|

      out = [row[:scan_procedure],
              row[:enrollment].enumber,
              row[:acpc_path],
              params[:special_flag].to_s]

      csv << out
    end

    csv.close

    # This is a kluge to try to get the file permissions readable by panda_user on each of the 
    # processing machines. "panda_user" on the network is different from "panda_user" on the 
    # old Panda server. 
    FileUtils.chown 'panda_user', 10513, "#{params[:processing_input_path]}/#{params[:driver_file_name]}"

  end


  def process(params)

    if params[:dry_run] == false

      require 'open3'

      command = "#{params[:processing_executable_path]} #{params[:processing_input_path]}/#{params[:driver_file_name]}"
      
      processing_call =  "ssh panda_user@#{params[:computer]}.dom.wisc.edu \"#{command}\""

      self.log << {:message => processing_call}
      # We don't have the "save_with_logs" on old Panda. :(
      # self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)

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