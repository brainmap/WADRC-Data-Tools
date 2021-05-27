class Jobs::RemoteRequest::RadiologyRequest < Jobs::RemoteRequest::RemoteRequestBase

	# This is a service class that requests the latest radiology reads from the radiology site, then
	# records them in the panda. Now that our rad reads are coming as JSONs, this is a lot easier.
	# 

	attr_accessor :response
	attr_accessor :http
	attr_accessor :filtered_rad_reads

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
		visit_rmrs = Visit.all().map(&:rmr).map{|item| item.upcase}

		@filtered_rad_reads = rad_reads.select{|rad| visit_rmrs.include? rad['subjID'].upcase}
		@log << {:message => "We got #{@filtered_rad_reads.count} overreads."}
	end

	def abs_sort(a,b)
      if a[0].abs > b[0].abs
        return 1
      elsif a[0].abs < b[0].abs
        return -1
      else
        return 0
      end
  	end

	def record(params)
		#we need visits to associate these with, and we need to validate these inputs before we save them.

		# 'Nm' => 'normal'
		normal_visit_ids = []
      	# 'A-NF' => 'abnormal no follow up' / 'abnormal'
      	abnormal_no_follow_up = []
      	# 'A-F' => 'abnormal, needs follow up' / 'abnormalFollow'
      	abnormal_needs_follow_up = []

		@log << {:message => "Starting to record the overreads."}
		@filtered_rad_reads.each do |rad|
			#we should validate this JSON
			rad_read_form = RadiologyOverreadForm.from_json(rad)

			if rad_read_form.valid?
				#try finding a matching visit

				# 2021-05-25 wbbevis -- Matching these reads to their visits is a little more complicated than
				# just finding the first one with a matching RMR. We need to actually find the visit that's 
				# closest to the date that the read was entered. 

				visits = Visit.where(:rmr => rad_read_form.rmr.upcase)

				sortable_list = visits.map{|item| [item.date - rad_read_form.scan_entry_date, item]}
				sorted_list = sortable_list.sort!{|a,b| abs_sort(a,b)}

				visit = sorted_list.first[1]

				if !visit.nil?
					#check that we're not making duplicates.
					if rad_read_form.summary == 'normal'
						normal_visit_ids << visit.id
					elsif rad_read_form.summary == 'abnormal'
						abnormal_no_follow_up << visit.id
					elsif rad_read_form.summary == 'abnormalFollow'
						abnormal_needs_follow_up << visit.id
					end

					if RadiologyOverread.where(:visit => visit).count == 0

						rad_read = RadiologyOverread.new().from_form(rad_read_form)
						rad_read.visit_id = visit.id

						rad_read.save

						@log << {:message => "New overread created for visit(id:#{visit.id})."}
					else
						
						if visit.date > (Date.today - 5.weeks)

							rad_read = RadiologyOverread.where(:visit => visit).first
							rad_read.from_form(rad_read_form)
							rad_read.save

							@log << {:message => "An overread already exists for visit(id:#{visit.id}), but it's new enough to update."}
						else

							@log << {:message => "An overread already exists for visit(id:#{visit.id}), skipping."}
						end
					end
				else
					#record this one as unmatched.
					#should we make an orphan that we can correct later?

				end
			end
		end

		@log << {:message => "Storing is complete!"}

		@log << {:message => "updating visits"}

		Visit.where(:id => normal_visit_ids).each do |visit|
			visit.radiology_outcome = 'Nm'
			visit.save
		end
		Visit.where(:id => abnormal_no_follow_up).each do |visit|
			visit.radiology_outcome = 'A-NF'
			visit.save
		end
		Visit.where(:id => abnormal_needs_follow_up).each do |visit|
			visit.radiology_outcome = 'A-F'
			visit.save
		end

		@log << {:message => "updating visits complete"}

	end

	def rotate_tables(params)
	end
end