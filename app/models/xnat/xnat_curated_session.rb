class Xnat::XnatCuratedSession < Xnat::XnatCurated

	belongs_to :project, :class_name => "XnatCuratedProject", foreign_key: :project_id
	has_many :scans, :class_name => "XnatCuratedScan", foreign_key: :session_id, primary_key: :id
	belongs_to :subject, :class_name => "XnatCuratedSubject", foreign_key: :subject_id
	belongs_to :visit, :class_name => "Visit", foreign_key: :visit_id
	belongs_to :appointment, :class_name => "Appointment", foreign_key: :appointment_id

	before_create :make_xnat_session_id

	def xnat_exists?(p=@params)
		# response = RestClient::Request.new(
		# 	:method => :get,
		# 	:url => "https://#{p[:xnat_address]}/data/projects/#{self.project.name}/subjects/#{self.subject.export_id}/experiments/",
		# 	:user => 'panda_uploader',
		# 	:password => 'XXXXXXX').execute

		# results = JSON.parse(response.to_str)

		# return results["ResultSet"]["Result"].select { |r| r["label"] == self.xnat_session_id }.length > 0


		#but for now:

		#log into merida, and use curl to GET the subject's URL, and log the result
		v_log_file_path = "#{ p[:working_directory] }/xnat_#{ self.xnat_session_id }.log"
		cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }; curl --netrc -o #{ v_log_file_path } -w \\\"%{http_code}\\\" -X GET https://#{ p[:xnat_address] }/data/archive/projects/#{ self.project.name }/subjects/#{ self.subject.export_id }/experiments?format=json\""
		if p[:verbose]
			puts cmd
		end
		response = r_call cmd
		if p[:verbose]
			puts response
		end

		#copy the log of that command back from the server, so that we can see the results
        response = r_call "rsync -av panda_user@#{ p[:computer] }.dom.wisc.edu:#{ v_log_file_path } #{ v_log_file_path }"

        json_file = File.open(v_log_file_path)
        data = JSON.load json_file

		if p[:verbose]
			puts data["ResultSet"]["Result"].select { |i| i["label"] == self.xnat_session_id }.to_s
		end

		#clean up that remote log
		response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"rm #{ v_log_file_path }\""

        return data["ResultSet"]["Result"].select { |i| i["label"] == self.xnat_session_id }.length > 0

	end

	def xnat_create(p=@params)
		# begin
		# 	response = RestClient::Request.new(
		# 		:method => :post,
		# 		:url => "https://#{p[:xnat_address]}/data/projects/#{self.project.name}/subjects/#{self.subject.export_id}/experiments/#{self.xnat_session_id}",
		# 		:user => 'panda_uploader',
		# 		:password => 'XXXXXXX').execute

		# 	# if the response code was 201, we're good.
		# 	# results = JSON.parse(response.to_str)
		# rescue RestClient::MethodNotAllowed => e
		# 	#log that this attempt failed.
		# end

		#but for now:

		#log into merida, and use curl to GET the subject's URL, and log the result
		v_log_file_path = "#{ p[:working_directory] }/xnat_#{ self.xnat_session_id }.log"
		querystring = "xsiType=xnat:mrSessionData" #&project=#{ self.project.name }&label=#{ self.xnat_session_id }"
		cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }; curl --netrc -o #{ v_log_file_path } -w \\\"%{http_code}\\\" -X PUT \\\"https://#{ p[:xnat_address] }/data/archive/projects/#{ self.project.name }/subjects/#{ self.subject.export_id }/experiments/#{ self.xnat_session_id }?#{querystring}\\\"\""
		if p[:verbose]
			puts cmd
		end
		response = r_call cmd
		if p[:verbose]
			puts response
		end

		#copy the log of that command back from the server, so that we can see the results
        response = r_call "rsync -av panda_user@#{ p[:computer] }.dom.wisc.edu:#{ v_log_file_path } #{ v_log_file_path }"

		#clean up that remote log
		response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"rm #{ v_log_file_path }\""

        result = File.open(v_log_file_path).read

        return result.include?("XNAT_")
	end


	def make_xnat_session_id

      # from the visit path, we can get the scan procedure's codename (then query for our scan procedure)
      # from appointment we can get secondary_key
      # then session_id = "#{subject.export_id.to_s}_#{sp_array.first.subjectid_base}#{sp_array.first.visit_abbr("_v1")}"
      # and, if there's a secondary_key, session_id += "_sk#{v_secondary_key}"
      # then save it to the session object

      sp_codename = ''
      path_array = self.visit.path.split('/')
      if path_array.count > 4
      	codename = path_array[4]
      end

      secondary_key = self.appointment.secondary_key
      sp_array = ScanProcedure.where("codename in (?)",codename)

      if sp_array.length > 0
      	self.xnat_session_id = "#{self.subject.export_id.to_s}_#{sp_array.first.subjectid_base}#{sp_array.first.visit_abbr("_v1")}"

      	if !secondary_key.blank? and secondary_key.length > 0
      		self.xnat_session_id += "_sk#{secondary_key}"
      	end
      end

	end
end