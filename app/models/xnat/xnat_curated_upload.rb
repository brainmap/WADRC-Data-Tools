class Xnat::XnatCuratedUpload

  def self.default_params
	  params = { schedule_name: 'xnat_curated_upload',
				base_path: Shared.get_base_path(), 
    			computer: "merida",
    			comment: [],
    			comment_warning: "",
    			log_base: "/mounts/data/preprocessed/logs/",
    			process_name: "xnat_curated",
    			stop_file_name: "xnat_curated_file_stop",
      			stop_file_path: "/mounts/data/preprocessed/logs/xnat_curated_file_stop",

      			project: nil,

	            #usually this script will grab the project from the driver table along with imageset ids,
	            # and upload anything that isn't already on xnat. If we specify a project on params, it 
	            # will only look for new entries under that project.

      			working_directory: "/tmp",
      			rm_endings: ["json","pickle","yaml","txt","xml","doc","xls","xlsx"],
	            default_xnat_run_upload_flag: 'W',
	            xnat_filesize_limit: '52428800',
	            dry_run: false,
	        	verbose: false }

      params[:xnat_script_dir] = params[:base_path]+"/data1/lab_scripts/"
      params[:script_dicom_clean] =  params[:xnat_script_dir]+"xnat_dicom_upload_cleaner.rb"
      params[:xnat_address] = 'xnat.medicine.wisc.edu'
      params
    end

    def setup(p=@params)
    	#create the tracking objects based on the driver objects

    	#get all of the drivers where xnat_exists_flag = 'N' (they haven't uploaded)
    	drivers = Xnat::XnatCuratedDriver.where("xnat_exists_flag = 'N'")

		# for each driver
		drivers.each do |driver|
			# get the image_dataset
			image_ds = ImageDataset.find(driver.image_dataset_id)
			visit = Visit.find(image_ds.visit_id)
			enrollment = Enrollment.where("id in (select enrollment_id from enrollment_visit_memberships where visit_id = ?)",visit.id).first
			participant = Participant.find(enrollment.participant_id)

			# check that an xnat_curated_subject for this image_dataset exists. if not, create the subject
			subject = Xnat::XnatCuratedSubject.find_or_create_by(project: driver.project, participant_id: participant.id)

			# check that an xnat_curated_session exists for this subject. if not, create the session
			session = Xnat::XnatCuratedSession.find_or_create_by(project: driver.project, subject: subject, visit: visit, appointment_id: visit.appointment_id)

			# check that an xnat_curated_scan exists for this session & image_dataset. if not, create the scan
			image_scan = Xnat::XnatCuratedScan.find_or_create_by(image_dataset:image_ds, project: driver.project, session: session)

			#should carry forward the "do not share scans" flags from visits, enrollments, vgroups, appointments, etc.
		end

    end

    def check(p=@params)

    	#without params filtering our drivers (or subjects, etc.) this should just grab everything and check that it's
    	# either "published" or "unpublished" from xnat

    	#param to check only those where xnat_exists_flag == the param

    	#get all of the subjects where "xnat_exists_flag" != 'Y'
    	subjects = Xnat::XnatCuratedSubject.where("xnat_exists_flag != 'Y'")

    	if !p[:project].nil?
    		project = Xnat::XnatCuratedProject.where("name = ?",p[:project])
    		subjects = subjects.where(:project => project)
    	end

    	subjects.each do |subject|
    		#check the status on the server. If the subject exists, update xnat_exists_flag to 'Y'
    		if subject.xnat_exists?(p)
    			subject.sessions.each do |session|
		    		if session.xnat_exists?(p)
    					session.scans.each do |image_scan|
    						if image_scan.xnat_exists?(p)
    							image_scan.xnat_exists_flag = 'Y'
    							image_scan.save
    						end
    					end

    					#if all of the scans exist, then we can mark the session as 'Y'
    					if session.scans.all { |s| s.xnat_exists_flag == 'Y' }
	    					session.xnat_exists_flag = 'Y'
	    					session.save
	    				end

    				end
    			end

    			if subject.sessions.all { |s| s.xnat_exists_flag == 'Y' }
	    			subject.xnat_exists_flag = 'Y'
	    			subject.save
	    		end
    		end
    	end
    end

    def sync(p=@params)

    	#get all of the subjects where "xnat_exists_flag" != 'Y'
    	subjects = Xnat::XnatCuratedSubject.where("xnat_exists_flag != 'Y'")

    	if !p[:project].nil?
    		project = Xnat::XnatCuratedProject.where("name = ?",p[:project])
    		subjects = subjects.where(:project => project)
    	end

    	subjects.each do |subject|
    		#check the status on the server. If the subject exists, update xnat_exists_flag to 'Y'
    		if !subject.xnat_exists?(p)
    			subject.xnat_create(p)
    		end
    		subject.sessions.each do |session|
		    	if !session.xnat_exists?(p)
		    		session.xnat_create(p)
		    	end
    			session.scans.each do |image_scan|
    				if !image_scan.xnat_exists?(p)
    					image_scan.xnat_create(p)
    				else
    					image_scan.xnat_exists_flag = 'Y'
    				end
    				image_scan.save
    			end

    			#if all of the scans exist, then we can mark the session as 'Y'
    			if session.scans.all { |s| s.xnat_exists_flag == 'Y' }
	    			session.xnat_exists_flag = 'Y'
	    		end
	    		session.save

    		end

	    	if subject.sessions.all { |s| s.xnat_exists_flag == 'Y' }
		    	subject.xnat_exists_flag = 'Y'
		    end
		    subject.save
		end
    end

end