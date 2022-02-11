class Jobs::ASL::ASLHarvester < Jobs::BaseJob

  require_relative "create_tr_cg"
  include CreateTrCg

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
      destination_table: 'cg_asl',
      processing_scripts_path: "/mounts/data/development/asl-pipeline/src",
      processing_output_path: "/mounts/data/development/asl-pipeline/output",
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
      run_by_user: 'panda_user',
      destination_table: 'cg_asl',
      processing_scripts_path: "/mounts/data/pipelines/asl-pipeline/src",
      processing_output_path: "/mounts/data/pipelines/asl-pipeline/output",
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
                             `id` int NOT NULL AUTO_INCREMENT,
                             `protocol` varchar(255) DEFAULT NULL,
                             `subject_id` varchar(255) DEFAULT NULL,
                             `reggie_id` varchar(255) DEFAULT NULL,
                             `file_type` varchar(255) DEFAULT NULL,
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

    create_return = create_tr_cg(params)
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
      log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nCreateTrCg #{params[:category]} START:\n#{create_return[:log]}TRACK: #{params[:category]} file added to QC Failed CSV. SKIPPING TRACKING!\n"
      return log
    end
  end

  def run(params)

    begin
      setup(params)

      harvest(params)

      #write_records(params)

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
    protocol_dirs = Dir.glob("*.visit*",:base=>params[:processing_output_path])
    protocol_dirs.each do |protocol|
      sp = ScanProcedure.where(:codename => protocol).first #first just in case mult entries??
      protocol_path = "#{params[:processing_output_path]}/#{protocol}"
      subject_dirs = Dir.glob("[!.]*",:base=>protocol_path)
      subject_dirs.each do |subject|
        enrollment = Enrollment.where(:enumber => subject).first
        #check for subject in cg_asl table and skip if already in table
        check_cg_sql = "SELECT * FROM #{params[:destination_table]} WHERE protocol = #{sp.id} AND subject_id = '#{subject}' AND reggie_id = #{enrollment.participant.reggieid};"
        check_out = @connection.execute(check_cg_sql)
        if check_out.count > 0
          self.log << {:ALREADY_TRACKED => "#{protocol}, #{subject}, #{enrollment.id}", :entries_found => "#{check_out.to_a}"}
          next
        end

        #log actions for each participant in their output dir
        harvest_log = "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nSUBJECT: #{subject}\nPROTOCOL: #{protocol}\n"
        pt_logs = "#{protocol_path}/#{subject}/logs"
        harvest_log_path = "#{pt_logs}/#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_harvest_log.txt"
        if !Dir.exist?("#{pt_logs}")
          Dir.mkdir("#{pt_logs}")
          harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nLOGS: No previous logs dir found! Created new one. Missing driver logs...\n"
        end

        #check if all expected files needed for QC exist
        check_globs = {
          :qc_coreg_cbf_120_png => "#{protocol_path}/#{subject}/qc_asl/coreg_cbf_120_qc.png",
          :qc_coreg_cbf_128_png => "#{protocol_path}/#{subject}/qc_asl/coreg_cbf_128_qc.png",
          :qc_coreg_cbf_140_png => "#{protocol_path}/#{subject}/qc_asl/coreg_cbf_140_qc.png",
          :wcg_tcCBF => "#{protocol_path}/#{subject}/wcg_*#{subject}*_tcCBF.nii",
          :cg_tcCBF => "#{protocol_path}/#{subject}/cg_*#{subject}*_tcCBF.nii",
          :tcCBF_nii => "#{protocol_path}/#{subject}/#{subject}*_tcCBF.nii",
          :tcCBF_json => "#{protocol_path}/#{subject}/#{subject}*_tcCBF.json"
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
        
        #Create QC HTML output for this protocol/subject
        html_glob ="#{protocol_path}/#{subject}/qc_asl/#{subject}_qc_image_summary.html"
        html_pre_check = Dir.glob("#{html_glob}")
        qc_script_dir = "#{params[:processing_scripts_path]}/asl_qc_scripts"
        if html_pre_check.empty?
          qc_call = "#{qc_script_dir}/create_html_summary.sh #{protocol} #{subject} #{qc_script_dir} #{params[:processing_output_path]}"
          `bash #{qc_call}`
          #qc_return = system( "bash #{qc_call}" )
          self.log << {:qc_log => "bash #{qc_call}"}
          harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\nHTML: QC_image_summary.html created.\n"
        end

        #Use create_tr_cg() from create_tr_cg.rb to create tracking or cg table entries for each file
        #Find JSON of output NIFTI for tracking
        json_glob = "#{protocol_path}/#{subject}/#{subject}*tcCBF.json"
        json_params = { candidate_path: json_glob,
          image_category: 'json',
          tracker_id: params[:tracker_id],
          subject: subject,
          enrollment_id: enrollment.id,
          sp_id: sp.id,
          sp: protocol,
          new_table: "#{params[:destination_table]}_new"}
        harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\n"
        harvest_log << track_file(json_params)
        harvest_log << "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}\n"

        #Find HTML of output NIFTI for tracking
        html_glob ="#{protocol_path}/#{subject}/qc_asl/#{subject}_qc_image_summary.html"
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
        cg_glob ="#{protocol_path}/#{subject}/cg_*#{subject}_*tcCBF.nii"
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

        File.open("#{harvest_log_path}", "a") {|f| f.write("#{harvest_log}") }
        #at_exit do
        #  File.open("#{harvest_log_path}", "a") {|f| f.write("#{harvest_log}") }
        #end
      end #end of subject_dirs.each
    end #end of protocol_dirs.each
  end #end of harvest() 

  def write_records(params)
    #confirm records dir exists 
    if !Dir.exist?(params[:record_dir])
      Dir.mkdir(params[:record_dir])
      self.log << {:message => "LOGS: No previous new record log dir found! Created new one.\n"}
    end
    #if records csv's with file already exist, then adjust name of file
    new_records_path = "#{params[:record_dir]}/#{params[:new_record_file_name]}.csv"
    if File.exist?(new_records_path)
      old_logs = Dir.glob("#{params[:record_dir]}/#{params[:new_record_file_name]}*.csv")
      new_records_path = "#{params[:record_dir]}/#{params[:new_record_file_name]}_#{old_logs.count}.csv"
      self.log << {:message => "LOGS: Old logs found. New log renamed to: #{new_records_path}.\n"}
    end
    fail_records_path = "#{params[:record_dir]}/#{params[:fail_record_file_name]}.csv"
    if File.exist?(fail_records_path)
      old_logs = Dir.glob("#{params[:record_dir]}/#{params[:fail_record_file_name]}*.csv")
      fail_records_path = "#{params[:record_dir]}/#{params[:fail_record_file_name]}_#{old_logs.count}.csv"
      self.log << {:message => "LOGS: Old logs found. New log renamed to: #{fail_records_path}.\n"}
    end

    #create CSV files
    columns_csv = ['protocol','subject','file_path','file_type']

    new_csv = CSV.open(new_records_path,'wb')
    new_csv << columns_csv
    @new_records.each do |row|
      new_csv << [row[:protocol],row[:subject],row[:path],row[:file_type]]
    end
    new_csv.close

    fail_csv = CSV.open(fail_records_path,'wb')
    fail_csv << columns_csv
    @fail_records.each do |row|
      fail_csv << [row[:protocol],row[:subject],row[:path],row[:file_type]]
    end
    fail_csv.close
    
    return_msg = "#{new_records_path} written. #{fail_records_path} written."
  end
  
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


# CREATE TABLE `cg_asl` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `protocol` varchar(255) DEFAULT NULL,
#   `subject_id` varchar(255) DEFAULT NULL,
#   `reggie_id` varchar(255) DEFAULT NULL,
#   `file_type` varchar(255) DEFAULT NULL,
#   PRIMARY KEY (`id`)
#   );
