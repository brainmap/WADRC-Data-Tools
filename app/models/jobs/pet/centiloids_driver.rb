class Jobs::Pet::CentiloidsDriver < Jobs::BaseJob

	attr_accessor :petscans
	attr_accessor :pettracer
	attr_accessor :driver
	attr_accessor :preprocessed_tracer_path

	def self.default_params
		params = { schedule_name: 'centiloids_driver',
				base_path: "/mounts/data/", 
    			computer: "merida",
                tracer_id: 1,
                method: "suvr"
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
		#if the paths are ok, and there's a preprocessed dir for our tracer and method
		@petscans.each do |pet_appt|
			print "."
			if pet_appt.paths_ok? and pet_appt.preprocessed_dir_exists?(@preprocessed_tracer_path)
				#then look for a *analysis-log*.mat file in the preprocessed dir. 
				path = pet_appt.preprocessed_dir(@preprocessed_tracer_path)
				analysis_logs = Dir.glob("*analysis-log*.mat",:base => path)
				centiloids_logs = Dir.glob("*centiloids-log*.csv",:base => path)
				if analysis_logs.length > 0 and centiloids_logs.length == 0
					#if there is one, let's add it to the list under this subject
					enrollment = pet_appt.appointment.vgroup.enrollments.first
					scan_procedure_codename = pet_appt.appointment.vgroup.scan_procedures.first.codename
					analysis_log_path = "#{path}/#{analysis_logs.first}"
					output_path = "#{path}/#{enrollment.enumber}_centiloids-log_#{@pettracer.name.downcase}_#{params[:method]}_#{scan_procedure_codename}.csv"

					@driver[enrollment.enumber] = {:analysis_log => analysis_log_path,:output => output_path}

					self.outputs << "< #{pet_appt.class} id:#{pet_appt.id} output_path:#{output_path}>"
				else 
					if analysis_logs.length == 0
						self.exclusions << "< #{pet_appt.class} id:#{pet_appt.id} message:'no analysis-log.mat file'>"
					elsif centiloids_logs.length > 0
						self.exclusions << "< #{pet_appt.class} id:#{pet_appt.id} message:'already has a centiloids-log.csv'>"
					end
				end
			else
				if !pet_appt.paths_ok?
					self.exclusions << "< #{pet_appt.class} id:#{pet_appt.id} message:'paths not ok'>"
				elsif !pet_appt.preprocessed_dir_exists?(@preprocessed_tracer_path)
					self.exclusions << "< #{pet_appt.class} id:#{pet_appt.id} message:'preprocessed dir isnt there'>"
				end
			end
		end
	end

	def write_driver(params)
		#write out the csv
		require 'csv'
		filename_suffix = params[:dry_run] ? "_dry_run" : ""
		pet_csv = "#{params[:base_path]}/preprocessed/logs/parallel_driver/#{Date.today.strftime("%Y-%m-%d")}_#{@pettracer.name.downcase}_#{params[:method]}_centiloids_driver#{filename_suffix}.csv"
		CSV.open(pet_csv, 'wb', row_sep: "\n", encoding: "UTF-8") do |writer|

        	writer << ["analysis_log", "output_path"].map{|s| s.encode("UTF-8")}

        	@driver.values.each do |row|
        		writer << [row[:analysis_log], row[:output]].map{|s| s.to_s.encode("UTF-8")}
      		end
    	end
	end
	
	def matlab_call(params)
		if !!!(params[:dry_run])

			#this is code from the pet driver. make the call something like this

	        # pet_scripts_dir="/mounts/data/analyses/tjbetthauser/MATLAB_Mac/pet_proc_v2b/batch_parallel"

	        # #for each of the subjects we're about to process, make a directory for that subject_id under the right study in preprocessed
	        # v_petscan_normal_run.each do |row|
	        #   visit_dir = "#{p[:base_path]}/preprocessed/visits/#{row[:proto]}.#{row[:visit]}/#{row[:enum]}"
	        #   if !File.directory?(visit_dir)
	        #     Dir.mkdir(visit_dir)
	        #   end
	        # end

	        # matlab_template = "export MATLABPATH=$MATLABPATH:#{pet_scripts_dir}" + " && matlab -nodesktop -nosplash -r \\\"try %{command}; catch exception; display(getReport(exception)); pause(1); end; exit;\\\""
	        # matlab_command = matlab_template % {command: "batch_pet_parallel_auto('#{pet_csv}',12,'#{v_pettracer.name.downcase}','#{p[:method]}')"}
	        # v_computer = p[:computer]
	        # v_call =  "ssh panda_user@#{v_computer}.dom.wisc.edu \"#{matlab_command}\""

	        # v_comment = v_comment + v_call+"\n"
	        # @schedulerun.comment = v_comment
	        # @schedulerun.save
	        # begin
	        #   stdin, stdout, stderr = Open3.popen3(v_call)
	        #   rescue => msg  
	        #   v_comment = v_comment + msg.to_s + "\n"  
	        # end
	        # # v_success ="N"
	        # while !stdout.eof?
	        #   v_output = stdout.read 1024 
	        #   #  v_comment = v_comment + v_output  
	        #   puts v_output  
	        # end
		end
	end
	
	def harvest(params)
	end
	
	def post_harvest(params)
	end

end