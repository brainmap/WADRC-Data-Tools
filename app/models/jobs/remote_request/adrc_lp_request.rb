class Jobs::RemoteRequest::AdrcLpRequest < Jobs::RemoteRequest::RemoteRequestBase

	# This is a service class that requests LP records from ADRC's REDcap.
	attr_accessor :response, :base_args, :records

	def self.default_params
	  	params = { :schedule_name => 'ADRC REDCap LP Request', 
	  				:run_by_user => 'panda_user',
	  				:adrc_token => Rails.application.config.redcap_adrc_token,
	  				:adrc_scan_procedures => [22,65,89,119]
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
			:content => 'report',
		    :format => 'json',
		    :report_id => '3826',
		    :csvDelimiter => '',
		    :rawOrLabel => 'raw',
		    :rawOrLabelHeaders => 'raw',
		    :exportCheckboxLabel => 'false',
		    :returnFormat => 'json'
		}

		http = HTTPClient.new
		@response = http.post("https://redcap.medicine.wisc.edu/api/",@base_args)

		@records = JSON.parse(@response.body)
		@log << {'message' => "Response was #{@response.code}"}

		e4_populated = @records.select{|item| item["lpdt_e4_v6"] != ""}

		unrecorded_e4 = []
		#let's find the records that we haven't stored yet.
		e4_populated.each do |record|
			redcap_lp_date = Date.strptime(record["lpdt_e4_v6"], "%Y-%m-%d")

			vgroups = Vgroup.joins(:scan_procedures).joins(:enrollments)
							.where("enrollments.enumber = '#{record["ptid"]}'")
							.where("scan_procedures.id in (#{params[:adrc_scan_procedures].join(',')})")
			lps = vgroups.map(&:appointments).flatten.select{|item| item.appointment_type == 'lumbar_puncture'}
			if lps.select{|item| item.appointment_date == redcap_lp_date}.count > 0
				next
			end

			# so if we're here, we've got an lp we haven't recorded before
			unrecorded_e4 << record

		end
		
		unrecorded_e4.each do |row|

			vgroups = Vgroup.joins(:enrollments).where("enrollments.enumber = ?",row["ptid"]).where(:vgroup_date => Date.strptime(row["lpdt_e4_v6"], "%Y-%m-%d"))
			if vgroups.count == 1
				# make the form and create the visits
				form = RedcapE4V6Form.from_csv(row)
				form.create_lp_appointment(vgroups.first)
				vgroups.first.completedlumbarpuncture = 'yes'
				vgroups.first.save

			elsif vgroups.count > 1
				# too many vgroups match this LP!
				message = "There were too many vgroups for #{row['ptid']} on #{row['lpdt_e4_v6']}"
				puts message
				@log << {'message' => message}
			else
				# no vgroups match this LP!
				message = "There weren't enough vgroups for #{row['ptid']} on #{row['lpdt_e4_v6']}"
				puts message
				@log << {'message' => message}
			end
		
		end


		@log << {'message' => "Storing is complete!"}
	end


	def rotate_tables(params)
		# we won't be rotating these
	end
end