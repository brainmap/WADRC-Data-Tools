class Jobs::RadiologyRequest < Jobs::BaseJob
	require 'net/http'

	# This is a service class that requests the latest radiology reads from the radiology site, then
	# records them in the panda. Now that our rad reads are coming as JSONs, this is a lot easier.
	attr_accessor :response
	attr_accessor :filtered_rad_reads

	def self.default_params
	  	params = { :schedule_name => 'Radiology Request', 
	  				:run_by_user => 'panda_user',
	  				:passwd => Rails.application.config.radiology_pass
	  			}
        params.default = ''
        params
    end

	def run(params)

		begin
			login(params)

			selection(params)

			record(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def login(params)
		#looks like we can do this with just one step
		other_login_uri = URI("https://radiology.wisc.edu/a/authentication/loginProcess.php")
		# login_uri = login_uri = URI("https://radiology.wisc.edu/a/authentication/login.php?from=https://radiology.wisc.edu/a/overreads/pandaList.php")
		login_req = Net::HTTP::Post.new(other_login_uri)
		data = {'submitType' => "login", 'loginName' => "datapanda@medicine.wisc.edu", 'pw' => params[:passwd], 'from' => "/a/overreads/pandaList.php"}
		login_req.set_form_data(data)

		@response = Net::HTTP.start(other_login_uri.host, other_login_uri.port, :use_ssl => true){|http| http.request(login_req)}

		self.response = @response

		# we may not even need this anymore.
		self.log << "Response was #{@response.code}, with cookie '#{@response["Set-Cookie"]}'"

		if !@response["Set-Cookie"].nil?
			@cookie = @response["Set-Cookie"].split(";")[0..2].join(";")
		else
			self.error_log << "We didn't get a cookie from the radiology site!"
		end


	end
	def selection(params)

		overread_uri = URI('https://radiology.wisc.edu/a/overreads/pandaList.php')
		overread_request = Net::HTTP::Get.new(overread_uri)
		overread_request['Cookie'] = @cookie
		@response = Net::HTTP.start(overread_uri.host, overread_uri.port, :use_ssl => true){|http| http.request(overread_request)}

		self.response = @response

		# we may not even need this anymore.
		self.log << "Response was #{@response.code}'"

		if @response.code == "200"
			self.log << "looking good!"
		else
			self.error_log << "there was some problem (response code was #{@response.code}}"
			return
		end

		#if the response wasn't a 200, then there was an error we should log, and add to errors.

		rad_reads = JSON.parse(@response.body)
		visit_rmrs = Visit.all().map(&:rmr)

		@filtered_rad_reads = rad_reads.select{|rad| visit_rmrs.include? rad['subjID'].upcase}

		self.filtered_rad_reads = @filtered_rad_reads
		self.log << "We got #{@filtered_rad_reads.count} overreads."
	end


	def record(params)
		#we need visits to associate these with, and we need to validate these inputs before we save them.

		self.log << "Starting to record the overreads."

		@filtered_rad_reads.each do |json|
			#we should validate this JSON
			rad_read_form = RadiologyOverreadForm.from_json(json)

			#we're only interested in writing down the reads for visits over a month ago
			if rad_read_form.scan_entry_date <= (Date.today - 1.month)
				if rad_read_form.valid?
					#try finding a matching visit
					visit = Visit.where(:rmr => rad_read_form.rmr.upcase).first

					if !visit.nil?
						#check that we're not making duplicates.
						if RadiologyOverread.where(:visit => visit).count == 0

							rad_read = RadiologyOverread.new().from_form(rad_read_form)
							rad_read.visit_id = visit.id

							rad_read.save
							self.log << "New overread created for visit(id:#{visit.id})."
						else
							self.log << "An overread already exists for visit(id:#{visit.id}), skipping."
						end
					else
						#record this one as unmatched.
						#should we make an orphan that we can correct later?

					end
				end
			end
		end

		self.log << "Storing is complete!"
	end
end