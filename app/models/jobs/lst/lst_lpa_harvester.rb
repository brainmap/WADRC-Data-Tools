class Jobs::Lst::LstLpaHarvester < Jobs::BaseJob

	# Like the driver class for this pipeline, the harvester is set up as a service class
	# that we can call like `job.run(params)`. Driver jobs and harvest jobs are broken up
	# by convention, as it allows more flexibility for how we run our processing, but 
	# the two could just as easily be a single sequence.

  	def self.default_params
		params = { schedule_name: 'LST/LPA Pipeline Harvester',
				base_path: '/mounts/data', 
    			computer: "merida",
                run_by_user: 'panda_user',
                destination_table: 'cg_lst_lpa',
                code_ver: 'dd1ceef-mod',
                processing_output_path: "/mounts/data/development/lstlpa/output",
                tracker_id: 17
    		}
        params.default = ''
        params
    end

  	def self.production_params
		params = { schedule_name: 'LST/LPA Pipeline Harvester',
				base_path: '/mounts/data', 
    			computer: "merida",
                run_by_user: 'panda_user',
                destination_table: 'cg_lst_lpa',
                code_ver: 'dd1ceef-mod',
                processing_output_path: "/mounts/data/pipelines/lstlpa/output",
                tracker_id: 17
    		}
        params.default = ''
        params
    end


	def run(params)

		begin
			setup(params)

			harvest(params)

			rotate_tables(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)
		sql = "truncate #{params[:destination_table]}_new"
		@connection.execute(sql)
	end
	
	def harvest(params)
		#loop over any results, and collect them in a _new table
		if !File.exists?(params[:processing_output_path]) or !File.directory?(params[:processing_output_path])
			self.error_log <<  {"message" => "Output dir doesn't exist or isn't a dir."}
			return
		end

		protocol_dirs = Dir.entries(params[:processing_output_path]).select{|entry| entry =~ /^[^.]/}
		protocol_dirs.each do |protocol|
			sp = ScanProcedure.where(:codename => protocol).first
			protocol_path = "#{params[:processing_output_path]}/#{protocol}"

			if File.exists?(protocol_path) and File.directory?(protocol_path)
				subject_dirs = Dir.entries(protocol_path).select{|entry| entry =~ /^[^.]/}
				subject_dirs.each do |subject|
					enrollment = Enrollment.where(:enumber => subject).first

					code_version_dir = "#{protocol_path}/#{subject}/#{params[:code_ver]}"

					if File.exists?(code_version_dir) and File.directory?(code_version_dir)
						filenames = Dir.entries(code_version_dir)
						csv_candidates = filenames.select{|entry| entry =~ /_lstlpa.csv$/}
						html_candidates = filenames.select{|entry| entry =~ /.html$/}

						if html_candidates.length > 0 and csv_candidates.length == 1
							html_path = "#{code_version_dir}/#{html_candidates.first}"

							#Is there a QC tracker for this object?
							existing_tracked_image = Processedimage.where("file_path like ?","%#{html_path}%")

				            if existing_tracked_image.count > 0
				            	#this files has been QC tracked, so if it's passed, we should add it to the searchable table

				            	tracker = Trfileimage.where(:image_id => existing_tracked_image.first.id, :image_category => 'html')
				                qc_value = tracker.first.trfile.qc_value

				                if qc_value == 'Pass'
				                	# create an insert from the csv
				                	csv = CSV.open("#{code_version_dir}/#{csv_candidates.first}",:headers => true)

								    new_form = LstLpaForm.from_csv(csv)

								    if new_form.valid?
					                	sql = new_form.to_sql_insert("#{params[:destination_table]}_new")
										@connection.execute(sql)
									end
				                end

				            else
				            	#this file isn't tracked yet, so let's start tracking it

				            	#then create a trfile and add the images to it.
				            	trfiles = Trfile.where("trtype_id in (?)",params[:tracker_id]).where("subjectid in (?)",subject)
			                    trfile = trfiles.first
			                    if trfiles.count == 0
			                       trfile = Trfile.new
			                       trfile.subjectid = subject
			                       trfile.enrollment_id = enrollment.id
			                       trfile.scan_procedure_id = sp.id
			                       trfile.trtype_id = params[:tracker_id]
			                       trfile.qc_value = "New Record"
			                       trfile.save
			                    end

								html_candidates.each do |candidate|

					            	image = Processedimage.new
			                        image.file_type = "html"
			                        image.file_name = candidate
			                        image.file_path = "#{code_version_dir}/#{candidate}"
			                        image.scan_procedure_id = sp.id
			                        image.enrollment_id = enrollment.id
			                        image.save

				                    trimg = Trfileimage.new
			                        trimg.trfile_id = trfile.id
			                        trimg.image_id = image.id
			                        trimg.image_category = "html"
			                        trimg.save
			                    end

			                    tredit = Tredit.new
		                       	tredit.trfile_id = trfile.id
		                       	tredit.save

		                       	#and set up the fields on this file
		                       	qc_fields = Tractiontype.where("trtype_id in (?)",params[:tracker_id])
		                       	if qc_fields.count > 0
		                        	qc_fields.each do |field|
		                            	rating = TreditAction.new
		                            	rating.tredit_id = tredit.id
		                            	rating.tractiontype_id = field.id
		                            	if !(field.form_default_value).blank?
		                               		rating.value = field.form_default_value
		                            	end
		                            	rating.save
		                          	end
		                       	end
				            end

						elsif html_candidates.length == 0
							#processing is done, but there's no product? log this.
							self.error_log <<  {"message" => "Output dir exists, but there isn't any html product.", "subject" => subject, "protocol" => sp.codename}
						else
							#weirdness. Too many products? Also log this.
							self.error_log <<  {"message" => "More than 1 html product, maybe more than one csv?", "subject" => subject, "protocol" => sp.codename}
						end
					end
				end
			end
		end

	end
	
	def rotate_tables(params)
		sql = "truncate table #{params[:destination_table]}_old"
		@connection.execute(sql)
		sql = "insert into #{params[:destination_table]}_old select * from #{params[:destination_table]}"
		@connection.execute(sql)
		sql = "truncate table #{params[:destination_table]}"
		@connection.execute(sql)
		sql = "insert into #{params[:destination_table]} select * from #{params[:destination_table]}_new"
		@connection.execute(sql)
	end
	
	def post_harvest(params)
	end


end


# CREATE TABLE `cg_lst_lpa` (
#   `id` int NOT NULL AUTO_INCREMENT,
# `subject_id` varchar(255) DEFAULT NULL,
# `scan_procedure` varchar(255) DEFAULT NULL,
# `os_version` varchar(255) DEFAULT NULL,
# `matlab_version` varchar(255) DEFAULT NULL,
# `spm_version` varchar(255) DEFAULT NULL,
# `spm_revision` varchar(255) DEFAULT NULL,
# `lst_version` varchar(255) DEFAULT NULL,
# `lstlpa_local_code_version` varchar(255) DEFAULT NULL,
# `original_image_path_flair` varchar(255) DEFAULT NULL,
# `original_image_path_T1` varchar(255) DEFAULT NULL,
# `lesion_volume_ml` float DEFAULT NULL,
# `number_of_lesions` int(11) DEFAULT NULL,
# `created_at` datetime DEFAULT NULL,
# `processed_at` datetime DEFAULT NULL,
# `participant_id` int(11) DEFAULT NULL,
#   PRIMARY KEY (`id`)
#   );