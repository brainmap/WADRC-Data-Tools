class Jobs::ImageReconciliation::ImageReconciliationAdcp < Jobs::ImageReconciliation::ImageReconciliationJob

	# This job implements the reconciliation of all of our RAW images after the drive failure
	# of 2021-02. We're rebuilding a drive and recovering many files from backups, and we 
	# need an automated job that will check all of the files being repopulated into raw for
	# consistency with the Panda records. 

	attr_accessor :selected
	attr_accessor :driver
	attr_accessor :output_tmp
	attr_accessor :result
	attr_accessor :errors

	def self.default_params
	  	params = { :schedule_name => 'Image Reconciliation', 
	  				:run_by_user => 'panda_user',
	  				:base_path => "/mounts/data",
	  				:scan_procedure_white_list => [80, 115],
	  				:insert_now => true,
	  				:save_to_sql => true,
	  				:sql_path => '/mounts/data/analyses/wbbevis/reconciliation/insert.sql'
	  			}
        params.default = ''
        params
    end

	# selection
	# Based on the white list filter, get all of the Image Datasets we can find.
		
	def selection(params)

		@driver = Jobs::ImageReconciliation::ImageDatasetAdcp.joins(:visit)
						.joins("LEFT JOIN appointments ON appointments.id = visits.appointment_id")
						.joins("LEFT JOIN vgroups ON vgroups.id = appointments.vgroup_id")
						.joins("LEFT JOIN scan_procedures_vgroups ON vgroups.id = scan_procedures_vgroups.vgroup_id")
						.where("scan_procedures_vgroups.scan_procedure_id in (#{params[:scan_procedure_white_list].join(",")})")

	end

end