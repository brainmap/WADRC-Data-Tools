class Jobs::RemoteRequest::BookedRequest < Jobs::RemoteRequest::RemoteRequestBase

	# This is a service class that requests the latest radiology reads from the radiology site, then
	# records them in the panda. Now that our rad reads are coming as JSONs, this is a lot easier.
	# attr_accessor :response, :cookie, :items

	# def self.default_params
	#   	params = { :schedule_name => 'Booked Appointment Request', 
	#   				:run_by_user => 'panda_user',
	#   				:passwd => Rails.application.config.booked_pass.chomp
	#   			}
 #        params.default = ''
 #        params
 #    end
	# def self.pet_appointment_params
	#   	params = { :schedule_name => 'Booked Appointment Request', 
	#   				:run_by_user => 'panda_user',
	#   				:passwd => Rails.application.config.booked_pass.chomp,
	#   				:agid => 30,
	#   				:appointment_type => "PET"
	#   			}
 #        params.default = ''
 #        params
 #    end
	# def self.mri_appointment_params
	#   	params = { :schedule_name => 'Booked Appointment Request',
	#   				:run_by_user => 'panda_user',
	#   				:passwd => Rails.application.config.booked_pass.chomp,
	#   				:agid => 29,
	#   				:appointment_type => "MRI"
	#   			}
 #        params.default = ''
 #        params
 #    end

	# class BookedReader
	# 	# include HTTParty #can't have this in the old panda
	# 	# base_uri 'https://booked.medicine.wisc.edu'
	# end

	# def login(params)
	# 	#oddly, the response to the POST to the login URL doesn't have a set cookie, but just a GET
	# 	# on the login page does. So, let's GET the login page first, grab the cookie, and make all of 
	# 	# our subsequent requests with that cookie.

	# 	self.response = BookedReader.get('/booked/Web/index.php')

	# 	if !self.response.headers["set-cookie"].nil?
	# 		self.cookie = self.response.headers["set-cookie"]
	# 	else
	# 		self.error_log << "We didn't get a cookie from the booked site!"
	# 	end

	# 	options = {body:{email: 'panda_json_user', password:params[:passwd], persistLogin:"true", login:"submit"},headers:{cookie:self.cookie}}
		
	# 	self.log << "Requesting from /booked/Web/index.php"
	# 	self.response = BookedReader.post('/booked/Web/index.php',options)

	# 	# we may not even need this anymore.
	# 	self.log << "Response was #{@response.code}"

	# end
	# def selection(params)
	# 	# https://booked.medicine.wisc.edu/booked/Web/reports/booked_to_appt_type_group_json.php?agid=29
	# 	# https://booked.medicine.wisc.edu/booked/Web/reports/booked_to_appt_type_group_json.php?agid=30
		
	# 	#now it's time to get the stuff we're looking for.
	# 	self.response = BookedReader.get("/booked/Web/reports/booked_to_appt_type_group_json.php?agid=#{params[:agid]}",{headers:{cookie:self.cookie}})

	# 	#if the response wasn't a 200, then there was an error we should log, and add to errors.
	# 	if self.response.code != 200
	# 		self.error_log << "Error! Response code was #{self.response.code} from booked!"
	# 		return
	# 	end

	# 	self.items = JSON.parse(self.response.body)

	# 	self.log << "we got #{self.items.count} items"
	# end


	# def record(params)
	# 	self.log << "Starting to record the booked visits."

	# 	# existing_booked = BookedAppointment.where(:appointmenttypegroupname => params[:appointment_type])

	# 	#initially I was thinking that we should delete anything that isn't found on the response, but 
	# 	# as the window moves forward, we'll start deleteing the appointments that fall outside of the
	# 	# window. I don't really want to do that, if only for how useful having those back appointments
	# 	# is going to be. So let's just keep everything.

	# 	# item_reference_numbers = @items.map{|item| item['reference_number']}
	# 	# missing_and_should_be_deleted = existing_booked.select{|appt| !item_reference_numbers.include? appt.reference_number }

	# 	self.items.each do |json|

	# 		#we should validate this JSON
	# 		#each of these comes in looking like ['identifier',{'key':'value'}], so let's just look at the [1] of each item
	# 		booked_appt_form = BookedAppointmentForm.from_json(json[1])

	# 		if booked_appt_form.valid?
	# 			existing_booked_appt = BookedAppointment.where(:reference_number => booked_appt_form.reference_number).first

	# 			if !existing_booked_appt.nil?
	# 				#update this from the form

	# 				existing_booked_appt.from_form(booked_appt_form)
	# 				existing_booked_appt.save
	# 				self.log << "Updated booked appointment (id: #{existing_booked_appt.id})"
	# 				self.outputs << "Edited BookedAppointment (id: #{existing_booked_appt.id})"
	# 			else 
	# 				new_booked_appt = BookedAppointment.new().from_form(booked_appt_form)
	# 				new_booked_appt.save
	# 				self.log << "Saved a new booked appointment (id: #{new_booked_appt.id})"
	# 				self.outputs << "New BookedAppointment (id: #{new_booked_appt.id})"
	# 			end
	# 		end
			
	# 	end

	# 	self.log << "Storing is complete!"
	# end
end