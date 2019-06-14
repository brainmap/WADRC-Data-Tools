class Xnat::XnatCuratedScan < Xnat::XnatCurated


	belongs_to :session, :class_name => "XnatCuratedSession", foreign_key: :session_id
	belongs_to :image_dataset, :class_name => "ImageDataset", foreign_key: :image_dataset_id
	belongs_to :project, :class_name => "XnatCuratedProject", foreign_key: :project_id

	before_create :make_file_path

	def xnat_exists?(p=@params)
		# response = RestClient::Request.new(
		# 	:method => :get,
		# 	:url => "https://#{p[:xnat_address]}/data/projects/#{self.project.name}/subjects/#{self.session.subject.export_id}/experiments/#{self.session.xnat_session_id}/scans/",
		# 	:user => 'panda_uploader',
		# 	:password => 'XXXXXXX').execute

		# results = JSON.parse(response.to_str)

		# return results["ResultSet"]["Result"].select { |r| r["label"] == self.xnat_session_id }.length > 0


		#but for now:

		#log into merida, and use curl to GET the subject's URL, and log the result
		file_path_array = self.file_path.split("/")
		v_log_file_path = "#{ p[:working_directory] }/xnat_#{ self.session.xnat_session_id }_#{ file_path_array.last }.log"
		cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }; curl --netrc -o #{ v_log_file_path } -w \\\"%{http_code}\\\" -X GET https://#{ p[:xnat_address] }/data/archive/projects/#{ self.project.name }/subjects/#{ self.session.subject.export_id }/experiments/#{ self.session.xnat_session_id }/scans?format=json\""
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


		#xnat does this great thing where it takes scan numbers that we give it, and strips the zero padding
		# off of the left, and then hands that value back as a string again...
		xnat_id = file_path_array.last.to_i.to_s

		if p[:verbose]
			puts data["ResultSet"]["Result"].select { |i| !i.nil? and i["ID"] == xnat_id }.to_s
		end
		#clean up that remote log
		response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"rm #{ v_log_file_path }\""

        return data["ResultSet"]["Result"].select { |i| !i.nil? and i["ID"] == xnat_id }.length > 0
	end

	def xnat_create(p=@params)
		begin

			#log into merida, make space in /tmp, remove old/conflicting files,
	        response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'cd #{ p[:working_directory] }; rm -rf #{ p[:working_directory] }/#{ self.session.xnat_session_id }.tgz'"
	        response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'cd #{ p[:working_directory] }; rm -rf #{ p[:working_directory] }/#{ self.session.xnat_session_id }.log'"
	        response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'cd #{ p[:working_directory] }; rm -rf #{ p[:working_directory] }/#{ self.session.xnat_session_id }'"

		    #make a working dir for this session
		    response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'cd #{ p[:working_directory] }; mkdir #{ self.session.xnat_session_id }'"
	        
	        #rsync in the scan we want, anonymize it, and tgz
	        response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu 'rsync -av #{ self.file_path } #{ p[:working_directory] }/#{ self.session.xnat_session_id }/'"
	          
		    #decompress the .bz2 archive
		    v_path_array = self.file_path.split("/")
		    scan_number = v_path_array.last
		    response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/#{ self.session.xnat_session_id }/#{ scan_number };find . -name '*.bz2' -exec bunzip2 {} \\\;\" "
	          

		    #remove any extra stuff we don't want to upload
		    p[:rm_endings].each do |file_ending|
		      response = r_call"ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/#{ self.session.xnat_session_id }/#{ scan_number }/;rm -rf *.#{ file_ending } \""
		    end

		    #strip dicom headers from the uploadable stuff
		    response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"#{ p[:script_dicom_clean] } '#{ p[:working_directory] }/#{ self.session.xnat_session_id }/#{ scan_number }' '#{ self.session.subject.export_id }' '#{ self.project.name }' '#{ self.session.xnat_session_id }' \" "

	        response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/;tar czf #{ self.session.xnat_session_id }_#{ scan_number }.tgz #{ self.session.xnat_session_id }/#{ scan_number }\""

	        #run the upload
	        
	        if !p[:dry_run]
	          v_log_file_path = "#{ p[:working_directory] }/#{ self.session.xnat_session_id }_#{ scan_number }.log"
	          puts "log file is #{ v_log_file_path }"
	          querystring = "xsiType=xnat:mrScanData&triggerPipelines=false"
	          cmd = "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/; curl --netrc -o #{ v_log_file_path } --speed-time 30 --speed-limit 10 -w \\\"%{http_code}\\\" -X POST --form project=#{ self.project.name } --form image_archive=@#{ self.session.xnat_session_id }_#{ scan_number }.tgz --form overwrite=append --form dest=/archive/projects/#{ self.project.name }/subjects/#{ self.session.subject.export_id }/experiments/#{ self.session.xnat_session_id } \\\"https://#{ p[:xnat_address] }/data/services/import?#{ querystring }\\\"\""
	          if p[:verbose]
	          	puts cmd
	          end
	          response = r_call cmd
	          # response = r_call "ssh panda_user@#{ p[:computer] }.dom.wisc.edu \"cd #{ p[:working_directory] }/; curl --netrc -o #{ self.session.xnat_session_id }.log --speed-time 30 --speed-limit 10 -w \\\"%{http_code}\\\" --form project=#{ self.project.name } --form image_archive=@#{ self.session.xnat_session_id }.tgz https://#{ p[:xnat_address] }/data/projects/#{ self.project.name }/subjects/#{ self.session.subject.export_id }/experiments/#{ self.session.xnat_session_id }/scans/#{ scan_number }?format=html&#{ querystring }\""
	          
	          puts response
	          
	          
	          #retrieve the log
	          response = r_call "rsync -av panda_user@#{ p[:computer] }.dom.wisc.edu:#{ v_log_file_path } #{ v_log_file_path }"

	          #then get back any log output, and search it for status of the upload
	          # => "Session processing may already be in progress" -> 'F' (already in progress)
	          # => "following sessions have been uploaded" -> 'D' (done)
	          # => "HTTP Status 401" -> 'F' failed login
	          # => "RMR" -> 'F' failed dicom cleaning
	          # else: some other failure

	          #for large uploads, XNAT seems to fail to respond, even when the upload works without conflicts.
	          # because of that, sometimes we just don't get back a log. But that's ok, because we can use 
	          # xnat_exists? to get ground truth. 
	          v_status = 'F'
	          v_status_comment = ''

	          if File.file?(v_log_file_path)
		          File.foreach(v_log_file_path).detect { |line| 
		            if line.include?("Session processing may already be in progress")
		              v_status ='F'
		              v_status_comment = "record already loaded:="+line
		            elsif  line.include?("following sessions have been uploaded")
		              v_status ='D'
		              v_status_comment = "recordloaded:="+line
		            elsif  line.include?("HTTP Status 401")
		              v_status ='F'
		              v_status_comment = "failed login:="+line
		            elsif  line.include?("RMR")
		              v_status ='F'
		              v_status_comment = "failed dicom cleaning:="+line
		            elsif  line.include?("Too Big!")
		              v_status ='B'
		              v_status_comment = "the archive we tried to upload was too large:="+line
		            else  
		              v_status ='F'
		              v_status_comment = "something unexpected:="+line
		            end
		          }
		      end

	      	end
			#log into merida, make space in /tmp, remove old/conflicting files,
			#rsync in the scan we want, anonymize it, and tgz
			#curl the tgz up to the server
			#copy the log back locally, and read it for our answer.
			puts "#{ v_status } -- #{v_status_comment}"

		rescue RestClient::MethodNotAllowed => e
			#log that this attempt failed.
		end
	end


	def make_file_path

	  #for this, we just copy forward from the related image_dataset
	  self.file_path = self.image_dataset.path

	end

end