class Processedimage <  ActiveRecord::Base
	has_many :processedimagessources,:class_name =>"Processedimagessource", :dependent => :destroy 


	def related_vgroup

		vgroup = nil

		case file_type
		when 'o_acpc T1'
			path_parts = file_path.split("/")
			raw_path = Shared.get_base_path() + "/raw/#{path_parts[5]}/mri/#{path_parts[6]}"
			visit = Visit.where("path like '#{raw_path}%'").first

			if !visit.nil?
				vgroup = visit.appointment.vgroup
			end
		when 'm_acpc T1'
			path_parts = file_path.split("/")
			raw_path = Shared.get_base_path() + "/raw/#{path_parts[5]}/mri/#{path_parts[6]}"
			visit = Visit.where("path like '#{raw_path}%'").first

			if !visit.nil?
				vgroup = visit.appointment.vgroup
			end
		when 'bias corrected mri'
			path_parts = file_path.split("/")
			raw_path = Shared.get_base_path() + "/raw/#{path_parts[5]}/mri/#{path_parts[6]}"
			visit = Visit.where("path like '#{raw_path}%'").first

			if !visit.nil?
				vgroup = visit.appointment.vgroup
			end
		when 'multispectral mri'
			path_parts = file_path.split("/")
			raw_path = Shared.get_base_path() + "/raw/#{path_parts[5]}/mri/#{path_parts[6]}"
			visit = Visit.where("path like '#{raw_path}%'").first

			if !visit.nil?
				vgroup = visit.appointment.vgroup
			end
		when 'y_acpc T1'
			path_parts = file_path.split("/")
			raw_path = Shared.get_base_path() + "/raw/#{path_parts[5]}/mri/#{path_parts[6]}"
			visit = Visit.where("path like '#{raw_path}%'").first

			if !visit.nil?
				vgroup = visit.appointment.vgroup
			end
		end

		vgroup
	end


	def related_vgroup?
		return !!(related_vgroup)
	end

end