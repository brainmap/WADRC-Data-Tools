class Jobs::ASL::ASLHarvesterBrave < Jobs::BaseJob

  require_relative "create_tr_cg_brave"
  include CreateTrCgBrave

  attr_accessor :new_records
  attr_accessor :fail_records

  # Like the driver class for this pipeline, the harvester is set up as a service class
  # that we can call like `job.run(params)`. Driver jobs and harvest jobs are broken up
  # by convention, as it allows more flexibility for how we run our processing, but 
  # the two could just as easily be a single sequence.

  def self.default_params
    params = { schedule_name: 'ASL Pipeline Harvester',
      base_path: '/mounts/data', 
      computer: "thumper",
      run_by_user: 'ngretzon',
      destination_table: 'cg_asl_brave',
      processing_scripts_path: "/mounts/data/development/asl-pipeline/src",
      processing_output_path: "/mounts/data/development/asl-pipeline/output",
      protocols: ["carlsson.brave.visit1"],
#      protocols: ["carlsson.brave.visit1","carlsson.brave.visit5","carlsson.brave.visit8"],
      tracker_id: 37,
      record_dir: "/mounts/data/development/asl-pipeline/output/qc_records",
      new_record_file_name: "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_new_records_need_qc",
      fail_record_file_name: "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_records_failed_qc"
    }
    params.default = ''
    params
  end

  def self.production_params
    params = { schedule_name: 'ASL Pipeline Harvester',
      base_path: '/mounts/data', 
      computer: "thumper",
      run_by_user: 'ngretzon',
      destination_table: 'cg_asl_brave',
      processing_scripts_path: "/mounts/data/pipelines/asl-pipeline/src",
      processing_output_path: "/mounts/data/pipelines/asl-pipeline/output",
      protocols: ["carlsson.brave.visit1"],
#      protocols: ["carlsson.brave.visit1","carlsson.brave.visit5","carlsson.brave.visit8"],
      tracker_id: 37,
      record_dir: "/mounts/data/pipelines/asl-pipeline/output/qc_records",
      new_record_file_name: "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_new_records_need_qc",
      fail_record_file_name: "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_records_failed_qc"
    }
    params.default = ''
    params
  end

  def create_cg_table(table_name)
    create_new = "CREATE TABLE `#{table_name}` (
                             `id` INT NOT NULL AUTO_INCREMENT,
                             `scan_procedure_id` INT DEFAULT NULL,
                             `enrollment_id` INT DEFAULT NULL,
                             `participant_id` INT DEFAULT NULL,
                             `trfile_id` INT DEFAULT NULL,
                             `processed_image_id` INT DEFAULT NULL,
                             `neuromorph_cbf_metrics_id` INT DEFAULT NULL,
                             `neuromorph_vgm_metrics_id` INT DEFAULT NULL,
                             `research_cbf` BOOLEAN DEFAULT NULL,
                             `gm_cbf_median` FLOAT DEFAULT NULL,
                             `gm_cbf_mad` FLOAT DEFAULT NULL,
                             `gm_cbf_mean` FLOAT DEFAULT NULL,
                             `gm_cbf_std` FLOAT DEFAULT NULL,
                             `wm_cbf_median` FLOAT DEFAULT NULL,
                             `wm_cbf_mad` FLOAT DEFAULT NULL,
                             `wm_cbf_mean` FLOAT DEFAULT NULL,
                             `wm_cbf_std` FLOAT DEFAULT NULL,
                             PRIMARY KEY (`id`)
                             );"
    @connection.execute(create_new)
    self.log << {"#{table_name}" => "Table Created."}
  end

  def track_file(params)
    #require_relative "create_tr_cg"
    #include CreateTrCg

    #params = { candidate_path: '',
    #  image_category: '',
    #  tracker_id: '',
    #  subject: '',
    #  enrollment_id: '',
    #  sp_id: '',
    #  sp: '',
    #  new_table: ''}

    create_return = create_tr_cg_brave(params)
    create_return[:job_log].each {|job| self.log << job}
    #self.log << create_return[:job_log]
    create_return[:exclusions].each {|exclude| self.exclusions << exclude}
    #self.exclusions << create_return[:exclusions]
    if create_return[:status] == "track_success"
      log = "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCreateTrCg #{params[:category]} START:\n#{create_return[:log]}TRACK: #{params[:category]} file successfully tracked.\n"
      return log
    elsif create_return[:status] == "track_fail"
      log = "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCreateTrCg #{params[:category]} START:\n#{create_return[:log]}TRACK: #{params[:category]} file not successfully tracked.\n"
      return log
    elsif create_return[:status] == "needs_qc"
      @new_records << {:subject => params[:subject], :protocol => params[:sp], :path => create_return[:path], :file_type => params[:category]}
      log = "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCreateTrCg #{params[:category]} START:\n#{create_return[:log]}TRACK: #{params[:category]} file added to New Record CSV.\n"
      return log
    elsif create_return[:status] == "qc_fail"
      @fail_records << {:subject => params[:subject], :protocol => params[:sp], :path => create_return[:path], :file_type => params[:category]}
      log = "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCreateTrCg #{params[:category]} START:\n#{create_return[:log]}TRACK: #{params[:category]} file added to QC Failed CSV. SKIPPING TRACKING!\n"
      return log
    end
  end

  def run(params)

    begin
      setup(params)

      harvest(params)

      rotate_tables(params)
      
      #post_harvest(params)

      close(params)
		
    rescue StandardError => error

      self.error_log << "Error (#{error.class}): #{error.message}"
      close_fail(params, error)
    end
  end

  def setup(params)
    @new_records = []
    @fail_records = []
    
    setup_msg = ''
    #remove leftover rotation tables and create blank ones
    if ActiveRecord::Base.connection.table_exists?("#{params[:destination_table]}_new")
      sql = "truncate #{params[:destination_table]}_new"
      @connection.execute(sql)
      setup_msg += "Truncated #{params[:destination_table]}_new; " 
    else
      create_cg_table("#{params[:destination_table]}_new")
      setup_msg += "Created #{params[:destination_table]}_new; "
    end

    if ActiveRecord::Base.connection.table_exists? "#{params[:destination_table]}_old"
      sql = "truncate table #{params[:destination_table]}_old"
      @connection.execute(sql)
      setup_msg += "Truncated #{params[:destination_table]}_old;"
    else
      create_cg_table("#{params[:destination_table]}_old")
      setup_msg += "Created #{params[:destination_table]}_old;"
    end
    return setup_msg
  end
	
  def harvest(params)
    #loop over any results, create qc html, and collect outputs in a _new table
    protocol_dirs = []
    params[:protocols].each do |glob| #specific to brave dirs only
      protocol_dirs = protocol_dirs + Dir.glob(glob,:base=>params[:processing_output_path])
    end
    #protocol_dirs = Dir.glob("*.visit*",:base=>params[:processing_output_path])
    protocol_dirs.each do |protocol|
      sp = ScanProcedure.where(:codename => protocol).first #first just in case mult entries??
      protocol_path = "#{params[:processing_output_path]}/#{protocol}"
      subject_dirs = Dir.glob("[!.]*",:base=>protocol_path)
      subject_dirs.each do |subject|
        subject_dir = "#{protocol_path}/#{subject}"
        #log actions for each participant in their output dir
        harvest_log = ""
        pt_logs = "#{subject_dir}/logs"
        if !Dir.exist?("#{pt_logs}")
          Dir.mkdir("#{pt_logs}")
          harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nLOGS: No previous logs dir found! Created new one. Missing driver logs...\n"
        end
        harvest_log_path = "#{pt_logs}/#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_harvest_log.txt"
        harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nSUBJECT: #{subject}\nPROTOCOL: #{protocol}\n"

        cbf_names = Dir.glob("#{subject}*CBF*",:base=>subject_dir)
        enrollment = Enrollment.where(:enumber => subject).first
        cbf_names.each do |cbf_dir|
          cbf_dir_path = "#{protocol_path}/#{subject}/#{cbf_dir}"
          cbf_nii_glob = Dir.glob("#{cbf_dir_path}/#{cbf_dir}.nii") #should only ever be one
          if cbf_nii_glob.empty?
            self.error_log << {"message" => "Missing #{cbf_dir}.", "subject" => "#{subject}"}
            harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nFILE_CHECK: Missing #{cbf_dir}!\nMISSING: Subject: #{subject}\nSCAN SKIPPED!\n"
            File.open("#{harvest_log_path}", "a") {|f| f.write("#{harvest_log}") }
            next
          else
            cbf_nii = cbf_nii_glob[0]
          endema

          #check if all expected files needed for QC exist
          check_globs = {
            :qc_coreg_cbf_120_png => "#{cbf_dir_path}/qc_asl/coreg_cbf_120_qc.png",
            :qc_coreg_cbf_128_png => "#{cbf_dir_path}/qc_asl/coreg_cbf_128_qc.png",
            :qc_coreg_cbf_140_png => "#{cbf_dir_path}/qc_asl/coreg_cbf_140_qc.png",
            :wcg_tcCBF => "#{cbf_dir_path}/wcg_mri#{cbf_dir}.nii",
            :cg_tcCBF => "#{cbf_dir_path}/cg_mri#{cbf_dir}.nii",
            :tcCBF_nii => "#{cbf_dir_path}/#{cbf_dir}.nii"
          }
          checks_out = check_globs.select {|key, glob| Dir.glob(glob).empty? }
          if !checks_out.empty?
            self.error_log << {"message" => "Missing necessary QC files.", "missing_files" => "#{checks_out.values}"}
            harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nFILE_CHECK: Missing necessary QC files!\nMISSING: #{checks_out.keys}\nSCAN SKIPPED!\n"
            File.open("#{harvest_log_path}", "a") {|f| f.write("#{harvest_log}") }
            next
          else
            harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nFILE_CHECK: All necessary QC files found.\n"
          end

          #Use create_tr_cg() from create_tr_cg.rb to create tracking or cg table entries for each file
          #Find HTML of output NIFTI for tracking
          html_glob ="#{cbf_dir_path}/report_LST_lpa_cg_mri#{cbf_dir}.html"
          html_params = { candidate_path: html_glob,
            image_category: 'html',
            tracker_id: params[:tracker_id],
            subject: subject,
            enrollment_id: enrollment.id,
            sp_id: sp.id,
            sp: protocol,
            new_table: "#{params[:destination_table]}_new"}
          harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\n"
          harvest_log << track_file(html_params)
          harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\n"
          #Find CG_tcCBF_NII of output NIFTI for tracking
          cg_glob ="#{cbf_dir_path}/cg_mri#{cbf_dir}.nii"
          cg_params = { candidate_path: cg_glob,
            image_category: 'cg_tcCBF',
            tracker_id: params[:tracker_id],
            subject: subject,
            enrollment_id: enrollment.id,
            sp_id: sp.id,
            sp: protocol,
            new_table: "#{params[:destination_table]}_new"}
          harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\n"
          harvest_log << track_file(cg_params)
          harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\n"
        end
        File.open("#{harvest_log_path}", "a") {|f| f.write("#{harvest_log}") }
      end #end of subject_dirs.each
    end #end of protocol_dirs.each
  end #end of harvest() 
  
  def rotate_tables(params)    
    #copy current cg_asl to holder table, create blank cg_asl, and then copy cg_asl_new the cg_asl table
    if ActiveRecord::Base.connection.table_exists? "#{params[:destination_table]}"
      
      sql_insert = "insert into #{params[:destination_table]}_old select * from #{params[:destination_table]};"
      @connection.execute(sql_insert)
      self.log << {:message => "#{params[:destination_table]} moved to #{params[:destination_table]}_old"}
      sql_trunc = "truncate table #{params[:destination_table]};"
      @connection.execute(sql_trunc)
      self.log << {:message => "#{params[:destination_table]} truncated."}
    else
      create_cg_table("#{params[:destination_table]}")
      self.log << {:message => "#{params[:destination_table]} created."}
    end


    sql_new = "insert into #{params[:destination_table]} select * from #{params[:destination_table]}_new;"
    @connection.execute(sql_new)
    return "Tables rotated!"
  end
  
  #def post_harvest(params)
  #end

