class Jobs::ASL::ASLDriver < Jobs::BaseJob

  attr_accessor :selected
  attr_accessor :driver
  attr_accessor :test_logs

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
      cbf_series_des: ["NOT DIAGNOSTIC: (Transit corrected CBF) UW eASL", "CBF"],
#      t1_series_des: ["Accelerated Sagittal IR-FSPGR MSV21", "mADNI3_T1"],
      #                series_des: ["NOT DIAGNOSTIC: (Transit corrected CBF) UW eASL"],
      #                sp_whitelist: [77],
      #                raw_data_path: "/mounts/data/raw",
      visits: ["carlsson.brave.visit1","carlsson.brave.visit5","carlsson.brave.visit8"],
      processing_output_path: "/mounts/data/development/asl-pipeline/output",
      processing_executable_path: "/mounts/data/development/asl-pipeline/src",
      processing_executable_name: "batch_asl",
      driver_path: "/mounts/data/development/asl-pipeline/input",
#      driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_asl_driver.csv"
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
      cbf_series_des: ["NOT DIAGNOSTIC: (Transit corrected CBF) UW eASL", "CBF"],
#      t1_series_des: ["Accelerated Sagittal IR-FSPGR MSV21", "mADNI3_T1"],
      #                series_des: ["NOT DIAGNOSTIC: (Transit corrected CBF) UW eASL"],
      #                sp_whitelist: [77],
      #                raw_data_path: "/mounts/data/raw",
      visits: ["carlsson.brave.visit1","carlsson.brave.visit5","carlsson.brave.visit8"],
      processing_output_path: "/mounts/data/pipelines/asl-pipeline/output",
      processing_executable_path: "/mounts/data/pipelines/asl-pipeline/src",
      processing_executable_name: "batch_asl",
      driver_path: "/mounts/data/pipelines/asl-pipeline/input",
