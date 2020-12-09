class Jobs::NaccUpload::NaccUploadBase < Jobs::BaseJob

	attr_accessor :sdm_filter
	attr_accessor :sdt_filter
	attr_accessor :selected
	attr_accessor :driver

	def self.default_params
	  	params = { :schedule_name => 'NACC Upload to S3', 
	  				:run_by_user => 'panda_user',
	  				# :access_key => Rails.application.config.nacc_access_key,
	  				# :secret_key => Rails.application.config.nacc_secret_key
	  				:remote_bucket => "naccimageraw",
	  				:cg_table => "cg_adrc_upload",
	  				:computer => "tamatoa",
	  				:target_dir => "/tmp/adrc_upload",
	  				:local => false
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
		@sdm_filter = SeriesDescriptionMap.where(:series_description_type_id => sdt_filter.map(&:id))
		@selected = []
		@driver = []

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
	    sql = "select distinct enrollments.enumber from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups  where enrollments.enumber like 'adrc%' 
              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
              and scan_procedures_vgroups.vgroup_id = vgroups.id
              and scan_procedures_vgroups.scan_procedure_id = 22            
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
	              and concat(enrollments.enumber,'_v3') NOT IN ( select subjectid from cg_adrc_upload_new)
	              and vgroups.transfer_mri ='yes'"
	    results = @connection.execute(sql)
	    results.each do |r|
	          enrollment = Enrollment.where("enumber in (?)",r[0])
	          sql2 = "insert into #{params[:cg_table]}_new (subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,dti_sent_flag,dti_status_flag) values('"+r[0]+"_v3','N','Y', "+enrollment.first.id.to_s+",89,'N','Y')"
	          results2 = @connection.execute(sql2)
	    end 

	    sql = "select distinct enrollments.enumber from enrollments,enrollment_vgroup_memberships, vgroups, scan_procedures_vgroups  where enrollments.enumber like 'adrc%' 
	              and vgroups.id = enrollment_vgroup_memberships.vgroup_id 
	              and enrollment_vgroup_memberships.enrollment_id = enrollments.id
	              and scan_procedures_vgroups.vgroup_id = vgroups.id
	              and scan_procedures_vgroups.scan_procedure_id = 119
	              and concat(enrollments.enumber,'_v4') NOT IN ( select subjectid from cg_adrc_upload_new)
	              and vgroups.transfer_mri ='yes'"
	    results = @connection.execute(sql)
	    results.each do |r|
	          enrollment = Enrollment.where("enumber in (?)",r[0])
	          sql2 = "insert into #{params[:cg_table]}_new (subjectid,sent_flag,status_flag, enrollment_id, scan_procedure_id,dti_sent_flag,dti_status_flag) values('"+r[0]+"_v4','N','Y', "+enrollment.first.id.to_s+",119,'N','Y')"
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
		    images = Jobs::NaccUpload::ImageDataset.where(:visit_id => visits.map(&:id)).select{|item| (@sdm_filter.map{|x| x.series_description.downcase}.include? item.series_description.downcase) and (item.series_description != 'DTI whole brain  2mm FATSAT ASSET')}
		    ppt = vgroup.enrollments.first.participant

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

		    adrc_case[:case_dir] = "#{adrc_case[:subject_id]}_#{vgroup.vgroup_date.strftime("%Y%m%d")}_wisc"
		    adrc_case[:subject_dir] = "#{params[:target_dir]}/#{adrc_case[:case_dir]}"
		    adrc_case[:participant] = ppt

		    if !File.directory?(adrc_case[:subject_dir])
		      Dir.mkdir(adrc_case[:subject_dir])
		    end

		    subject_subdirs = []
	        adrc_case[:images] = []

		    images.each do |image|

		    	#check that there's nothing rated "severe" or "incomplete" on the IQC checks for this image
		    	if image.passed_iqc?

			    	path_parts = image.path.split("/")
			    	image_target_dir = "#{adrc_case[:subject_dir]}/#{path_parts.last}"

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
				r_call "cp -r #{image_case[:path]}/* #{image_case[:target_dir]}/"

			end

			# 2020-12-04 wbbevis -- Until Merida gets reimaged and returned to the lab, I'm going to have to use
			# Tamatoa as the host for this process. Not a bad fit, really, as everyone is out of the office, and 
			# it's a relatively hefty machine that can do this kind of work pretty quickly. Once Merida is back, 
			# I'll need to upgrade python3 on it to 3.8. 


		    if !params[:local]
			    # copy that to the sending host

			    r_call "cd #{params[:target_dir]}; zip -r #{adrc_case[:case_dir]}.zip #{adrc_case[:case_dir]}"
			    r_call "rsync -av #{params[:target_dir]}/#{adrc_case[:case_dir]}.zip #{params[:run_by_user]}@#{params[:computer]}.dom.wisc.edu:/Users/#{params[:run_by_user]}/adrc_upload/"
				r_call "ssh #{params[:run_by_user]}@#{params[:computer]}.dom.wisc.edu \"/usr/bin/gunzip /Users/#{params[:run_by_user]}/adrc_upload/#{adrc_case[:case_dir]}.zip\""
			end

			adrc_case[:images].each do |image_case|


			    if !params[:local]
					# unzip what's in the target dir
					r_call "ssh #{params[:run_by_user]}@#{params[:computer]}.dom.wisc.edu \"/usr/bin/bunzip2 /Users/#{params[:run_by_user]}/adrc_upload/#{image_case[:target_dir]}/*.bz2\""
				else
					r_call "/usr/bin/bunzip2 #{image_case[:target_dir]}/*.bz2"
				end

				# remove any of those extraneous files
				# this may seem less readable than doing it other ways, but this ... is actually better.
				glob_patterns = ['/*','/*/*','/*/*/*'].map{|prefix| ['.json','.yaml','.pickle'].map{|suffix| "#{prefix}#{suffix}"}}.flatten
				glob_patterns.each do |pattern|
					Dir.glob(image_case[:target_dir]+pattern).each do |deleteable_file|

			    		if !params[:local]
							remote_file_path = deleteable_file.gsub(params[:target_dir],"/Users/#{params[:run_by_user]}/adrc_upload")
							# File.delete(image_case[:target_dir]+pattern)
							r_call "ssh #{params[:run_by_user]}@#{params[:computer]}.dom.wisc.edu \"rm #{remote_file_path}\""
						else
							r_call "rm #{deleteable_file}"
						end

					end
				end

                scrubbable_file_extensions = ['/*','/*/*','/*/*/*'].map{|prefix| ['.dcm','.0*','.1*', '.2*','.3*'].map{|suffix| "#{prefix}#{suffix}"}}.flatten
                scrubbable_file_extensions.each do |file_extention|
                	Dir.glob(image_case[:target_dir]+file_extention).each do |scrubbable_dcm_filename|

			    		if !params[:local]
	                		remote_scrubbable_filename = scrubbable_dcm_filename.gsub(params[:target_dir],"/Users/#{params[:run_by_user]}/adrc_upload")
	                		r_call "ssh #{params[:run_by_user]}@#{params[:computer]}.dom.wisc.edu \"cd /Users/#{params[:run_by_user]}/adrc_upload/; source ./bin/activate; python dicom_scrubber.py #{remote_scrubbable_filename} -a #{adrc_case[:participant].adrcnum}; deactivate\""
	                	else
	                		r_call "cd /Users/#{params[:run_by_user]}/adrc_upload/; source ./bin/activate; python dicom_scrubber.py #{scrubbable_dcm_filename} -a #{adrc_case[:participant].adrcnum}; deactivate"
	                	end
                	end
                end

                # instead of 
            end


			if !params[:local]
            	r_call "ssh #{params[:run_by_user]}@#{params[:computer]}.dom.wisc.edu \"cd /Users/#{params[:run_by_user]}/adrc_upload/; /usr/bin/zip -r #{adrc_case[:case_dir]}.zip #{adrc_case[:case_dir]}"
            else
            	r_call "cd /tmp/adrc_upload/; /usr/bin/zip -r #{adrc_case[:case_dir]}.zip #{adrc_case[:case_dir]}"
            end

            # serialize the directory
		    # r_call "tar -C /tmp/adrc_upload -zcf /tmp/adrc_upload/#{adrc_case[:case_dir]}.tar.gz #{adrc_case[:case_dir]}"
		    # sounds like they actually want .zip files
		    # remove the local copy
		    # r_call "rm -rf /tmp/adrc_upload/#{adrc_case[:case_dir]}/"

		end
	end

	# send
	# 	verify that the send worked
	# 	update the driver table
		
	def send_to_s3(params)

		@driver.each do |adrc_case|

			json_report = ''
			if !params[:local]
        		json_report = r_call "ssh #{params[:run_by_user]}@#{params[:computer]}.dom.wisc.edu \"cd /Users/#{params[:run_by_user]}/adrc_upload/; source ./bin/activate && python s3_adrc_upload.py #{adrc_case[:case_dir]}.zip\""
        	else
        		json_report = r_call "cd /Users/#{params[:run_by_user]}/adrc_upload/; source ./bin/activate && python s3_adrc_upload.py #{adrc_case[:case_dir]}.zip -d /tmp/adrc_upload;  deactivate"
        	end
        	report = JSON.parse(json_report)
        	puts json_report

        	# r_call "ssh panda_user@#{params[:computer]}.dom.wisc.edu \"ls /home/panda_user/upload_adrc/#{adrc_case[:case_dir]}.zip\""

        	# r_call "rm -rf /tmp/adrc_upload/#{adrc_case[:case_dir]}.zip"

        	sql_sent = "update cg_adrc_upload set sent_flag ='Y' where subjectid ='#{adrc_case[:subject_id]}'"
        	@connection.execute(sql_sent)
    	end
	end

end