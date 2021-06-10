class Jobs::Lst::LstLpaHarvester < Jobs::BaseJob

	# Like the driver class for this pipeline, the harvester is set up as a service class
	# that we can call like `job.run(params)`. Driver jobs and harvest jobs are broken up
	# by convention, as it allows more flexibility for how we run our processing, but 
	# the two could just as easily be a single sequence.
	attr_accessor :success
	attr_accessor :failed
	attr_accessor :total_cases
	attr_accessor :success_log

  	def self.default_params
		params = { schedule_name: 'LST/LPA Pipeline Harvester',
				base_path: '/mounts/data', 
    			computer: "merida",
                run_by_user: 'panda_user',
                destination_table: 'cg_lst_lpa',
                code_ver: '020',
                older_versions: ['dd1ceef-mod','fc14b99','6992d9e','20ae61c','6bbec87','d0fc77a9','b42e83aa','019','020'],
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
                code_ver: '020',
                older_versions: ['dd1ceef-mod','fc14b99','6992d9e','20ae61c','6bbec87','d0fc77a9a2','b42e83aa','019','020'],
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

			post_harvest(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)
		self.success = []
		self.success_log = []
		self.failed = []
		self.total_cases = 0
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

					# 2020-12-01 wbbevis - given that there are a lot of new versions of the code,
					# we're going to need to loop through the available code version subdirs, and
					# find the latest version with all the products we need.

					# 2021-05-26 wbbevis - We need to harvest stuff that's been processed with a
					# special "processing flag", which gets its own special subdir. We should
					# harvest this if it's the latest stuff. Bascially, there will be cases where
					# we've got both a most-recently processed subdir, and a sibling special 
					# processing subdir, and we want to be able to harvest both.

					params[:older_versions].reverse.each do |code_version|

						subject_dir_path = "#{protocol_path}/#{subject}/"

						candidate_subdirs = Dir.entries(subject_dir_path).select{|entry| (entry =~ /^[^.]/) and (entry =~ Regexp.new(code_version))}

						found_trackable = false

						candidate_subdirs.each do |subdir|
							code_version_dir = "#{subject_dir_path}#{subdir}"
							processing_flag = nil

							if (subdir =~ /_/)
								# if subdir is "020_ADNIFLAIR", then processing_flag will end up == "ADNIFLAIR"
								processing_flag = subdir.split("_").last
							end

							csv_candidates = []
							html_candidates = []

							if File.exists?(code_version_dir) and File.directory?(code_version_dir)
								filenames = Dir.entries(code_version_dir)
								csv_candidates = filenames.select{|entry| entry =~ /_lstlpa.csv$/}
								html_candidates = filenames.select{|entry| (entry =~ /.html$/) and !(entry =~ /-/)}
							end

							if html_candidates.length == 0 or csv_candidates.length != 1
								next
							else

								self.total_cases += 1
								self.success << {:protocol => protocol, :subject => subject}

								html_path = "#{code_version_dir}/#{html_candidates.first}"

								#Is there a QC tracker for this object?
								existing_tracked_image = Processedimage.where("file_path like ?","%#{html_path}%")

					            if existing_tracked_image.count > 0
					            	#this files has been QC tracked, so if it's passed, we should add it to the searchable table
					            	self.success_log << {:message => 'a case with an existing tracked image', :protocol => protocol, :subject => subject}
					            	matching_image = Trfileimage.where(:image_id => existing_tracked_image.first.id, :image_category => 'html').first

					            	if matching_image.nil?
					            		# 2021-06-10 wbbevis -- this is a failed case: we've got an existing processedimage 
					            		# without a corresponding trfileimage. Let's record this in failed so we can see them 
					            		# when harvesting manually, but otherwise next

					            		self.failed << {:message => "an existing tracked image without a matching trfileimage", :processed_image_id => existing_tracked_image.first.id}
					            	else	

						            	qc_value = matching_image.trfile.qc_value

							            if qc_value == 'Pass'
							            	# create an insert from the csv
							            	csv = CSV.open("#{code_version_dir}/#{csv_candidates.first}",:headers => true)

											new_form = LstLpaForm.from_csv(csv)
											new_form.processing_flag = processing_flag

										    if new_form.valid?
								               	sql = new_form.to_sql_insert("#{params[:destination_table]}_new")
												@connection.execute(sql)
											end
							            end
							        end

					            else
					            	#this file isn't tracked yet, so let's start tracking it
					            	self.success_log << {:message => 'a case that isnt tracked yet', :protocol => protocol, :subject => subject}

					            	#then create a trfile and add the images to it.

					            	# 2021-06-07 wbbevis - previously, we were checking for an existing tracker file. Now we're just making a new one, in order to 
					            	# accommodate special processing.
					            	# trfiles = Trfile.where("trtype_id in (?)",params[:tracker_id]).where("subjectid in (?)",subject).where(:scan_procedure_id => sp.id)

				                    trfile = Trfile.new
				                    trfile.subjectid = subject
				                    trfile.enrollment_id = enrollment.id
				                    trfile.scan_procedure_id = sp.id
				                    trfile.trtype_id = params[:tracker_id]
				                    trfile.qc_value = "New Record"
				                    trfile.save

				                    if !processing_flag.nil?
				                    	tags = TrTag.where(:name => processing_flag)
				                    	tag = tags.first
				                    	if tags.count == 0
				                    		tag = TrTag.new(:name => processing_flag)
				                    		tag.save
				                    	end

				                    	tag.trfiles << trfile
				                    	tag.save

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
					            
					            found_trackable = true
					            
					        end

					        if found_trackable
					        	break
					        end
					    end

						# elsif html_candidates.length == 0
						# 	#processing is done, but there's no product? log this.
						# 	self.error_log <<  {"message" => "Output dir exists, but there isn't any html product. (or this is a case with hyphens in the filename).", "subject" => subject, "protocol" => sp.codename}
						# 	self.failed << {:protocol => protocol, :subject => subject}
						# else
						# 	#weirdness. Too many products? Also log this.
						# 	self.error_log <<  {"message" => "More than 1 html product, maybe more than one csv?", "subject" => subject, "protocol" => sp.codename}
						# 	self.failed << {:protocol => protocol, :subject => subject}
						# end
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
		success = []
		failure = []
		sql = "select original_image_path_flair, id from cg_lst_lpa"
		result = @connection.execute(sql).to_a

		result.each do |row|
			path_parts = row[0].split("/")
			filename_parts = path_parts.last.split("_")
			sp_path = "/mounts/data/raw/#{path_parts[5]}/"
			if File.exists?(sp_path) and File.directory?(sp_path)

				if Dir.entries(sp_path).include? "mri"
					sp_path = sp_path + "mri/"
				end

				subdir = Dir.entries(sp_path).select{|item| item =~ Regexp.new(path_parts[6])}.first

				raw_glob = "#{sp_path}#{subdir}/#{filename_parts.last.gsub(/.nii/,'')}"
				#glob_hits = Dir.glob(raw_glob)
					
				visits = Visit.joins("LEFT JOIN appointments ON appointments.id = visits.appointment_id").joins("LEFT JOIN vgroups ON vgroups.id = appointments.vgroup_id").joins("LEFT JOIN enrollment_vgroup_memberships ON vgroups.id = enrollment_vgroup_memberships.vgroup_id").joins("LEFT JOIN enrollments ON enrollment_vgroup_memberships.enrollment_id = enrollments.id").joins("LEFT JOIN scan_procedures_vgroups ON vgroups.id = scan_procedures_vgroups.vgroup_id").joins("LEFT JOIN scan_procedures ON scan_procedures_vgroups.scan_procedure_id = scan_procedures.id").where("enrollments.enumber = '#{path_parts[6]}'").where("scan_procedures.codename = '#{path_parts[5]}'")

				images = visits.map(&:image_datasets).flatten

				if File.exists?(raw_glob) and File.directory?(raw_glob)

					#success!

					image = images.select{|item| item.path == raw_glob}.first

					success << {:id => row[1], :pure_corrected => image.pure_corrected?.to_s, :receive_coil_name => image.receive_coil_name, :mri_station_name => image.mri_station_name, :method => 'found by path'}

					sql = "update cg_lst_lpa set pure_corrected = '#{image.pure_corrected?.to_s}', receive_coil_name = '#{image.receive_coil_name}', mri_station_name = '#{image.mri_station_name}' where id = #{row[1]};"
					@connection.execute(sql)


				else
					# let's try something a little different

					filtered_images = images.select{|image| (image.series_description =~ /ORIG/).nil? and ((image.series_description =~ /SAG Cube T2 FLAIR/i)  or (image.series_description =~ /Sag T2 FLAIR Cube/i)  or (image.series_description =~ /Sag CUBE T2FLAIR/i) or (image.series_description =~ /Sag CUBE flair/i))}

					if filtered_images.count == 1
						image = filtered_images.first
						success << {:id => row[1], :pure_corrected => image.pure_corrected?.to_s, :receive_coil_name => image.receive_coil_name, :mri_station_name => image.mri_station_name, :method => 'found by filter'}
						
						sql = "update cg_lst_lpa set pure_corrected = '#{image.pure_corrected?.to_s}', receive_coil_name = '#{image.receive_coil_name}', mri_station_name = '#{image.mri_station_name}' where id = #{row[1]};"
						@connection.execute(sql)

					else
						failure << {:id => row[1], :path => row[0], :message => "can't find a path, filter didn't work (#{filtered_images.count})", :raw_dir => raw_glob, :scan_procedure => path_parts[5]}
					end
				end
			else
				failure << {:id => row[1], :path => row[0], :message => "paths didn't exist (scan procedure)"}
			end
		end
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

# alter table  cg_lst_lpa add column t2_prep varchar(5) default NULL;
# alter table  cg_lst_lpa add column receive_coil_name varchar(20) default NULL;
# alter table  cg_lst_lpa add column pure_corrected varchar(5) default NULL;
# alter table  cg_lst_lpa add column mri_station_name varchar(20) default NULL;
