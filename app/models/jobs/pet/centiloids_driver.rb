class Jobs::Pet::CentiloidsDriver < Jobs::BaseJob

	attr_accessor :petscans
	attr_accessor :pettracer
	attr_accessor :driver
	attr_accessor :preprocessed_tracer_path
	attr_accessor :centiloid_csv

	def self.default_params
		params = { schedule_name: 'centiloids_driver',
				base_path: "/mounts/data/", 
    			computer: "kanga",
                tracer_id: 1,
                method: "suvr",
                run_by_user: "panda_user",
                qc_tracker_id: 10, #pib suvr
                dry_run: false
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

			matlab_call(params)

			harvest(params)

			post_harvest(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)
    	@pettracer = LookupPettracer.where("id = ?",params[:tracer_id]).first
    	@preprocessed_tracer_path = "/pet/#{@pettracer.name.downcase}/#{params[:method]}/code_ver2b"
    	@driver = {}
	end

	def selection(params)
		@petscans = Jobs::Pet::Petscan.where("petscans.lookup_pettracer_id in (?) 
                   and petscans.good_to_process_flag = 'Y'
                   and petscans.appointment_id in 
                     ( select appointments.id from appointments, vgroups 
                        where appointments.vgroup_id = vgroups.id 
                         and vgroups.transfer_pet in ('no','yes') )
                  and petscans.appointment_id not in (select appointments.id from appointments, scan_procedures_vgroups
                  where appointments.vgroup_id = scan_procedures_vgroups.vgroup_id
                  and scan_procedures_vgroups.scan_procedure_id in (?))",params[:tracer_id],params[:exclude_sp_pet_array])

		@petscans.each do |pet_appt|
        	self.inputs << "< #{pet_appt.class} id:#{pet_appt.id} >"
		end
	end
	
	def filter(params)

		scan_procedures = ScanProcedure.all().map(&:codename)
		scan_procedures.each do |codename|

			protocol_path = "#{params[:base_path]}preprocessed/visits/#{codename}"
			if Dir.exists?(protocol_path)

				subject_ids = Dir.entries(protocol_path) - ['.','..']
				subject_ids.each do |subject_id|
					path = "#{protocol_path}/#{subject_id}#{@preprocessed_tracer_path}"
					if Dir.exists?(path)
						# there may be cases where the "subject_id" here isn't quite what we
						# expect a subject_id to be elsewhere, i.e. when they rescan a subject),
						# sometimes they'll append a "_v2" to the id. The scan is filed with a
						# "subject_id_v2" in the filesystem, but might not have the "_v2" in 
						# nii product.

						cleaned_subject_id = subject_id.split("_")

						analysis_logs = Dir.glob("#{path}/*analysis-log*.mat")
						centiloids_logs = Dir.glob("#{path}/*centiloids-log*.csv")
						images = Dir.glob("#{path}/w#{cleaned_subject_id[0]}*pib_suvr*_2b.nii")

						# We're also going to need only QC'd images, so if there isn't a QC pass in the tracker for a processed image
						# in this dir, fail the case.

						# here, file_type should be something like "suvr pib"
		                processed_images = Processedimage.where(:file_path => images.map{|img| "#{path}/#{img}"}.join(",")).where(:file_type => "#{params[:method].downcase} #{@pettracer.name.downcase}")
		                qc_values = []

			            if processed_images.count > 0
			                tracker = Trfileimage.joins(:trfile).where("trfiles.trtype_id = #{params[:qc_tracker_id]}").where(:image_id => processed_images.map(&:id), :image_category => 'processedimage')
			                tracker.each do |tr|
				                qc_values += [tr.trfile.qc_value]
				            end
			            end

						if analysis_logs.length > 0 and centiloids_logs.length == 0 and qc_values.include?('Pass')
							#if there is one, let's add it to the list under this subject
							analysis_log_path = "#{path}/#{analysis_logs.first}"
							output_path = "#{path}/#{cleaned_subject_id[0]}_centiloids-log_#{@pettracer.name.downcase}_#{params[:method]}_#{codename}.csv"

							# The key to the driver should be the preprocessed path, not the enumber, because enumbers can
							# have multiple enrollments.
							@driver[path] = {:analysis_log => analysis_log_path,:output => output_path}

							self.outputs << "< #{codename} #{subject_id} output_path:#{output_path}>"
						else 
							if analysis_logs.length == 0
								self.exclusions << {:protocol => codename, :subject => subject_id, :message => 'no analysis-log.mat file'}
							elsif centiloids_logs.length > 0
								self.exclusions << {:protocol => codename, :subject => subject_id, :message => 'already has a centiloids-log.csv'}
							elsif !qc_values.include?('Pass')
								self.exclusions << {:protocol => codename, :subject => subject_id, :message => 'hasnt passed QC'}
							end
						end
					else
						self.exclusions << "< #{codename} #{subject_id} message:'paths not ok'>"
					end
				end
			end
		end
	end

	def cleanup_centiloids_products(petscan_path,globs=["*centiloids-log*.csv","*centiloid*.csv.error"])
		globs.each do |glob_pattern|
			matching_products = Dir.glob("#{petscan_path}/#{glob_pattern}")
			matching_products.each do |product_path|
				File.delete(product_path)
			end
		end
	end

	def write_driver(params)
		#write out the csv
		require 'csv'
		filename_suffix = !!!(params[:dry_run]) ? "_dry_run" : ""
		@centiloid_csv = "#{params[:base_path]}preprocessed/logs/parallel_driver/#{Date.today.strftime("%Y-%m-%d")}_#{@pettracer.name.downcase}_#{params[:method]}_centiloids_driver#{filename_suffix}.csv"
		CSV.open(@centiloid_csv, 'wb', row_sep: "\n", encoding: "UTF-8") do |writer|

        	writer << ["analysis_log", "output_path"].map{|s| s.encode("UTF-8")}

        	@driver.values.each do |row|
        		writer << [row[:analysis_log], row[:output]].map{|s| s.to_s.encode("UTF-8")}
      		end
    	end
	end
	
	def matlab_call(params)
		if !!!(params[:dry_run])
			require 'open3'

			#this is code from the pet driver. make the call something like this

	        pet_scripts_dir="/mounts/data/analyses/rvcadman/centiloidcalc"
	        matlab_template = "export MATLABPATH=$MATLABPATH:#{pet_scripts_dir}" + " && matlab -nodesktop -nosplash -r \\\"try %{command}; catch exception; display(getReport(exception)); pause(1); end; exit;\\\""
	        matlab_command = matlab_template % {command: "computecentiloid('#{@centiloid_csv}','#{@pettracer.name.downcase}','#{params[:method]}')"}
	        v_computer = params[:computer]
	        v_call =  "ssh panda_user@#{v_computer}.dom.wisc.edu \"#{matlab_command}\""

	        self.log << "calling #{v_call}"
	        begin
	        	stdin, stdout, stderr = Open3.popen3(v_call)
		        while !stdout.eof?
		        	v_output = stdout.read 1024 
		        	#  v_comment = v_comment + v_output  
		        	self.log << v_output  
		        end
	        rescue => msg
	        	self.error_log << "error #{msg.to_s}"
	        end
		end
	end
	
	def harvest(params)
	end
	
	def post_harvest(params)
	end

end


# CREATE TABLE `cg_centiloids` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `petscan_id` int(11) DEFAULT NULL,
#   `subject_id` varchar(255) DEFAULT NULL,
#   `centiloid_value` float DEFAULT NULL,
#   `reference_roi` varchar(255) DEFAULT NULL,
#   `signal_roi` varchar(255) DEFAULT NULL,
#   `method` varchar(50) DEFAULT NULL,
#   `signal_value` float DEFAULT NULL,
#   `reference_value` float DEFAULT NULL,
#   `renormalized_value` float DEFAULT NULL,
#   `age_at_appointment` float DEFAULT NULL,
#   `source_file_path` varchar(500) DEFAULT NULL,
#   `input_file_path` varchar(500) DEFAULT NULL,
#   `image_path` varchar(500) DEFAULT NULL,
#   `code_version` varchar(50) DEFAULT NULL,
#   `created_at` datetime DEFAULT NULL,
#   `processed_at` datetime DEFAULT NULL,
#   PRIMARY KEY (`id`),
#   KEY `petscan_id` (`petscan_id`)
# );

# CREATE TABLE `cg_centiloids_new` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `petscan_id` int(11) DEFAULT NULL,
#   `subject_id` varchar(255) DEFAULT NULL,
#   `centiloid_value` float DEFAULT NULL,
#   `reference_roi` varchar(255) DEFAULT NULL,
#   `signal_roi` varchar(255) DEFAULT NULL,
#   `method` varchar(50) DEFAULT NULL,
#   `signal_value` float DEFAULT NULL,
#   `reference_value` float DEFAULT NULL,
#   `renormalized_value` float DEFAULT NULL,
#   `age_at_appointment` float DEFAULT NULL,
#   `source_file_path` varchar(500) DEFAULT NULL,
#   `input_file_path` varchar(500) DEFAULT NULL,
#   `image_path` varchar(500) DEFAULT NULL,
#   `code_version` varchar(50) DEFAULT NULL,
#   `created_at` datetime DEFAULT NULL,
#   `processed_at` datetime DEFAULT NULL,
#   PRIMARY KEY (`id`),
#   KEY `petscan_id` (`petscan_id`)
# );

# CREATE TABLE `cg_centiloids_old` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `petscan_id` int(11) DEFAULT NULL,
#   `subject_id` varchar(255) DEFAULT NULL,
#   `centiloid_value` float DEFAULT NULL,
#   `reference_roi` varchar(255) DEFAULT NULL,
#   `signal_roi` varchar(255) DEFAULT NULL,
#   `method` varchar(50) DEFAULT NULL,
#   `signal_value` float DEFAULT NULL,
#   `reference_value` float DEFAULT NULL,
#   `renormalized_value` float DEFAULT NULL,
#   `age_at_appointment` float DEFAULT NULL,
#   `source_file_path` varchar(500) DEFAULT NULL,
#   `input_file_path` varchar(500) DEFAULT NULL,
#   `image_path` varchar(500) DEFAULT NULL,
#   `code_version` varchar(50) DEFAULT NULL,
#   `created_at` datetime DEFAULT NULL,
#   `processed_at` datetime DEFAULT NULL,
#   PRIMARY KEY (`id`),
#   KEY `petscan_id` (`petscan_id`)
# );

# CREATE TABLE `cg_centiloids_edit` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `petscan_id` int(11) DEFAULT NULL,
#   `subject_id` varchar(255) DEFAULT NULL,
#   `centiloid_value` float DEFAULT NULL,
#   `reference_roi` varchar(255) DEFAULT NULL,
#   `signal_roi` varchar(255) DEFAULT NULL,
#   `method` varchar(50) DEFAULT NULL,
#   `signal_value` float DEFAULT NULL,
#   `reference_value` float DEFAULT NULL,
#   `renormalized_value` float DEFAULT NULL,
#   `age_at_appointment` float DEFAULT NULL,
#   `source_file_path` varchar(500) DEFAULT NULL,
#   `input_file_path` varchar(500) DEFAULT NULL,
#   `image_path` varchar(500) DEFAULT NULL,
#   `code_version` varchar(50) DEFAULT NULL,
#   `created_at` datetime DEFAULT NULL,
#   `processed_at` datetime DEFAULT NULL,
#   PRIMARY KEY (`id`),
#   KEY `petscan_id` (`petscan_id`)
# );