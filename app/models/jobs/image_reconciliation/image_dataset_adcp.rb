class Jobs::ImageReconciliation::ImageDatasetAdcp < Jobs::ImageReconciliation::ImageDataset


	def check_preprocessed(path_prefix, echo_the_candidate=false)


		result = {:image => self}

		# if this is a scan_archive file, there won't be anything in preprocessed.
		# Also, there won't be a dcm_file_count (it should be nil). So we should 
		# return something to that effect, and record same in the database.

		raw_path_parts = path.split('/')

		enrollments = visit.appointment.vgroup.enrollments
	    scan_procedures = visit.appointment.vgroup.scan_procedures
	    path_relevant_sp = scan_procedures.select{|item| path =~ Regexp.new(item.codename)}.first
	    path_relevant_enrollment = enrollments.select{|item| path =~ Regexp.new(item.enumber)}.first
	    preprocessed_path = "#{path_prefix}/preprocessed/visits/#{path_relevant_sp.codename}/#{path_relevant_enrollment.enumber}/#{raw_path_parts[6]}/unknown/"

	    if path =~ /scan_archives/
	    	result[:scan_archives] = true

			result[:preprocessed_path_exists] = false
			result[:longest_existing_preprocessed_path] = ''
		    result[:best_matching_candidate] = ''
			result[:matched_with_study_id] = 0
			result[:matched_count_with_study_id] = 0
			result[:matched_count_without_study_id] = 0

	    else
	    	result[:scan_archives] = 'false'


		    study_id = dicom_taghash.nil? ? '\d*' : (dicom_taghash["0020,0010"].nil? ? '\d*' : (dicom_taghash["0020,0010"].key?(:value) ? dicom_taghash["0020,0010"][:value] : '\d*'))
		    series_number = dicom_taghash.nil? ? '\d*' : (dicom_taghash["0020,0011"].nil? ? '\d*' : (dicom_taghash["0020,0011"].key?(:value) ? dicom_taghash["0020,0011"][:value].rjust(3,'0') : '\d*'))

		    unfixed_filename = "#{path_relevant_enrollment.enumber}_#{series_description}_#{study_id}_#{series_number}.nii"
		    fixed_filename = clean_series_description(unfixed_filename)

			if File.exists?(preprocessed_path) and File.directory?(preprocessed_path)
				result[:preprocessed_path_exists] = true
				result[:longest_existing_preprocessed_path] = preprocessed_path

			    matching = Dir.entries(preprocessed_path).select{|item| !(item =~ /^[.]/) and (item =~ Regexp.new(fixed_filename))}

			    if matching.count == 1

			    	result[:best_matching_candidate] = "#{preprocessed_path}#{matching.first}"
				    result[:matched_with_study_id] = matching.count == 1
				    result[:matched_count_with_study_id] = matching.count
				    result[:matched_count_without_study_id] = 0

			    elsif matching.count == 0
			    	#we should also try without the study id
				    result[:matched_with_study_id] = false

				    result[:matched_count_with_study_id] = 0

				    unfixed_filename = "#{path_relevant_enrollment.enumber}_#{series_description}_#{series_number}.nii"
				    fixed_filename = clean_series_description(unfixed_filename)

				    matching = Dir.entries(preprocessed_path).select{|item| !(item =~ /^[.]/) and (item =~ Regexp.new(fixed_filename))}
				    result[:matched_count_without_study_id] = matching.count
			    	result[:best_matching_candidate] = "#{preprocessed_path}#{matching.first}"
				else

			    	result[:best_matching_candidate] = ""
				    result[:matched_with_study_id] = matching.count == 1
				    result[:matched_count_with_study_id] = matching.count
				    result[:matched_count_without_study_id] = 0
				end

			else

				result[:preprocessed_path_exists] = false

				path_parts = preprocessed_path.split("/")[1..-1]
				stub_path = path_prefix
				last_part = path_parts.shift

				while path_parts.count > 0 and Dir.exists? stub_path + "/" + last_part
					stub_path += "/" + last_part
					last_part = path_parts.shift
				end

				result[:longest_existing_preprocessed_path] = stub_path
				result[:matched_with_study_id] = false
				result[:matched_count_with_study_id] = 0

				result[:best_matching_candidate] = ""
				result[:matched_count_without_study_id] = 0

			end
		end

	    if echo_the_candidate
	    	puts "#{preprocessed_path}#{fixed_filename}"
	    end

	    return result
	end

	def scan_procedures_have_path_relevancy?(image)

	    scan_procedures = image.visit.appointment.vgroup.scan_procedures
	    path_relevant_sp = scan_procedures.select{|item| image.path =~ Regexp.new(item.codename)}.first

	    if path_relevant_sp.nil?
	    	return false
	    end

	    return true

	end
		
end