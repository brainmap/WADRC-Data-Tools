class Xnat::XnatCuratedSubject < Xnat::XnatCurated

	attr_accessor :label

	has_many :sessions, :class_name => "XnatCuratedSession", foreign_key: :subject_id, primary_key: :id
	belongs_to :project, :class_name => "XnatCuratedProject", foreign_key: :project_id
	belongs_to :participant, :class_name => "Participant", foreign_key: :participant_id

	before_create :make_export_id

	def xnat_exists?(p=@params)
		# someday, when we use config/secrets.yml:

		# response = RestClient::Request.new(
		# 	:method => :get,
		# 	:url => "https://#{p[:xnat_address]}/data/projects/#{self.project.name}/subjects/",
		# 	:user => 'panda_uploader',
		# 	:password => 'XXXXXXX').execute

		# results = JSON.parse(response.to_str)

		# return results["ResultSet"]["Result"].select { |r| r["label"] == self.export_id }.length > 0


		#but for now:

		#log into merida, and use curl to GET the subject's URL, and log the result
		v_log_file_path = "#{ p[:working_directory] }/xnat_#{ self.export_id }.log"
		cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }; curl --netrc -o #{ v_log_file_path } -w \\\"%{http_code}\\\" -X GET https://#{ p[:xnat_address] }/data/archive/projects/#{ self.project.name }/subjects?format=json\""
		if p[:verbose]
			puts cmd
		end
		response = r_call cmd
		if p[:verbose]
			puts response
		end

		#copy the log of that command back from the server, so that we can see the results
        cmd = "rsync -av panda_user@#{ p[:computer] }.dom.wisc.edu:#{ v_log_file_path } #{ v_log_file_path }"
        if p[:verbose]
			puts cmd
		end
		response = r_call cmd
		if p[:verbose]
			puts response
		end

        json_file = File.open(v_log_file_path)
        data = JSON.load json_file

		if p[:verbose]
			puts data["ResultSet"]["Result"].select { |i| i["label"] == self.export_id }.to_s
		end

		#clean up that remote log
		response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"rm #{ v_log_file_path }\""

        return data["ResultSet"]["Result"].select { |i| i["label"] == self.export_id }.length > 0

	end

	def xnat_create(p=@params)
		# begin
		# 	response = RestClient::Request.new(
		# 		:method => :post,
		# 		:url => "https://#{p[:xnat_address]}/data/projects/#{self.project.name}/subjects/#{self.export_id}",
		# 		:user => 'panda_uploader',
		# 		:password => 'XXXXXXX').execute

		# 	# if the response code was 201, we're good.
		# 	# results = JSON.parse(response.to_str)
		# rescue RestClient::MethodNotAllowed => e
		# 	#log that this attempt failed.
		# end


		#log into merida, and use curl to GET the subject's URL, and log the result
		v_log_file_path = "#{ p[:working_directory] }/xnat_#{ self.export_id }.log"
		cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }; curl --netrc -o #{ v_log_file_path } -w \\\"%{http_code}\\\" -X PUT https://#{ p[:xnat_address] }/data/archive/projects/#{ self.project.name }/subjects/#{ self.export_id }?format=json\""
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

	def make_export_id

		connection = ActiveRecord::Base.connection();
		sql = "select export_id from xnat_curated_subjects where export_id is NOT NULL"
		v_exportid_results = connection.execute(sql)
		v_exportid_array = []
		v_exportid_results.each { |r| v_exportid_array << r }

		r = Random.new
		candidate_export_id = r.rand(1000..9999999999).to_s.rjust(10,'0')
	    while v_exportid_results.include?("#{self.project.name}_#{candidate_export_id}")
	    	candidate_export_id = r.rand(1000..9999999999).to_s.rjust(10,'0')
	    end
      	self.export_id = "#{self.project.name}_#{candidate_export_id}"
	end
end