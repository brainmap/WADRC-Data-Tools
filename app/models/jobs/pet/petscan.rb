
	class Jobs::Pet::Petscan < Petscan

		def paths_ok?
			#paths_ok implies that:
		    # => if there's only one, it's a file or a directory
		    # => if there are multiple petfiles, they're all directories
		    #scan_files = Petfile.where("petscan_id = ?", self.id)

			v_petfiles_pass = true

		    case petfiles.count
		      when 0 then return false
		      when 1 then v_petfiles_pass = petfiles.first.path_ok?
		      else v_petfiles_pass = petfiles.all? { |f| f.path_ok? && f.path_dir? }
		    end

		    v_path_array = pet_path.split('/')
		    if v_path_array.count > 10
		      return false
		    end

		    #if we can't find anything else wrong with these paths, then we're probably ok, 
		    # but as soon as we find a new failing case, this is where new tests should go
		    return v_petfiles_pass
		end

		def paths_ok!
		    #like paths_ok?, but raises errors that should be caught by the calling function to diagnose weird/bad petfile records
		    #scan_files = Petfile.where("petscan_id = ?", self.id)

		    v_petfiles_pass = true

		    case petfiles.count
		      when 0 then
		        begin
		          raise Exceptions::PetscanNoEcatsError, "No Petfile records exist."
		        end
		      when 1 then
		        begin
		          if !petfiles.first.path_ok?
		            if petfiles.first.nil?
		              raise Exceptions::PetscanPathError, "The only Petfile has a nil path."
		            elsif petfiles.first.blank?
		              raise Exceptions::PetscanPathError, "The only Petfile has a blank path."
		            elsif !File.directory?(petfiles.first.path) && !File.file?(petfiles.first.path)
		              raise Exceptions::PetscanPathError, "The only Petfile has a path, but it's neither a file nor a directory. '#{petfiles.first.path}'"
		            else
		              raise Exceptions::PetscanError, "Some other error with the Petfile."
		            end
		          end
		        end
		      else
		        if !petfiles.all? { |f| f.path_ok? && f.path_dir? }
		          #multiple ecat files?
		          if petfiles.map { |f| if f.file_name.end_with?(".v"); then true; end }.compact.length > 1
		            raise Exceptions::PetscanTooManyEcatsError, "Multiple Ecat files."
		          end

		          petfiles.each do |f|
		            if !f.path_ok?
		              raise Exceptions::PetscanPathError, "Petfile's path wasn't ok: '#{f.path}'."
		            elsif !f.path_dir?
		              raise Exceptions::PetscanTooManyEcatsError, "Petfile's path wasn't a directory: '#{f.path}'."
		            else
		              raise Exceptions::PetscanError, "Some other error with a Petfile."
		            end
		          end
		        end
			end

		    v_path_array = pet_path.split('/')
		    if v_path_array.count > 10
		      raise Exceptions::PetscanPathError, "Petfile's path was too long: '#{pet_path}'."
		    end

		    return v_petfiles_pass

		end

		def preprocessed_dir_exists?(dir_name='/pet/pib/dvr/code_ver2b',base_path='/mounts/data')

		    # If this directory exists in preprocessed, that means that this isn't the first time 
		    # the files have been processed. If we're doing reprocessing, that's ok, and we should
		    # continue. If we're doing initial processing, skip this one.

		    if pet_path.nil?
		      return false
		    end

		    if pet_path.split("/").length < 9
		      return false
		    end

		    #some pet paths are paths to an ecat file, which should end with ".v". These we've got
		    # get the subject id by cutting it out of the ecat name.
		    v_subjectid = ''
		    v_path_array = pet_path.split('/')

		    if File.exist?(pet_path) and !File.directory?(pet_path) and pet_path.end_with?(".v")
		      v_subjectid_array = v_path_array[-1].split("_")
		      
		      # 2021-06-04 wbbevis - The downcasing I was doing here for consistency ended up missing some 
		      # wrap cases where the subject id is correctly "wrapLXXXX" (where Xs are numbers). They could
		      # have a capital A, L or M, and the filesystem reflects this. So, we should get that right, 
		      # or else we keep reprocessing the same cases over and over.

		      if v_subjectid_array[0] =~ /WRAP/i
		      	v_subjectid = v_subjectid_array[0].gsub(/WRAP/i, 'wrap')
		      else
			    v_subjectid = v_subjectid_array[0].downcase
			  end


		    #others are paths to a directory under raw. these should have a subject id as a directory
		    # in the middle of their path
		    elsif File.directory?(pet_path)
		      v_subjectid = v_path_array[7]
		    else
		      return false
		    end

		    v_preprocessed_path = base_path+"/preprocessed/visits/"

		    v_scan_procedure_codename = v_path_array[4]

		    v_subjectid_pet_pib_processed_path = v_preprocessed_path + v_scan_procedure_codename + "/" + v_subjectid + dir_name

		    #puts "check path: #{v_subjectid_pet_pib_processed_path} (id:#{self.id})"

		    return File.directory?(v_subjectid_pet_pib_processed_path)

		end

		def preprocessed_dir(dir_name='/pet/pib/dvr/code_ver2b',base_path='/mounts/data')

		    if pet_path.nil?
		      return false
		    end

		    if pet_path.split("/").length < 9
		      return false
		    end

		    #some pet paths are paths to an ecat file, which should end with ".v". These we've got
		    # get the subject id by cutting it out of the ecat name.
		    v_subjectid = ''
		    v_path_array = pet_path.split('/')

		    if File.exist?(pet_path) and !File.directory?(pet_path) and pet_path.end_with?(".v")
		      v_subjectid_array = v_path_array[-1].split("_")
		      v_subjectid = v_subjectid_array[0].downcase

		    #others are paths to a directory under raw. these should have a subject id as a directory
		    # in the middle of their path
		    elsif File.directory?(pet_path)
		      v_subjectid = v_path_array[7]
		    else
		      return false
		    end

		    v_preprocessed_path = base_path+"/preprocessed/visits/"

		    v_scan_procedure_codename = v_path_array[4]

		    v_subjectid_pet_pib_processed_path = v_preprocessed_path + v_scan_procedure_codename + "/" + v_subjectid + dir_name

		    #puts "check path: #{v_subjectid_pet_pib_processed_path} (id:#{self.id})"

		    return v_subjectid_pet_pib_processed_path

		end

		def related_enumber
		    if pet_path.nil?
		      return nil
		    end

			enrollments = appointment.vgroup.enrollments
		    path_relevant_enrollment = enrollments.select{|item| pet_path =~ Regexp.new(item.enumber)}.first
		    return path_relevant_enrollment

		end

		def related_scan_procedure
		    if pet_path.nil?
		      return nil
		    end

		    scan_procedures = appointment.vgroup.scan_procedures
		    path_relevant_sp = scan_procedures.select{|item| pet_path =~ Regexp.new(item.codename)}.first
		    return path_relevant_sp

		end

		def related_appointment
		    if pet_path.nil?
		      return nil
		    end
		    if @v_appointment.nil?
		      v_appointment = Appointment.where("id in (?)",appointment_id)
		      if v_appointment.count <= 0
		        return nil
		      else
		        @v_appointment = v_appointment.first
		      end
		    end
		    return @v_appointment
		end

		def related_participant
		    if pet_path.nil?
		      return nil
		    end
		    if @v_participant.nil?
		      @v_participant = Participant.find(Vgroup.find(related_appointment.vgroup_id).participant_id)
		      # if v_scan_procedures.count <= 0
		      #   return nil
		      # else
		      #   @v_scan_procedure = v_scan_procedures.first
		      # end
		    end
		    return @v_participant
		end

		def o_acpc_file_exists?
		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    if related_enumber.nil? or related_scan_procedure.nil?
		      return false
		    end

		    v_subjectid_tissue_seg = v_preprocessed_path+related_scan_procedure.codename+"/"+related_enumber.enumber+"/unknown"
		    # puts "checking "+v_subjectid_tissue_seg
		    if File.directory?(v_subjectid_tissue_seg)
		      v_matching_files = Dir.entries(v_subjectid_tissue_seg).select { |f| f.start_with?("o") and f.end_with?(".nii") }
		      if v_matching_files.length == 0
		        #not enough o_acpc.nii files
		        return false
		      elsif v_matching_files.length == 1
		        #just right
		        return true
		      else
		        #too many o_acpc.nii files
		        return false
		      end
		    end

		    #we didn't find a file, so
		    return false
		end

		def path_sort(a,b)
		    if !a.scan(/PU/).blank? and !b.scan(/PU/).blank?
		      return 0
		    elsif !a.scan(/ORIG/).blank? and !b.scan(/ORIG/).blank?
		      return 0
		    elsif !a.scan(/PU/).blank?
		      return -1
		    elsif !a.scan(/ORIG/).blank?
		      return 1
		    elsif !b.scan(/PU/).blank?
		      return 1
		    elsif !b.scan(/ORIG/).blank?
		      return -1
		    else
		      return 0
		    end
		end

		def get_o_acpc_file
		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    v_subjectid_tissue_seg = v_preprocessed_path+related_scan_procedure.codename+"/"+related_enumber.enumber+"/unknown"
		    if File.directory?(v_subjectid_tissue_seg)
		      Dir.entries(v_subjectid_tissue_seg).each do |f|
		        if f.start_with?("o") and f.end_with?(".nii")
		          return "#{v_subjectid_tissue_seg}/#{f}"
		        end
		      end
		    end

		    #we didn't find a file, so
		    return false
		end

		def appropriate_T2?(filename)
		    if filename.include?('T2') and filename.end_with?(".nii")
		      if filename.include?('ORIG')
		        return true
		      elsif filename.include?('PU')
		        return true
		      elsif filename.include?('CUBE-T2')
		        return true
		      elsif filename.include?('CUBE-Flair') or filename.include?('CUBE-FLAIR')
		        return true
		      elsif filename =~ /FLAIR_CUBE/i
		        return true
		      end
		    end
		    return false
		end

		def multispectral_file_exists?
		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    if related_enumber.nil? or related_scan_procedure.nil?
		      return false
		    end

		    v_subjectid_tissue_seg = v_preprocessed_path+related_scan_procedure.codename+"/"+related_enumber.enumber+"/unknown"
		    
		    if File.directory?(v_subjectid_tissue_seg)

		      v_matching_files = Dir.entries(v_subjectid_tissue_seg).select { |f| appropriate_T2?(f) }

		      if v_matching_files.length > 0
		        return true
		      end
		    end

		    #we didn't find a file, so
		    return false
		end

		def get_multispectral_file
		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    v_subjectid_tissue_seg = v_preprocessed_path+related_scan_procedure.codename+"/"+related_enumber.enumber+"/unknown"
		    if File.directory?(v_subjectid_tissue_seg)
		      Dir.entries(v_subjectid_tissue_seg).each do |f|
		        if appropriate_T2?(f)
		          return "#{v_subjectid_tissue_seg}/#{f}"
		        end
		      end
		    end

		    #we didn't find a file, so
		    return false
		end

		def recent_o_acpc_file_exists?(v_mri_visits)

		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    v_mri_visits.each do |mri_visit|
		      if mri_visit.path.include?("adcp")
		        next
		      end

		      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
		      if v_raw_path_array.include?("/mri/")
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
		      else
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
		      end

		      if File.directory?(v_other_mri_unknown)
		        v_matching_files = Dir.entries(v_other_mri_unknown).select { |f| f.start_with?("o") and f.end_with?(".nii") }
		        if v_matching_files.length == 1
		          return true
		        end
		      end

		    end

		    #we didn't find a file, so
		    return false
		end

		def get_recent_o_acpc_file(v_mri_visits)
		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    v_mri_visits.each do |mri_visit|
		      if mri_visit.path.include?("adcp")
		        next
		      end

		      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
		      if v_raw_path_array.include?("/mri/")
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
		      else
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
		      end

		      if File.directory?(v_other_mri_unknown)
		        Dir.entries(v_other_mri_unknown).each do |f|
		          if f.start_with?("o") and f.end_with?(".nii")
		            return "#{v_other_mri_unknown}/#{f}"
		          end
		        end
		      end

		    end

		    #we didn't find a file, so
		    return false
		end

		def get_recent_o_acpc_visit(v_mri_visits)
		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    v_mri_visits.each do |mri_visit|
		      if mri_visit.path.include?("adcp")
		        next
		      end

		      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
		      if v_raw_path_array.include?("mri")
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
		      else
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
		      end

		      if File.directory?(v_other_mri_unknown)
		        Dir.entries(v_other_mri_unknown).each do |f|
		          if f.start_with?("o") and f.end_with?(".nii")
		            return mri_visit
		          end
		        end
		      end

		    end

		    #we didn't find a file, so
		    return false
		end


		def recent_multispectral_file_exists?(v_mri_visits)
		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    if related_enumber.nil? or related_scan_procedure.nil?
		      return false
		    end

		    v_mri_visits.each do |mri_visit|
		      if mri_visit.path.include?("adcp")
		        next
		      end

		      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
		      if v_raw_path_array.include?("/mri/")
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
		      else
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
		      end

		      if File.directory?(v_other_mri_unknown)

		        v_matching_files = Dir.entries(v_other_mri_unknown).select { |f| appropriate_T2?(f) }

		        if v_matching_files.length > 0
		          return true
		        end
		      end
		    end

		    #we didn't find a file, so
		    return false
		end

		def get_recent_multispectral_file(v_mri_visits)
		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    v_mri_visits.each do |mri_visit|
		      if mri_visit.path.include?("adcp")
		        next
		      end

		      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
		      if v_raw_path_array.include?("/mri/")
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
		      else
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
		      end

		      if File.directory?(v_other_mri_unknown)
		        Dir.entries(v_other_mri_unknown).each do |f|
		          if appropriate_T2?(f)
		            return "#{v_other_mri_unknown}/#{f}"
		          end
		        end
		      end
		    end

		    #we didn't find a file, so
		    return false
		end

		def get_recent_multispectral_visit(v_mri_visits)
		    v_base_path = Shared.get_base_path()
		    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

		    v_mri_visits.each do |mri_visit|
		      if mri_visit.path.include?("adcp")
		        next
		      end

		      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
		      if v_raw_path_array.include?("mri")
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
		      else
		        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
		      end

		      if File.directory?(v_other_mri_unknown)
		        Dir.entries(v_other_mri_unknown).each do |f|
		          if appropriate_T2?(f)
		            return mri_visit
		          end
		        end
		      end
		    end

		    #we didn't find a file, so
		    return false
		end
	end