end

end



# CREATE TABLE `cg_asl_brave` (
#   `id` INT NOT NULL AUTO_INCREMENT,
#   `scan_procedure_id` INT DEFAULT NULL,
#   `enrollment_id` INT DEFAULT NULL,
#   `participant_id` INT DEFAULT NULL,
#   `trfile_id` INT DEFAULT NULL,
#   `processed_image_id` INT DEFAULT NULL,
#   `neuromorph_cbf_metrics_id` INT DEFAULT NULL,
#   `neuromorph_vgm_metrics_id` INT DEFAULT NULL,
#   `research_cbf` BOOLEAN DEFAULT NULL,
#   `gm_cbf_median` FLOAT DEFAULT NULL,
#   `gm_cbf_mad` FLOAT DEFAULT NULL,
#   `gm_cbf_mean` FLOAT DEFAULT NULL,
#   `gm_cbf_std` FLOAT DEFAULT NULL,
#   `wm_cbf_median` FLOAT DEFAULT NULL,
#   `wm_cbf_mad` FLOAT DEFAULT NULL,
#   `wm_cbf_mean` FLOAT DEFAULT NULL,
#   `wm_cbf_std` FLOAT DEFAULT NULL,
#   PRIMARY KEY (`id`)
#   );

#create = "CREATE TABLE `cg_asl_brave` (`id` INT NOT NULL AUTO_INCREMENT,`scan_procedure_id` INT DEFAULT NULL,`enrollment_id` INT DEFAULT NULL,`participant_id` INT DEFAULT NULL,`trfile_id` INT DEFAULT NULL,`processed_image_id` INT DEFAULT NULL,`neuromorph_cbf_metrics_id` INT DEFAULT NULL,`neuromorph_vgm_metrics_id` INT DEFAULT NULL, `research_cbf` BOOLEAN DEFAULT NULL, `gm_cbf_median` FLOAT DEFAULT NULL,`gm_cbf_mad` FLOAT DEFAULT NULL,`gm_cbf_mean` FLOAT DEFAULT NULL,`gm_cbf_std` FLOAT DEFAULT NULL,`wm_cbf_median` FLOAT DEFAULT NULL,`wm_cbf_mad` FLOAT DEFAULT NULL,`wm_cbf_mean` FLOAT DEFAULT NULL,`wm_cbf_std` FLOAT DEFAULT NULL,PRIMARY KEY (`id`));"


