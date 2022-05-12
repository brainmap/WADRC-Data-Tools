
	class Jobs::FslFirst::Vgroup < Vgroup

		# 2022-05-05 wbbevis -- The "related_enrollment" and "related_scan_procedure" methods in this file aren't
		# really relevant to this class anymore. On Petscans and MRI Visits, we have files associated in the filesystem
		# and we can look to the paths their saved on for guidnace about which enrollment number to use as their 
		# primary. Here not so much -- the vgroup is just an umbrella over those things and there isn't one visit type
		# or the other that takes prescidence for deciding the overall "primary" scan procedure. (Not that this
		# wouldn't be a worthwhile feature for the future...) 

		# So, this should probably take a slightly different tack for finding existing FSL first volumes, but let's 
		# keep doing the wrapper functions to make the main driver a little more readable. 

		# There are tricks we can take from pathname here that might give us good methods. We could also do some kind
		# of fingerprint based on the first directories we know about.

		def preprocessed_paths
			scan_procedures.map{|sp| enrollments.map{|enr| "/mounts/data/preprocessed/visits/#{sp.codename}/#{enr.enumber}/"}}.flatten.select{|path| Dir.exists? path}
		end

		def pipeline_output_paths(pipeline_name)
			scan_procedures.map{|sp| enrollments.map{|enr| "/mounts/data/pipelines/#{pipeline_name}/#{sp.codename}/#{enr.enumber}/"}}.flatten.select{|path| Dir.exists? path}
		end

		def first_dir?(path)
			extensions = ["nii", "vtk", "log", "bvars", "com", "com2", "mat", "html", "csv"]
			# does this directory have the things in it we expect with a first output dir?
			if File.exists?(path) and File.directory?(path)
				pn = Pathname.new(path)

				# not great on the readability here, but what this is doing finding the difference between the "extentions"
				# list above and the extentions found on files in the directory.
				[] == (extensions - pn.children.select{|child| !(File.directory?(child.to_s))}.map{|child| child.to_s[(child.to_s =~ /[^.]+(?=.$|$)/)..-1]}.uniq)
			else
				false
			end
		end

		def old_first_directories
			preprocessed_paths.map{|item| item + "first/"}.select{|item| Dir.exists? item and first_dir?(item)}
		end
		def new_first_directories
			pipeline_output_paths("fsl_first").select{|item| Dir.exists?(item) and first_dir?(item)}
		end


	end