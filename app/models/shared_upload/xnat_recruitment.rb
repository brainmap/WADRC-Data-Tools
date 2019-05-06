class SharedUpload::XnatRecruitment < SharedUpload::SharedUploadBase

  def self.default_params
	  params = { schedule_name: 'xnat_recruitment',
				base_path: Shared.get_base_path(), 
    			computer: "merida",
    			comment: [],
    			comment_warning: "",
    			log_base: "/mounts/data/preprocessed/logs/",
    			process_name: "xnat_file",
    			stop_file_name: "xnat_file_stop",
      			stop_file_path: "/mounts/data/preprocessed/logs/xnat_file_stop",

      			scan_procedure_array: [26,41,77,91], #pdt's and mk
      			series_description_category_array: ['T1_Volumetric','T2'], # mpnrage?
	      		series_description_category_id_array: [19, 20, 5], #,1 ]
      			project: "wbbsp",  #"wadrc_sp" #"up-test"

            temporary_xnat_ids_tn: "t_xnat_curated_image_datasets",
            xnat_driver_tn: "xnat_curated_driver",
            default_xnat_run_upload_flag: 'R',
            days_back: '15'}

      params
    end

    def run(p=@params)

      #we've got a combination of scan procedures, series descriptions, and a project name. We want to use a few 
      # working tables to determine if there are any eligble scans out there matching our project's parameters, but that
      # haven't been collected yet. If there are, collect them, and insert them into the xnat driver table, which will
      # allow another process ("xnat_curated_upload") to do the uploading. 

      #first, let's make sure our workspace is clear

      sql = "truncate #{ p[:temporary_xnat_ids_tn] }"
      results = @connection.execute(sql)

      #then we'll find the new scans we're looking for.

      sql = "insert into #{ p[:temporary_xnat_ids_tn] } (visit_id,image_dataset_id,xnat_exists_flag,file_path)
        select image_datasets.visit_id, image_datasets.id, 'N',image_datasets.path
        from image_datasets join visits on image_datasets.visit_id = visits.id
          join appointments on appointments.id = visits.appointment_id
          join series_description_maps on image_datasets.series_description = series_description_maps.series_description
          join scan_procedures_vgroups on appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
        where (image_datasets.do_not_share_scans_flag is null or image_datasets.do_not_share_scans_flag != 'Y')
          and series_description_maps.series_description_type_id in (#{ p[:series_description_category_id_array].join(',') }) 
          and scan_procedures_vgroups.scan_procedure_id in (#{ p[:scan_procedure_array].join(',') }) 
          and (image_datasets.visit_id, image_datasets.id ) NOT IN
                          (select visit_id, image_dataset_id from #{ p[:xnat_ids_tn] } where project = '#{ p[:project] }' )"

      if p[:days_back]
          sql += " and appointments.appointment_date < ( NOW() - INTERVAL #{ p[:days_back] } DAY)"
      end

      sql += " group by image_datasets.id"

      results = @connection.execute(sql)

      # set the xnat_do_not_share based on pilot and enumber/study consent forms
      sql ="update #{ p[:temporary_xnat_ids_tn] } xid set  xnat_do_not_share_flag = 'Y'
        where xid.visit_id in (select v.id from visits v, enrollments e, enrollment_visit_memberships evm
        where xid.visit_id = v.id   and v.id = evm.visit_id and evm.enrollment_id = e.id  and e.do_not_share_scans_flag = 'Y')"
      results = @connection.execute(sql)
      sql ="update  #{ p[:temporary_xnat_ids_tn] } set xnat_do_not_share_flag = 'Y' where visit_id in 
        (select v.id from visits v, appointments a, vgroups vg where v.appointment_id = a.id and a.vgroup_id = vg.id  and vg.pilot_flag = 'Y')"
      results = @connection.execute(sql)
      
      #then we're ready to insert these ids into our driver table
      sql = "insert into #{ p[:xnat_driver_tn] } (image_dataset_id, project) 
          select image_dataset_id, '#{ p[:project] }'
          from #{ p[:temporary_xnat_ids_tn] } where xnat_do_not_share_flag = 'N'"

      results = @connection.execute(sql)

    #clean up and tell the SecheduledJob that we're done
    close
end
end