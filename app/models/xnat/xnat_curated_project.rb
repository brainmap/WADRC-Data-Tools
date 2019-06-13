class Xnat::XnatCuratedProject < Xnat::XnatCurated

	has_many :subjects, :class_name => "XnatCuratedSubject", foreign_key: :project_id, primary_key: :id
	has_many :drivers, :class_name => "XnatCuratedDriver", foreign_key: :project_id, primary_key: :id

	def initialize(args)
		self.name = args[:name]
		
	end

	def xnat_exists?(p=@params)
		# someday, when we use config/secrets.yml:

		# response = RestClient::Request.new(
		# 	:method => :get,
		# 	:url => "https://#{p[:xnat_address]}/data/projects/",
		# 	:user => 'panda_uploader',
		# 	:password => 'XXXXXXX').execute

		# results = JSON.parse(response.to_str)

		# return results["ResultSet"]["Result"].select { |r| r["ID"] == self.name }.length > 0

		#but for now:

		#log into merida, and use curl to GET the project's URL, and log the result
		v_log_file_path = "#{ p[:working_directory] }/xnat_#{ self.name }.log"
		cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }; curl --netrc -o #{ v_log_file_path } -w \\\"%{http_code}\\\" -X GET https://#{ p[:xnat_address] }/data/archive/projects/#{ self.name }?format=json\""
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
			puts data["items"].select { |i| i["data_fields"]["ID"] == self.name }.to_s
		end

		#clean up that remote log
		response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"rm #{ v_log_file_path }\""

		#return a boolean of our result
        return data["items"].select { |i| i["data_fields"]["ID"] == self.name }.length > 0

	end

end