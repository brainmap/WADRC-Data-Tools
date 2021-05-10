class Jobs::RemoteRequest::RadiologyRequest < Jobs::RemoteRequest::RemoteRequestBase

	# This is a service class that requests the latest radiology reads from the radiology site, then
	# records them in the panda. Now that our rad reads are coming as JSONs, this is a lot easier.
	# 

	attr_accessor :response
	attr_accessor :http

	def self.default_params
	  	params = { :schedule_name => 'Radiology Request', 
	  				:run_by_user => 'panda_user',
	  				:passwd => Rails.application.config.radiology_pass
	  			}
        params.default = ''
        params
    end

	# class RadReader
	# 	# include HTTParty # can't have this in old panda
	# 	base_uri 'https://www.radiology.wisc.edu'
	# end

	def login(params)
		#looks like we can do this with just one step

		@http = HTTPClient.new
		@http.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
		login = {
			:body => {
				:submitType => 'login',
				:loginName => 'datapanda@medicine.wisc.edu', 
				:pw => params[:passwd], 
				:from => "/a/overreads/pandaList.php"
			}
		}

		@log << {:message => "Requesting from /a/authentication/loginProcess.php"}
		@response = @http.post('https://www.radiology.wisc.edu/a/authentication/loginProcess.php',login)

		# we may not even need this anymore.
		@log << {:message => "Response was #{@response.code}, with cookie '#{@response.headers["Set-Cookie"]}'"}

		if !@response.headers["Set-Cookie"].nil?
			@cookie = @response.headers["Set-Cookie"].split(";")[0..2].join(";")

			cookie = WebAgent::Cookie.new
			cookie.name = 'asdf'
			cookie.value = @cookie
			cookie.url = URI.parse 'https://www.radiology.wisc.edu/'
			@http.cookie_manager.add cookie

		else
			self.error_log << "We didn't get a cookie from the radiology site!"
		end
	end

	def selection(params)

		@response = @http.post('https://www.radiology.wisc.edu/a/overreads/pandaList.php')
		#if the response wasn't a 200, then there was an error we should log, and add to errors.

		rad_reads = JSON.parse(@response.body)
		visit_rmrs = Visit.all().map(&:rmr)

		@filtered_rad_reads = rad_reads.select{|rad| visit_rmrs.include? rad['subjID'].upcase}
		@log << {:message => "We got #{@filtered_rad_reads.count} overreads."}
	end


	def record(params)
		#we need visits to associate these with, and we need to validate these inputs before we save them.

		@log << {:message => "Starting to record the overreads."}
		@filtered_rad_reads.each do |rad|
			#we should validate this JSON
			rad_read_form = RadiologyOverreadForm.from_json(rad)

			if rad_read_form.valid?
				#try finding a matching visit
				visit = Visit.where(:rmr => rad_read_form.rmr.upcase).first

				if !visit.nil?
					#check that we're not making duplicates.
					if RadiologyOverread.where(:visit => visit).count == 0

						rad_read = RadiologyOverread.new().from_form(rad_read_form)
						rad_read.visit_id = visit.id

						rad_read.save
						@log << {:message => "New overread created for visit(id:#{visit.id})."}
					else
						@log << {:message => "An overread already exists for visit(id:#{visit.id}), skipping."}
					end
				else
					#record this one as unmatched.
					#should we make an orphan that we can correct later?

				end
			end
		end

		@log << {:message => "Storing is complete!"}
	end

	def rotate_tables(params)
	end
end