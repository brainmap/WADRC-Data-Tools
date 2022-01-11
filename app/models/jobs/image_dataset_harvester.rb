class Jobs::ImageDatasetHarvester < Jobs::BaseJob

	# Like the driver class for this pipeline, the harvester is set up as a service class
	# that we can call like `job.run(params)`. Driver jobs and harvest jobs are broken up
	# by convention, as it allows more flexibility for how we run our processing, but 
	# the two could just as easily be a single sequence.
	attr_accessor :success
	attr_accessor :failed
	attr_accessor :total_cases
	attr_accessor :success_log

  	def self.default_params
		params = { schedule_name: 'ImageDataset Metadata Harvester',
				base_path: '/mounts/data', 
                run_by_user: 'panda_user',
                weeks_in_the_past: 2
    		}
        params.default = ''
        params
    end

  	def self.production_params
		params = { schedule_name: 'ImageDataset Metadata Harvester',
				base_path: '/mounts/data', 
                run_by_user: 'panda_user',
                weeks_in_the_past: 2
    		}
        params.default = ''
        params
    end


	def run(params)

		begin
			setup(params)

			selection(params)

			harvest(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)
		self.selected = []
	end

	def selection(params)

		@selected = ImageDataset.where("created_at > '(?)'",(Date.today - params[:weeks_in_the_past].weeks).strftime("%Y-%m-%d"))
                              .where("appointments.appointment_date > ?",params[:date_cutoff])

	end
	
	def harvest(params)
		
		# check to see if this image has metadata now, and if not, try to harvest some.

		@selected.each do |img|
			if img.metadata001.nil?

				new_img_form = ImageDatasetMetadataForm.from_image_dataset_taghash(img)

				if new_img_form.valid?
					@connection.execute(new_img_form.to_sql_insert())
				end

			end
		end

	end
	

end


# CREATE TABLE `cg_lst_lpa` (
#   `id` int NOT NULL AUTO_INCREMENT,
# `subject_id` varchar(255) DEFAULT NULL,
# `scan_procedure` varchar(255) DEFAULT NULL,
# `os_version` varchar(255) DEFAULT NULL,
# `matlab_version` varchar(255) DEFAULT NULL,
# `spm_version` varchar(255) DEFAULT NULL,
# `spm_revision` varchar(255) DEFAULT NULL,
# `lst_version` varchar(255) DEFAULT NULL,
# `lstlpa_local_code_version` varchar(255) DEFAULT NULL,
# `original_image_path_flair` varchar(255) DEFAULT NULL,
# `original_image_path_T1` varchar(255) DEFAULT NULL,
# `lesion_volume_ml` float DEFAULT NULL,
# `number_of_lesions` int(11) DEFAULT NULL,
# `created_at` datetime DEFAULT NULL,
# `processed_at` datetime DEFAULT NULL,
# `participant_id` int(11) DEFAULT NULL,

#   PRIMARY KEY (`id`)
#   );

# alter table  cg_lst_lpa add column t2_prep varchar(5) default NULL;
# alter table  cg_lst_lpa add column receive_coil_name varchar(20) default NULL;
# alter table  cg_lst_lpa add column pure_corrected varchar(5) default NULL;
# alter table  cg_lst_lpa add column mri_station_name varchar(20) default NULL;
