class Jobs::RemoteRequest::NeuropathologyRequest < Jobs::RemoteRequest::RemoteRequestBase

	# This is a service class that requests the latest radiology reads from the radiology site, then
	# records them in the panda. Now that our rad reads are coming as JSONs, this is a lot easier.
	attr_accessor :response, :base_args, :records

	def self.default_params
	  	params = { :schedule_name => 'Neuropathology Request', 
	  				:run_by_user => 'panda_user',
	  				:adrc_token => Rails.application.config.adrc_neuropathology_token,
	  				:wrap_token => Rails.application.config.wrap_neuropathology_token,
	  				:neuropathology_table => 'cg_neuropathology'
	  			}
        params.default = ''
        params
    end

	def login(params)
		#looks like we can do this with just one step

	end

	def selection(params)

	end


	def record(params)

		@base_args = {
			:token => params[:adrc_token],
			:content => 'record',
			:format => 'json',
			:type => 'flat',
			:rawOrLabel => 'raw',
			:rawOrLabelHeaders => 'raw',
			:exportCheckboxLabel => 'false',
			:exportSurveyFields => 'false',
			:exportDataAccessGroups => 'false',
			:returnFormat => 'json'
		}

		#get the subjects, along with which forms they've completed
		ardc_options = @base_args.merge({'fields[0]' => 'nacc_neuropathology_data_form_v10_complete',
									'fields[1]' => 'ptid'
								})

		http = HTTPClient.new
		@response = http.post("https://redcap.medicine.wisc.edu/api/",ardc_options)

		@records = JSON.parse(@response.body)
		self.log << {'message' => "Response was #{@response.code}"}

		self.log << {'message' => "ADRC -- Starting to record the neuropath data."}
		v10_subjects = @records.select{|res| res['nacc_neuropathology_data_form_v10_complete'] == "2"}

		v10_subjects.each do |subj|

			options = @base_args.merge({'records[0]' => subj['ptid']})
			v10_response = http.post("https://redcap.medicine.wisc.edu/api/",options)

			#we should validate this JSON
			v10_form = NeuropathologyV10Form.from_json(JSON.parse(v10_response.body)[0])

			if v10_form.valid?

				sql = v10_form.to_sql_insert("#{params[:neuropathology_table]}_new")

				result = @connection.execute(sql)

			end
		end

		#then the same for the WRAP ppts
		wrap_options = @base_args.merge({:token => params[:wrap_token],
									'fields[0]' => 'wrap_neuropathology_data_form_v10_complete',
									'fields[1]' => 'ptid'
								})

		http = HTTPClient.new
		@response = http.post("https://redcap.medicine.wisc.edu/api/",wrap_options)

		@records += JSON.parse(@response.body)
		self.log << {'message' => "Response was #{@response.code}"}

		self.log << {'message' => "WRAP -- Starting to record the neuropath data."}
		wrap_v10_subjects = @records.select{|res| res['wrap_neuropathology_data_form_v10_complete'] == "2"}

		wrap_v10_subjects.each do |subj|

			options = @base_args.merge({:token => params[:wrap_token],'records[0]' => subj['ptid']})
			v10_response = http.post("https://redcap.medicine.wisc.edu/api/",options)

			#we should validate this JSON
			v10_form = NeuropathologyV10Form.from_json(JSON.parse(v10_response.body)[0])

			if v10_form.valid?

				sql = v10_form.to_sql_insert("#{params[:neuropathology_table]}_new")

				result = @connection.execute(sql)

			end
		end

		self.log << {'message' => "Storing is complete!"}
	end


	def rotate_tables(params)
		sql = "truncate table #{params[:neuropathology_table]}"
		@connection.execute(sql)
		sql = "insert into #{params[:neuropathology_table]} select * from #{params[:neuropathology_table]}_new"
		@connection.execute(sql)
	end
end