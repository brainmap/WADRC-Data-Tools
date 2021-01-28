class Jobs::T2Metadata::T2SidetableHarvest < Jobs::BaseJob

	require 'open3'
	
	attr_accessor :header
	attr_accessor :error_rows
	attr_accessor :connection
	attr_accessor :total_scans_considered
	attr_accessor :selected
	attr_accessor :driver

	def self.default_params
	  	params = { :schedule_name => 'T2 Metadata Harvest, side-table', 
	  				:base_path => "/mounts/data/raw",
	  				:run_by_user => 'panda_user',
	  				:target_table => 'image_dataset_metadata',
	  				:write_sql_to_file => true,
	  				:sql_outfile => "/mounts/data/analyses/wbbevis/t2_metadata/sql_outfile_sidetable.sql",
	  				:auto_insert => false
	  			}
        params.default = ''
        params
    end

	def run(params)

		begin
			setup(params)


			selection(params)

			filter(params)

			harvest(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)
		@error_rows = []
		@connection = ActiveRecord::Base.connection
		@driver = []

	end

	def selection(params)
		#@selected = ImageDataset.where("(series_description not like 'ORIG%') and ((series_description like 'SAG Cube T2 FLAIR%') or (series_description like 'Sag T2 FLAIR Cube%')  or (series_description like 'Sag CUBE T2FLAIR%') or (series_description like 'Sag CUBE flair%'))")
		@selected = ImageDataset.where("(series_description like '%T2%') or (series_description like '%T1%') or (series_description like '%Pseudo%')").where("id not in (select image_dataset_id from #{params[:target_table]})").where("dicom_taghash is not NULL and dicom_taghash != ''")
	end

	def filter(params)
		# here we're going to populate @driver with images, and we want to be sure that all of the paths exist,
		# that there are dicoms somewhere below the directory in path, etc. 

		@selected.each do |image|

			# Since we're pulling already-harvested values from the image dataset table, we don't really need to filter anyone out here.

			@driver << image
		end
	end

	def tag_value(img, address)
		if !img.dicom_taghash[address].nil?
			return img.dicom_taghash[address][:value]
		else
			return nil
		end
	end

	def harvest(params)

		sql_outfile = nil
		if params[:write_sql_to_file]
			sql_outfile	= File.open(params[:sql_outfile], 'wb')
		end

		@driver.each do |image|
			# We've got an image object, and we need a short list of tag values from it. 

			scan_procedure = image.visit.appointment.vgroup.scan_procedures.map{|item| item.codename}.join(",")
			enumber = image.visit.appointment.vgroup.enrollments.map{|item| item.enumber}.join(",")
			visit_date = image.visit.appointment.appointment_date.strftime("%Y-%m-%d")
			scan_number = image.path.split("/").last
			mri_station_name = tag_value(image,"0008,1010")
			study_description = tag_value(image,"0008,1030")
			series_description = tag_value(image,"0008,103E")
			body_part = tag_value(image,"0018,0015")
			scanning_sequence = tag_value(image,"0018,0020")
			sequence_variant = tag_value(image,"0018,0021")
			scan_options = tag_value(image,"0018,0022")
			mr_acquisition_type = tag_value(image,"0018,0023")
			protocol_name = tag_value(image,"0018,1030")
			receive_coil_name = tag_value(image,"0018,1250")
			filter_mode = tag_value(image,"0043,102D")


			sql = "INSERT INTO #{params[:target_table]} (image_dataset_id, scan_procedure, enumber, visit_date, scan_number, mri_station_name, study_description, series_description, body_part, scanning_sequence, sequence_variant, scan_options, mr_acquisition_type, protocol_name, receive_coil_name, filter_mode) values (#{image.id}, \"#{scan_procedure}\", \"#{enumber}\", \"#{visit_date}\", \"#{scan_number}\", \"#{mri_station_name}\", \"#{study_description}\", \"#{series_description}\", \"#{body_part}\", \"#{scanning_sequence}\", \"#{sequence_variant}\", \"#{scan_options}\", \"#{mr_acquisition_type}\", \"#{protocol_name}\", \"#{receive_coil_name}\", \"#{filter_mode}\");"

			if params[:write_sql_to_file]
				sql_outfile.write("#{sql}\n")
			end

			if params[:auto_insert]
				@connection.execute(sql)
			end

		end

		if params[:write_sql_to_file]
			sql_outfile.close
		end

	end

	def report_errors(params)

	end
end

# CREATE TABLE `image_dataset_metadata` (
# `id` int NOT NULL AUTO_INCREMENT,
# `image_dataset_id` int(11) DEFAULT NULL,
# `scan_procedure` varchar(255) DEFAULT NULL,
# `enumber` varchar(100) DEFAULT NULL,
# `visit_date` date DEFAULT NULL,
# `scan_number` varchar(50) DEFAULT NULL,
# `mri_station_name` varchar(50) DEFAULT NULL,
# `study_description` varchar(50) DEFAULT NULL,
# `series_description` varchar(50) DEFAULT NULL,
# `body_part` varchar(50) DEFAULT NULL,
# `scanning_sequence` varchar(50) DEFAULT NULL,
# `sequence_variant` varchar(50) DEFAULT NULL,
# `scan_options` varchar(255) DEFAULT NULL,
# `mr_acquisition_type` varchar(50) DEFAULT NULL,
# `protocol_name` varchar(50) DEFAULT NULL,
# `receive_coil_name` varchar(50) DEFAULT NULL,
# `filter_mode` varchar(50) DEFAULT NULL,
#  PRIMARY KEY (`id`)
#  )