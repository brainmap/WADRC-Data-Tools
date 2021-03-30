class Jobs::ImageReconciliation::ImageReconciliationJob < Jobs::BaseJob

	# This job implements the reconciliation of all of our RAW images after the drive failure
	# of 2021-02. We're rebuilding a drive and recovering many files from backups, and we 
	# need an automated job that will check all of the files being repopulated into raw for
	# consistency with the Panda records. 

	attr_accessor :selected
	attr_accessor :driver
	attr_accessor :output_tmp
	attr_accessor :result

	def self.default_params
	  	params = { :schedule_name => 'Image Reconciliation', 
	  				:run_by_user => 'panda_user',
	  				:base_path => "/mounts/data",
	  				:scan_procedure_white_list => [6, 8, 9, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26,
	  												 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 
	  												 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 
	  												 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 
	  												 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 
	  												 95, 96, 97, 98, 99, 100, 104, 105, 106, 107, 109, 110, 111, 112, 113, 
	  												 114, 115, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 129, 
	  												 130, 131, 133, 134, 135, 136, 137, 138, 139, 143, 144, 145, 146, 147, 
	  												 148, 149, 150, 151],
	  				:insert_now => true,
	  				:save_to_sql => true,
	  				:sql_path => '/mounts/data/analyses/wbbevis/reconciliation/insert.sql'
	  			}
        params.default = ''
        params
    end

    # As part of testing this script, and validating that we've got everything there, this should
    # be run on daily.0 ("/Volumes/backup/daily.0/BRAINDATA/data") to give us a baseline. Using base_path to do path conversion should actually
    # work really well. 

	def run(params)

		begin
			setup(params)

			selection(params)

			scan_images(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	# setup
	# 	build the job & status
	# 	build whatever initial values and members we need
	#   build a temp dir, and remember the path to that dir

		
	def setup(params)

		@selected = []
		@driver = []
		@output_tmp = Dir.mktmpdir

	end


	# selection
	# Based on the white list filter, get all of the Image Datasets we can find.
		
	def selection(params)

		@driver = Jobs::ImageReconciliation::ImageDataset.joins(:visit)
						.joins("LEFT JOIN appointments ON appointments.id = visits.appointment_id")
						.joins("LEFT JOIN vgroups ON vgroups.id = appointments.vgroup_id")
						.joins("LEFT JOIN scan_procedures_vgroups ON vgroups.id = scan_procedures_vgroups.vgroup_id")
						.where("scan_procedures_vgroups.scan_procedure_id in (#{params[:scan_procedure_white_list].join(",")})")

	end

	# scan_images

	# For each image in the driver, we need to determine the state of the image. 
	# Does the image's path exist down to the containing dir?
	# 	if no, what's the longest existing subpath for this path?
	# Are there any .bz2 archives within the image's dir?
	# Does the number of .bz2 archives match the number we've got on dcm_file_count?
	# If there's an archive for the one that originally populated the image dataset,
	# 	copy that one into the temp dir, and unzip it (it would be good to record any
	# 	errors or output from this). Then get the dicom_dump.py output for this file.
	# From the dicom_dump.py output, json loads it, and compare the values in there with
	# 	the values on image dataset record. (i.e. slice count) 
	# Get a preprocessed_path for this image. Does that exist? If not, what's the longest
	# 	existing path?
	# are there any nii files that match this image under preprocessed?

	
	def scan_images(params)

		sql_file = nil
		if params[:save_to_sql]
			sql_file = File.open(params[:sql_path],'wb')
		end

		@driver.each do |image|

			raw_result = image.check_raw(params[:base_path])
			preprocessed_result = image.check_preprocessed(params[:base_path])

			# given that this will run for a long time, and we'll probbaly need to restart it / run it in samples and 
			# batches, it would probably be best if we recorded these values into the database, rather than just into 
			# a report hash.

			merged = raw_result.merge(preprocessed_result)

			reconciliation_form = Jobs::ImageReconciliation::ImageReconciliationForm.from_result(merged)

			if reconciliation_form.valid?
				sql = reconciliation_form.to_sql_insert
 
				if params[:save_to_sql]
					sql_file.write("#{sql}\n")
				end

				if params[:insert_now]
					@connection.execute(sql)
				end
			end
		end

		if params[:save_to_sql]
			sql_file.close()
		end

	end

end