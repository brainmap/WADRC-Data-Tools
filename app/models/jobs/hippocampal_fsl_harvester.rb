class Jobs::HippocampalFslHarvester < Jobs::BaseJob

  	def self.default_params
		params = { schedule_name: 'Hippocampal Volume Quality Harvester',
				base_path: '/mounts/data/preprocessed/visits', 
    			computer: "merida",
                run_by_user: 'panda_user',
                scan_procedure_blacklist: ['bendlin.mets.visit1',
                							'bendlin.tami.visit1',
                							'bendlin.wmad.visit1',
                							'carlson.sharp.visit1',
                							'carlson.sharp.visit2',
            								'carlson.sharp.visit3',
            								'carlson.sharp.visit4',
            								'dempsey.plaque.visit1',
            								'dempsey.plaque.visit2',
            								'gleason.falls.visit1',
            								'johnson.merit220.visit1',
            								'johnson.merit220.visit2',
            								'johnson.tbi.aware.visit3',
            								'johnson.tbi-va.visit1',
            								'ries.aware.visit1'],
                tracker_id: 18
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

		protocol_dirs = Dir.entries(params[:base_path]).select{|entry| entry =~ /^[^.]/ and !params[:scan_procedure_blacklist].include? entry and File.directory?("#{params[:base_path]}/#{entry}")}
		protocol_dirs.each do |protocol|
			sp = ScanProcedure.where(:codename => protocol).first
			if !sp.nil?
				protocol_path = "#{params[:base_path]}/#{protocol}"

				if File.exists?(protocol_path) and File.directory?(protocol_path)
					subject_dirs = Dir.entries(protocol_path).select{|entry| entry =~ /^[^.]/}
					subject_dirs.each do |subject|
						enrollment = Enrollment.where(:enumber => subject).first

						if enrollment.nil?
							# is this a 'b'-type 2ndary scan?
							if subject =~ /b$/ or subject =~ /\.2$/ 
								enrollment = Enrollment.where(:enumber => subject.gsub(/b$/,'').gsub(/\.2$/,'')).first

								if enrollment.nil?
									self.error_log <<  {"message" => "Can;t handle the way this subject is named.", "subject" => subject, "protocol" => sp.codename}
									next
								end
							end
						end

						first_dir = "#{protocol_path}/#{subject}/first"

						if File.exists?(first_dir) and File.directory?(first_dir)
							filenames = Dir.entries(first_dir)
							csv_candidates = filenames.select{|entry| entry =~ /_first_roi_vol.csv$/}
							html_candidates = filenames.select{|entry| entry =~ /.html$/}
							nii_candidates = filenames.select{|entry| entry =~ /.nii$/ and File.symlink?("#{first_dir}/#{entry}")}


							if html_candidates.length > 0 and csv_candidates.length == 1
								html_path = "#{first_dir}/#{html_candidates.first}"

								#Is there a QC tracker for this object?
								existing_tracked_image = Processedimage.where("file_path like ?","%#{html_path}%")

					            if existing_tracked_image.count > 0
					            	#this files has been QC tracked, so if it's passed, we should add it to the searchable table

					            	tracker = Trfileimage.where(:image_id => existing_tracked_image.first.id, :image_category => 'html')
					                qc_value = tracker.first.trfile.qc_value

					                if qc_value == 'Pass'
					                	# create an insert from the csv
					                	csv = CSV.open("#{first_dir}/#{csv_candidates.first}",:headers => true)

					                	# We need a new table for these values, rather than the LSTLPA tables.

									 #    new_form = LstLpaForm.from_csv(csv)

									 #    if new_form.valid?
						   			 #             	sql = new_form.to_sql_insert("#{params[:destination_table]}_new")
										# 	@connection.execute(sql)
										# end
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

				                    nii_candidates.each do |nii|
				                    	ref_path = File.readlink("#{first_dir}/#{nii}")

						            	image = Processedimage.new
				                        image.file_type = "nii"
				                        image.file_name = nii
				                        image.file_path = "#{ref_path}"
				                        image.scan_procedure_id = sp.id
				                        image.enrollment_id = enrollment.id
				                        image.save

					                    trimg = Trfileimage.new
				                        trimg.trfile_id = trfile.id
				                        trimg.image_id = image.id
				                        trimg.image_category = "nii"
				                        trimg.save
				                    end

									html_candidates.each do |candidate|
						            	image = Processedimage.new
				                        image.file_type = "html"
				                        image.file_name = candidate
				                        image.file_path = "#{first_dir}/#{candidate}"
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
