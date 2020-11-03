class Jobs::Pet::PopulateShareable < Jobs::BaseJob

	attr_accessor :petscans
	attr_accessor :pettracer
	attr_accessor :driver
	attr_accessor :driver_csv
	attr_accessor :preprocessed_tracer_path

	def self.default_params
		params = { schedule_name: 'Populate Shareable',
				base_path: "/mounts/data/", 
    			computer: "kanga",
                tracer_id: 1,
                method: "dvr",
                run_by_user: "panda_user",
                n_cores: 10, #the number of CPU cores to occupy
                dry_run: false
    		}
        params.default = ''
        params
    end

	def run(params)

		begin
			setup(params)

			selection(params)

			write_driver(params)

			matlab_call(params)

			final_pass(params)

			report(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << {:message => "Error (#{error.class}): #{error.message}"}
			close_fail(params, error)

		end
	end

	def tracer_tracker_map(tracer_id, method_name)
		# current to 2020-06-11, these are the correct trtypes to use when looking up 
		# a QC value for a given image. If this returns nil, we don't have QC tracked
		# for this tracer/method combination

		case method_name
		when 'dvr'
			case tracer_id.to_i
			when 1 #PiB
				return 11 #PET PIB dvr quality
			when 2 #FDG
				return 14 #PET FDG quality
			when 6 #AV45
				return 16 #PET AV45 quality
			when 9 #AV1451
				return 9 #PET AV1451 quality
			else
				return nil
			end
		when 'suvr'
			case tracer_id.to_i
			when 1 #PiB
				return 10 #PET PIB Suvr quality
			when 11 #MK6240
				return 8 #PET MK6240 quality
			else
				return nil
			end
		else
			return nil
		end
	end



	def setup(params)
    	@pettracer = LookupPettracer.where("id = ?",params[:tracer_id]).first
    	@preprocessed_tracer_path = "/pet/#{@pettracer.name.downcase}/#{params[:method]}/code_ver2b"
    	@driver = {}
	end

	def selection(params)

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

						cleaned_subject_id = subject_id.split("_").first

						# now that we've got a good directory, we need a QC tracker that we can ask
						# about what's in here. 
						trtype_id = tracer_tracker_map(params[:tracer_id],params[:method])
						if !trtype_id.nil?

							images = Dir.glob("w#{cleaned_subject_id}*_2b.nii",:base => path)

							# We're also going to need only QC'd images, so if there isn't a QC pass in the tracker for a processed image
							# in this dir, fail the case.

							# here, file_type should be something like "suvr pib"
			                processed_images = Processedimage.where(:file_path => images.map{|img| "#{path}/#{img}"}.join(",")).where(:file_type => "#{params[:method].downcase} #{@pettracer.name.downcase}")
			                qc_values = []

				            if processed_images.count > 0
				                tracker = Trfileimage.joins(:trfile).where("trfiles.trtype_id = ?",trtype_id).where(:image_id => processed_images.map(&:id), :image_category => 'processedimage')
				                qc_values = tracker.map{|tr| tr.trfile.qc_value}

								if qc_values.include?('Pass')

									#
									raw_path = "#{params[:base_path]}raw/#{codename}/pet/#{@pettracer.name.upcase}/#{cleaned_subject_id}/"
									if !Dir.exists?(raw_path)
										print ','
										self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "raw path is missing (#{raw_path})"}
										next
									end

									#now that we've got a good petscan case, let's build the path to the output dir
									output_path = "#{params[:base_path]}shareable/pet/#{@pettracer.name.downcase}/#{codename}/#{cleaned_subject_id}/"
									if Dir.exists?(output_path)
										print ','
										self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "output path already exists (#{output_path})"}
										next
									end


									#we also need to get a petscan for this path
									vgroups = Vgroup.joins("LEFT JOIN enrollment_vgroup_memberships on vgroups.id = enrollment_vgroup_memberships.vgroup_id")
													.joins("LEFT JOIN enrollments on enrollment_vgroup_memberships.enrollment_id = enrollments.id")
													.joins("LEFT JOIN scan_procedures_vgroups on vgroups.id = scan_procedures_vgroups.vgroup_id")
													.joins("LEFT JOIN scan_procedures on scan_procedures.id = scan_procedures_vgroups.scan_procedure_id")
													.where("enrollments.enumber = ?",cleaned_subject_id)
													.where("scan_procedures.codename = ?",codename)

									petscans = vgroups.map{|vgroup| vgroup.appointments.map{|appt| Petscan.where("appointment_id = ?",appt.id).order("appointment_id")}}.flatten.select{|pet| pet.lookup_pettracer_id == @pettracer.id}
									pet_appt = petscans.first


									#if either the enrollment's do_not_share_scans_flag is set, or the vgroups do_not_share_scans flag is set, then exclude
									vgroup = pet_appt.appointment.vgroup
									if !vgroup.nil? and vgroup.do_not_share_scans == "DO NOT SHARE"
										print ','
										self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "DO NOT SHARE set on this vgroup(#{vgroup.id})"}
										next
									end

									enrollments = vgroup.enrollments
									if enrollments.count > 0 and enrollments.select{|item| item.do_not_share_scans_flag == 'Y'}.count > 0
										print ','
										self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "DO NOT SHARE set on this enrollment (#{enrollments.select{|item| item.do_not_share_scans_flag == 'Y'}.first.id})"}
										next
									end

									# Per Tobey J Betthauser, having ppt weight info, while helpful, isn't something that should fail the case for this process.
									# If we've got weight that's good, and we should use it, but if we don't, nbd, we can still share the data. 

									# But, also per Dr. TJB, we do certaily need injection time, scan start time, and injected dose.
									# If we don't have all of those, we should fail the case.


									# 2020-08-06 wbbevis -- we're dropping this error so that we can get the shareable populated. This
									# exclusion was mostly kicking out cases where students didn't write down a value for scan start &
									# injection times because they were the same (which is what we expect for PiB). This will be updated 
									# in the future, but for now we're going to generate this so we can get the data out the door.

									# if pet_appt.injecttiontime.nil? or pet_appt.scanstarttime.nil? or pet_appt.netinjecteddose.nil?
									# 	print ','

									# 	self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "petscan has nil values important to BIDS (injecttiontime.nil? == #{pet_appt.injecttiontime.nil?.to_s}, scanstarttime.nil? == #{pet_appt.scanstarttime.nil?.to_s}, netinjecteddose.nil? == #{pet_appt.netinjecteddose.nil?.to_s})"}
									# 	next
									# end

									# also add exclusions for:
									# enrollments.do_not_share_scans_flag
									# image_datasets.do_not_share_scans_flag
									# vgroups.do_not_share_scans_flag

									if pet_appt.netinjecteddose.nil?
										print ','

										self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "petscan has nil values important to BIDS (injecttiontime.nil? == #{pet_appt.injecttiontime.nil?.to_s}, scanstarttime.nil? == #{pet_appt.scanstarttime.nil?.to_s}, netinjecteddose.nil? == #{pet_appt.netinjecteddose.nil?.to_s})"}
										next
									end


									@driver[path] = {:source_path => "#{path}/",:target_path => output_path,:raw_path => raw_path,:scan_procedure => codename, :subject_id => cleaned_subject_id, :petscan => pet_appt, :tracer => @pettracer.name.downcase}
									print '.'
									self.outputs << {:source_path => "#{path}/",:target_path => output_path,:raw_path => raw_path,:scan_procedure => codename, :subject_id => cleaned_subject_id, :petscan => pet_appt, :tracer => @pettracer.name.downcase}
								else
									print ','
									self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "hasnt passed QC"}
								end
							else
								print ','
								self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "no QC tracker for this tracer/method combination"}
							end
						else 
							print ','
							self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "no processed images"}
						end
					else
						print ','
						self.exclusions << {:scan_procedure => codename, :subject_id => subject_id, :message => "paths not ok"}
					end
				end
			end
		end
	end

	def write_driver(params)
		#write out the csv
		require 'csv'
		filename_suffix = !!!(params[:dry_run]) ? "_dry_run" : ""
		@driver_csv = "#{params[:base_path]}preprocessed/logs/parallel_driver/#{Date.today.strftime("%Y-%m-%d")}_#{@pettracer.name.downcase}_#{params[:method]}_populate_shareable_driver#{filename_suffix}.csv"
		CSV.open(@driver_csv, 'wb', row_sep: "\n", encoding: "UTF-8") do |writer|

        	writer << ["raw_path", "protocol", "enum", "tracer", "target_path"].map{|s| s.encode("UTF-8")}

        	@driver.values.each do |row|
        		writer << [row[:raw_path], row[:scan_procedure], row[:subject_id], row[:tracer], row[:target_path]].map{|s| s.to_s.encode("UTF-8")}
      		end
    	end
	end
	
	def matlab_call(params)
		if !!!(params[:dry_run])
			require 'open3'

			# here, since we're committed to doing this, and it isn't a dry run, let's actuall
			# make the target dirs

			@driver.values.each do |row|
				# I was hoping this would be able to mkdir recursively, but apparently it can't.
				# So let's check & mkdir witht he scan_procedure first
				scan_proc_dir = "#{params[:base_path]}shareable/pet/#{row[:tracer]}/#{row[:scan_procedure]}/"
				if !File.directory?(scan_proc_dir)
	        		Dir.mkdir(scan_proc_dir)
	        	end

	        	if !File.directory?(row[:target_path])
	        		Dir.mkdir(row[:target_path])
	        	end
	        end

	        pet_scripts_dir="/mounts/data/analyses/tjbetthauser/DataSharing/NIIbids"
	        matlab_template = "export MATLABPATH=$MATLABPATH:#{pet_scripts_dir}" + " && matlab -nodesktop -nosplash -r \\\"try %{command}; catch exception; display(getReport(exception)); pause(1); end; exit;\\\""
	        matlab_command = matlab_template % {command: "batch_PET2niibids('#{@driver_csv}',#{params[:n_cores]})"}
	        v_computer = params[:computer]
	        v_call =  "ssh panda_user@#{v_computer}.dom.wisc.edu \"#{matlab_command}\""

	        self.log << {:message => "calling #{v_call}"}
	        begin
	        	stdin, stdout, stderr = Open3.popen3(v_call)
		        while !stdout.eof?
		        	v_output = stdout.read 1024 
		        	#  v_comment = v_comment + v_output  
		        	self.log << v_output  
		        end
	        rescue => msg
	        	self.error_log << {:message => "error #{msg.to_s}"}
	        end
		end
	end
	
	def final_pass(params)
		#here, we need to loop through all of our newly populated target dirs
		@driver.values.each do |row|
	        if File.directory?(row[:target_path])
				entries = Dir.entries(row[:target_path])
				# check that everything is there

				bids_files = Dir.glob("*.json", :base => row[:target_path])

				if bids_files.count > 0

					bids_raw = File.read(row[:target_path] + bids_files.first)
					bids_json = JSON.parse(bids_raw)

					vgroups = Vgroup.joins("LEFT JOIN enrollment_vgroup_memberships on vgroups.id = enrollment_vgroup_memberships.vgroup_id")
									.joins("LEFT JOIN enrollments on enrollment_vgroup_memberships.enrollment_id = enrollments.id")
									.joins("LEFT JOIN scan_procedures_vgroups on vgroups.id = scan_procedures_vgroups.vgroup_id")
									.joins("LEFT JOIN scan_procedures on scan_procedures.id = scan_procedures_vgroups.scan_procedure_id")
									.where("enrollments.enumber = ?",row[:subject_id])
									.where("scan_procedures.codename = ?",row[:scan_procedure])

					petscans = vgroups.map{|vgroup| vgroup.appointments.map{|appt| Petscan.where("appointment_id = ?",appt.id).order("appointment_id")}}.flatten.select{|pet| pet.lookup_pettracer_id == @pettracer.id}

					#there should just be one of these, but there might also be 0 or >1
					pet_appt = petscans.first

					vitals = Vital.where("appointment_id = ?",pet_appt.appointment_id).where("weight is not NULL").where("weight > 0.0")

					if vitals.count == 0 or vitals.first.weight.nil?
						# maybe there aren't any vitals?
						bids_json["Info"]["BodyWeight"] = 0.0
					else
						bids_json["Info"]["BodyWeight"] = (vitals.first.weight / 2.205).ceil(0)
					end

					bids_json["Info"]["BodyWeightUnit"] = 'kg'

					if pet_appt.injecttiontime.nil?
						bids_json["Time"]["InjectionStart"] = "00:00:00"
					else
						bids_json["Time"]["InjectionStart"] = pet_appt.injecttiontime.strftime("%H:%M:%S")
					end


					if pet_appt.scanstarttime.nil?
						bids_json["Time"]["ScanStart"] = "00:00:00"
					else
						bids_json["Time"]["ScanStart"] = pet_appt.scanstarttime.strftime("%H:%M:%S")
					end


					bids_json["Radiochem"]["InjectedRadioactivity"] = (pet_appt.netinjecteddose * 37).to_i
					bids_json["Radiochem"]["InjectedRadioactivityUnits"] = "MBq"

					pretty_bids_out = File.open(row[:target_path] + bids_files.first,'wb')
					pretty_bids_out.write(JSON.pretty_generate(bids_json))
					pretty_bids_out.close
					# open & parse the JSON files
					# udpate values in them with a few values from the Panda
					# close & save the JSON named with the participant's (6-digit padded) reggie ID
					# mv the other files around and rename them with 6-digit reggie ids.
					# remove the old files. 
				end
			end
		end
	end
	
	def report(params)
		
		# write the log to the outputs file

		# write the driver to the inputs file 

	end

end