#CREATE TABLE `neuromorph_cbf_metrics` (
#    `id` INT NOT NULL AUTO_INCREMENT,
#    `cg_asl_id` INT DEFAULT NULL,
#    ONE COLUMN PER ROI NAME WITH CBF FLOAT VALUE
#    PRIMARY KEY (`id`)
#    );

#CREATE TABLE `neuromorph_vgm_metrics` (
#    `id` INT NOT NULL AUTO_INCREMENT,
#    `cg_asl_id` INT DEFAULT NULL,
#    ONE COLUMN PER ROI NAME WITH VGM INT VALUE
#    PRIMARY KEY (`id`)
#    );




#roi_id = [4,11,23,30,31,32,35,36,37,38,39,40,41,44,45,46,47,48,49,50,51,52,55,56,57,58,59,60,61,62,63,64,69,71,72,73,75,76,100,101,102,103,104,105,106,107,108,109,112,113,114,115,116,117,118,119,120,121,122,123,124,125,128,129,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207]
#roi_name = ["3rd Ventricle","4th Ventricle","Right Accumbens Area","Left Accumbens Area	Right Amygdala","Left Amygdala","Brain Stem","Right Caudate","Left Caudate","Right Cerebellum Exterior","Left Cerebellum Exterior","Right Cerebellum White Matter","Left Cerebellum White Matter","Right Cerebral White Matter","Left Cerebral White Matter","CSF","Right Hippocampus","Left Hippocampus","Right Inf Lat Vent","Left Inf Lat Vent","Right Lateral Ventricle","Left Lateral Ventricle","Right Pallidum","Left Pallidum","Right Putamen","Left Putamen","Right Thalamus Proper","Left Thalamus Proper","Right Ventral DC","Left Ventral DC","Right vessel","Left vessel","Optic Chiasm","Cerebellar Vermal Lobules I-V","Cerebellar Vermal Lobules VI-VII","Cerebellar Vermal Lobules VIII-X","Left Basal Forebrain","Right Basal Forebrain","Right ACgG anterior cingulate gyrus","Left ACgG anterior cingulate gyrus","Right AIns anterior insula","Left AIns anterior insula","Right AOrG anterior orbital gyrus","Left AOrG anterior orbital gyrus","Right AnG angular gyrus","Left AnG angular gyrus","Right Calc calcarine cortex","Left Calc calcarine cortex","Right CO central operculum","Left CO central operculum","Right Cun cuneus","Left Cun cuneus","Right Ent entorhinal area","Left Ent entorhinal area","Right FO frontal operculum","Left FO frontal operculum","Right FRP frontal pole","Left FRP frontal pole","Right FuG fusiform gyrus","Left FuG fusiform gyrus","Right GRe gyrus rectus","Left GRe gyrus rectus","Right IOG inferior occipital gyrus","Left IOG inferior occipital gyrus","Right ITG inferior temporal gyrus","Left ITG inferior temporal gyrus","Right LiG lingual gyrus","Left LiG lingual gyrus","Right LOrG lateral orbital gyrus","Left LOrG lateral orbital gyrus","Right MCgG middle cingulate gyrus","Left MCgG middle cingulate gyrus","Right MFC medial frontal cortex","Left MFC medial frontal cortex","Right MFG middle frontal gyrus","Left MFG middle frontal gyrus","Right MOG middle occipital gyrus","Left MOG middle occipital gyrus","Right MOrG medial orbital gyrus","Left MOrG medial orbital gyrus","Right MPoG postcentral gyrus medial segment","Left MPoG postcentral gyrus medial segment","Right MPrG precentral gyrus medial segment","Left MPrG precentral gyrus medial segment","Right MSFG superior frontal gyrus medial segment","Left MSFG superior frontal gyrus medial segment","Right MTG middle temporal gyrus","Left MTG middle temporal gyrus","Right OCP occipital pole","Left OCP occipital pole","Right OFuG occipital fusiform gyrus","Left OFuG occipital fusiform gyrus","Right OpIFG opercular part of the inferior frontal gyrus","Left OpIFG opercular part of the inferior frontal gyrus","Right OrIFG orbital part of the inferior frontal gyrus","Left OrIFG orbital part of the inferior frontal gyrus","Right PCgG posterior cingulate gyrus","Left PCgG posterior cingulate gyrus","Right PCu precuneus","Left PCu precuneus","Right PHG parahippocampal gyrus","Left PHG parahippocampal gyrus","Right PIns posterior insula","Left PIns posterior insula","Right PO parietal operculum","Left PO parietal operculum","Right PoG postcentral gyrus","Left PoG postcentral gyrus","Right POrG posterior orbital gyrus","Left POrG posterior orbital gyrus","Right PP planum polare","Left PP planum polare","Right PrG precentral gyrus","Left PrG precentral gyrus","Right PT planum temporale","Left PT planum temporale","Right SCA subcallosal area","Left SCA subcallosal area","Right SFG superior frontal gyrus","Left SFG superior frontal gyrus","Right SMC supplementary motor cortex","Left SMC supplementary motor cortex","Right SMG supramarginal gyrus","Left SMG supramarginal gyrus","Right SOG superior occipital gyrus","Left SOG superior occipital gyrus","Right SPL superior parietal lobule","Left SPL superior parietal lobule","Right STG superior temporal gyrus","Left STG superior temporal gyrus","Right TMP temporal pole","Left TMP temporal pole","Right TrIFG triangular part of the inferior frontal gyrus","Left TrIFG triangular part of the inferior frontal gyrus","Right TTG transverse temporal gyrus","Left TTG transverse temporal gyrus"]