#      driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_asl_driver.csv"
      driver_file_name: "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_asl_driver.csv"
    }
    params.default = ''
    params
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

      # we also need the reggie_id for this person, so let's get the participant
      participant = nil
      if !enrollment.participant_id.nil? and !enrollment.participant_id.blank?
        participant = Participant.where(:id => enrollment.participant_id).first
      else
        self.exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "vgroup's primary enrollment has a broken participant link"}
        next
      end

      #Create tmp log path in case output dir is not made for this participant
      filter_log_path = "#{params[:processing_output_path]}/#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_filter_log.txt"

      #Get Visit to get file paths to DICOMS
      #Make visit dir if not already made for another pt
      visit_output = "#{params[:processing_output_path]}/#{scan_procedure.codename}/"
      if !Dir.exist?("#{visit_output}")
        Dir.mkdir("#{visit_output}")
      end
      visits = vgroup.appointments.map(&:visits).flatten
      visits.each do |visit|
        #For each instance of Visit, get corresponding ImageDataset instances
        #scans = visits.map(&:image_datasets).flatten #typo of "visits" instead of "visit" may have had unforeseen consequences
        scans = visit.image_datasets
        #For each instance of ImageDataset, check if series description matches strings in params array of desired series
        scans.each do |image|
          #If not a tc_CBF then skip scan
          #Selection method only takes vgroups that have a CBF scan; visits then gets all scans for those vgroups so we must skip non-CBF scans
          if !params[:cbf_series_des].include?(image.series_description)
            next
          end
          participant_output = "#{params[:processing_output_path]}/#{scan_procedure.codename}/#{enrollment.enumber}"
          #make dir for this participant scan
          if !Dir.exist?("#{participant_output}")
            Dir.mkdir("#{participant_output}")
          end
          #begin log
          filter_log << "SCAN: #{image.path}.\n"
          pt_logs = "#{participant_output}/logs"
          filter_log_path = "#{pt_logs}/#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_filter_log.txt"
          if !Dir.exist?("#{pt_logs}")
            Dir.mkdir("#{pt_logs}")
          end
          #before logs included timestamps we had to not overwrite old logs
          #if File.exist?("#{filter_log_path}")
          #  old_logs = Dir.glob("#{pt_logs}/#{Date.today.strftime("%Y-%m-%d")}_filter_log*.txt")
          #  filter_log_path = "#{pt_logs}/#{Date.today.strftime("%Y-%m-%d")}_filter_log_#{old_logs.count}.txt"
         #  filter_log << "LOGS: Old logs found. New log renamed to: #{filter_log_path}.\n"
         #end

          ###Copy T1 for this visit to output for processing
          t1_pre_check = Dir.glob("#{participant_output}/o#{enrollment.enumber}*.nii")
          if t1_pre_check.empty?
            t1_pre_path = Dir.glob("/mounts/data/preprocessed/visits/#{scan_procedure.codename}/#{enrollment.enumber}/unknown/o#{enrollment.enumber}*.nii")[0] #find T1 in preprocessed
            `cp #{t1_pre_path} #{participant_output}`
            t1_file_path = Dir.glob("#{participant_output}/o#{enrollment.enumber}*.nii")[0]
            self.log << {:t1_copy_log => "Copied: #{t1_file_path}"}
            #used system() and captured return value
            #t1_copy_return = system( "cp #{t1_pre_path} #{participant_output}" )
            #t1_file_path = Dir.glob("#{participant_output}/o#{enrollment.enumber}*.nii")[0]
            #self.log << {:t1_copy_log => t1_copy_return, :t1_file => "#{t1_file_path}"}
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nT1: #{t1_file_path} copied to ouptut.\n"
          else
            self.log << {:file => "#{t1_pre_check[0]}", :message => "NIFTI for T1 already exists."}
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nT1: #{t1_pre_check[0]} already in ouptut.\n"
            #Set path for driver to pre-exisiting T1
            t1_file_path = t1_pre_check[0]
          end

          #check if tc_CBF.nii already exists before moving onto creating tc_CBF.nii
          pt_path = image.path.split('/')
          participant_scan = pt_path.filter{|name| name.match?("#{enrollment.enumber}")}[0]
          nii_output = "#{participant_output}/#{participant_scan}_tcCBF.nii" #file path for output nifti

          ###Copy BZ2 DCM's for tcCBF, extract copies, export NIFTI, and create tar ball of DCM's.
          if !File.exist?("#{nii_output}")
            need_extraction = true
            tcCBF_bz2 = []

            ###Create NIFTIs for CBF scan
            #if scan is CBF then create copy of .bz2 DICOMS and create NIFTI from copies
            if pt_path.include?("scan_archives") && pt_path.include?("tcCBF_DICOMs")
              #Search for scan_archives folder with DICOMS to be exported to NII
              tcCBF_bz2 = Dir.glob("#{image.path}/*.dcm.bz2")
              if tcCBF_bz2.empty?
                tcCBF_bz2 = Dir.glob("#{image.path}/*.dcm") 
              end
              filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nBZ2: #{tcCBF_bz2}\nThese BZ2 found.\n"
            else #if path from Panda is not for scan_archives then try and find the right path
             # tcCBF_bz2 = []
              #catch cases where DICOMs are unzipped already Ex. asthana.adrc-clinical-core.visit1/adrc01098_6764_06062019
              #catch cases with /mri/ dir inside of scan_procedure dir
              tcCBF_bz2_mri = Dir.glob("/mounts/data/raw/#{scan_procedure.codename}/mri/#{participant_scan}/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm.bz2")
              tcCBF_bz2_mri_dcm = Dir.glob("/mounts/data/raw/#{scan_procedure.codename}/mri/#{participant_scan}/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm")
              tcCBF_bz2_no_mri = Dir.glob("/mounts/data/raw/#{scan_procedure.codename}/#{participant_scan}/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm.bz2")
              tcCBF_bz2_no_mri_dcm = Dir.glob("/mounts/data/raw/#{scan_procedure.codename}/#{participant_scan}/scan_archives/*/*_eASL/processed_data/DICOM/DICOM/Standard_label/tcCBF_DICOMs/*.dcm")
              
              tcCBF_searches = {:tcCBF_bz2_mri => tcCBF_bz2_mri, 
                :tcCBF_bz2_mri_dcm => tcCBF_bz2_mri_dcm,
                :tcCBF_bz2_no_mri => tcCBF_bz2_no_mri,
                :tcCBF_bz2_no_mri_dcm => tcCBF_bz2_no_mri_dcm}
              tcCBF_searches.each do |key, glob|
                if !glob.empty?
                  tcCBF_bz2 = glob
                  if key.to_s = "tcCBF_bz2_mri_dcm" || key.to_s = "tcCBF_bz2_no_mri_dcm"
                    need_extraction = false
                  end
                end
              end
              if tcCBF_bz2.empty?
                self.exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "bz2 files not found in raw data dir", :participant_scan => participant_scan}
                filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nBZ2: No BZ2 found! SKIPPED SCAN!\n"
                File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
                break #skip the rest of the scans for this visit and this visit if cannot get tcCBF.nii
              end
              filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nBZ2: Path from Panda not for scan_archives. Found these in scan_archives:\n#{tcCBF_bz2}\n.Copied to ouptut.\n"
            end
            
            #if .dcm.bz2 files found then copy them, unzip them, create NIFTI, tar unzipped .dcm into one tar ball file; delete tmp dir after???
            #Copy bz and make nii
            #tmp_dir = "#{tcCBF_dir}/tmp" #dont have permission to add to preprocessed
            tmp_dir = "#{participant_output}/tmp"
            if !Dir.exist?("#{tmp_dir}")
              Dir.mkdir("#{tmp_dir}")
            elsif Dir.exist?("#{tmp_dir}")
              `rm -rf #{tmp_dir}`
              #tmp_rm_return = system("rm -rf #{tmp_dir}")
              filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nTMP DIR: Old tmp dir removed and new one created.\n"
              filter_log << "TMP: Old tmp dir removed and #{tmp_dir} created.\n"
              Dir.mkdir("#{tmp_dir}")
            end


            #unzip each bz into tmp dir and save cmd outputs
            tcCBF_bz2.each do |bz|
              bz_filename = bz.split('/').last
              bz_name = bz_filename.split('.')[0]
              if File.exist?("#{tmp_dir}/#{bz_name}.dcm")
                filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nBZ2: #{tmp_dir}/#{bz_name}.dcm already exists. Skipping extracting #{tmp_dir}/#{bz_filename}.\n"
                #break #stop checking individual bz2.dcms
                next
              end
              if File.exist?("#{tmp_dir}/#{bz_filename}") 
                filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nBZ2: #{tmp_dir}/#{bz_filename} already exists. Skipping copying...\n"
