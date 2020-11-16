class Jobs::NaccUpload::NaccUploadBase < Jobs::BaseJob

	attr_accessor :sdm_filter
	attr_accessor :selected
	attr_accessor :driver

	def self.default_params
	  	params = { :schedule_name => 'NACC Upload to S3', 
	  				:run_by_user => 'panda_user',
	  				# :access_key => Rails.application.config.nacc_access_key,
	  				# :secret_key => Rails.application.config.nacc_secret_key
	  				:remote_bucket => "naccimageraw",
	  				:cg_table => "cg_adrc_upload",
	  				:computer => "moana",
	  				:target_dir => "/tmp/adrc_upload"
	  			}
        params.default = ''
        params
    end


	def run(params)

		begin
			setup(params)

			table_rotation(params)

			selection(params)

			filter(params)

			prep_for_send(params)

			send_to_s3(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	# setup
	# 	build the job & status
	# 	build whatever initial values and members we need
		
	def setup(params)

		@sdt_filter = SeriesDescriptionType.where(:series_description_type => ['T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','T2','T2 Flair','T2_Flair','T2+Flair','DTI'])
		@sdm_filter = SeriesDescriptionMap.where(:series_description_type_id => sdt_filter.map(&:id)).map{|item| item.series_description.downcase}

	    if !File.directory?(params[:target_dir])
	      Dir.mkdir(params[:target_dir])
	    end

	end


	# table rotation
	#   truncate table cg_adrc_upload_new
	#   copy in from cg_adrc_upload

	
	def table_rotation(params)


		sql = "truncate #{params[:cg_table]}_new"
		@connection.execute(sql)

    	sql = "insert into #{params[:cg_table]}_new(subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,status_comment,dir_list,  dti_sent_flag, dti_status_flag,  dti_dir_list ,  pcvipr_sent_flag,  pcvipr_status_flag,  pcvipr_dir_list ,
  						wahlin_t1_asl_resting_sent_flag,  wahlin_t1_asl_resting_status_flag, wahlin_t1_asl_resting_dir_list ,xnat_sent_flag,  xnat_status_flag,  xnat_dir_list ) select subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,status_comment,dir_list, dti_sent_flag, dti_status_flag,  dti_dir_list ,  pcvipr_sent_flag,  pcvipr_status_flag,  pcvipr_dir_list ,
  						wahlin_t1_asl_resting_sent_flag,  wahlin_t1_asl_resting_status_flag, wahlin_t1_asl_resting_dir_list ,xnat_sent_flag,  xnat_status_flag,  xnat_dir_list  from #{params[:cg_table]}"
    	@connection.execute(sql)

	    # recruit new adrc scans ---   change 
	    v_weeks_back = "2"
	    sql = "select distinct enrollments.enumber from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups  where enrollments.enumber like 'adrc%' 
              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
              and scan_procedures_vgroups.vgroup_id = vgroups.id
              and scan_procedures_vgroups.scan_procedure_id = 22
              and vgroups.vgroup_date < DATE_SUB(curdate(), INTERVAL "+v_weeks_back+" WEEK)             
              and enrollments.enumber NOT IN ( select subjectid from cg_adrc_upload_new)
              and vgroups.transfer_mri ='yes'"
	    results = @connection.execute(sql)
	    results.each do |r|
	          enrollment = Enrollment.where("enumber in (?)",r[0])
	          sql2 = "insert into #{params[:cg_table]}_new (subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,dti_sent_flag,dti_status_flag) values('"+r[0]+"','N','Y', "+enrollment.first.id.to_s+",22,'N','Y')"
	          results2 = @connection.execute(sql2)
	    end
	     # its going to grab ~70 -need to adjust v_weeks_back  to cover 2015-08-05
	        sql = "select distinct enrollments.enumber from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups  where enrollments.enumber like 'adrc%' 
	              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
	              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
	              and scan_procedures_vgroups.vgroup_id = vgroups.id
	              and scan_procedures_vgroups.scan_procedure_id = 65
	              and vgroups.vgroup_date < DATE_SUB(curdate(), INTERVAL "+v_weeks_back+" WEEK)             
	              and concat(enrollments.enumber,'_v2') NOT IN ( select subjectid from cg_adrc_upload_new)
	              and vgroups.transfer_mri ='yes'"
	    results = @connection.execute(sql)
	    results.each do |r|
	          enrollment = Enrollment.where("enumber in (?)",r[0])
	          sql2 = "insert into #{params[:cg_table]}_new (subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,dti_sent_flag,dti_status_flag) values('"+r[0]+"_v2','N','Y', "+enrollment.first.id.to_s+",65,'N','Y')"
	          results2 = @connection.execute(sql2)
	    end   

	    sql = "select distinct enrollments.enumber from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups  where enrollments.enumber like 'adrc%' 
	              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
	              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
	              and scan_procedures_vgroups.vgroup_id = vgroups.id
	              and scan_procedures_vgroups.scan_procedure_id = 89
	              and vgroups.vgroup_date < DATE_SUB(curdate(), INTERVAL "+v_weeks_back+" WEEK)             
	              and concat(enrollments.enumber,'_v3') NOT IN ( select subjectid from cg_adrc_upload_new)
	              and vgroups.transfer_mri ='yes'"
	    results = @connection.execute(sql)
	    results.each do |r|
	          enrollment = Enrollment.where("enumber in (?)",r[0])
	          sql2 = "insert into #{params[:cg_table]}_new (subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,dti_sent_flag,dti_status_flag) values('"+r[0]+"_v3','N','Y', "+enrollment.first.id.to_s+",89,'N','Y')"
	          results2 = @connection.execute(sql2)
	    end 

	    sql = "truncate #{params[:cg_table]}_old"
	    @connection.execute(sql)

	    sql = "insert into #{params[:cg_table]}_old select * from #{params[:cg_table]}" 
	    @connection.execute(sql)

	    sql = "truncate #{params[:cg_table]}"
	    @connection.execute(sql)

	   	sql = "insert into #{params[:cg_table]} select * from #{params[:cg_table]}_new"
	    @connection.execute(sql)

	    shared = Shared.new
	    shared.apply_cg_edits(params[:cg_table])

	end

	# selection
	#   get enrollments for MRI scan appointments from the last 2 weeks that aren't already in cg_adrc_upload_new
	#   from scan_procedures 89, 65, and 22 (adrc visits 3, 2, & 1, respectively)
	# check that /tmp/adrc_upload exists, and if not, mkdir
	# for each subject in cg_adrc_upload where where sent_flag ='N' and status_flag in ('Y','R')
	#   get their scan_procedure id from the table, and look for a corresponding vgroup
	#   make a folder named something like /tmp/adrc_upload/[subjectid]_YYYYMMDD_wisc
	#   get their scans, with mapped scan procedure names from series_description_maps
	# => "select distinct appointments.appointment_date, visits.id visit_id, image_datasets.id image_dataset_id, image_datasets.series_description, image_datasets.path, series_description_types.series_description_type 
              #     from vgroups , appointments, visits, image_datasets, series_description_maps, series_description_types  
              #     where vgroups.transfer_mri = 'yes' and vgroups.id = appointments.vgroup_id 
              #     and appointments.id = visits.appointment_id and visits.id = image_datasets.visit_id
              #     and LOWER(image_datasets.series_description) =   LOWER(series_description_maps.series_description)
              #     and series_description_maps.series_description_type_id = series_description_types.id
              #     and series_description_types.series_description_type in ('T1 Volumetic','T1 Volumetric','T1+Volumetric','T1_Volumetric','T1','T2','T2 Flair','T2_Flair','T2+Flair','DTI') 
              #     and image_datasets.series_description != 'DTI whole brain  2mm FATSAT ASSET'
              #     and vgroups.id in (select evm.vgroup_id from enrollment_vgroup_memberships evm, enrollments e where evm.enrollment_id = e.id and e.enumber ='"+v_subjectid_chop+"')
              # and vgroups.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg where spvg.scan_procedure_id = "+r[1].to_s+")
              #      order by appointments.appointment_date "

		
	def selection(params)

		sql = "select distinct subjectid,scan_procedure_id,status_flag from cg_adrc_upload where sent_flag ='N' and status_flag in ('Y','R') "
    	results = @connection.execute(sql)

	    results.each do |row|

	    	adrc_case = {:subject_id => row[0], :scan_procedure => ScanProcedure.where(:id => row[1]).first}
	    	adrc_case[:enumber] = (row[0]).gsub('_v2','').gsub('_v3','').gsub('_v4','').gsub('_v5','').gsub('_v6','').gsub('_v7','')
	    	adrc_case[:status_flag] = row[2]

	    	@selected << adrc_case
	    end
	end


	# => if we have < 2 files to send, error out this case & remove the subject's target dir

	def filter(params)

		@selected.each do |adrc_case|

		    self.log << {:message => "packing #{adrc_case[:subject_id]}"}
		    vgroup = Vgroup.joins("LEFT JOIN enrollment_vgroup_memberships ON vgroups.id = enrollment_vgroup_memberships.vgroup_id")
		    				.joins("LEFT JOIN scan_procedures_vgroups ON scan_procedures_vgroups.vgroup_id = vgroups.id")
		    				.where("enrollment_vgroup_memberships.enrollment_id = ?",Enrollment.where(:enumber => adrc_case[:enumber]).first.id)
		    				.where("scan_procedures_vgroups.scan_procedure_id = ?",adrc_case[:scan_procedure].id)
		    				.first


		    #does this vgroup have the right image datasets?
		    visits = Visit.where(:appointment_id => vgroup.appointments.select{|item| item.appointment_type == 'mri'}.map(&:id))
		    images = Jobs::NaccUpload::ImageDataset.where(:visit_id => visits.map(&:id)).select{|item| (@sdm_filter.include? item.series_description.downcase) and (item.series_description != 'DTI whole brain  2mm FATSAT ASSET')}

	        # if we only have 2 different scan types, or the status flag for this case is 'R', fail the case
	        series_description_counts = images.each_with_object(Hash.new(0)){|item,hash| hash[@sdm_filter.select{|sdm| sdm.series_description.downcase == item.series_description.downcase}.first.series_description_type_id] += 1}
	        if series_description_counts.keys.count < 2
	        	self.exclusions << {:protocol => adrc_case[:scan_procedure].codename, :subject => adrc_case[:enumber], :message => "too few scan types"}
	        	next
	        end

	        if adrc_case[:status_flag] == 'R'
	        	self.exclusions << {:protocol => adrc_case[:scan_procedure].codename, :subject => adrc_case[:enumber], :message => "status is 'R' for this case"}
	        	next
	        end

	        #this case passes, so let's set it up for prep

		    adrc_case[:case_directory] = "#{adrc_case[:subject_id]}_#{vgroup.vgroup_date.strftime("%Y%m%d")}_wisc"
		    adrc_case[:subject_dir] = "#{params[:target_dir]}/#{adrc_case[:case_directory]}"

		    if !File.directory?(subject_dir)
		      Dir.mkdir(subject_dir)
		    end

		    subject_subdirs = []
	        adrc_case[:images] = []

		    images.each do |image|

		    	#check that there's nothing rated "severe" or "incomplete" on the IQC checks for this image
		    	if image.passed_iqc?

			    	path_parts = image.path.split("/")
			    	image_target_dir = "#{subject_dir}/#{path_parts.last}"

			    	if subject_subdirs.include? image_target_dir
			    		#tack something on the end so that we don't overwrite
			    		image_target_dir = "#{image_target_dir}_#{subject_subdirs.count}}"
			    	end

			    	subject_subdirs << image_target_dir
		    		adrc_case[:images] << {:path => File.realpath(image.path), :target_dir => image_target_dir}
		    	end
		    end

		    @driver << adrc_case

		end
	end

	# 	prep for send
	# => for each of those datasets, copy from the path into our waiting subject dir
	# => unzip any .bz2 files
	# => remove .yaml, .json, and .pickle files from the target dir for this scan
	# => scrub some values
	
	def prep_for_send(params)

		@driver.each do |adrc_case|

			adrc_case[:images].each do |image_case|
				# create the target dir
				r_call "mkdir #{image_case[:target_dir]}"

				# copy over the image
				r_call "cp -r #{image_case[:path]} #{image_case[:target_dir]}"

				# unzip what's in the target dir
				r_call "/usr/bin/bunzip2 #{image_case[:target_dir]}/*.bz2"

				# remove any of those extraneous files
				# this may seem less readable than doing it other ways, but this ... is actually better.
				glob_patterns = ['/*','/*/*','/*/*/*'].map{|prefix| ['.json','.yaml','.pickle'].map{|suffix| "#{prefix}#{suffix}"}}.flatten
				glob_patterns.each do |pattern|
					if(File.exist?(image_case[:target_dir]+pattern))
						File.delete(image_case[:target_dir]+pattern)
					end
				end

				# scrub any dicom files we find within the target dir

				v_dicom_field_array =['0010,0030','0010,0010','0008,0050','0008,1030','0010,0020','0040,0254','0008,0080','0008,1010','0009,1002','0009,1030','0018,1000',
                        '0025,101A','0040,0242','0040,0243']
        		v_dicom_field_value_hash ={'0010,0030'=>'DOB','0010,0010'=>'Name','0008,0050'=>'Accession Number',
                           '0008,1030'=>'Study Description', '0010,0020'=>'Patient ID','0040,0254'=>'Performed Proc Step Desc',
                            '0008,0080'=>'Institution Name','0008,1010'=>'Station Name','0009,1002'=>'Private',
                            '0009,1030'=>'Private','0018,1000'=>'Device Serial Number','0025,101A'=>'Private',
                            '0040,0242'=>'Performed Station Name','0040,0243'=>'Performed Location'}

                scrubbable_file_extensions = ['/*/*/*.dcm', '/*/*/*.0*', '/*/*/*.1*', '/*/*/*.2*', '/*/*/*.3*']
                scrubbable_file_extensions.each do |file_extention|
                	Dir.glob(image_case[:target_dir]+file_extention).each do |scrubbable_dcm_filename|
                		d = DICOM::DObject.read(scrubbable_dcm_filename); 
                        v_dicom_field_array.each do |dicom_key|
                        	if !d[dicom_key].nil? 
                            	d[dicom_key].value = v_dicom_field_value_hash[dicom_key]
                            	d.write(scrubbable_dcm_filename);
                            end 
                        end
                	end
                end

            end
                
            # rsync this to 
            r_call "rsync -av #{image_case[:target_dir]} panda_user@#{params[:computer]}.dom.wisc.edu:/home/panda_user/upload_adrc/"

            r_call "ssh panda_user@#{params[:computer]}.dom.wisc.edu \"tar -C /home/panda_user/upload_adrc -zcf /home/panda_user/upload_adrc/#{adrc_case[:subject_dir]}.tar.gz #{adrc_case[:subject_dir]}/\""

	        r_call "ssh panda_user@#{params[:computer]}.dom.wisc.edu \"rm -rf /home/panda_user/upload_adrc/#{adrc_case[:subject_dir]}/\""

	        r_call "rsync -av panda_user@#{params[:computer]}.dom.wisc.edu:/home/panda_user/upload_adrc/#{adrc_case[:subject_dir]}.tar.gz #{image_case[:target_dir]}/#{adrc_case[:subject_dir]}.tar.gz"
		end
	end

	# send
	# 	verify that the send worked
	# 	update the driver table
		
	def send_to_s3(params)

		@driver.each do |adrc_case|

        	v_call_sftp = 'ssh panda_user@'+v_computer+'.dom.wisc.edu "/home/panda_user/upload_adrc/sftp_adrc_upload.py" '


        	v_call = 'ssh panda_user@'+v_computer+'.dom.wisc.edu "ls /home/panda_user/upload_adrc/'+v_subject_dir+'.tar.gz"'

        	if v_return.include?("No such file or directory")
        		#this upload failed
        	end


        	r_call " rm -rf "+v_target_dir+"/"+v_subject_dir+".tar.gz"

        	sql_sent = "update cg_adrc_upload set sent_flag ='Y' where subjectid ='#{adrc_case[:subject_id]}'"
        	@connection.execute(sql_sent)
    	end
	end

end