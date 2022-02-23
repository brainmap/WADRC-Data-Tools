class Jobs::ASL::ASLDriver < Jobs::BaseJob

  attr_accessor :selected
  attr_accessor :driver

  # These Job classes are designed around a "service object" pattern that's useful for 
  # jobs we run regularly. Service objects tend to be organized so that you can tell 
  # them to do their job with something like `job.run(params)`. They also fit well with 
  # our cron jobs. 

  # For more information, read: 
  # https://www.toptal.com/ruby-on-rails/rails-service-objects-tutorial

  # In this case, I like having a set of default parameters with these. If I'm working 
  # with one of these drivers in the console, I can make changes to my params object
  # on the fly if need be. This also makes it easy to run slightly different pipelines
  # by changing what params are passed to the generic job (i.e. different PET tracers, 
  # different sets of scan procedures/protocols, etc.)

  def self.default_params
    params = { schedule_name: 'ASL Pipeline Driver',
      computer: "thumper",
      parallel_jobs: 10,
      dry_run: false,
      run_by_user: 'ngretzon',
      cbf_series_des: ["CBF"],
      t1_globs: ['/mounts/data/preprocessed/visits/#{scan_procedure.codename}/#{enrollment.enumber}/unknown/o#{enrollment.enumber}*.nii'],
      use_preproc_nii: ["carlsson.brave.visit1","carlsson.brave.visit5","carlsson.brave.visit8"],
      cbf_globs: ['/mounts/data/preprocessed/visits/#{scan_procedure.codename}/#{enrollment.enumber}/unknown/#{enrollment.enumber}*CBF*.nii'], #specific to only carlsson.brave.visit; others use DCM's
      dcm_globs: ['/mounts/data/raw/#{scan_procedure.codename}/mri/#{participant_scan}*/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm.bz2',
                 '/mounts/data/raw/#{scan_procedure.codename}/mri/#{participant_scan}*/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm',
                 '/mounts/data/raw/#{scan_procedure.codename}/#{participant_scan}*/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm.bz2',
                 '/mounts/data/raw/#{scan_procedure.codename}/#{participant_scan}*/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm'],
      processed_check_globs: ["cg_mri*_CBF.nii","wcg_mri*_CBF.nii","native_space_perfusion.json","/mri/neuromorphometrics*.csv"],
      #                sp_whitelist: [77],
      #visits: ["carlsson.brave.visit1","carlsson.brave.visit5","carlsson.brave.visit8"],
      visits: ["carlsson.brave.visit1","carlsson.brave.visit5","carlsson.brave.visit8"],
      processing_output_path: "/mounts/data/development/asl-pipeline/output",
      processing_executable_path: "/mounts/data/development/asl-pipeline/src",
      processing_executable_name: "batch_asl",
      driver_path: "/mounts/data/development/asl-pipeline/input",
      driver_file_name: "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_asl_driver.csv"
    }
    params.default = ''
    params
  end

  def self.production_params
    params = { schedule_name: 'ASL Pipeline Driver',
      computer: "thumper",
      parallel_jobs: 10,
      dry_run: false,
      run_by_user: 'panda_user',
      cbf_series_des: ["CBF"],
      t1_globs: ['/mounts/data/preprocessed/visits/#{scan_procedure.codename}/#{enrollment.enumber}/unknown/o#{enrollment.enumber}*.nii'],
      use_preproc_nii: ["carlsson.brave.visit1","carlsson.brave.visit5","carlsson.brave.visit8"],
      cbf_globs: ['/mounts/data/preprocessed/visits/#{scan_procedure.codename}/#{enrollment.enumber}/unknown/#{enrollment.enumber}*CBF*.nii'], #specific to only carlsson.brave.visit; others use DCM's
      dcm_globs: ['/mounts/data/raw/#{scan_procedure.codename}/mri/#{participant_scan}/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm.bz2',
                 '/mounts/data/raw/#{scan_procedure.codename}/mri/#{participant_scan}/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm',
                 '/mounts/data/raw/#{scan_procedure.codename}/#{participant_scan}/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm.bz2',
                 '/mounts/data/raw/#{scan_procedure.codename}/#{participant_scan}/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm'],
      processed_check_globs: ["cg_mri*_CBF.nii","wcg_mri*_CBF.nii","native_space_perfusion.json","/mri/neuromorphometrics*.csv"],
      visits: ["carlsson.brave.visit1","carlsson.brave.visit5","carlsson.brave.visit8"],
      processing_output_path: "/mounts/data/pipelines/asl-pipeline/output",
      processing_executable_path: "/mounts/data/pipelines/asl-pipeline/src",
      processing_executable_name: "batch_asl",
      driver_path: "/mounts/data/pipelines/asl-pipeline/input",
      driver_file_name: "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_asl_driver.csv"
    }
    params.default = ''
    params
  end

  def copy_file_from_glob(search_glob,pt_out,file_suffix=".nii",mk_file_dir=true)
    #Use mk_file_dir=true to create new dir for CBF files; T1 files should be kept in pt_out 
    files_out = []
    files_found = []
    
    files_found.concat(Dir.glob(search_glob))
    
    if !files_found.empty?
      files_found.each do |file|
        file_name = file.split('/').last.split('.').first
        if mk_file_dir == true
          file_dir = "#{pt_out}/#{cbf_name}"
          if !Dir.exist?(file_dir)
            Dir.mkdir(file_dir)
          end
        else
          file_dir = pt_out
        end
        file_copy = "#{file_dir}/#{file_name}#{file_suffix}"
        `cp #{file} #{file_copy}`
        files_out.push(file_copy)
      end
    end
    return files_out
  end

  def run(params)

    # Most of the driver code will have some distinct phases. Breaking up the driver
    # job like this can be very useful when developing & debugging. I've found it 
    # useful to have these overall phases:

    begin
      setup(params)
      # For initializing useful attributes.

      selection(params)
      # Select a large mass of candidate cases to filter through

      filter(params)
      # Winnow out cases that pass our criteria for this pipeline from those that we need
      # to exclude.

      write_driver(params)
      # Write the driver out to our pipeline's input dir before processing.

      process(params)
      # Call the processing executable, and record any outputs.

      close(params)
      # Save all of our logs to attachments associated with this job run instance, and
      # update the overall status of the job run.
      
    rescue StandardError => error

      # If there are any uncaught errors when running this job, our status should be
      # set as failing, and we should try to save any log information.

      self.error_log << {:message => "Error (#{error.class}): #{error.message}"}
      close_fail(params, error)

    end
  end

  def setup(params)

    @driver = []

  end

  def selection(params)

    # We're looking at all of the MRI visits from any protocol that's on the whitelist. 
    # In this case, I'm using a little convenience class that's included next to this 
    # driver class. It inherits from Panda's normal Vgroup class, so it can act just like
    # our normal Vgroup instances, but it adds a couple of methods to keep our code here 
    # in the driver more concise and readable.
    
    ###USUAL line to use; does not focus on individual visits
    #@selected = Jobs::ASL::Vgroup.joins([{appointments: {visits: :image_datasets}}]).where(image_datasets: {series_description: params[:cbf_series_des]})

    #filter = Jobs::PopulateShareable::RegexFilter.new_from_map("ASL_TC_CBF")
    #@selected = Jobs::ASL::Vgroup.visits.image_datasets.select{|img| filter.inclusive(img.series_description)}
    
    #Focus only on visits from paramaters
    @selected = Jobs::ASL::Vgroup.joins([{appointments: {visits: :image_datasets}}]).where(image_datasets: {series_description: params[:cbf_series_des]}, vgroups: {primary_scan_procedure: params[:visits]})

    
  end

  def filter(params)

    # Here, we're taking the mass of inputs we're considering from the selection method, 
    # and filter out any cases that won't work for our processing code. In this case, we 
    # need the scan procedure/protocol name, the primary enumber, and the reggieid. If 
    # case has all of those set up in place, we can accept the case into the driver. If
    # not, we log the exclusion so that we can see that later when we generate a report 
    # for this job run.
    
    ##Get file paths for entire vgroup then search for each visit's path
    ##file_path = Dir.glob("#{vgroup.related_scan_procedure}", :base => params[:raw_data_path])
    @selected.sample(10).each do |vgroup|
      #    @selected.each do |vgroup|
      #initalize vars for this vgroup
      t1_file_path = nil
      nii_output = nil
      participant_scan = nil
      participant_output = nil
      #log filter actions for each participant to their output dir
      filter_log = ""
      #Create tmp log path in case output dir is not made for this participant
      filter_log_path = "#{params[:processing_output_path]}/#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_filter_log.txt"
      filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nVGROUP: VGroup.id = #{vgroup.id}; Participant_id = #{vgroup.participant_id}\n"


      #Filter out vgroups missing essential info
      scan_procedure = vgroup.related_scan_procedure
      if scan_procedure.nil?
        self.exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "scan procedures broken for this vgroup"}
        next
      end

      enrollment = vgroup.related_enrollment
      if enrollment.nil?
        self.exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "vgroup has no enrollments"}
        next
      end

      #Get Visit to get file paths to DICOMS
      #Make visit dir if not already made for another pt
      visit_output = "#{params[:processing_output_path]}/#{scan_procedure.codename}/"
      if !Dir.exist?(visit_output)
        Dir.mkdir(visit_output)
      end
      visits = vgroup.appointments.map(&:visits).flatten
      visits.each do |visit|
        #For each instance of Visit, get corresponding ImageDataset instances
        #scans = visits.map(&:image_datasets).flatten #typo of "visits" instead of "visit" may have had unforeseen consequences

        participant_output = "#{visit_output}/#{enrollment.enumber}"
        #make dir for this participant scan
        if !Dir.exist?("#{participant_output}")
          Dir.mkdir("#{participant_output}")
        end
        #begin log
        filter_log << "SCAN_NUMBER: #{visit.scan_number}.\n"
        pt_logs = "#{participant_output}/logs"
        filter_log_path = "#{pt_logs}/#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_filter_log.txt"
        if !Dir.exist?(pt_logs)
          Dir.mkdir(pt_logs)
        end
        
        ###Copy T1 for this visit to output for processing
        t1_pre_check = Dir.glob("#{participant_output}/*_T1.nii")
        if t1_pre_check.empty?
          t1_paths = []
          params[:t1_globs].each do |glob|
            t1_found_paths = find_file_from_glob(search_glob=glob,pt_out=participant_output,
                                                 file_suffix="_T1.nii",mk_file_dir=false)
            t1_paths.concat(t1_founds_paths)
          end #params[:t1_globs].each do |glob|
          if t1_paths.empty?
            self.log << {:file => "#{enrollment.enumber}", :message => "NIFTI for T1 not found!."}
            self.error_log << {:file => "#{enrollment.enumber}", :message => "NIFTI for T1 not found!."}
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nT1: NOT FOUND FOR #{enrollment.enumber}!\n"
            File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
            next
          else
            t1_file_path = t1_paths.first
            if t1_paths.count > 1
              self.log << {:file => "#{t1_paths}", :message => "Multiple T1's found. #{t1_paths.first} selected and added to driver for processing.\n"}
              filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nT1: Multiple T1's found. #{t1_paths.first} selected and added to driver for processing.\n"
              #Remove other T1's
              t1_paths.drop(1).each do |path|
                `rm -fv #{path}`
              end
            end
          end
        else
          self.log << {:file => "#{t1_pre_check.first}", :message => "NIFTI for T1 already exists."}
          filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nT1: #{t1_pre_check.first} already in ouptut.\n"
          #Set path for driver to pre-exisiting T1
          t1_file_path = t1_pre_check[0]
        end


        #Check if CBF NIFTI, otherwise find DCM's and create NIFTI   
        if params[:use_preproc_nii].include?(scan_procedure.codename)
          cbf_paths = []
          params[:cbf_globs].each do |glob|
            glob_full = glob.gsub(/\\/,"") #globs are input as string literals so #{} have backspaces before them; this removes the backspaces so the variables can be expanded
            cbf_copied_paths = copy_file_from_glob(search_glob=glob_full,pt_out=participant_output,
                                                   file_suffix="_CBF.nii",mk_file_dir=true)
            cbf_paths.concat(cbf_copied_paths)
          end #params[:cbf_globs].each do |glob|

          if cbf_paths.empty?
            self.log << {:file => "#{enrollment.enumber}", :message => "NIFTI for CBF not found!."}
            self.error_log << {:file => "#{enrollment.enumber}", :message => "NIFTI for CBF not found!."}
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCBF: NOT FOUND FOR #{enrollment.enumber}!\n"
            File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
            next
          else
            cbf_paths.each do |cbf|
              cbf_dir = cbf.split('/').tap(&:pop).join('/')
              #Run check on each of params[:processed_check_globs] using cbf_dir; Add each cbf to driver with T1 path
              #Check if already processed before adding to driver
              processed_found = []
              params[:processed_check_globs].each do |glob|
                check_out = Dir.glob("#{cbf_dir}/#{glob}")
                if !check_out.empty?
                  processed_found.concat(check_out)
                end
              end
              if processed_found.count == params[:processed_check_globs].count
                self.log << {:file => "#{enrollment.enumber}: #{visit}", :message => "Processing files already present!."}
                filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCBF: #{visit} already processed. Skipping!\n"
                File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
                next
              elsif !processed_found.empty? #Remove strays if not all of processed globs found
                processed_found.each do |path|
                  `rm -fv #{path}`
                end
              end
              #Add scan to driver
              @driver << {:cbf_file_path => cbf, :t1_file_path => t1_file_path, :enumber => enrollment.enumber, :protocol => scan_procedure.codename}
              self.log << {:scan => cbf_name, :message => "Added to driver to be processed."}
              filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nSUCCESS: #{cbf_name} added to driver to be processed.\n"
              File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
            end #cbf_paths.empty?
          end
        else
          ###Copy CBF for this visit to output for processing
          dcms_paths = {}
          #Find DCM's for CBF and create CBF NIFTI
          params[:dcm_globs].each do |glob|
            glob_full = glob.gsub(/\\/,"") #globs are input as string literals so #{} have backspaces before them; this removes the backspaces so the variables can be expanded
            dcms_found = Dir.glob(glob_full)
            if !dcms_found.empty?
              dcm_path_parts = dcms_found.first.split('/')
              dcm_tmp_dir = dcm_path_parts.select{ |part| part.include?('ASL') }
              dcms_paths.store(dcm_tmp_dir.first, dcms_found)
              #dcms_paths.concat(dcms_found)
              #break #prevent two scan session's DCM's from being found by stopping after first
            end
          end #params[:dcm_globs].each
          if dcms_paths.empty?
            self.log << {:file => "#{enrollment.enumber}", :message => "DICOM's for CBF not found!."}
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCBF: DICOM's NOT FOUND FOR #{enrollment.enumber}!\n"
            #        elsif dcms_paths.length > 1
          else #Just treat cases of multiple or single CBF scans the same 
            dcms_paths.each_pair do |key, array|
              
              #Create dir for each CBF NIFTI
              cbf_dir = "#{participant_output}/#{key}"
              if !Dir.exist?(cbf_dir)
                Dir.mkdir(cbf_dir)
              end
              #Create tmp dir for DCM's; delete after dcm2niix
              tmp_dir = "#{cbf_dir}/tmp"
              if !Dir.exist?(tmp_dir)
                Dir.mkdir(tmp_dir)
              end
              array.each do |path|
                `cp #{path} #{tmp_dir}`
                if path.split('.').last == "bz"
                  `bzip2 -d #{tmp_dir}/#{path.split('/').last}`
                end
              end

              #Check if already processed
              processed_found = []
              params[:processed_check_globs].each do |glob|
                check_out = Dir.glob("#{participant_output}/#{key}/#{glob}")
                if !check_out.empty?
                  processed_found.concat(check_out)
                end
              end
              if processed_found.count == params[:processed_check_globs].count
                self.log << {:file => "#{enrollment.enumber}: #{visit}", :message => "Processing files already present!."}
                filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCBF: #{visit} already processed. Skipping!\n"
                File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
                next
              elsif !processed_found.empty? #Remove strays if not all of processed globs found
                processed_found.each do |path|
                  `rm -fv #{path}`
                end
              end
              
              #dcm2niix
              cbf_name_nii = "#{enrollment.enumber}_#{key}_CBF.nii"
              `/apps/mricrogl/dcm2niix -f #{cbf_name_nii} -o #{cbf_dir} #{tmp_dir}`
              #rm tmp dir with dicoms
              `rm -rf #{tmp_dir}`
              #Add scan to driver
              @driver << {:cbf_file_path => cbf, :t1_file_path => t1_file_path, :enumber => enrollment.enumber, :protocol => scan_procedure.codename}
              self.log << {:scan => cbf_name, :message => "Added to driver to be processed."}
              filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nSUCCESS: #{cbf_name} added to driver to be processed.\n"
              File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
            end
            #        elsif dcms_paths.length == "1"
          end
        end #if use_preproc_nii
      end #visits.each 
      #at_exit do
      #  File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
      #end
    end # @selected.each
  end #def filter

  def write_driver(params)

    # Think of the driver files like a list of parameters that you could call your 
    # processing script with from the command line if it were being run for a single
    # case. In this case, our driver file is very simple: just the protocol & enumber
    # for this visit, and the reggie_id associated with the visit's participant.

    csv = CSV.open("#{params[:driver_path]}/#{params[:driver_file_name]}",'wb')
    csv << ['protocol','enumber','cbf_file_path', 't1_file_path']

    @driver.each do |row|

      csv << [row[:protocol],row[:enumber],row[:cbf_file_path],row[:t1_file_path]]

    end

    csv.close
    return "#{params[:driver_path]}/#{params[:driver_file_name]}"
  end

  def process(params)

    # Here's where the real work gets done. If we're not doing a dry run of the job
    # (which can be very helpful in development), we start by looping over the driver
    # list and building the directories that will eventually hold each of the processed
    # products.

    if params[:dry_run] == false

      require 'open3'

      # the processing script expects the directories to already be built
      @driver.each do |row|
        proto_dir = "#{params[:processing_output_path]}/#{row[:protocol]}"
        if !Dir.exist?(proto_dir)
          Dir.mkdir(proto_dir)
        end

        visit_dir = "#{params[:processing_output_path]}/#{row[:protocol]}/#{row[:enumber]}"
        if !Dir.exist?(visit_dir)
          Dir.mkdir(visit_dir)
        end
      end

      # Then we call the processing script, with a path to the driver we wrote down
      # in the previous step.
      matlab_template = "export MATLABPATH=$MATLABPATH:#{params[:processing_executable_path]}" + " && matlab -nodesktop -nosplash -r \\\"try %{command}; catch exception; display(getReport(exception)); pause(1); end; exit;\\\""
      matlab_command = matlab_template % {command: "#{params[:processing_executable_name]}('#{params[:driver_path]}/#{params[:driver_file_name]}','#{params[:processing_executable_path]}',#{params[:parallel_jobs]})"}
      processing_call = "ssh #{params[:run_by_user]}@#{params[:computer]}.dom.wisc.edu \"#{matlab_command}\""


      self.log << {:message => processing_call}
      self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)

      # All of the STDOUT output from the processing script gets captured and logged, and
      # after the processing script is complete, we save everything and update the overall
      # status of the job.

      begin
        #stdin, stdout, stderr, wait_thr = Open3.popen3(processing_call)
        stdin, stdout, stderr = Open3.popen3(processing_call)

        while !stdout.eof?
          v_output = stdout.read 1024  
          # puts v_output
          self.log << {:message => v_output.to_s}
        end
        
        stdin.close
        stdout.close
        stderr.close

      rescue => msg  
        self.log << {:message => msg.to_s}
      end
      self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)
    end
  end
end