#                next #move onto next bz2.dcm
              else
                `cp #{bz} #{tmp_dir}`
                cp_log = "cp #{bz} #{tmp_dir}/"
                #cp_return = system( "cp #{bz} #{tmp_dir}" ) #false if error
                #cp_log = "cp #{bz} #{tmp_dir}/ >> #{cp_return}"
                self.log << {:cp_log => cp_log, :bz_file => bz_filename}
                filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nBZ2: #{bz} copied to output.\n"
              end

              
              
              if need_extraction == true 
                `bzip2 -d #{tmp_dir}/#{bz_filename}`
                bzip_log = "bzip2 -d #{bz} #{t1_file_path}"
                #bzip_return = system( "bzip2 -d #{tmp_bz}" ) #false if error
                #bzip_log = "bzip2 -d #{bz} #{t1_file_path} >> #{bzip_return}"
                self.log << {:bzip_log => bzip_log, :bz_file => bz_name}
                filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nBZ2: #{bz_name} unzipped to output.\n"
              end
            end

            #Check if as many dcm exist as there were bz2
            tcCBF_dcms = Dir.glob("#{tmp_dir}/*.dcm")
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nBZ2: BZ2 DCM's Found in Output:\n#{tcCBF_dcms}.\n"
            if !(tcCBF_bz2.count == tcCBF_dcms.count)
              self.exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "bz2 dcms and unzipped dcms not equal in count so visit skipped", :participant_scan => participant_scan}
              filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nBZ2: NOT ALL BZ2 FOUND IN OUTPUT! SKIPPED SCAN!\n"
              File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
              break #if we do not get all DCM slices then will not get a good NIFTI for a tc_CBF of a visit so skip visit
            end


            #Create nii file from unzipped DICOMs named enumber_tcCBF.nii in asl-pipeline/output/protocol_visit/enumber
            ###TODO### figure out path for dcm2niix on machine this will run on 
            `/apps/mricrogl/dcm2niix -f #{participant_scan}_tcCBF -o #{participant_output} #{tmp_dir}`
            #dcm2niix_return = system( "/apps/mricrogl/dcm2niix -f #{participant_scan}_tcCBF -o #{participant_output} #{tmp_dir}" )
            if !File.exist?("#{participant_output}/#{participant_scan}_tcCBF.nii")
              self.exclusions << {:class => vgroup.class, :id => vgroup.id, :message => "tcCBF.nii not successfully created"}
              filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCBF: tcCBF.nii not successfully created. SKIPPED SCAN!\n"
              File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
              next
            end
            self.log << {:dcm2niix_log => "#{participant_output}/#{participant_scan}_tcCBF.nii", :message => "tcCBF.nii created."}
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCBF: #{participant_scan}_tcCBF.nii created in output.\n"

            #Create tar ball of DICOMs
            `tar -czf #{participant_output}/#{participant_scan}.tgz #{tmp_dir}/*dcm`
            #tar_return = system( "tar -czf #{participant_output}/#{participant_scan}.tgz #{tmp_dir}/*dcm" )
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nTAR: #{participant_scan}.tgz created in output.\n"
            self.log << {:tar_log => "Tar created: #{participant_output}/#{participant_scan}.tgz"}
            #remove tmp after export nii; Consider checking for nii and trying again before deleteing
            `rm -rf #{tmp_dir}`
            #tmp_rm_return = system("rm -rf #{tmp_dir}")
            self.log << {:tmp_dir => "Tmp dir removed: #{tmp_dir}"}
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nTMP: #{tmp_dir} removed. \n"

          elsif File.exist?("#{nii_output}")
            self.log << {:class => vgroup.class, :id => vgroup.id, :message => "tcCBF.nii already exists in output.", :participant_scan => participant_scan}
            #next
            #t1_file_path = Dir.glob("#{participant_output}/o#{enrollment.enumber}*.nii")[0]
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCBF: tcCBF.nii already exists in output: #{t1_file_path}\n"
          end

          #Create array to be written to CSV; Do not add to driver if MATLAB outputs already exist
          #Remove any exisiting QC/processed files if not all are found
          check_globs = {
            :qc_coreg_cbf_120_png => "#{participant_output}/qc_asl/coreg_cbf_120_qc.png",
            :qc_coreg_cbf_128_png => "#{participant_output}/qc_asl/coreg_cbf_128_qc.png",
            :qc_coreg_cbf_140_png => "#{participant_output}/qc_asl/coreg_cbf_140_qc.png",
            :wcg_tcCBF => "#{participant_output}/wcg_mri#{participant_scan}_tcCBF.nii",
            :cg_tcCBF => "#{participant_output}/cg_mri#{participant_scan}_tcCBF.nii",
            :tcCBF_nii => "#{participant_output}/#{participant_scan}_tcCBF.nii",
            :tcCBF_json => "#{participant_output}/#{participant_scan}_tcCBF.json"
          }
          found = {}
          missing = []
          check_globs.each do |key, glob|
            glob_out = Dir.glob(glob)
            if glob_out.empty?
              missing << key.to_s
            else
              found.store(key,glob)
            end
          end
          if missing.include?("tcCBF_nii") || missing.include?("tcCBF_json")
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nFILE_CHECK: MISSING: #{missing}\nCannot process this scan. Skipping scan for processing...\n"
            File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
            next
          elsif missing.count != 5
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nFILE_CHECK: Missing some necessary QC files!\nMISSING: #{missing}\nFOUND: #{found.values}\nDeleting QC/processed files found and adding scan to driver to be processed.\n"
            found.each do |key, value| 
              if !["tcCBF_nii", "tcCBF_json"].include?(key.to_s)
                `rm -v #{value}`
                filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nFILE_CHECK: Deleted: #{value}\n"
              end
            end
          else
            filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nFILE_CHECK: All necessary QC files found. Skipping scan for processing...\n"
            File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
            next
          end

          #Add scan to driver
          @driver << {:cbf_file_path => nii_output, :t1_file_path => t1_file_path, :enumber => enrollment.enumber, :protocol => scan_procedure.codename, :reggie_id => participant.reggieid}
          self.log << {:scan => participant_scan, :message => "Added to driver to be processed."}
          filter_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nSUCCESS: #{participant_scan} added to driver to be processed.\n"
          File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
        end
      end
      at_exit do
        File.open("#{filter_log_path}", "w") {|f| f.write("#{filter_log}") }
      end
    end
  end

  def write_driver(params)

    # Think of the driver files like a list of parameters that you could call your 
    # processing script with from the command line if it were being run for a single
    # case. In this case, our driver file is very simple: just the protocol & enumber
    # for this visit, and the reggie_id associated with the visit's participant.

    csv = CSV.open("#{params[:driver_path]}/#{params[:driver_file_name]}",'wb')
    csv << ['protocol','enumber','reggie_id','cbf_file_path', 't1_file_path']

    @driver.each do |row|

      csv << [row[:protocol],row[:enumber],row[:reggie_id],row[:cbf_file_path],row[:t1_file_path]]

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
      matlab_command = matlab_template % {command: "#{params[:processing_executable_name]}('#{params[:driver_path]}/#{params[:driver_file_name]}',#{params[:parallel_jobs]})"}
      processing_call = "ssh #{params[:run_by_user]}@#{params[:computer]}.dom.wisc.edu \"#{matlab_command}\""


      self.log << {:message => processing_call}
      # self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)

      # All of the STDOUT output from the processing script gets captured and logged, and
      # after the processing script is complete, we save everything and update the overall
      # status of the job.

      begin
        stdin, stdout, stderr, wait_thr = Open3.popen3(processing_call)

        while !stdout.eof?
          v_output = stdout.read 1024  
          # puts v_output
          self.log << {:message => v_output.to_s}
        end

      rescue => msg  
        self.log << {:message => msg.to_s}
      end
      # self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)
      self.close(params)
    end
  end
end
