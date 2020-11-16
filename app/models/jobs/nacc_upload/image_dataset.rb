
	class Jobs::NaccUpload::ImageDataset < ImageDataset
		FAILING_STATUSES = Set.new( ["Incomplete","Severe"] )

		def passed_iqc?
			#look up any iqc for this image. If anything is severe, or 
			iqc_check = ImageDatasetQualityCheck.where(:image_dataset_id => id).first
			if iqc_check.nil?
				return false
			end

			failing_checks = Set.new
		    iqc_check.attribute_names.each do |name|
		      unless name.blank?
		        if FAILING_STATUSES.include?(iqc_check[name])
		          failing_checks << name.capitalize.gsub("_", " ")
		        end
		      end
		    end

		    if failing_checks.count == 0
		    	return true
		    end
		    return false
		end
	end