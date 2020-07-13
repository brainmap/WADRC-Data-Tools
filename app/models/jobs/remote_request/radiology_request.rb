class Jobs::RemoteRequest::RadiologyRequest < Jobs::RemoteRequest::RemoteRequestBase

	# This is a service class that requests the latest radiology reads from the radiology site, then
	# records them in the panda. Now that our rad reads are coming as JSONs, this is a lot easier.
	attr_accessor :response

	def self.default_params
	  	params = { :schedule_name => 'Radiology Request', 
	  				:run_by_user => 'panda_user',
	  				:passwd => Rails.application.config.radiology_pass
	  			}
        params.default = ''
        params
    end

	class RadReader
		# include HTTParty # can't have this in old panda
		base_uri 'https://www.radiology.wisc.edu'
	end

	def login(params)
		#looks like we can do this with just one step

	end
	def selection(params)
		options = {body:{submitType: 'login', loginName: 'datapanda@medicine.wisc.edu', pw:params[:passwd], from:"/a/overreads/pandaList.php"}}
		
		self.log << "Requesting from /a/authentication/loginProcess.php"
		@response = RadReader.post('/a/authentication/loginProcess.php',options)

		self.response = response

		# we may not even need this anymore.
		self.log << "Response was #{@response.code}, with cookie '#{@response.headers["set-cookie"]}'"

		if !@response.headers["set-cookie"].nil?
			@cookie = @response.headers["set-cookie"].split(";")[0..2].join(";")
		else
			self.error_log << "We didn't get a cookie from the radiology site!"
		end

		#if the response wasn't a 200, then there was an error we should log, and add to errors.

		rad_reads = JSON.parse(@response.body)
		visit_rmrs = Visit.all().map(&:rmr)

		@filtered_rad_reads = rad_reads.select{|rad| visit_rmrs.include? rad['subjID'].upcase}
		self.log << "We got #{@filtered_rad_reads.count} overreads."
	end


	def record(params)
		#we need visits to associate these with, and we need to validate these inputs before we save them.

		self.log << "Starting to record the overreads."
		@filtered_rad_reads.each do |json|
			#we should validate this JSON
			rad_read_form = RadiologyOverreadForm.from_json(json)

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

		self.log << "Storing is complete!"
	end
end