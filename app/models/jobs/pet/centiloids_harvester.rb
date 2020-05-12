class Jobs::Pet::CentiloidsHarvester < Jobs::BaseJob

  attr_accessor :pettracer
  attr_accessor :tracer_path
  attr_accessor :preprocessed_path
  attr_accessor :secondary_key_array
  attr_accessor :scan_procedures
  attr_accessor :petscans


	def self.default_params
		params = { schedule_name: 'centiloids_harvester',
				base_path: "/mounts/data/", 
    			computer: "kanga",
                tracer_id: 1,
                method: "suvr",
                dry_run: false,
                centiloid_table: "cg_centiloids",
                sql_path: "/mounts/data/analyses/panda_user/",
                sql_filename: "centiloids_harvest.sql",
                run_by_user: "panda_user",
                write_to_sql: false
                # sp_whitelist: [117,118]
    		}
        params.default = ''
        params
    end

	def run(params)

		begin
			setup(params)

			harvest(params)

			rotate_tables(params)

			post_harvest(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)

		sql = "truncate #{params[:centiloid_table]}_new"
		@connection.execute(sql)

		@pettracer = LookupPettracer.where("id = ?",params[:tracer_id]).first

		@tracer_path = "/pet/#{@pettracer.name.downcase}/#{params[:method]}/code_ver2b"
		# @schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
		@preprocessed_path = params[:base_path]+"/preprocessed/visits/"
		@secondary_key_array =["b","c","d","e",".R"]

		# @scan_procedures = []
		
		if !params[:sp_blacklist].blank?
			@scan_procedures = ScanProcedure.where("scan_procedures.id not in (?)", params[:sp_blacklist])
		elsif !params[:sp_whitelist].blank?
			@scan_procedures = ScanProcedure.where("scan_procedures.id in (?)", params[:sp_whitelist])
		else
			@scan_procedures = ScanProcedure.all()
		end
	end
	
	def harvest(params)

		if params[:write_to_sql]
			sql_file = File.open("#{params[:sql_path]}/#{params[:sql_filename]}",'wb')
		end

		scan_procedures = ScanProcedure.all().map(&:codename)
		scan_procedures.each do |codename|

			protocol_path = "#{params[:base_path]}preprocessed/visits/#{codename}"
			if Dir.exists?(protocol_path)

				subject_ids = Dir.entries(protocol_path) - ['.','..']
				subject_ids.each do |subject_id|
					path = "#{protocol_path}/#{subject_id}#{@preprocessed_tracer_path}"
					if Dir.exists?(path)

						cleaned_subject_id = subject_id.split("_")

						centiloids_logs = Dir.glob("#{path}/*centiloids-log*.csv")
						centiloids_errors = Dir.glob("#{path}/*centiloid*.csv.error")

				        if centiloids_logs.count > 0
				        	#starting from petscans seems not to work, so let's get the petscan here

							scan_procedure = ScanProcedure.where(:codename => codename)

							appointments = Appointment.joins("LEFT JOIN vgroups ON vgroups.id = appointments.vgroup_id")
													.joins("LEFT JOIN enrollment_vgroup_memberships ON vgroups.id = enrollment_vgroup_memberships.vgroup_id")
													.joins("LEFT JOIN enrollments ON enrollments.id = enrollment_vgroup_memberships.enrollment_id")
													.where("enrollments.enumber = '#{subject_id}'")
													.where(:appointment_type => 'pet_scan')

							petscans = Jobs::Pet::Petscan.where("petscans.lookup_pettracer_id in (?) 
								and petscans.good_to_process_flag = 'Y'
								and petscans.appointment_id in (?)
								and petscans.appointment_id in (select appointments.id from appointments, scan_procedures_vgroups
								where appointments.vgroup_id = scan_procedures_vgroups.vgroup_id
								and scan_procedures_vgroups.scan_procedure_id in (?))",1,appointments.map(&:id),scan_procedure.map(&:id))

							pet_appt = petscans.first
				        	centiloid_file_name = centiloids_logs.first
				            print "*"
					        self.log << "centiloid.csv is #{centiloid_file_name}"
					        csv = CSV.open(centiloid_file_name,:headers => true)
					        centiloid_form = CentiloidForm.from_csv(csv, params[:method], centiloid_file_name, pet_appt)

							sql = ''
							if !centiloid_form.valid?
								@error_rows << centiloid_form
							end

							begin

								sql = centiloid_form.to_sql_insert("#{params[:centiloid_table]}_new")
								puts "#{sql}"
								if !params[:dry_run]
									@connection.execute(sql)
								end
								if params[:write_to_sql]
									sql_file.write("#{sql}\n")
								end

							rescue ArgumentError => e
								self.error_log << "#{e.message}, with: #{centiloid_file_name}"
							end
						end

						# we also need to scan for error logs for this 
				        if centiloids_errors.count > 0
				        	centiloid_error_file_name = centiloids_errors.first
				            print "_"
					        self.log << "centiloid.csv.error is #{centiloid_error_file_name}"

					        error_csv = CSV.open(centiloid_error_file_name,:headers => true)
					        error_values = {}
							error_csv.each do |row|
								error_values[row["Description"]] = row["Value"]
							end

					        self.exclusions << "centiloid error: ExceptionIdentifier: #{error_values['ExceptionIdentifier']}, ExceptionMessage: #{error_values['ExceptionMessage']}, InputFile: #{error_values['InputFile']}"
					        next
				        end
				    else
						self.exclusions << "< #{path} does not exist>"
		        	end
		    	end
		    end
		end

    	#close the sql file
		if params[:write_to_sql]
			sql_file.close
		end
	end

	def rotate_tables(params)
		sql = "truncate table #{params[:centiloid_table]}_old"
		@connection.execute(sql)
		sql = "insert into #{params[:centiloid_table]}_old select * from #{params[:centiloid_table]}"
		@connection.execute(sql)
		sql = "truncate table #{params[:centiloid_table]}"
		@connection.execute(sql)
		sql = "insert into #{params[:centiloid_table]} select * from #{params[:centiloid_table]}_new"
		@connection.execute(sql)
	end
	
	def post_harvest(params)
	end

end