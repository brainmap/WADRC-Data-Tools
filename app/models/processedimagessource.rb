class Processedimagessource <  ActiveRecord::Base
	  belongs_to :processedimage

	def related_vgroup

		vgroup = nil

		case source_image_type
		when 'petfile'
			working_path = file_path
			if working_path.include?('-') #sometimes these are multiple paths joined by '-', but they should all have the same root vgroup
				working_path = file_path.split("-").first
			end
			query_path = working_path.split("/")[0..9].join("/")
			petfile = Petfile.where("path like '#{query_path}%'").first

			if !petfile.nil?
				vgroup = petfile.petscan.appointment.vgroup
			end

		when 'processedimage'
			processed = Processedimage.find(source_image_id)
			vgroup = processed.related_vgroup

		when 'image_dataset'
			img = ImageDataset.find(source_image_id)
			vgroup = img.visit.appointment.vgroup

		end

		vgroup
	end


	def related_vgroup?
		return !!(related_vgroup)
	end
end
