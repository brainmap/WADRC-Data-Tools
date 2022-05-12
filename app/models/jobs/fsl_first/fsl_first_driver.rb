class Jobs::FslFirst::FslFirstDriver < Jobs::BaseJob

  attr_accessor :selected
  attr_accessor :driver

  # 2022-05-05 wbbevis -- I'm migrating this in here as the last of the main pipelines that need to leave 
  # shared.rb. 

  def self.default_params
    params = { schedule_name: 'FSL FIRST Driver',
                computer: "moana",
                dry_run: false,
                run_by_user: 'panda_user',
                sp_whitelist: [77],
                processing_output_path: "/mounts/data/development/fsl_first/output",
                processing_executable_path: "singularity run -B /mounts:/mounts /mounts/data/analyses/wbbevis/fsl_test/centos6.10_fsl5.0.10.sif",
                driver_path: "/mounts/data/development/fsl_first/input",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_fsl_first_driver.csv",
                pipeline_id: 2
              }
    params.default = ''
    params
  end

  def self.production_params
    params = { schedule_name: 'FSL FIRST Driver',
                computer: "moana",
                dry_run: false,
                run_by_user: 'panda_user',
                sp_whitelist: [77],
                sp_blacklist: [-1,62,53,54,55,56,57,15,19,17,30,6,13,11,12,32,35,25,23,8,48,16,100],
                processing_output_path: "/mounts/data/pipelines/fsl_first/output",
                processing_executable_path: "singularity run -B /mounts:/mounts /mounts/data/analyses/wbbevis/fsl_test/centos6.10_fsl5.0.10.sif",
                driver_path: "/mounts/data/pipelines/fsl_first/input",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_fsl_first_driver.csv",
                pipeline_id: 2
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

      close(params)
    
    rescue StandardError => error

      @error_log << {:message => "Error (#{error.class}): #{error.message}"}
      close_fail(params, error)

    end
  end

  def setup(params)
    @log.info(@params[:schedule_name]) { "starting setup" }

      @driver = []

    @log.info(@params[:schedule_name]) { "completed setup" }
  end

  def selection(params)
    @log.info(@params[:schedule_name]) { "starting selection" }
    
    @selected = Jobs::FslFirst::Vgroup.joins(:scan_procedures)
                              .where("scan_procedures_vgroups.scan_procedure_id not in (?)",params[:sp_blacklist])
                              .order(id: :desc)

                              # .where("scan_procedures_vgroups.scan_procedure_id in (?)",params[:sp_whitelist])

    @log.info(@params[:schedule_name]) { "completed selection. There are #{@selected.count} Jobs::FslFirst::Vgroup records selected." }
  end

  def filter(params)
    @log.info(@params[:schedule_name]) { "starting filtering" }

    # When filtering out cases here, we need to check for existing outputs in both the old locations (i.e. 
    # /mounts/data/preprocessed/visits/<sp.codename>/<enr.enumber>/first), as well as the new locations
    # (/mounts/data/pipelines/fsl_first/outputs/<sp.codename>/<enr.enumber>/).

    @selected.each do |vgroup|

          if vgroup.scan_procedures.count == 0

            @log.info(@params[:schedule_name]) { JSON.generate({'type' => "exclusion", 'id' => vgroup.id, 'message' => "scan procedures broken for this vgroup"}) }
            @exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "scan procedures broken for this vgroup"}
            next
          end

          if vgroup.enrollments.count == 0

            @log.info(@params[:schedule_name]) { JSON.generate({'type' => "exclusion", 'id' => vgroup.id, 'message' => "vgroup has no enrollments"}) }
            @exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "vgroup has no enrollments"}
            # 2022-05-10 wbbevis -- we can't make a real case here, if there aren't proper enrollments. # Jobs::JobCase.find_or_create_by(:pipeline_id => @params[:pipeline_id], :enrollment_id => vgroup.enrollments.first.id, :scan_procedure_id => vgroup.scan_procedures.first.id, :exclusion_message => "vgroup's primary enrollment has a broken participant link").save
            next
          end

          # we also need the reggie_id for this person, so let's get the participant
          participant = nil
          if !vgroup.enrollments.first.participant_id.nil? and !vgroup.enrollments.first.participant_id.blank?
            participant = Participant.where(:id => vgroup.enrollments.first.participant_id).first
          else

            @log.info(@params[:schedule_name]) { JSON.generate({'type' => "exclusion", 'id' => vgroup.id, 'message' => "vgroup's primary enrollment has a broken participant link"}) }
            @exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "vgroup's primary enrollment has a broken participant link"}

            job_case = Jobs::JobCase.find_or_create_by(:pipeline_id => @params[:pipeline_id], :enrollment_id => vgroup.enrollments.first.id, :scan_procedure_id => vgroup.scan_procedures.first.id)
            job_case.status = "excluded"
            job_case.exclusion_message = "vgroup's primary enrollment has a broken participant link"
            job_case.job_run = @job_run
            job_case.save

            next
          end

          print "."

          if vgroup.old_first_directories.count > 0
            @log.info(@params[:schedule_name]) { JSON.generate({'type' => "processed", 'id' => vgroup.id, 'message' => "Already processed (preprocessed)"}) }
            @exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "Already processed"}
          elsif vgroup.new_first_directories.count > 0
            @log.info(@params[:schedule_name]) { JSON.generate({'type' => "processed", 'id' => vgroup.id, 'message' => "Already processed (pipelines)"}) }
            @exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "Already processed"}
          else

            acpc_niis = vgroup.preprocessed_paths.map{|item| item + "unknown/"}.select{|item| Dir.exists?(item)}.map{|item| Dir.glob(item + "o*.nii")}.flatten

            if acpc_niis.count > 0

              scan_procedure = vgroup.scan_procedures.first
              enrollment = vgroup.enrollments.first

              @log.info(@params[:schedule_name]) { JSON.generate({'type' => "new_record", 'id' => vgroup.id, 'message' => "Enqueueing new record"}) }
              @driver << {:vgroup => vgroup, :enumber => enrollment.enumber, :protocol => scan_procedure.codename, :reggie_id => participant.reggieid}

              job_case = Jobs::JobCase.find_or_create_by(:pipeline_id => @params[:pipeline_id], :enrollment_id => vgroup.enrollments.first.id, :scan_procedure_id => vgroup.scan_procedures.first.id)
              job_case.status = "enqueued"
              job_case.job_run = @job_run
              job_case.save

            else

              @exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "No ACPC file found"}

              job_case = Jobs::JobCase.find_or_create_by(:pipeline_id => @params[:pipeline_id], :enrollment_id => vgroup.enrollments.first.id, :scan_procedure_id => vgroup.scan_procedures.first.id)
              job_case.status = "excluded"
              job_case.exclusion_message = "No ACPC file found"
              job_case.job_run = @job_run
              job_case.save

            end
          end
      end

      @log.info(@params[:schedule_name]) { "completed filtering. There were #{@exclusions.count} excluded from processing. " }
      exclusion_hash = @exclusions.each_with_object(Hash.new(0)){|item, hash| hash[item[:message]] += 1}
      exclusion_hash.keys.each do |key|
        @log.info(@params[:schedule_name]) { "Exclusions: #{key} => #{exclusion_hash[key]}" }
      end

  end

  def write_driver(params)

    @log.info(@params[:schedule_name]) { "starting write_driver" }

    csv = CSV.open("#{params[:driver_path]}/#{params[:driver_file_name]}",'wb')
    csv << ['protocol','enumber','reggie_id']

    @driver.each do |row|
      csv << [row[:protocol],row[:enumber],row[:reggie_id]]
    end

    csv.close

    @log.info(@params[:schedule_name]) { "completed write_driver" }
  end

  def process(params)
    @log.info(@params[:schedule_name]) { "starting processing" }

    if params[:dry_run] == false

      require 'open3'

      # the processing script expects the directories to already be built
      @driver.each do |row|
          proto_dir = "#{params[:processing_output_path]}/#{row[:protocol]}"
          if !File.directory?(proto_dir)

            @log.info(@params[:schedule_name]) { "mkdir #{proto_dir}" }
            Dir.mkdir(proto_dir)
          end

          visit_dir = "#{params[:processing_output_path]}/#{row[:protocol]}/#{row[:enumber]}"
          if !File.directory?(visit_dir)

            @log.info(@params[:schedule_name]) { "mkdir #{visit_dir}" }
            Dir.mkdir(visit_dir)
          end
      end

      @driver.each do |row|

        enrollment = Enrollment.where(:enumber => row[:enumber]).first
        scan_procedure = ScanProcedure.where(:codename => row[:protocol]).first

        @log.info(@params[:schedule_name]) { "processing #{row[:protocol]} #{row[:enumber]} to #{params[:processing_output_path]}/#{row[:protocol]}/#{row[:enumber]}/" }
        fsl_command = "#{params[:processing_executable_path]} -p #{row[:protocol]} -b #{row[:enumber]} -o #{params[:processing_output_path]}/#{row[:protocol]}/#{row[:enumber]}/"
        
        processing_call =  "ssh panda_user@#{params[:computer]}.dom.wisc.edu \"#{fsl_command}\""

        @log.info(@params[:schedule_name]) { processing_call }

        begin
          job_case = Jobs::JobCase.find_or_create_by(:pipeline_id => @params[:pipeline_id], :enrollment_id => enrollment.id, :scan_procedure_id => scan_procedure.id)
          job_case.job_run = @job_run
          job_case.status = "started"
          job_case.save

          stdin, stdout, stderr = Open3.popen3(processing_call)

          while !stdout.eof?
            v_output = stdout.read 1024  
            # puts v_output
            @log.info(@params[:schedule_name]) { v_output.to_s}
              
          end

          job_case.status = "processed"
          job_case.save

        rescue => msg  
          @log.error(@params[:schedule_name]) { msg.to_s }
          @error_log << msg.to_s

          job_case = Jobs::JobCase.find_or_create_by(:pipeline_id => @params[:pipeline_id], :enrollment_id => enrollment.id, :scan_procedure_id => scan_procedure.id)
          job_case.job_run = @job_run
          job_case.status = "error"
          job_case.failure_message = msg.to_s
          job_case.save

        end

      end
    end

    @log.info(@params[:schedule_name]) { "completed processing" }
  end
end