
	class Jobs::Atrophy::Visit < Visit

		def preprocessed_dir_exists?(dir_name='unknown',base_path='/mounts/data')

			if preprocessed_dir.nil?
				false
			end
		    File.directory?(preprocessed_dir)

		end

		def preprocessed_dir(dir_name='unknown',base_path='/mounts/data')

			if !related_scan_procedure.nil? and !related_enrollment.nil?
			    base_path+"/preprocessed/visits/#{related_scan_procedure.codename}/#{related_enrollment.enumber}/#{dir_name}"
			else
				nil
			end

		end

		def secondary_dir_exists?(base_path='/mounts/data')
			if related_scan_procedure.nil? or related_enrollment.nil?
				return false
			end

			entries = Dir.glob(base_path+"/preprocessed/visits/#{related_scan_procedure.codename}/#{related_enrollment.enumber}*")
			if entries.count > 1
				return true
			end
			false

		end

		def secondary_dirs(dir_name='unknown', base_path='/mounts/data')
			
			pre = []
			if preprocessed_dir_exists?
				pre << preprocessed_dir
			end
			entries = Dir.glob(base_path+"/preprocessed/visits/#{related_scan_procedure.codename}/#{related_enrollment.enumber}*")
			((entries.map{|entry| base_path+"/preprocessed/visits/#{related_scan_procedure.codename}/#{entry}/#{dir_name}"}) - pre).select{|path| File.exists? path}
			

		end


		def related_enrollment
		    if path.nil?
		      return nil
		    end

			enrollments = appointment.vgroup.enrollments
		    path_relevant_enrollment = enrollments.select{|item| path =~ Regexp.new(item.enumber)}.first
		    return path_relevant_enrollment

		end

		def related_scan_procedure
		    if path.nil?
		      return nil
		    end

		    scan_procedures = appointment.vgroup.scan_procedures
		    path_relevant_sp = scan_procedures.select{|item| path =~ Regexp.new(item.codename)}.first
		    return path_relevant_sp

		end

		def o_acpc_file_exists?

		    if related_enrollment.nil? or related_scan_procedure.nil? or !preprocessed_dir_exists?
		      false
		    end

		    acpc_candidates = Dir.entries(preprocessed_dir).select { |f| f.start_with?("o") and f.end_with?(".nii") }
		    if acpc_candidates.length == 0
		        #not enough o_acpc.nii files
		        false
		    elsif acpc_candidates.length >0
		        # we can drill down in the get method in case there's a default scan
		        true
		    end
		    false
		end

		def get_o_acpc_file
			if o_acpc_file_exists?

			    acpc_candidates = Dir.entries(preprocessed_dir).select { |f| f.start_with?("o") and f.end_with?(".nii") }

			    if acpc_candidates.count == 1
				    "#{preprocessed_dir}/#{acpc_candidates.first}"
				else
					#does this file have a default? 
				end
			else
				nil
			end
		end

	end