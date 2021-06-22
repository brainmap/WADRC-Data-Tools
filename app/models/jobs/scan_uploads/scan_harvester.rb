class Jobs::ScanUploads::ScanHarvester < Jobs::BaseJob

	# 2021-06-21 wbbevis -- This is a harvester used to populate the a tracker used for tracking uploads to the SCAN protocol
	# sharing system with NACC. 

	attr_accessor :success
	attr_accessor :failed
	attr_accessor :total_cases
	attr_accessor :success_log
	attr_accessor :scan_procedure_whitelist

  	def self.default_params
		params = { schedule_name: 'SCAN Upload Harvester',
				base_path: '/mounts/data', 
				processing_output_path: '/preprocessed/visits',
				scan_relevant_whitelist: [22, 65, 89, 119, 105, 106, 117, 150, 126],
				tracer_whitelist: [1, 11],
    			computer: "moana",
                run_by_user: 'panda_user',
                tracker_id: 20
    		}
        params.default = ''
        params
    end

  	def self.production_params
		params = { schedule_name: 'SCAN Upload Harvester',
				base_path: '/mounts/data', 
				processing_output_path: '/preprocessed/visits',
				scan_relevant_whitelist: [22, 65, 89, 119, 105, 106, 117, 150, 126],
				tracer_whitelist: [1, 11],
    			computer: "moana",
                run_by_user: 'panda_user',
                tracker_id: 20
    		}
        params.default = ''
        params
    end


	def run(params)

		begin
			setup(params)

			harvest(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)
		@success = []
		@success_log = []
		@failed = []
		@total_cases = 0
		@scan_procedure_whitelist = ScanProcedure.where(:id => params[:scan_relevant_whitelist])
		# sql = "truncate #{params[:destination_table]}_new"
		# @connection.execute(sql)
	end

	def harvest(params)

		relevant_vgroups = Vgroup.joins(:scan_procedures).where("scan_procedures.id in (#{params[:scan_relevant_whitelist].join(',')})").uniq
		relevant_vgroups.each do |vgroup|
			
			# is this an adrc case?
			participants = Participant.where(:id => vgroup.enrollments.map(&:participant_id)).uniq.compact

			if participants.count > 1
				@failed << {:message => "this vgroup has too many participants", :vgroup_id => vgroup.id, :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}
				next
			elsif participants.count == 0 or participants.first.nil?
				@failed << {:message => "this vgroup doesn't have enough participants", :vgroup_id => vgroup.id, :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}
				next
			end

			ppt = participants.first

			if ppt.adrcnum.nil? or ppt.adrcnum.blank?
				@failed << {:message => "this participant isn't ADRC", :vgroup_id => vgroup.id, :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}
				next
			end

			# ok, do we have the right scans?

			visits = Visit.where(:appointment_id => vgroup.appointments.map(&:id))

			visits.each do |visit|
				# we should really do one upload for each visit if there are multiple visits. So each visit gets its own tracker file.
				images = visit.image_datasets

				ir_fspgr = images.select{|img| img.series_description =~ /Accelerated Sagittal IR-FSPGR/i}
				sag_3d_flair = images.select{|img| img.series_description =~ /Sagittal 3D FLAIR/i}

				if ir_fspgr.count > 1
					@failed << {:message => "too many IR-FSPGR on this visit", :vgroup_id => vgroup.id, :visit_id => visit.id, :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}
					next
				end

				if sag_3d_flair.count > 1
					@failed << {:message => "too many Sagittal 3D FLAIR on this visit", :vgroup_id => vgroup.id, :visit_id => visit.id, :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}
					next
				end

				if ir_fspgr.count < 1
					@failed << {:message => "not enough IR-FSPGR on this visit", :vgroup_id => vgroup.id, :visit_id => visit.id, :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}
					next
				end

				if sag_3d_flair.count < 1
					@failed << {:message => "not enough Sagittal 3D FLAIR on this visit", :vgroup_id => vgroup.id, :visit_id => visit.id, :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}
					next
				end

				# ok, so this case is looking good. Has it already been tracked?

				existing_files = Trfile.joins(:tr_tags).where(:trtype_id => params[:tracker_id]).where(:scan_procedure_id => vgroup.scan_procedures.map(&:id)).where(:enrollment_id => vgroup.enrollments.map(&:id)).where("tr_tags.name = 'SCAN_MRI'")

				if existing_files.count > 0

					# this is case is already being tracked in this tracker. 
					# right now, we don't have to do anything to these guys.

					next
				else
					@success_log << {:message => 'a case that isnt tracked yet', :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}

					enrollment = vgroup.enrollments.first
					scan_procedure = vgroup.scan_procedures.select{|item| params[:scan_relevant_whitelist].include? item.id}.first

			        #then create a trfile and add the images to it.
			        trfile = Trfile.new
			        trfile.subjectid = enrollment.enumber
			        trfile.enrollment_id = enrollment.id
			        trfile.scan_procedure_id = scan_procedure.id
		            trfile.trtype_id = params[:tracker_id]
		            trfile.qc_value = "New Record"
			        trfile.save
			        
			        # ir_fspgr
			        trimg = Trfileimage.new
		            trimg.trfile_id = trfile.id
		            trimg.image_id = ir_fspgr.first.id
		            trimg.image_category = "image_dataset"
			        trimg.save

			        # sag_3d_flair
			        trimg = Trfileimage.new
		            trimg.trfile_id = trfile.id
		            trimg.image_id = sag_3d_flair.first.id
		            trimg.image_category = "image_dataset"
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
		                    when "ADRC Number"
		                      	rating.value = ppt.adrcnum
		                    when "Scan date"
		                      	rating.value = visit.date.strftime("%y-%m-%d")
		            		
		                    else
			                    if !(field.form_default_value).blank?
			                        rating.value = field.form_default_value
			                    end
			                end
		                    rating.save
	                    end
				    end

				    # and tag this as SCAN_MRI
				    tags = TrTag.where(:name => "SCAN_MRI")
				    tag = tags.first
				    if tags.count == 0
				    	tag = TrTag.new(:name => "SCAN_MRI")
				    	tag.save
				    end

				    tag.trfiles << trfile
				    tag.save

				end

			end
			
			# and also check this vgroup for PET
			pet_appts = Petscan.where(:appointment_id => vgroup.appointments.map(&:id))

			pet_appts.each do |pet_appt|
				# We need to check this against the PET tracer whitelist

				if !(params[:tracer_whitelist].include? pet_appt.lookup_pettracer_id)
					@failed << {:message => "PET appt doesn't have a whitelisted tracer", :vgroup_id => vgroup.id, :petscan_id => pet_appt.id, :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}
					next
				end

				# ok, so this case is looking good. Has it already been tracked?

				existing_files = Trfile.joins(:tr_tags).where(:trtype_id => params[:tracker_id]).where(:scan_procedure_id => vgroup.scan_procedures.map(&:id)).where(:enrollment_id => vgroup.enrollments.map(&:id)).where("tr_tags.name = 'SCAN_PET'")

				if existing_files.count > 0

					# this is case is already being tracked in this tracker. 
					# right now, we don't have to do anything to these guys.

					next
				else
					@success_log << {:message => 'a case that isnt tracked yet', :scan_procedure => vgroup.scan_procedures.map(&:codename).join(','), :enrollment => vgroup.enrollments.map(&:enumber).join(',')}

					enrollment = vgroup.enrollments.first
					scan_procedure = vgroup.scan_procedures.select{|item| params[:scan_relevant_whitelist].include? item.id}.first
					tracer = LookupPettracer.where(:id => pet_appt.lookup_pettracer_id).first
					appointment = Appointment.where(:id => pet_appt.appointment_id).first

			        trfile = Trfile.new
			        trfile.subjectid = enrollment.enumber
			        trfile.enrollment_id = enrollment.id
			        trfile.scan_procedure_id = scan_procedure.id
		            trfile.trtype_id = params[:tracker_id]
		            trfile.qc_value = "New Record"
			        trfile.save
			            
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
		                    when "ADRC Number"
		                      	rating.value = ppt.adrcnum
		                    when "Tracer"
		                      	rating.value = tracer.name
		                    when "Scan date"
		                      	rating.value = appointment.appointment_date.strftime("%y-%m-%d")
		                    else
			                    if !(field.form_default_value).blank?
			                        rating.value = field.form_default_value
			                    end
			                end
		                    rating.save
	                    end
				    end

				    # and tag this as SCAN_PET
				    tags = TrTag.where(:name => "SCAN_PET")
				    tag = tags.first
				    if tags.count == 0
				    	tag = TrTag.new(:name => "SCAN_PET")
				    	tag.save
				    end

				    tag.trfiles << trfile
				    tag.save

				end

			end
		end

	end
	
	def clear_tracker(params)

		files = Trfile.where(:trtype_id => params[:tracker_id])
		files.each do |file|
			file.trfileimages.each do |image|
				image.delete
			end
			file.tredits do |tredit|
				tredit.delete
			end
			file.delete
		end
	end


end

