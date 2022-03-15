class Jobs::RemoteRequest::WrapLpRequest < Jobs::RemoteRequest::RemoteRequestBase

	# This is a service class that requests LP records from ADRC's REDcap.
	attr_accessor :response, :base_args, :records

	def self.default_params
	  	params = { :schedule_name => 'WRAP REDCap LP Request', 
	  				:run_by_user => 'panda_user',
	  				:wrap_token => Rails.application.config.redcap_wrap_token,
	  				:wrap_scan_procedures => [94,152]
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
			:token => params[:wrap_token],
			:content => 'record',
			:format => 'json',
			'forms[0]' => 'wrap_e4_v6_lp',
			'forms[1]' => 'header',
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

		# 2022-03-15 wbbevis -- Beware the Ides of March. Apparently the WRAP REDCap project has been 
		# set up in a subtly different way from the ADRC project, such that the date of the LP event
		# has been broken up onto another record. This means that one query that captures both the date
		# info and the E4 info returns 2 records that I now have to merge (somehow).

		# How do we know which E4 goes with what header? We can treat ptid + redcap_repeat_instance as
		# a composite key. The header will have a value "header" for the redcap_repeat_instrument field,
		# and the E4 will have "wrap_e4_v6_lp". From there, we can merge the header and the E4 to get
		# something that the form object can read.

		all_ptids = @records.map{|item| item["ptid"]}.uniq
		e4_populated = []

		all_ptids.each do |ptid|
			redcap_records = @records.select{|item| item["ptid"] == ptid}
			instance_numbers = redcap_records.map{|item| item["redcap_repeat_instance"]}.uniq
			instance_numbers.each do |instance|
				header = redcap_records.select{|item| item["redcap_repeat_instrument"] == "header" and item["redcap_repeat_instance"] == instance}.first
				e4 = redcap_records.select{|item| item["redcap_repeat_instrument"] == "wrap_e4_v6_lp" and item["redcap_repeat_instance"] == instance}.first

				if header.nil?
					header = Hash.new("")
				end
				if e4.nil?
					e4 = Hash.new("")
				end

				e4_populated << merge_records(header,e4)

			end
		end

		e4_populated = e4_populated.select{|item| item["lpdt_ev_v6"] != ''}

		puts "#{e4_populated}"

		unrecorded_e4 = []
		#let's find the records that we haven't stored yet.
		e4_populated.each do |record|
			redcap_lp_date = Date.strptime(record["lpdt_ev_v6"], "%Y-%m-%d")

			vgroups = Vgroup.joins(:scan_procedures).joins(:enrollments)
							.where("enrollments.enumber = 'wrap#{record["ptid"].rjust(4,'0')}'")
							.where("scan_procedures.id in (#{params[:wrap_scan_procedures].join(',')})")
			lps = vgroups.map(&:appointments).flatten.select{|item| item.appointment_type == 'lumbar_puncture'}
			if lps.select{|item| item.appointment_date == redcap_lp_date}.count > 0
				next
			end

			# so if we're here, we've got an lp we haven't recorded before
			unrecorded_e4 << record

		end
		
		unrecorded_e4.each do |row|

			vgroups = Vgroup.joins(:scan_procedures).joins(:enrollments).where("enrollments.enumber = ?","wrap#{row["ptid"].rjust(4,'0')}").where("scan_procedures.id in (#{params[:wrap_scan_procedures].join(',')})").where(:vgroup_date => Date.strptime(row["lpdt_ev_v6"], "%Y-%m-%d"))
			if vgroups.count == 1
				# make the form and create the visits
				form = RedcapE4V6WrapForm.from_csv(row)
				form.create_lp_appointment(vgroups.first)
				vgroups.first.completedlumbarpuncture = 'yes'
				vgroups.first.save

			elsif vgroups.count > 1
				# too many vgroups match this LP!
				message = "There were too many vgroups for #{row['ptid']} on #{row['lpdt_ev_v6']}"
				puts message
				@log << {'message' => message}
			else
				# no vgroups match this LP!
				message = "There weren't enough vgroups for #{row['ptid']} on #{row['lpdt_ev_v6']}. We're going to create one."
				puts message
				@log << {'message' => message}

				enr = Enrollment.where(:enumber => "wrap#{row["ptid"].rjust(4,'0')}").first

				# create a vgroup
				vgroup = Vgroup.new(:participant_id => enr.participant_id, :vgroup_date => Date.strptime(row["lpdt_ev_v6"], "%Y-%m-%d"), :completedlumbarpuncture => 'yes')
				visit_1 = ScanProcedure.where(:codename => "johnson.wrap_biomarker.visit1").first
				visit_2 = ScanProcedure.where(:codename => "johnson.wrap_biomarker.visit2").first

				# add scan procedure
					# decide which one to assign
				visit1_vgroups = Vgroup.joins(:scan_procedures).joins(:enrollments).where("enrollments.enumber = ?","wrap#{row["ptid"].rjust(4,'0')}").where("scan_procedures.id in (#{visit_1.id})")
				visit2_vgroups = Vgroup.joins(:scan_procedures).joins(:enrollments).where("enrollments.enumber = ?","wrap#{row["ptid"].rjust(4,'0')}").where("scan_procedures.id in (#{visit_2.id})")

				vgroup.save

				if visit1_vgroups.count < 1
					vgroup.scan_procedures << visit_1
				else
					vgroup.scan_procedures << visit_2
				end

				vgroup.save

				# add the enrollments to it
                enrollment_vgroup_membership = EnrollmentVgroupMembership.new
                enrollment_vgroup_membership.enrollment_id = enr.id
                enrollment_vgroup_membership.vgroup_id = vgroup.id
                enrollment_vgroup_membership.save

				# add an appointment ("lumbar_puncture")
				form = RedcapE4V6WrapForm.from_csv(row)
				form.create_lp_appointment(vgroup)

			end
		
		end


		@log << {'message' => "Storing is complete!"}
	end

	def merge_records(a,b)
		out = {}
		keys = (a.keys + b.keys).uniq
		keys.each do |key|
			out[key] = ( (a[key].blank? or a[key].nil?) ? b[key] : a[key])
		end
		out
	end

	def rotate_tables(params)
		# we won't be rotating these
	end
end