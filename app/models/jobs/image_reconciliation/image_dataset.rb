class Jobs::ImageReconciliation::ImageDataset < ImageDataset

	def check_raw(path_prefix)
		# does the image's path exist in the containing raw dir?
		result = {:image => self}
		raw_path = path.gsub(/^\/mounts\/data/,path_prefix)

		if File.exists?(raw_path) and File.directory?(raw_path)
			result[:raw_path_exists] = true
			result[:longest_existing_raw_path] = raw_path

			# do bz2s exist here?
			bz2_entries = Dir.entries(raw_path).select{|item| item =~ /.bz2$/}

			result[:bz2s_exist_in_raw] = bz2_entries.count > 0
			result[:bz2_count] = bz2_entries.count
			result[:bz2_count_matches_image] = (bz2_entries.count == dcm_file_count)

		else
			result[:raw_path_exists] = false

			path_parts = raw_path.split("/")[1..-1]
			stub_path = path_prefix
			last_part = path_parts.shift

			while path_parts.count > 0 and Dir.exists? stub_path + "/" + last_part
				stub_path += "/" + last_part
				last_part = path_parts.shift
			end
			# now, path should exist, and be the deepest existing path we can find.
			result[:longest_existing_raw_path] = stub_path
			result[:bz2s_exist_in_raw] = false
			result[:bz2_count] = 0
			result[:bz2_count_matches_image] = (0 == dcm_file_count)
		end

		return result
	end

	def clean_series_description(input_string)
	    #Replace special characters with logical non-special characters
	    #tmp = re.sub('[\(\)+:^/ ]','_',input_string) #paren, plus, caret, slash, space -> _    
	    tmp = input_string.gsub(/[\]\\\[ \/\(\)\{\}\'\`\|\+\=\~\:\;\,\^\?\#\!\$\%]/, "[_-]")
	    tmp = tmp.gsub(/[<]/,'lt')
	    tmp = tmp.gsub(/[>]/,'gt')
	    tmp = tmp.gsub(/[&]/,'_and_')
	    tmp = tmp.gsub(/[@]/,'at')
	    tmp = tmp.gsub(/__/,'_') #consilidate underscores...end up with at most two in a row
	    tmp = tmp.gsub(/_\./,'.') #remove trailing underscores
	    tmp = tmp.gsub(/\*/,'star') #* -> star
	    tmp = tmp.gsub(/\xb2/n,'2') #superscript -> numeral
	    tmp = tmp.gsub(/\xb3/n,'3') #superscript -> numeral
	    return tmp
	end

	def check_preprocessed(path_prefix, echo_the_candidate=false)

		result = {:image => self}

		enrollments = visit.appointment.vgroup.enrollments
	    scan_procedures = visit.appointment.vgroup.scan_procedures
	    path_relevant_sp = scan_procedures.select{|item| path =~ Regexp.new(item.codename)}.first
	    path_relevant_enrollment = enrollments.select{|item| path =~ Regexp.new(item.enumber)}.first
	    preprocessed_path = "#{path_prefix}/preprocessed/visits/#{path_relevant_sp.codename}/#{path_relevant_enrollment.enumber}/unknown/"

	    study_id = dicom_taghash.nil? ? '\d*' : (dicom_taghash["0020,0010"].nil? ? '\d*' : dicom_taghash["0020,0010"][:value])
	    series_number = dicom_taghash.nil? ? '\d*' : (dicom_taghash["0020,0011"].nil? ? '\d*' : dicom_taghash["0020,0011"][:value].rjust(3,'0'))

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