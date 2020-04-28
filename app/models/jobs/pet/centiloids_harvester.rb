class Jobs::Pet::CentiloidsHarvester < Jobs::BaseJob

  attr_accessor :pettracer
  attr_accessor :tracer_path
  attr_accessor :preprocessed_path
  attr_accessor :secondary_key_array
  attr_accessor :scan_procedures

	def self.default_params
		params = { schedule_name: 'centiloids_harvester',
				base_path: "/mounts/data/", 
    			computer: "merida",
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
		@pettracer = LookupPettracer.where("id = ?",params[:tracer_id]).first

		@tracer_path = "/pet/#{@pettracer.name.downcase}/#{params[:method]}/code_ver2b"
		# @schedule_owner_email_array = get_schedule_owner_email(@schedule.id)
		@preprocessed_path = params[:base_path]+"/preprocessed/visits/"
		@secondary_key_array =["b","c","d","e",".R"]

	end
	
	def harvest(params)

		if params[:write_to_sql]
			sql_file = File.open("#{params[:sql_path]}/#{params[:sql_filename]}",'wb')
		end

		@scan_procedures = []
		
		if !params[:sp_blacklist].blank?
			@scan_procedures = ScanProcedure.where("scan_procedures.id not in (?)", params[:sp_blacklist])
		elsif !params[:sp_whitelist].blank?
			@scan_procedures = ScanProcedure.where("scan_procedures.id in (?)", params[:sp_whitelist])
		else
			@scan_procedures = ScanProcedure.all()
		end

		@scan_procedures.each do |sp|
			self.log << "start "+sp.codename
			v_visit_number = sp.visit_abbr
			v_codename_hyphen =  sp.codename.gsub(".","-")
			v_preprocessed_full_path = @preprocessed_path+sp.codename
        	if File.directory?(v_preprocessed_full_path)

        		enrollment_conditions = ''
        		if sp.subjectid_base.include? "-"
        			enrollment_conditions = sp.subjectid_base.split('-').map{|sp_base| "enrollments.enumber like '#{sp_base}%'"}.join(" or ")
        		else
        			enrollment_conditions = "enrollments.enumber like '#{sp.subjectid_base}%'"
        		end

        		enrollments = Enrollment.joins("LEFT JOIN enrollment_vgroup_memberships ON enrollment_vgroup_memberships.enrollment_id = enrollments.id")
                              .joins("LEFT JOIN scan_procedures_vgroups ON scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id")
                              .where("scan_procedures_vgroups.scan_procedure_id = #{sp.id.to_s}")
                              .where(enrollment_conditions)
                              .uniq
                self.log << "we got #{enrollments.count} for #{sp.codename}"

          		enrollments.each do |enrollment|
	                self.log << "starting #{enrollment.enumber}"
	                print "."

		            v_subjectid_path = v_preprocessed_full_path+"/"+enrollment.enumber
		            v_subjectid_v_num = enrollment.enumber + v_visit_number

		            v_subjectid_pet_tracer_path = v_subjectid_path+@tracer_path
		            v_subjectid_array = []

		            #sometimes there are _2 etc. visits, like if they've got to rescan the person
		            begin
		                if File.directory?(v_subjectid_pet_tracer_path)
		                    v_subjectid_array.push(enrollment.enumber)
		                end
		                @secondary_key_array.each do |k|
		                    if File.directory?(v_subjectid_path+k+@tracer_path)
		                        v_subjectid_array.push((enrollment.enumber+k))
		                        v_subjectid_v_num = enrollment.enumber+k + v_visit_number
		                        v_subjectid_path = v_preprocessed_full_path+"/"+enrollment.enumber+k
		                        v_subjectid_pet_tracer_path =v_subjectid_path+@tracer_path
		                    end
		                end
		            rescue => msg  
		                self.log << "IN RESCUE ERROR: #{msg}"
		            end
		            v_subjectid_array = v_subjectid_array.uniq

		            v_subjectid_array.each do |subj|
		            	v_secondary_key =""
		            	if subj != enrollment.enumber
		            		v_secondary_key = subj.gsub(enrollment.enumber,"")
		            	end

		            	v_subjectid = subj
		            	v_subjectid_v_num = subj + v_visit_number
		            	v_subjectid_path = v_preprocessed_full_path+"/"+subj
		            	v_subjectid_pet_tracer_path =v_subjectid_path+@tracer_path

		            	if File.directory?(v_subjectid_pet_tracer_path)

		            		centiloid_file_name = Dir.glob(v_subjectid_pet_tracer_path + "/*centiloid*.csv").first
		            		centiloid_error_file_name = Dir.glob(v_subjectid_pet_tracer_path + "/*centiloid*.csv.error").first

		            		if !centiloid_file_name.nil?
		            			print "*"
			            		self.log << "centiloid.csv is #{centiloid_file_name}"

			            		#let's also get the petscan for this directory
			            		vgroups = enrollment.vgroups.select{|vgroup| vgroup.scan_procedures.map(&:codename).include? sp.codename}.flatten
			            		petscans = Petscan.where(:lookup_pettracer_id => @pettracer).where(:appointment_id => vgroups.map{|vgroup| vgroup.appointments.map(&:id)}.flatten)
			            		petscan = nil
			            		if petscans.count == 1
			            			petscan = petscans.first
			            		elsif petscans.count == 0
			            			self.exclusions << "can't find a matching Petscan for #{v_subjectid_pet_tracer_path}"
			            			next
			            		elsif petscans.count > 1
			            			self.exclusions << "too many Petscans for #{v_subjectid_pet_tracer_path}! (ids: #{petscan.map(&:id).join(", ")})"
			            			next
			            		end

			            		csv = CSV.open(centiloid_file_name,:headers => true)
			            		centiloid_form = CentiloidForm.from_csv(csv, params[:method], centiloid_file_name, petscan)

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
		            		if !centiloid_error_file_name.nil?
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
		            	end
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