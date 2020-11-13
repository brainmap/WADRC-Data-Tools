class Jobs::GlobalAtrophy::GlobalAtrophyHarvester < Jobs::BaseJob

	attr_accessor :success
	attr_accessor :failed
	attr_accessor :total_cases
	attr_accessor :success_log

  	def self.default_params
		params = { schedule_name: 'Global Atrophy Harvester',
				base_path: '/mounts/data', 
				processing_output_path: '/preprocessed/visits',
    			computer: "merida",
                run_by_user: 'panda_user',
                destination_table: 'cg_global_atrophy',
                tracker_id: 19
    		}
        params.default = ''
        params
    end

  	def self.production_params
		params = { schedule_name: 'Global Atrophy Harvester',
				base_path: '/mounts/data', 
				processing_output_path: '/preprocessed/visits',
    			computer: "merida",
                run_by_user: 'panda_user',
                destination_table: 'cg_global_atrophy',
                tracker_id: 19
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
		self.success = []
		self.success_log = []
		self.failed = []
		self.total_cases = 0
		# sql = "truncate #{params[:destination_table]}_new"
		# @connection.execute(sql)
	end
	
	def harvest(params)

		# then check for a tissue_volumes.csv in tissue_seg, 
		# and an rbm_icv_b90.txt in rbm_icv. 

		# Once we've got a passing case, we should check for existing trfiles in the tracker. 
		# If it's not there, make a new case in the tracker. 
		# If it is there, and there's a QC "Pass" for the file, we can write something to a table? Maybe that part should be left for the future.

		# Loop over the protocols in preprocessed/visits, 
		base_path = "#{params[:base_path]}#{params[:processing_output_path]}"
		protocol_dirs = Dir.entries(base_path).select{|entry| entry =~ /^[^.]/ and File.directory?("#{base_path}/#{entry}")}
		protocol_dirs.each do |protocol|
			sp = ScanProcedure.where(:codename => protocol).first
			protocol_path = "#{base_path}/#{protocol}"

			# then into the subjects in each folder, 
			subject_dirs = Dir.entries(protocol_path).select{|entry| entry =~ /^[^.]/ and File.directory?("#{protocol_path}/#{entry}")}
			subject_dirs.each do |subject|
				#we've got to strip some stuff here

				subject_cleaned = subject.gsub(/[a-z]$/,'').gsub(/_v1$/,'').gsub(/_v2$/,'').gsub(/_v3$/,'').gsub(/_v4$/,'').gsub(/_v5$/,'').gsub(/_v6$/,'').gsub(/_v6$/,'').gsub(/_v7$/,'')

				enrollment = Enrollment.where(:enumber => subject_cleaned).first

				if enrollment.nil?
					self.failed << {:protocol => protocol, :subject => subject, :message => "this subject id probably doesn't exist"}
					next
				end

				# check for tissue_seg and rbm_icv folders
				tissue_seg_folder = "#{protocol_path}/#{subject}/tissue_seg"
				rbm_icv_folder = "#{protocol_path}/#{subject}/rbm_icv"

				if !File.exists?(tissue_seg_folder) or !File.directory?(tissue_seg_folder)
					self.failed << {:protocol => protocol, :subject => subject, :message => "tissue_seg folder doesn't exist for this subject"}
					next
				end

				tissue_seg_filenames = Dir.entries(tissue_seg_folder)
				tissue_seg_csv = tissue_seg_filenames.select{|entry| entry =~ /tissue_volumes.csv/}.first

				if tissue_seg_csv.nil? or tissue_seg_csv.blank?
					self.failed << {:protocol => protocol, :subject => subject, :message => "no tissue_seg csv file for this subject"}
					next
				end

				if !File.exists?(rbm_icv_folder) or !File.directory?(rbm_icv_folder)
					self.failed << {:protocol => protocol, :subject => subject, :message => "rbm_icv folder doesn't exist for this subject"}
					next
				end

				rbm_icv_filenames = Dir.entries(rbm_icv_folder)
				rbm_icv_txt = rbm_icv_filenames.select{|entry| entry =~ /rbm_icv_b90.txt/}.first
				icv_mask = rbm_icv_filenames.select{|entry| entry =~ /wmask_ICV.nii/}.first

				if rbm_icv_txt.nil? or rbm_icv_txt.blank?
					self.failed << {:protocol => protocol, :subject => subject, :message => "no rbm_icv txt file for this subject"}
					next
				end
				if icv_mask.nil? or icv_mask.blank?
					self.failed << {:protocol => protocol, :subject => subject, :message => "no wmask_ICV.nii for this subject"}
					next
				end

				#unpack the csv & txt files

				tissue_seg_values = CSV.read("#{tissue_seg_folder}/#{tissue_seg_csv}",:headers => true)
				rbm_icv_value = File.read("#{rbm_icv_folder}/#{rbm_icv_txt}")

				# we should probably do some kind of check here just to make sure we've got something in those values

				# if we've made it this far, this is a good case, and we should check to see if it's already tracked
				icv_mask_path = "#{rbm_icv_folder}/#{icv_mask}"
				existing_tracked_image = Processedimage.where("file_path like ?","%#{icv_mask_path}%")

				if existing_tracked_image.count > 0
			        #this files has been QC tracked, so if it's passed, we should add it to the searchable table
			        self.success_log << {:message => 'a case with an existing tracked image', :protocol => protocol, :subject => subject}
			        matching_image = Trfileimage.where(:image_id => existing_tracked_image.first.id, :image_category => 'nii').first

			        qc_value = matching_image.trfile.qc_value

					if qc_value == 'Pass'
					    	# create an insert from the csv
					  #       csv = CSV.open("#{code_version_dir}/#{csv_candidates.first}",:headers => true)

							# new_form = LstLpaForm.from_csv(csv)

							# if new_form.valid?
						 #       	sql = new_form.to_sql_insert("#{params[:destination_table]}_new")
							# 	@connection.execute(sql)
							# end

							# What do we do here?
				    end


				else
			        #this file isn't tracked yet, so let's start tracking it
			   	    self.success_log << {:message => 'a case that isnt tracked yet', :protocol => protocol, :subject => subject}

			        #then create a trfile and add the images to it.
				    trfiles = Trfile.where("trtype_id in (?)",params[:tracker_id]).where("subjectid in (?)",subject).where(:scan_procedure_id => sp.id)
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

					image = Processedimage.new
			        image.file_type = "nii"
			        image.file_name = icv_mask
		            image.file_path = icv_mask_path
		            image.scan_procedure_id = sp.id
		            image.enrollment_id = enrollment.id
			        image.save

			        trimg = Trfileimage.new
		            trimg.trfile_id = trfile.id
		            trimg.image_id = image.id
		            trimg.image_category = "nii"
			        trimg.save
			            
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

		                    case field.description
		                    when "Brain Volume"
		                      	rating.value = (tissue_seg_values.first["Volume1"].to_f + tissue_seg_values.first["Volume2"].to_f).to_s
		                    when "CSF Volume"
		                       	rating.value = tissue_seg_values.first["Volume3"].to_f.to_s
	                        when "ICV Mask"
		                        rating.value = rbm_icv_value.strip
		                    else
			                    if !(field.form_default_value).blank?
			                        rating.value = field.form_default_value
			                    end
			                end
		                    rating.save
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
	
	def clear_tracker(params)

		files = Trfile.where(:trtype_id => params[:tracker_id])
		files.each do |file|
			file.trfileimages.each do |image|
				proc_image = Processedimage.where(:id => image.image_id).first
				if !proc_image.nil?
					proc_image.delete
				end
				image.delete
			end
			file.tredits do |tredit|
				tredit.delete
			end
			file.delete
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