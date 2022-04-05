class Jobs::Atrophy::AtrophyHarvester < Jobs::BaseJob

	attr_accessor :success
	attr_accessor :failed
	attr_accessor :total_cases
	attr_accessor :success_log

  	def self.default_params
		params = { schedule_name: 'CAT12 Atrophy Pipeline Harvester',
				base_path: '/mounts/data', 
    			computer: "moana",
                run_by_user: 'panda_user',
                destination_table: 'cg_atrophy',
                roi_destination_table: 'cg_atrophy_roi',
                code_ver: '009',
                older_versions: ['007','008','009'],
                processing_output_path: "/mounts/data/development/atrophy/output",
                tracker_id: 38
    		}
        params.default = ''
        params
    end

  	def self.production_params
		params = { schedule_name: 'CAT12 Atrophy Pipeline Harvester',
				base_path: '/mounts/data', 
    			computer: "moana",
                run_by_user: 'panda_user',
                destination_table: 'cg_atrophy',
                roi_destination_table: 'cg_atrophy_roi',
                code_ver: '009',
                older_versions: ['009'],
                processing_output_path: "/mounts/data/pipelines/atrophy/output",
                tracker_id: 38
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

			# post_harvest(params)
		
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
		sql = "truncate #{params[:roi_destination_table]}_aal3"
		@connection.execute(sql)
		sql = "truncate #{params[:roi_destination_table]}_cobra"
		@connection.execute(sql)
		sql = "truncate #{params[:roi_destination_table]}_julichbrain"
		@connection.execute(sql)
		sql = "truncate #{params[:roi_destination_table]}_neuromorphometrics"
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

					params[:older_versions].reverse.each do |code_version|

						subject_dir_path = "#{protocol_path}/#{subject}/"

						candidate_subdirs = Dir.entries(subject_dir_path).select{|entry| (entry =~ /^[^.]/) and (entry =~ Regexp.new(code_version))}

						found_trackable = false
						found_non_special = false

						candidate_subdirs.each do |subdir|
							code_version_dir = "#{subject_dir_path}#{subdir}"
							report_subdir = "#{code_version_dir}/report"
							processing_flag = nil

							if (subdir =~ /_/)
								# if subdir is "020_ADNIFLAIR", then processing_flag will end up == "ADNIFLAIR"
								processing_flag = subdir.split("_").last
							end

							csv_candidates = []
							pdf_candidates = []

							# CSV
							if File.exists?(code_version_dir) and File.directory?(code_version_dir)
								filenames = Dir.entries(code_version_dir)
								csv_candidates = filenames.select{|entry| entry =~ /atrophy[0-9a-zA-Z_-]*\.csv$/}
							end

							# PDF
							# if File.exists?(report_subdir) and File.directory?(report_subdir)
							# 	filenames = Dir.entries(report_subdir)
							# 	pdf_candidates = filenames.select{|entry| (entry =~ /\.pdf$/)}
							# end

							if csv_candidates.length != 2
								next
							else

								self.total_cases += 1
								self.success << {:protocol => protocol, :subject => subject}

								# pdf_path = "#{report_subdir}/#{pdf_candidates.first}"

								command_path = "/mounts/data/pipelines/atrophy/src/atrophyqc.sh /mounts/data/pipelines/atrophy/output/#{protocol}/#{subject}/#{code_version}"

								summary_csv = csv_candidates.select{|entry| entry =~ /summary/}
								roi_csv = csv_candidates.select{|entry| entry =~ /roiVolumes/}

								# csv report
			                    csv_path = "#{code_version_dir}/#{summary_csv.first}"

			                    # we may need these values in just a minute
			                    csv_data = Hash.new("")
			                    CSV.foreach(csv_path, :headers => true) do |row|
			                      csv_data[row["Description"]] = row["Value"].to_s.strip
			                    end

								#We're not quite tracking images like we are in other places. 
								existing_tracked_image = Processedimage.where("file_path like ?","%#{command_path}%")

					            if existing_tracked_image.count > 0
					            	#this files has been QC tracked, so if it's passed, we should add it to the searchable table
					            	self.success_log << {:message => 'a case with an existing tracked image', :protocol => protocol, :subject => subject}
					            	matching_image = Trfileimage.where(:image_id => existing_tracked_image.first.id, :image_category => 'command').first

					            	if matching_image.nil? or matching_image.trfile.nil?
					            		# 2021-06-10 wbbevis -- this is a failed case: we've got an existing processedimage 
					            		# without a corresponding trfileimage. Let's record this in failed so we can see them 
					            		# when harvesting manually, but otherwise next

					            		self.failed << {:message => "an existing tracked image without a matching trfileimage", :processed_image_id => existing_tracked_image.first.id}
					            	else	

						            	qc_value = matching_image.trfile.qc_value

							            if qc_value == 'Pass'
							            	# create an insert from the csv
							            	#the global products table
							            	csv = CSV.open("#{code_version_dir}/#{summary_csv.first}",:headers => true)

											new_form = AtrophyForm.from_csv(csv)
											new_form.processing_flag = processing_flag

										    if new_form.valid?
								               	sql = new_form.to_sql_insert("#{params[:destination_table]}_new")
												@connection.execute(sql)
											end

											#ROIs
								        	roi = CSV.open("#{code_version_dir}/#{roi_csv.first}",:headers => true)
								        	# puts "#{code_version_dir}/#{roi_csv.first}"

								        	roi.each do |roi_row|

								        		# puts "roi_row is #{roi_row.to_h}"

												new_roi_form = AtrophyRoiForm.from_csv(roi_row,subject,sp.codename)

											    if new_roi_form.valid?
										           	
											    	case new_roi_form.atlas
											    	when 'aal3'
										           		sql = new_roi_form.to_sql_insert("#{params[:roi_destination_table]}_aal3")
														connection.execute(sql)

											    	when 'cobra'
										           		sql = new_roi_form.to_sql_insert("#{params[:roi_destination_table]}_cobra")
														connection.execute(sql)

													when 'julichbrain'	
										           		sql = new_roi_form.to_sql_insert("#{params[:roi_destination_table]}_julichbrain")
														connection.execute(sql)
														
													when 'neuromorphometrics'	
										           		sql = new_roi_form.to_sql_insert("#{params[:roi_destination_table]}_neuromorphometrics")
														connection.execute(sql)
														
										           	end
												end
											end
							            end
							        end

					            else
					            	#this file isn't tracked yet, so let's start tracking it
					            	self.success_log << {:message => 'a case that isnt tracked yet', :protocol => protocol, :subject => subject}

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

				                    else
				                    	found_non_special = true
				                    end

					            	image = Processedimage.new
				                    image.file_type = "command"
				                    image.file_name = command_path
			                        image.file_path = command_path
			                        image.scan_procedure_id = sp.id
			                        image.enrollment_id = enrollment.id
				                    image.save

					                trimg = Trfileimage.new
				                    trimg.trfile_id = trfile.id
				                    trimg.image_id = image.id
				                    trimg.image_category = "command"
				                    trimg.save

				                    tredit = Tredit.new
			                       	tredit.trfile_id = trfile.id
			                       	tredit.save

			                       	#and set up the fields on this file
			                       	qc_fields = Tractiontype.where("trtype_id in (?)",params[:tracker_id])
			                       	if qc_fields.count > 0

			                       		#TIV
			                       		tiv_field = qc_fields.select{|item| item.description == 'Total Intracranial Volume'}.first
			                            tiv_rating = TreditAction.new
			                            tiv_rating.tredit_id = tredit.id
			                            tiv_rating.tractiontype_id = tiv_field.id
			                            tiv_rating.value = csv_data["TIV"].to_s
			                            tiv_rating.save

			                       		#GM volume
			                       		gm_field = qc_fields.select{|item| item.description == 'GM Volume'}.first
			                            gm_rating = TreditAction.new
			                            gm_rating.tredit_id = tredit.id
			                            gm_rating.tractiontype_id = gm_field.id
			                            gm_rating.value = csv_data["GM volume"].to_s
			                            gm_rating.save

			                       		#WM volume
			                       		wm_field = qc_fields.select{|item| item.description == 'WM Volume'}.first
			                            wm_rating = TreditAction.new
			                            wm_rating.tredit_id = tredit.id
			                            wm_rating.tractiontype_id = wm_field.id
			                            wm_rating.value = csv_data["WM volume"].to_s
			                            wm_rating.save

			                       		#CSF volume
			                       		csf_field = qc_fields.select{|item| item.description == 'CSF Volume'}.first
			                            csf_rating = TreditAction.new
			                            csf_rating.tredit_id = tredit.id
			                            csf_rating.tractiontype_id = csf_field.id
			                            csf_rating.value = csv_data["CSF volume"].to_s
			                            csf_rating.save

			                       		#WMH volume
			                       		wmh_field = qc_fields.select{|item| item.description == 'WMH Volume'}.first
			                            wmh_rating = TreditAction.new
			                            wmh_rating.tredit_id = tredit.id
			                            wmh_rating.tractiontype_id = wmh_field.id
			                            wmh_rating.value = csv_data["WMH volume"].to_s
			                            wmh_rating.save

			                       		#%IQR
			                       		iqr_pct_field = qc_fields.select{|item| item.description == '%IQR'}.first
			                            iqr_pct_rating = TreditAction.new
			                            iqr_pct_rating.tredit_id = tredit.id
			                            iqr_pct_rating.tractiontype_id = iqr_pct_field.id
			                            iqr_pct_rating.value = csv_data["%IQR"].to_s
			                            iqr_pct_rating.save

			                       		#IQR letter grade
			                       		iqr_letter_field = qc_fields.select{|item| item.description == 'IQR Letter Grade'}.first
			                            iqr_letter_rating = TreditAction.new
			                            iqr_letter_rating.tredit_id = tredit.id
			                            iqr_letter_rating.tractiontype_id = iqr_letter_field.id
			                            iqr_letter_rating.value = csv_data["IQR letter grade"].to_s
			                            iqr_letter_rating.save

			                       		#Rating
			                       		# rating_field = qc_fields.select{|item| item.description == 'Rating'}.first
			                         #    rating_rating = TreditAction.new
			                         #    rating_rating.tredit_id = tredit.id
			                         #    rating_rating.tractiontype_id = rating_field.id
			                         #    rating_rating.value = "Pass"
			                         #    rating_rating.save

			                       		#Rating comment
			                       		comment_field = qc_fields.select{|item| item.description == 'QC Rating Comment'}.first
			                            comment_rating = TreditAction.new
			                            comment_rating.tredit_id = tredit.id
			                            comment_rating.tractiontype_id = comment_field.id
			                            comment_rating.value = ""
			                            comment_rating.save
			                       	end
					            end
					            
					            found_trackable = true
					            
					        end

					        if found_trackable and found_non_special
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

end


# CREATE TABLE `cg_atrophy_new` (
#   `id` int NOT NULL AUTO_INCREMENT,
# `subject_id` varchar(255) DEFAULT NULL,
# `scan_procedure` varchar(255) DEFAULT NULL,
# `os_version` varchar(255) DEFAULT NULL,
# `matlab_version` varchar(255) DEFAULT NULL,
# `spm_version` varchar(255) DEFAULT NULL,
# `spm_revision` varchar(255) DEFAULT NULL,
# `cat12_release` varchar(255) DEFAULT NULL,
# `cat12_version` varchar(255) DEFAULT NULL,
# `cat12_date` varchar(20) DEFAULT NULL,
# `atrophy_local_code_version` varchar(255) DEFAULT NULL,
# `original_image_path` varchar(255) DEFAULT NULL,
# `tiv` float DEFAULT NULL,
# `gm_volume` float DEFAULT NULL,
# `wm_volume` float DEFAULT NULL,
# `csf_volume` float DEFAULT NULL,
# `wmh_volume` float DEFAULT NULL,
# `iqr_percent` float DEFAULT NULL,
# `iqr_letter_grade` float DEFAULT NULL,
# `created_at` datetime DEFAULT NULL,
# `processed_at` datetime DEFAULT NULL,
# `participant_id` int(11) DEFAULT NULL,
#   PRIMARY KEY (`id`)
#   );
