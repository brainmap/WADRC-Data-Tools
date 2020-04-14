class Jobs::Pet::PibSuvrHarvest < Jobs::Pet::PetHarvestBase

  attr_accessor :pettracer
  attr_accessor :tracer_path
  attr_accessor :preprocessed_path
  attr_accessor :secondary_key_array
  attr_accessor :scan_procedures
  attr_accessor :connection
  attr_accessor :roi_column_names
  attr_accessor :roi_file_cn_array
  attr_accessor :aal_mni_v4_pibindex_cn_array
  attr_accessor :log_file_cn_array
  attr_accessor :cg_tn_roi
  attr_accessor :cg_tn_roi_atlas_tjb_mni_v1
  attr_accessor :cg_tn_roi_atlas_homic_mni_v1
  attr_accessor :cg_tn_roi_atlas_morimod_mni_v1
  attr_accessor :cg_tn_roi_atlas_na
  attr_accessor :aal_atlas
  attr_accessor :tjb_mni_v1
  attr_accessor :homic_mni_v1
  attr_accessor :morimod_mni_v1
  attr_accessor :atlas_map

  def self.default_params
    # - set up params
    params = { schedule_name: 'pet_pib_suvr_harvest',
                base_path: '/mounts/data', 
                computer: "kanga",
                comment: [],
                dry_run: false,
                tracer_id: "1",
                run_by_user: 'panda_user',
                method: "suvr",
                code_version: "code_ver2b",
                product_file_type: "suvr pib",
                trtype_id: 16,
                sp_blacklist: [54,56,57,95,55,76,78,72,70,71,99,81,75,83,92,93,88,68,97,61,62,46,60,8,21,28,31,34,82,84,85,86,33,40,42,44,51,96,9,25,23,19,15,24,36,100,35,73,32,6,12,16,13,11,90,59,63,43,4,17,74,98,100,101,102,103,108,110,111,112,113,114]
              }

    params
  end
  def self.av45_params
    # - set up params
    params = { schedule_name: 'pet_av45_harvest',
                base_path: '/mounts/data', 
                computer: "kanga",
                comment: [],
                dry_run: false,
                tracer_id: "6",
                run_by_user: 'panda_user',
                method: "suvr",
                code_version: "code_ver2b",
                product_file_type: "suvr av45",
                trtype_id: 16,
                sp_blacklist: [54,56,57,95,55,76,78,72,70,71,99,81,75,83,92,93,88,68,97,61,62,46,60,8,21,28,31,34,82,84,85,86,33,40,42,44,51,96,9,25,23,19,15,24,36,100,35,73,32,6,12,16,13,11,90,59,63,43,4,17,74,98,100,101,102,103,108,110,111,112,113,114]
                # sp_whitelist: [52]
              }

    params
  end

  def compare_file_header(p_standard_header,p_file_header)
    v_comment =""
    v_flag = "Y"
    if p_standard_header.gsub(/ /,"").gsub(/\n/,"") !=  p_file_header.gsub(/  /,"").gsub(/\n/,"")
      v_comment = "ERROR!!! file header  not match expected header \n"+p_standard_header+"\n"+p_file_header 
      v_flag = "N"              
    else
      #v_comment =" header matches expected."
    end
    return v_flag, v_comment
  end

  def create_processed_image(type:, path:, scan_procedure_id:, enrollment_id:, comment:"")
      v_processedimage = Processedimage.new
      v_processedimage.file_type = type
      v_processedimage.file_name = path.split("/").last
      v_processedimage.file_path = path
      v_processedimage.scan_procedure_id = scan_procedure_id
      v_processedimage.enrollment_id = enrollment_id
      v_processedimage.comment = comment
      v_processedimage.save  
      return v_processedimage
  end

  def create_processed_image_source(path:, processed_image_id:, source_id:, source_type:, comment:"")
      v_processedimagesource = Processedimagessource.new
      v_processedimagesource.file_name = path.split("/").last
      v_processedimagesource.file_path = path
      v_processedimagesource.source_image_id = source_id
      v_processedimagesource.source_image_type = source_type
      v_processedimagesource.processedimage_id = processed_image_id
      v_processedimagesource.comment = comment
      v_processedimagesource.save
      return v_processedimagesource
  end

  def rotate_and_apply_edits(table_prefix, column_list)
      #table prefix should look something like "cg_pet_<tracer_name>_roi" so that we can tack on 
      # suffixes for the particular atlases & _new, _old, _edit, etc.

      #check that we've got the right number of entries in the old and current tables.

      sql = "select count(*) from #{table_prefix}_old"
      results_old = @connection.execute(sql)

      sql = "select count(*) from #{table_prefix}"
      results_current = @connection.execute(sql)

      v_old_cnt = results_old.first.to_s.to_i
      v_present_cnt = results_current.first.to_s.to_i
      v_old_minus_present =v_old_cnt-v_present_cnt
      v_present_minus_old = v_present_cnt-v_old_cnt

      #if the old table has 30% more rows than the present table, don't truncate anything.
      #else, truncate old, insert into old from current
      if ( v_old_minus_present <= 0 or ( v_old_cnt > 0 and  (v_present_minus_old/v_old_cnt)>0.7     ) )
          sql =  "truncate table #{table_prefix}_old"
          results = @connection.execute(sql)
          sql = "insert into #{table_prefix}_old select * from #{table_prefix}"
          results = @connection.execute(sql)
      else
          v_comment = " The #{table_prefix}_old table has 30% more rows than the present #{table_prefix}\n Not truncating #{table_prefix}_old "+v_comment 
      end

      #insert into current from new
      sql =  "truncate table #{table_prefix}"
      results = @connection.execute(sql)

      sql = "insert into #{table_prefix}(#{column_list.join(",")},subjectid,enrollment_id,scan_procedure_id,secondary_key,file_name,pet_processing_date,mri_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name,bias_corrected_t1_mri_file,mni_space_t1_mri,multispectral_file,pet_log_file,coregistration_reference_file,processed_4d_pet_file,processed_sum_pet_file,processed_suvr_pet_file,mni_space_suvr_pet_file,pet_analysis_log_file,atlas,age_at_appointment,general_comment,pet_date_mri_date_diff_days) 
                select distinct #{column_list.join(",")},t.subjectid,t.enrollment_id, scan_procedure_id,secondary_key,file_name,pet_processing_date,mri_processing_date,pet_code_version,ecat_file_name,original_t1_mri_file_name,bias_corrected_t1_mri_file,mni_space_t1_mri,multispectral_file,pet_log_file,coregistration_reference_file,processed_4d_pet_file,processed_sum_pet_file,processed_suvr_pet_file,mni_space_suvr_pet_file,pet_analysis_log_file,atlas,age_at_appointment,general_comment,pet_date_mri_date_diff_days from #{table_prefix}_new t
                                               where t.scan_procedure_id is not null  and t.enrollment_id is not null "
      results = @connection.execute(sql)
  end

  def setup(params)
      #this will eventually be populated with the petscans that we can't process, organized by scan_procedure.codename, and subject_id
      @pettracer = LookupPettracer.where("id = ?",params[:tracer_id]).first

      @tracer_path = "/pet/#{@pettracer.name.downcase}/#{params[:method]}/code_ver2b"
      # @schedule_owner_email_array = get_schedule_owner_email(@schedule.id)

      @preprocessed_path = params[:base_path]+"/preprocessed/visits/"
      @secondary_key_array =["b","c","d","e",".R"]
      @connection = ActiveRecord::Base.connection();


      @roi_file_cn_array = ["Region","Atlas","ROI_Number","SUVR","Volume_cc"]
      @roi_column_names = {}
      @roi_column_names[''] = ["suvr_precentral_l","suvr_precentral_r",
        "suvr_frontal_sup_l","suvr_frontal_sup_r","suvr_frontal_sup_orb_l","suvr_frontal_sup_orb_r","suvr_frontal_mid_l","suvr_frontal_mid_r",
        "suvr_frontal_mid_orb_l","suvr_frontal_mid_orb_r","suvr_frontal_inf_oper_l","suvr_frontal_inf_oper_r",
        "suvr_frontal_inf_tri_l","suvr_frontal_inf_tri_r","suvr_frontal_inf_orb_l","suvr_frontal_inf_orb_r",
        "suvr_rolandic_oper_l","suvr_rolandic_oper_r",
        "suvr_supp_motor_area_l","suvr_supp_motor_area_r",
        "suvr_olfactory_l","suvr_olfactory_r",
        "suvr_frontal_sup_medial_l","suvr_frontal_sup_medial_r","suvr_frontal_med_orb_l","suvr_frontal_med_orb_r",
        "suvr_rectus_l","suvr_rectus_r",
        "suvr_insula_l","suvr_insula_r",
        "suvr_cingulum_ant_l","suvr_cingulum_ant_r","suvr_cingulum_mid_l","suvr_cingulum_mid_r","suvr_cingulum_post_l","suvr_cingulum_post_r",
        "suvr_hippocampus_l","suvr_hippocampus_r",
        "suvr_parahippocampal_l","suvr_parahippocampal_r",
        "suvr_amygdala_l","suvr_amygdala_r",
        "suvr_calcarine_l","suvr_calcarine_r",
        "suvr_cuneus_l","suvr_cuneus_r",
        "suvr_lingual_l","suvr_lingual_r",
        "suvr_occipital_sup_l","suvr_occipital_sup_r","suvr_occipital_mid_l","suvr_occipital_mid_r","suvr_occipital_inf_l",
        "suvr_occipital_inf_r",
        "suvr_fusiform_l","suvr_fusiform_r",
        "suvr_postcentral_l","suvr_postcentral_r","suvr_parietal_sup_l","suvr_parietal_sup_r","suvr_parietal_inf_l",
        "suvr_parietal_inf_r",
        "suvr_supramarginal_l","suvr_supramarginal_r",
        "suvr_angular_l","suvr_angular_r",
        "suvr_precuneus_l","suvr_precuneus_r",
        "suvr_paracentral_lobule_l","suvr_paracentral_lobule_r",
        "suvr_caudate_l","suvr_caudate_r",
        "suvr_putamen_l","suvr_putamen_r",
        "suvr_pallidum_l","suvr_pallidum_r",
        "suvr_thalamus_l","suvr_thalamus_r",
        "suvr_heschl_l","suvr_heschl_r",
        "suvr_temporal_sup_l","suvr_temporal_sup_r",
        "suvr_temporal_pole_sup_l","suvr_temporal_pole_sup_r","suvr_temporal_mid_l","suvr_temporal_mid_r",
        "suvr_temporal_pole_mid_l","suvr_temporal_pole_mid_r","suvr_temporal_inf_l","suvr_temporal_inf_r",
        "suvr_cerebelum_crus1_l","suvr_cerebelum_crus1_r","suvr_cerebelum_crus2_l","suvr_cerebelum_crus2_r","suvr_cerebelum_3_l",
        "suvr_cerebelum_3_r","suvr_cerebelum_4_5_l","suvr_cerebelum_4_5_r","suvr_cerebelum_6_l","suvr_cerebelum_6_r",
        "suvr_cerebelum_7b_l","suvr_cerebelum_7b_r","suvr_cerebelum_8_l","suvr_cerebelum_8_r","suvr_cerebelum_9_l",
        "suvr_cerebelum_9_r","suvr_cerebelum_10_l","suvr_cerebelum_10_r",
        "suvr_vermis_1_2","suvr_vermis_3","suvr_vermis_4_5","suvr_vermis_6","suvr_vermis_7","suvr_vermis_8",
        "suvr_vermis_9","suvr_vermis_10",
        "volume_cc_precentral_l","volume_cc_precentral_r","volume_cc_frontal_sup_l","volume_cc_frontal_sup_r",
        "volume_cc_frontal_sup_orb_l","volume_cc_frontal_sup_orb_r","volume_cc_frontal_mid_l",
        "volume_cc_frontal_mid_r","volume_cc_frontal_mid_orb_l","volume_cc_frontal_mid_orb_r",
        "volume_cc_frontal_inf_oper_l","volume_cc_frontal_inf_oper_r","volume_cc_frontal_inf_tri_l",
        "volume_cc_frontal_inf_tri_r","volume_cc_frontal_inf_orb_l","volume_cc_frontal_inf_orb_r",
        "volume_cc_rolandic_oper_l","volume_cc_rolandic_oper_r",
        "volume_cc_supp_motor_area_l","volume_cc_supp_motor_area_r",
        "volume_cc_olfactory_l","volume_cc_olfactory_r",
        "volume_cc_frontal_sup_medial_l","volume_cc_frontal_sup_medial_r","volume_cc_frontal_med_orb_l","volume_cc_frontal_med_orb_r",
        "volume_cc_rectus_l","volume_cc_rectus_r",
        "volume_cc_insula_l","volume_cc_insula_r",
        "volume_cc_cingulum_ant_l","volume_cc_cingulum_ant_r","volume_cc_cingulum_mid_l","volume_cc_cingulum_mid_r","volume_cc_cingulum_post_l",
        "volume_cc_cingulum_post_r",
        "volume_cc_hippocampus_l","volume_cc_hippocampus_r",
        "volume_cc_parahippocampal_l","volume_cc_parahippocampal_r",
        "volume_cc_amygdala_l","volume_cc_amygdala_r",
        "volume_cc_calcarine_l","volume_cc_calcarine_r",
        "volume_cc_cuneus_l","volume_cc_cuneus_r",
        "volume_cc_lingual_l","volume_cc_lingual_r",
        "volume_cc_occipital_sup_l","volume_cc_occipital_sup_r","volume_cc_occipital_mid_l","volume_cc_occipital_mid_r","volume_cc_occipital_inf_l","volume_cc_occipital_inf_r",
        "volume_cc_fusiform_l","volume_cc_fusiform_r",
        "volume_cc_postcentral_l","volume_cc_postcentral_r",
        "volume_cc_parietal_sup_l","volume_cc_parietal_sup_r","volume_cc_parietal_inf_l","volume_cc_parietal_inf_r",
        "volume_cc_supramarginal_l","volume_cc_supramarginal_r",
        "volume_cc_angular_l","volume_cc_angular_r",
        "volume_cc_precuneus_l","volume_cc_precuneus_r",
        "volume_cc_paracentral_lobule_l","volume_cc_paracentral_lobule_r",
        "volume_cc_caudate_l","volume_cc_caudate_r",
        "volume_cc_putamen_l","volume_cc_putamen_r",
        "volume_cc_pallidum_l","volume_cc_pallidum_r",
        "volume_cc_thalamus_l","volume_cc_thalamus_r",
        "volume_cc_heschl_l","volume_cc_heschl_r",
        "volume_cc_temporal_sup_l","volume_cc_temporal_sup_r","volume_cc_temporal_pole_sup_l","volume_cc_temporal_pole_sup_r","volume_cc_temporal_mid_l","volume_cc_temporal_mid_r","volume_cc_temporal_pole_mid_l","volume_cc_temporal_pole_mid_r","volume_cc_temporal_inf_l","volume_cc_temporal_inf_r",
        "volume_cc_cerebelum_crus1_l","volume_cc_cerebelum_crus1_r","volume_cc_cerebelum_crus2_l","volume_cc_cerebelum_crus2_r",
        "volume_cc_cerebelum_3_l","volume_cc_cerebelum_3_r","volume_cc_cerebelum_4_5_l","volume_cc_cerebelum_4_5_r",
        "volume_cc_cerebelum_6_l","volume_cc_cerebelum_6_r","volume_cc_cerebelum_7b_l","volume_cc_cerebelum_7b_r",
        "volume_cc_cerebelum_8_l","volume_cc_cerebelum_8_r","volume_cc_cerebelum_9_l","volume_cc_cerebelum_9_r",
        "volume_cc_cerebelum_10_l","volume_cc_cerebelum_10_r",
        "volume_cc_vermis_1_2","volume_cc_vermis_3","volume_cc_vermis_4_5","volume_cc_vermis_6","volume_cc_vermis_7","volume_cc_vermis_8","volume_cc_vermis_9","volume_cc_vermis_10"]
      @roi_column_names['_atlas_tjb_mni_v1'] = ["suvr_clivus","suvr_ethmoid","suvr_meninges","suvr_pineal","suvr_vermis_sup_ant",
        "suvr_cerebellum_superior","suvr_substantia_nigra","suvr_sphenotemporalbuttress","suvr_pons",
        "volume_cc_clivus","volume_cc_ethmoid","volume_cc_meninges","volume_cc_pineal","volume_cc_vermis_sup_ant",
        "volume_cc_cerebellum_superior","volume_cc_substantia_nigra","volume_cc_sphenotemporalbuttress","volume_cc_pons"]
      @roi_column_names['_atlas_homic_mni_v1'] = ["suvr_front_pole_l","suvr_front_pole_r","suvr_insular_ctx_l","suvr_insular_ctx_r",
        "suvr_sup_front_gy_l","suvr_sup_front_gy_r","suvr_mid_front_gy_l","suvr_mid_front_gy_r",
        "suvr_inf_front_gy_pars_triangularis_l","suvr_inf_front_gy_pars_triangularis_r",
        "suvr_inf_front_gy_pars_opercularis_l","suvr_inf_front_gy_pars_opercularis_r","suvr_precentral_gy_l",
        "suvr_precentral_gy_r","suvr_temp_pole_l","suvr_temp_pole_r","suvr_sup_temp_gy_ant_l",
        "suvr_sup_temp_gy_ant_r","suvr_sup_temp_gy_post_l","suvr_sup_temp_gy_post_r","suvr_mid_temp_gy_ant_l",
        "suvr_mid_temp_gy_ant_r","suvr_mid_temp_gy_post_l","suvr_mid_temp_gy_post_r",
        "suvr_mid_temp_gy_temporooccipital_l","suvr_mid_temp_gy_temporooccipital_r","suvr_inf_temp_gy_ant_l",
        "suvr_inf_temp_gy_ant_r","suvr_inf_temp_gy_post_l","suvr_inf_temp_gy_post_r",
        "suvr_inf_temp_gy_temporooccipital_l","suvr_inf_temp_gy_temporooccipital_r","suvr_postcentral_gy_l",
        "suvr_postcentral_gy_r","suvr_sup_parietal_lobule_l","suvr_sup_parietal_lobule_r","suvr_supramarginal_gy_ant_l",
        "suvr_supramarginal_gy_ant_r","suvr_supramarginal_gy_post_l","suvr_supramarginal_gy_post_r","suvr_angular_gy_l",
        "suvr_angular_gy_r","suvr_lat_occ_ctx_sup_l","suvr_lat_occ_ctx_sup_r","suvr_lat_occ_ctx_inf_l",
        "suvr_lat_occ_ctx_inf_r","suvr_intracalcarine_ctx_l","suvr_intracalcarine_ctx_r","suvr_front_medial_ctx_l",
        "suvr_front_medial_ctx_r","suvr_juxtapositional_lobule_ctx_l","suvr_juxtapositional_lobule_ctx_r",
        "suvr_subcallosal_ctx_l","suvr_subcallosal_ctx_r","suvr_paracingulate_gy_l","suvr_paracingulate_gy_r",
        "suvr_cingulate_gy_ant_l","suvr_cingulate_gy_ant_r","suvr_cingulate_gy_post_l","suvr_cingulate_gy_post_r",
        "suvr_precuneous_ctx_l","suvr_precuneous_ctx_r","suvr_cuneal_ctx_l","suvr_cuneal_ctx_r",
        "suvr_front_orbital_ctx_l","suvr_front_orbital_ctx_r","suvr_parahippocampal_gy_ant_l",
        "suvr_parahippocampal_gy_ant_r","suvr_parahippocampal_gy_post_l","suvr_parahippocampal_gy_post_r",
        "suvr_lingual_gy_l","suvr_lingual_gy_r","suvr_temp_fusiform_ctx_ant_l","suvr_temp_fusiform_ctx_ant_r",
        "suvr_temp_fusiform_ctx_post_l","suvr_temp_fusiform_ctx_post_r","suvr_temp_occ_fusiform_ctx_l",
        "suvr_temp_occ_fusiform_ctx_r","suvr_occ_fusiform_gy_l","suvr_occ_fusiform_gy_r","suvr_front_operculum_ctx_l",
        "suvr_front_operculum_ctx_r","suvr_central_opercular_ctx_l","suvr_central_opercular_ctx_r",
        "suvr_parietal_operculum_ctx_l","suvr_parietal_operculum_ctx_r","suvr_planum_polare_l","suvr_planum_polare_r",
        "suvr_heschls_gy_l","suvr_heschls_gy_r","suvr_planum_temporale_l","suvr_planum_temporale_r",
        "suvr_supracalcarine_ctx_l","suvr_supracalcarine_ctx_r","suvr_occ_pole_l","suvr_occ_pole_r","suvr_thalamus_l",
        "suvr_thalamus_r","suvr_caudate_l","suvr_caudate_r","suvr_putamen_l","suvr_putamen_r","suvr_pallidum_l",
        "suvr_pallidum_r","suvr_hippocampus_l","suvr_hippocampus_r","suvr_amygdala_l","suvr_amygdala_r",
        "suvr_accumbens_l","suvr_accumbens_r","suvr_cerebellum_gm_l","suvr_cerebellum_gm_r","suvr_cerebellum_wm_l",
        "suvr_cerebellum_wm_r","suvr_brainstem","volume_cc_front_pole_l","volume_cc_front_pole_r",
        "volume_cc_insular_ctx_l","volume_cc_insular_ctx_r","volume_cc_sup_front_gy_l","volume_cc_sup_front_gy_r",
        "volume_cc_mid_front_gy_l","volume_cc_mid_front_gy_r","volume_cc_inf_front_gy_pars_triangularis_l",
        "volume_cc_inf_front_gy_pars_triangularis_r","volume_cc_inf_front_gy_pars_opercularis_l",
        "volume_cc_inf_front_gy_pars_opercularis_r","volume_cc_precentral_gy_l","volume_cc_precentral_gy_r",
        "volume_cc_temp_pole_l","volume_cc_temp_pole_r","volume_cc_sup_temp_gy_ant_l","volume_cc_sup_temp_gy_ant_r",
        "volume_cc_sup_temp_gy_post_l","volume_cc_sup_temp_gy_post_r","volume_cc_mid_temp_gy_ant_l",
        "volume_cc_mid_temp_gy_ant_r","volume_cc_mid_temp_gy_post_l","volume_cc_mid_temp_gy_post_r",
        "volume_cc_mid_temp_gy_temporooccipital_l","volume_cc_mid_temp_gy_temporooccipital_r",
        "volume_cc_inf_temp_gy_ant_l","volume_cc_inf_temp_gy_ant_r","volume_cc_inf_temp_gy_post_l",
        "volume_cc_inf_temp_gy_post_r","volume_cc_inf_temp_gy_temporooccipital_l",
        "volume_cc_inf_temp_gy_temporooccipital_r","volume_cc_postcentral_gy_l","volume_cc_postcentral_gy_r",
        "volume_cc_sup_parietal_lobule_l","volume_cc_sup_parietal_lobule_r","volume_cc_supramarginal_gy_ant_l",
        "volume_cc_supramarginal_gy_ant_r","volume_cc_supramarginal_gy_post_l","volume_cc_supramarginal_gy_post_r",
        "volume_cc_angular_gy_l","volume_cc_angular_gy_r","volume_cc_lat_occ_ctx_sup_l","volume_cc_lat_occ_ctx_sup_r",
        "volume_cc_lat_occ_ctx_inf_l","volume_cc_lat_occ_ctx_inf_r","volume_cc_intracalcarine_ctx_l",
        "volume_cc_intracalcarine_ctx_r","volume_cc_front_medial_ctx_l","volume_cc_front_medial_ctx_r",
        "volume_cc_juxtapositional_lobule_ctx_l","volume_cc_juxtapositional_lobule_ctx_r","volume_cc_subcallosal_ctx_l",
        "volume_cc_subcallosal_ctx_r","volume_cc_paracingulate_gy_l","volume_cc_paracingulate_gy_r",
        "volume_cc_cingulate_gy_ant_l","volume_cc_cingulate_gy_ant_r","volume_cc_cingulate_gy_post_l",
        "volume_cc_cingulate_gy_post_r","volume_cc_precuneous_ctx_l","volume_cc_precuneous_ctx_r",
        "volume_cc_cuneal_ctx_l","volume_cc_cuneal_ctx_r","volume_cc_front_orbital_ctx_l","volume_cc_front_orbital_ctx_r",
        "volume_cc_parahippocampal_gy_ant_l","volume_cc_parahippocampal_gy_ant_r","volume_cc_parahippocampal_gy_post_l",
        "volume_cc_parahippocampal_gy_post_r","volume_cc_lingual_gy_l","volume_cc_lingual_gy_r",
        "volume_cc_temp_fusiform_ctx_ant_l","volume_cc_temp_fusiform_ctx_ant_r","volume_cc_temp_fusiform_ctx_post_l",
        "volume_cc_temp_fusiform_ctx_post_r","volume_cc_temp_occ_fusiform_ctx_l","volume_cc_temp_occ_fusiform_ctx_r",
        "volume_cc_occ_fusiform_gy_l","volume_cc_occ_fusiform_gy_r","volume_cc_front_operculum_ctx_l",
        "volume_cc_front_operculum_ctx_r","volume_cc_central_opercular_ctx_l","volume_cc_central_opercular_ctx_r",
        "volume_cc_parietal_operculum_ctx_l","volume_cc_parietal_operculum_ctx_r","volume_cc_planum_polare_l",
        "volume_cc_planum_polare_r","volume_cc_heschls_gy_l","volume_cc_heschls_gy_r","volume_cc_planum_temporale_l",
        "volume_cc_planum_temporale_r","volume_cc_supracalcarine_ctx_l","volume_cc_supracalcarine_ctx_r",
        "volume_cc_occ_pole_l","volume_cc_occ_pole_r","volume_cc_thalamus_l","volume_cc_thalamus_r",
        "volume_cc_caudate_l","volume_cc_caudate_r","volume_cc_putamen_l","volume_cc_putamen_r","volume_cc_pallidum_l",
        "volume_cc_pallidum_r","volume_cc_hippocampus_l","volume_cc_hippocampus_r","volume_cc_amygdala_l",
        "volume_cc_amygdala_r","volume_cc_accumbens_l","volume_cc_accumbens_r","volume_cc_cerebellum_gm_l",
        "volume_cc_cerebellum_gm_r","volume_cc_cerebellum_wm_l","volume_cc_cerebellum_wm_r","volume_cc_brainstem"]
      @roi_column_names['_atlas_morimod_mni_v1'] = ["suvr_left_anterior_capsule_limb_of_internal","suvr_right_anterior_capsule_limb_of_internal",
        "suvr_left_posterior_capsule_limb_of_internal","suvr_right_posterior_capsule_limb_of_internal",
        "suvr_left_posterior_thalamic_radiation","suvr_right_posterior_thalamic_radiation",
        "suvr_left_anterior_corona_radiata","suvr_right_anterior_corona_radiata","suvr_left_superior_corona_radiata",
        "suvr_right_superior_corona_radiata","suvr_left_posterior_corona_radiata","suvr_right_posterior_corona_radiata",
        "suvr_left_superior_longitudinal_longitudinal","suvr_right_superior_longitudinal_longitudinal",
        "suvr_left_sagital_stratum","suvr_right_sagital_stratum","suvr_left_capsule_external",
        "suvr_right_capsule_external","suvr_left_corpus_callosum_genu","suvr_right_corpus_callosum_genu",
        "suvr_left_corpus_callosum_body","suvr_right_corpus_callosum_body","suvr_left_corpus_callosum",
        "suvr_right_corpus_callosum","suvr_left_capsule_retrolenticular_part_of_ic",
        "suvr_right_capsule_retrolenticular_part_of_ic","volume_cc_left_anterior_capsule_limb_of_internal",
        "volume_cc_right_anterior_capsule_limb_of_internal","volume_cc_left_posterior_capsule_limb_of_internal",
        "volume_cc_right_posterior_capsule_limb_of_internal","volume_cc_left_posterior_thalamic_radiation",
        "volume_cc_right_posterior_thalamic_radiation","volume_cc_left_anterior_corona_radiata",
        "volume_cc_right_anterior_corona_radiata","volume_cc_left_superior_corona_radiata",
        "volume_cc_right_superior_corona_radiata","volume_cc_left_posterior_corona_radiata",
        "volume_cc_right_posterior_corona_radiata","volume_cc_left_superior_longitudinal_longitudinal",
        "volume_cc_right_superior_longitudinal_longitudinal","volume_cc_left_sagital_stratum",
        "volume_cc_right_sagital_stratum","volume_cc_left_capsule_external","volume_cc_right_capsule_external",
        "volume_cc_left_corpus_callosum_genu","volume_cc_right_corpus_callosum_genu","volume_cc_left_corpus_callosum_body",
        "volume_cc_right_corpus_callosum_body","volume_cc_left_corpus_callosum","volume_cc_right_corpus_callosum",
        "volume_cc_left_capsule_retrolenticular_part_of_ic","volume_cc_right_capsule_retrolenticular_part_of_ic"]
      @roi_column_names['_atlas_na'] = ["suvr_altref_cblm_gm","suvr_altref_cblm_whole","suvr_altref_cblm_wm","suvr_altref_centsm_wm",
        "volume_cc_altref_cblm_gm","volume_cc_altref_cblm_whole","volume_cc_altref_cblm_wm","volume_cc_altref_centsm_wm"]

      
      @aal_mni_v4_pibindex_cn_array = ["suvr_frontal_mid_orb_l","suvr_frontal_mid_orb_r",
        "suvr_cingulum_ant_l","suvr_cingulum_ant_r","suvr_cingulum_post_l","suvr_cingulum_post_r",
        "suvr_supramarginal_l","suvr_supramarginal_r",
        "suvr_angular_l","suvr_angular_r",
        "suvr_precuneus_l","suvr_precuneus_r",
        "suvr_temporal_sup_l","suvr_temporal_sup_r","suvr_temporal_mid_l","suvr_temporal_mid_r"]

      @log_file_cn_array = ["Description","Value"]
      @cg_tn_roi = "cg_pet_#{@pettracer.name.downcase}_roi"
      @cg_tn_roi_atlas_tjb_mni_v1 = "cg_pet_#{@pettracer.name.downcase}_roi_atlas_tjb_mni_v1"
      @cg_tn_roi_atlas_homic_mni_v1 = "cg_pet_#{@pettracer.name.downcase}_roi_atlas_homic_mni_v1"
      @cg_tn_roi_atlas_morimod_mni_v1 = "cg_pet_#{@pettracer.name.downcase}_roi_atlas_morimod_mni_v1"
      @cg_tn_roi_atlas_na = "cg_pet_#{@pettracer.name.downcase}_roi"



      @aal_atlas = "aal_MNI_V4"
      @tjb_mni_v1 = "tjb_MNI_V1"
      @homic_mni_v1 = "homic_MNI_V1"
      @morimod_mni_v1 = "morimod_MNI_V1"

      @atlas_map = {"aal_MNI_V4" => '',
                    "tjb_MNI_V1" => '_atlas_tjb_mni_v1',
                    "homic_MNI_V1" => '_atlas_homic_mni_v1',
                    "morimod_MNI_V1" => '_atlas_morimod_mni_v1',
                    "NA" => '_atlas_na'}
      @atlas_map.default = nil


      @atlas_map.values.each do |atlas|
        table_name = "cg_pet_#{@pettracer.name.downcase}_roi#{atlas}"
        sql = "truncate #{table_name}_new"
        results = @connection.execute(sql)
      end

  end

  def harvest(params)

      @scan_procedures = []
      if !params[:sp_whitelist].nil?
        @scan_procedures = ScanProcedure.where("scan_procedures.id in (?)", params[:sp_whitelist])
      else

        @scan_procedures = ScanProcedure.where("scan_procedures.id not in (?)", params[:sp_blacklist])
      end


      @scan_procedures.each do |sp|
        self.log << "start "+sp.codename
        v_visit_number = sp.visit_abbr
        v_codename_hyphen =  sp.codename.gsub(".","-")

        v_preprocessed_full_path = @preprocessed_path+sp.codename
        if File.directory?(v_preprocessed_full_path)

          enrollment_conditions = ''

          if sp.subjectid_base.include? "-"
            enrollment_conditions = sp.subjectid_base.split('-').map{|sp_base| "enrollments.enumber like '#{sp_base}%'"}.join(" or ")
          else
            enrollment_conditions = "enrollments.enumber like '#{sp.subjectid_base}%'"
          end
          # puts "sql for enumbers: #{sql_enum}"

          enrollments = Enrollment.joins("LEFT JOIN enrollment_vgroup_memberships ON enrollment_vgroup_memberships.enrollment_id = enrollments.id")
                              .joins("LEFT JOIN scan_procedures_vgroups ON scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id")
                              .where("scan_procedures_vgroups.scan_procedure_id = #{sp.id.to_s}")
                              .where(enrollment_conditions)
                              .uniq

          enrollments.each do |enrollment|
            self.log << "starting #{enrollment.enumber}"

            v_subjectid_path = v_preprocessed_full_path+"/"+enrollment.enumber
            v_subjectid_v_num = enrollment.enumber + v_visit_number

            v_subjectid_pet_tracer_path = v_subjectid_path+@tracer_path
            v_subjectid_array = []

            #sometimes there are _2 etc. visits, like if they've got to rescan the person
            begin
                if File.directory?(v_subjectid_pet_tracer_path)
                    v_subjectid_array.push(enrollment.enumber)
                end
                @secondary_key_array.each do |k|
                    if File.directory?(v_subjectid_path+k+@tracer_path)
                        v_subjectid_array.push((enrollment.enumber+k))
                        v_subjectid_v_num = enrollment.enumber+k + v_visit_number
                        v_subjectid_path = v_preprocessed_full_path+"/"+enrollment.enumber+k
                        v_subjectid_pet_tracer_path =v_subjectid_path+@tracer_path
                    end
                end
            rescue => msg  
                self.log << "IN RESCUE ERROR: #{msg}"
            end
            v_subjectid_array = v_subjectid_array.uniq

            v_subjectid_array.each do |subj|
              v_secondary_key =""
              if subj != enrollment.enumber
                 v_secondary_key = subj.gsub(enrollment.enumber,"")
              end

              v_subjectid = subj
              v_subjectid_v_num = subj + v_visit_number
              v_subjectid_path = v_preprocessed_full_path+"/"+subj
              v_subjectid_pet_tracer_path =v_subjectid_path+@tracer_path
              if File.directory?(v_subjectid_pet_tracer_path)
                v_dir_array = Dir.entries(v_subjectid_pet_tracer_path)

                roi_file_name = Dir.glob(v_subjectid_pet_tracer_path + "/*roi-summary*.csv").first
                self.log << "roi_summary.csv is #{roi_file_name}"

                log_file_name = Dir.glob(v_subjectid_pet_tracer_path + "/*panda-log*.csv").first
                self.log << "panda_log.csv is #{log_file_name}"

                tacs_file_name = Dir.glob(v_subjectid_pet_tracer_path + "/*_tacs_*.csv").first
                self.log << "tacs.csv is #{tacs_file_name}"
                  
                product_file_path = Dir.glob(v_subjectid_pet_tracer_path + "/w*.nii").first
                product_file_name = nil
                if !product_file_path.nil?
                  product_file_name = product_file_path.split("/").last
                end

                self.log << "product file is #{product_file_name}"

                if !roi_file_name.blank? and !log_file_name.blank? and !product_file_name.blank?

                  log_file_data = Hash.new("") #this makes a hash with a default value for missing/new keys, in this case the empty string
                  CSV.foreach(log_file_name, :headers => true) do |row|
                    log_file_data[row["Description"]] = row["Value"].to_s.strip
                  end

                  # if the tracer doesn't match the current tracer, skip this enrollment
                  if log_file_data["tracer"] != @pettracer.name.downcase
                    self.exclusions << "{\"class\":\"#{enrollment.class}\", \"id\":\"#{enrollment.id}\", \"message\":\"the log file's tracer (#{log_file_data["tracer"]}) is != this job's tracer (#{@pettracer.name.downcase})\"}"
                    next
                  end

                  # if the subject_id doesn't match our current subject_id, skip
                  if log_file_data["study ID"] != enrollment.enumber
                    self.exclusions << "{\"class\":\"#{enrollment.class}\", \"id\":\"#{enrollment.id}\", \"message\":\"the log's study ID (#{log_file_data["study ID"]}) is != this enumber (#{enrollment.enumber})\"}"
                    next
                  end

                  # if the PET code version doesn't match us, skip
                  if !params[:code_version].include? log_file_data["PET code version"]
                    self.exclusions << "{\"class\":\"#{enrollment.class}\", \"id\":\"#{enrollment.id}\", \"message\":\"the log's code version (#{log_file_data["PET code version"]}) is != this job's code version (#{params[:code_version]})\"}"
                    next
                  end

                  # if the method (dvr or suvr) doesn't match, skip
                  if log_file_data["method"] != params[:method]
                    self.exclusions << "{\"class\":\"#{enrollment.class}\", \"id\":\"#{enrollment.id}\", \"message\":\"the log's method (#{log_file_data["method"]}) is != this job's method (#{params[:method]})\"}"
                    next
                  end

                  # if the "protocol description" doesn't match our sp.codename, skip
                  if log_file_data["protocol description"] != sp.codename
                    self.exclusions << "{\"class\":\"#{enrollment.class}\", \"id\":\"#{enrollment.id}\", \"message\":\"the log's protocol description (#{log_file_data["protocol description"]}) is != this subject's scan procedure (#{sp.codename})\"}"
                    next
                  end

                  #if there's a "original t1 MRI file" on our log, we should get the date of the appointment where that MRI was made.
                  if !log_file_data["original t1 MRI file"].blank?
                    #since this might not be an MRI associated with our current visit, we should be thorough with finding the right visit
                    v_original_t1_mri_file_array = log_file_data["original t1 MRI file"].split("/")
                    if !v_original_t1_mri_file_array.nil? and v_original_t1_mri_file_array.count > 5
                      mri_sps = ScanProcedure.where("codename in (?)",v_original_t1_mri_file_array[5])
                      mri_enums = Enrollment.where("enumber in (?) or concat(enumber,'b') in (?)",v_original_t1_mri_file_array[6],v_original_t1_mri_file_array[6])
                      if !mri_sps.nil? and !mri_enums.nil?  and mri_sps.count > 0 and mri_enums.count > 0
                        mri_appointments = Appointment.where("appointments.appointment_type = 'mri' 
                                           and appointments.vgroup_id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships 
                                                               where enrollment_vgroup_memberships.enrollment_id in (?))
                                           and appointments.vgroup_id in (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups
                                                             where scan_procedures_vgroups.scan_procedure_id in (?))",mri_enums.first.id,mri_sps.first.id)      
                        if mri_appointments.count > 0 and mri_appointments.count < 2
                          mri_date  = mri_appointments.first.appointment_date
                        else
                          self.exclusions << "{\"class\":\"#{enrollment.class}\", \"id\":\"#{enrollment.id}\", \"message\":\"Too many MRI appointments? (count was #{mri_appointments.count})\"}"
                          next
                        end
                      end
                    end
                  end

                  #there may also be multiple ecat files in the ecat file field. We should get all of them together.

                  if !log_file_data["ecat file"].blank? or !log_file_data["raw PET file"].blank?
                    ecat_file = !log_file_data["ecat file"].blank? ? log_file_data["ecat file"] : log_file_data["raw PET file"]
                    ecat_file_array = []
                    ecat_file_chop_array = ecat_file.split("-")
                    if ecat_file_chop_array.count > 1
                      ecat_file_chop_array.each do |val|
                        ecat_file_array.push(File.dirname(val).to_s)
                      end
                    end
                    ecat_file_array.push(ecat_file)
                    petscans = Petscan.where("petscans.id in (select petfiles.petscan_id from petfiles where petfiles.path in (?))",ecat_file_array)
                    if petscans.count > 0
                      v_appointment = Appointment.find(petscans.first.appointment_id)
                      v_age_at_appointment = v_appointment.age_at_appointment.to_s
                      pet_date  = v_appointment.appointment_date
                    else # sometimes the processing ecat not match the panda ecat 
                                        # use tracer, enumber and scan_procedure
                      v_appointments = Appointment.where("appointments.appointment_type = 'pet_scan' 
                                           and appointments.id in (select petscans.appointment_id from petscans where petscans.lookup_pettracer_id in (?))
                                           and appointments.vgroup_id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships 
                                                        where enrollment_vgroup_memberships.enrollment_id in (?))
                                            and appointments.vgroup_id in (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups
                                                         where scan_procedures_vgroups.scan_procedure_id in (?))",params[:tracer_id],enrollment.id,sp.id)
                      if v_appointments.count > 0
                        age_at_appointment = v_appointments.first.age_at_appointment.to_s
                        pet_date  = v_appointments.first.appointment_date
                      end
                    end
                  end


                  if !pet_date.blank? and !mri_date.blank?
                    pet_date_mri_date_diff_days =  ((pet_date - mri_date)).to_i.to_s
                  end

                  v_mri_processed_date_change = false
                  v_pet_processed_date_change = false


                  v_sql_check = "Select mri_processing_date,pet_processing_date,subjectid,enrollment_id,scan_procedure_id from cg_pet_mk6240_roi where enrollment_id = "+enrollment.id.to_s+" and scan_procedure_id = "+sp.id.to_s+" and secondary_key = '"+v_secondary_key.to_s+"'"
                  results_check = @connection.execute(v_sql_check) 
                  if !results_check.nil? and !results_check.first.nil? and !results_check.first[0].blank? and results_check.first[0].to_s != log_file_data["MRI image processing date"] and !log_file_data["MRI image processing date"].blank?
                    v_mri_processed_date_change = true
                  end
                  if !results_check.nil? and !results_check.first.nil? and !results_check.first[1].blank? and results_check.first[1].to_s != log_file_data["PET image processing date"] and !log_file_data["PET image processing date"].blank?
                    v_pet_processed_date_change = true
                  end

                  # record a new processed image for our product file (the w*.nii file)

                  processed_image_product = Processedimage.where("file_path in (?)",product_file_name)
                  @trfileimage_processedimages = []
                  if processed_image_product.count < 1
                    new_processedimage = create_processed_image(type:params[:product_file_type], path:product_file_path, scan_procedure_id:sp.id, enrollment_id:enrollment.id)

                    @trfileimage_processedimages.push(new_processedimage.id)

                    # and an image source for the ecat file(s)
                    v_petfiles = Petfile.where("petfiles.path in (?)",ecat_file_array)
                    if v_petfiles.count > 0
                      v_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'petfile'",new_processedimage.id,v_petfiles.first.id)
                      if v_processedimagesources.count < 1 and v_petfiles.count > 0
                        v_processedimagesource = create_processed_image_source(path:ecat_file, processed_image_id:new_processedimage.id, source_id:v_petfiles.first.id, source_type:'petfile')
                      end
                    end

                    # if a record doesn't exist for an o_acpc T1 used in making this w*.nii, create the Processedimage record for it
                    # And if a source record doesn't exists for the o_acpc T1, create one.

                    v_mri_processedimage_id = ""
                    v_original_t1_mri_file_unknown = log_file_data["original t1 MRI file"].gsub("tissue_seg","unknown") # think the oACPC in tissue seg are from unknown
                    v_mri_processedimages = Processedimage.where("file_path in (?) or file_path in (?)",log_file_data["original t1 MRI file"],v_original_t1_mri_file_unknown)
                    if v_mri_processedimages.count < 1
                      v_mri_processedimage = create_processed_image(type:"o_acpc T1", path:log_file_data["original t1 MRI file"], scan_procedure_id:sp.id, enrollment_id:enrollment.id)
                      v_mri_processedimage_id = v_mri_processedimage.id
                    else
                      v_mri_processedimage_id = v_mri_processedimages.first.id
                    end

                    v_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'processedimage'",new_processedimage.id,v_mri_processedimage_id)
                    if v_processedimagesources.count < 1 
                        v_processedimagesource = create_processed_image_source(path:log_file_data["original t1 MRI file"], processed_image_id:new_processedimage.id, source_id:v_mri_processedimage_id, source_type:'processedimage')

                    end
                  else
                        #if there's already an existing processed image for this file path
                    @trfileimage_processedimages.push(processed_image_product.first.id)
                  end


                  if log_file_data["Bias Corrected T1 MRI file"]  > ""
                    v_processedimages = Processedimage.where("file_path in (?)",log_file_data["Bias Corrected T1 MRI file"] )
                    v_sql_check = "Select mri_processing_date,subjectid,enrollment_id,scan_procedure_id from cg_pet_mk6240_roi where enrollment_id = "+enrollment.id.to_s+" and scan_procedure_id = "+sp.id.to_s+" and secondary_key = '"+v_secondary_key.to_s+"'"
                    results_check = @connection.execute(v_sql_check) 
                    if v_mri_processed_date_change == "Y"
                      if v_processedimages.count > 0
                        # rename exisiting processedimage file in database if  mri processing date changed - rename with old processing date
                        # f.start_with?("w"+v_subjectid) and f.end_with?(".nii")
                        #  15-Oct-2018 14:55:40 => 15_Oct_2018_14_55_40.
                        v_date_time_nii = "_"+results_check.first[0].gsub(" ","_").gsub(":","_").gsub("-","_")+".nii"
                        v_check_date_file_path = v_processedimages.first.file_path
                        v_check_date_file_path = v_check_date_file_path.gsub(".nii",v_date_time_nii)
                        v_processesimages_check = Processedimage.where("file_path in (?)",v_check_date_file_path)
                        if v_processesimages_check.count <1
                          v_processedimages.first.file_path = v_processedimages.first.file_path.gsub(".nii",v_date_time_nii)
                          v_processedimages.first.file_name = v_processedimages.first.file_name.gsub(".nii",v_date_time_nii)
                          v_processedimages.first.save
                        else
                          v_trfileimages = Trfileimage.where("image_id in (?)",v_processedimages.first.id)
                          v_trfileimages.each do |trfileimage|
                            trfileimage.image_id = v_processesimages_check.first.id
                            trfileimage.save
                          end
                        end
                        v_processedimages = nil
                      
                      end
                    end
                    v_processedimages = nil
                    v_processedimages = Processedimage.where("file_path in (?)",log_file_data["Bias Corrected T1 MRI file"] )
                    if v_processedimages.count <1
                      # need to collect source files, then make processedimage record

                      v_processedimage = create_processed_image(type:"bias corrected mri", path:log_file_data["Bias Corrected T1 MRI file"], scan_procedure_id:sp.id, enrollment_id:enrollment.id)
                      v_processedimage_file_id = v_processedimage.id
                      @trfileimage_processedimages.push(v_processedimage.id)


                      v_mri_processedimage_id = ""
                      v_original_t1_mri_file_unknown = log_file_data["original t1 MRI file"].gsub("tissue_seg","unknown")
                      v_mri_processedimages = Processedimage.where("file_path in (?) or file_path in (?)",log_file_data["original t1 MRI file"],v_original_t1_mri_file_unknown)
                      if v_mri_processedimages.count < 1

                        v_mri_processedimage = create_processed_image(type:"o_acpc T1", path:log_file_data["original t1 MRI file"], scan_procedure_id:sp.id, enrollment_id:enrollment.id)
                        v_mri_processedimage_id = v_mri_processedimage.id

                      else
                        v_mri_processedimage_id = v_mri_processedimages.first.id
                      end
                      v_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'processedimage'",v_processedimage_file_id,v_mri_processedimage_id)
                      if v_processedimagesources.count < 1 
                        v_processedimagesource = create_processed_image_source(path:log_file_data["original t1 MRI file"], processed_image_id:v_processedimage_file_id, source_id:v_mri_processedimage_id, source_type:'processedimage')
                      end
                    else
                      @trfileimage_processedimages.push(v_processedimages.first.id)
                    end
                  end

                  # if a record doesn't exist for the multispectral file used in making this w*.nii, create the Processedimage record for it
                  # And if a source record doesn't exists for the multispectral file, create one.
                  if log_file_data["multispectral file"]  > ""
                    v_processedimages = Processedimage.where("file_path in (?)",log_file_data["multispectral file"] )
                    if v_processedimages.count <1
                      # need to collect source files, then make processedimage record
                      v_processedimage_file = create_processed_image(type: "multispectral mri", path: log_file_data["multispectral file"], scan_procedure_id: sp.id, enrollment_id: enrollment.id)
                      v_processedimage_file_id = v_processedimage_file
                      @trfileimage_processedimages.push(v_processedimages.first.id)

                      v_mri_processedimage_id = ""
                      v_original_t1_mri_file_unknown = log_file_data["original t1 MRI file"].gsub("tissue_seg","unknown") # think the oACPC in tissue seg are from unknown
                      v_mri_processedimages = Processedimage.where("file_path in (?) or file_path in (?)",log_file_data["original t1 MRI file"],v_original_t1_mri_file_unknown)
                      if v_mri_processedimages.count < 1
                        v_mri_processedimage = create_processed_image(type: "o_acpc T1", path: v_original_t1_mri_file_unknown, scan_procedure_id: sp.id, enrollment_id: enrollment.id)
                        v_mri_processedimage_id = v_mri_processedimage.id
                      else
                        v_mri_processedimage_id = v_mri_processedimages.first.id
                      end

                      v_processedimagesources = Processedimagessource.where("processedimage_id in (?) and source_image_id in (?) and source_image_type = 'processedimage'",v_processedimages.first.id,v_mri_processedimage_id)
                      if v_processedimagesources.count < 1 
                        v_processedimagesource = create_processed_image_source(path: log_file_data["original t1 MRI file"], processed_image_id:v_processedimages.first.id, source_id:v_mri_processedimage_id, source_type:'processedimage')
                        v_processedimagesource_id = v_processedimagesource.id
                      end
                    else
                      @trfileimage_processedimages.push(v_processedimages.first.id)
                    end
                  end


                  # if there aren't any trfile records for this subjectid, create one and track that we created a new w*.nii.
                  trfiles = Trfile.where("trtype_id in (?)",params[:trtype_id]).where("subjectid in (?)",v_subjectid_v_num)
                  v_qc_value = "Waiting"
                  if trfiles.count == 0
                    trfile = Trfile.new
                    trfile.subjectid = v_subjectid_v_num
                    # @trfile.secondary_key = v_secondary_key
                    trfile.enrollment_id = enrollment.id
                    trfile.scan_procedure_id = sp.id
                    trfile.trtype_id = params[:trtype_id]
                    trfile.qc_value = "New Record"
                    v_qc_value = "New Record"
                    trfile.qc_notes = "autoinsert by panda "
                    trfile.save
                    # NEED processedimage @trfile.image_dataset_id = v_ids_id
                    if @trfileimage_processedimages.kind_of?(Array)
                      @trfileimage_processedimages.each do |img|
                        v_img = Trfileimage.new
                        v_img.trfile_id = trfile.id
                        v_img.image_category = "processedimage"
                        v_img.image_id = img
                        v_img.save
                      end
                    end
                    tredit = Tredit.new
                    tredit.trfile_id = trfile.id
                    #@tredit.user_id = current_user.id
                    tredit.save
                    v_tractiontypes = Tractiontype.where("trtype_id in (?)",params[:trtype_id])
                    if !v_tractiontypes.nil?
                      v_tractiontypes.each do |tat|
                        v_tredit_action = TreditAction.new
                        v_tredit_action.tredit_id = tredit.id
                        v_tredit_action.tractiontype_id = tat.id
                        if !(tat.form_default_value).blank?
                          v_tredit_action.value = tat.form_default_value
                        end
                        v_tredit_action.save
                      end
                    end
                  else
                    v_qc_value = (trfiles.first).qc_value
                    if v_qc_value.nil? or v_qc_value.blank?
                      v_qc_value = "Waiting"
                    end
                  end

                  # Then scan in the roi file (which is a csv), and sort out the lines into their respective hashes.
                  v_roi_hash = Hash.new()
                  atlas_map.values.each do |atlas|
                    v_roi_hash[atlas] = {}
                  end

                  if !roi_file_name.blank?
                    #check that the header is the header we're expecting
                    header = File.open(roi_file_name) {|f| f.readline.strip }
                    v_return_flag,v_return_comment  = compare_file_header(header,@roi_file_cn_array.join(","))
                    if v_return_flag == "N" 
                      self.log << "ROI header didn't match: #{roi_file_name}=>#{v_return_comment}"
                    else

                      roi_summary_data = CSV.read(roi_file_name, :headers => true)

                      # we almost certainly won't be doing DVR with anything but PiB, but this should still generalize
                      roi_summary_data.each do |row|
                        atlas = atlas_map[row["Atlas"]]

                        if atlas.nil?
                          self.log << "UNEXPECTED ATLAS #{row["Atlas"]};"
                        else

                          # self.log << "#{atlas}"
                          # self.log << "#{params[:method].downcase}_#{row["Region"].downcase}"
                          # self.log << "#{row[params[:method].upcase]}"
                          v_roi_hash[atlas][params[:method]+"_"+row["Region"].downcase] = row[params[:method].upcase]
                          v_roi_hash[atlas]["volume_cc_"+row["Region"].downcase] = row["Volume_cc"]
                          v_roi_hash[atlas]["atlas_name"] = row["Atlas"]

                        end
                      end
                    end

                  else
                    #report a missing roi file
                    self.log << "ERROR: missing ROI file, enumber: #{enrollment.id}, scan_procedure: #{sp.codename}" 
                  end


                  #now we check to see if this file has changed or been reprocessed, and we decide what our QC status is
                  v_change = false
                  v_blank_row = false
                  # do some checks to decide if this is a new record, or a reprocess of an old record. Then decide on a QC value for the trfiles record.
                  v_sql_check = "Select "+@roi_column_names[''].join(',')+",subjectid,enrollment_id,scan_procedure_id from cg_pet_#{@pettracer.name.downcase}_roi where enrollment_id = "+enrollment.id.to_s+" and scan_procedure_id = "+sp.id.to_s+" and secondary_key = '"+v_secondary_key.to_s+"'"
                  results_check = @connection.execute(v_sql_check)
                  if (!results_check.nil? and !results_check.first.nil? and !results_check.first[0].nil?  and (results_check.count) > 0 and (results_check.count) < 2) or (v_qc_value != "New Record" and (results_check.nil? or (!results_check.nil? and (results_check.count) < 1) ) )
                    if (v_qc_value != "New Record" and (results_check.nil? or (!results_check.nil? and (results_check.count) < 1) ) )
                      v_change = true
                      v_blank_row = true
                    end
                    v_col_array = @roi_column_names['']
                    v_cnt_col = 0
                    if !v_blank_row
                      v_col_array.each do |cn|
                        if v_roi_hash[cn].nil? or v_roi_hash[cn].blank?
                        else
                          if results_check.first[v_cnt_col].strip.to_s > "" and  v_roi_hash[cn].to_s != results_check.first[v_cnt_col].to_s
                            v_change = true
                          end
                        end
                        v_cnt_col = v_cnt_col + 1
                      end
                    end
                    if v_mri_processed_date_change or v_pet_processed_date_change
                      v_change = true
                    end

                    if v_change
                      trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid_v_num)
                      if v_mri_processed_date_change == "Y" and  v_pet_processed_date_change == "Y" 
                        trfiles.first.qc_notes = " mri reprocessed-"+log_file_data["MRI image processing date"]+", pet reprocessed-"+log_file_data["PET image processing date"]+" roi changed [qc_status was="+trfiles.first.qc_value.to_s+"] "+trfiles.first.qc_notes
                      elsif  v_mri_processed_date_change == "Y" 
                        trfiles.first.qc_notes = " mri reprocessed-"+log_file_data["MRI image processing date"]+" roi changed [qc_status was="+trfiles.first.qc_value.to_s+"] "+trfiles.first.qc_notes
                      elsif v_pet_processed_date_change == "Y" 
                        trfiles.first.qc_notes = " pet reprocessed-"+log_file_data["PET image processing date"]+" roi changed [qc_status was="+trfiles.first.qc_value.to_s+"] "+trfiles.first.qc_notes
                      else
                        trfiles.first.qc_notes = " roi changed [qc_status was="+trfiles.first.qc_value.to_s+"] "+trfiles.first.qc_notes
                      end
                      #added
                      trfiles.first.file_completed_flag = "N"
                      # add comments if mri processed or pet processed date change
                      trfiles.first.qc_value = "Reprocessed"
                      trfiles.first.save
                      existing_trfileimages = Trfileimage.where("trfile_id in (?)",@trfiles.first.id)
                      existing_trfileimages.each do |trfileimage|
                      trfileimage.delete
                    end
                    # NEED processedimage @trfile.image_dataset_id = v_ids_id
                    if @trfileimage_processedimages.kind_of?(Array)
                      @trfileimage_processedimages.each do |img|
                        v_img = Trfileimage.new
                        v_img.trfile_id = @trfiles.first.id
                        v_img.image_category = "processedimage"
                        v_img.image_id = img
                        v_img.save
                      end
                    end
                  end

                end

                # for atlas in ['_atlas_tjb_mni_v1','_atlas_homic_mni_v1','_atlas_morimod_mni_v1','_atlas_na','_']
                # table name = "cg_pet_#{tracer_name}_roi#{atlas}_new"
                preamble_fields = %w"file_name subjectid enrollment_id scan_procedure_id secondary_key pet_processing_date mri_processing_date pet_code_version original_t1_mri_file_name bias_corrected_t1_mri_file mni_space_t1_mri multispectral_file pet_log_file coregistration_reference_file processed_4d_pet_file processed_sum_pet_file processed_suvr_pet_file mni_space_suvr_pet_file pet_analysis_log_file ecat_file_name atlas age_at_appointment general_comment pet_date_mri_date_diff_days"
                self.log << "file name => #{roi_file_name.split("/").last.to_s}"
                self.log << "subjectid => #{v_subjectid_v_num}"
                self.log << "enrollment_id => #{enrollment.id.to_s}"
                self.log << "scan_procedure_id => #{sp.id.to_s}"
                self.log << "secondary_key => #{v_secondary_key.to_s}"
                self.log << "pet_processing_date => #{pet_date.to_s}"
                self.log << "mri_processing_date => #{mri_date.to_s}"
                self.log << "pet_code_version => #{log_file_data["PET code version"]}"
                self.log << "original_t1_mri_file_name => #{log_file_data["original t1 MRI file"].to_s}"
                self.log << "bias_corrected_t1_mri_file => #{log_file_data["Bias Corrected T1 MRI file"]}"
                self.log << "mni_space_t1_mri => #{log_file_data["MNI space T1 MRI"]}"
                self.log << "multispectral_file => #{log_file_data["multispectral file"]}"
                self.log << "pet_log_file => #{log_file_data["PET log file"]}"
                self.log << "coregistration_reference_file => #{log_file_data["coregistration reference file"]}"
                self.log << "processed_4d_pet_file => #{log_file_data["processed 4D PET file"]}"
                self.log << "processed_sum_pet_file => #{log_file_data["processed SUM PET file"]}"
                self.log << "processed_suvr_pet_file => #{log_file_data["processed SUVR PET file"]}"
                self.log << "mni_space_suvr_pet_file => #{log_file_data["MNI space SUVR PET file"]}"
                self.log << "pet_analysis_log_file => #{log_file_data["PET analysis log file"]}"
                self.log << "ecat_file_name => #{ecat_file.to_s}"
                self.log << "atlas => %{atlas_name}"
                self.log << "age_at_appointment => #{v_age_at_appointment}"
                self.log << "general_comment => #{v_qc_value}"
                self.log << "pet_date_mri_date_diff_days => #{pet_date_mri_date_diff_days}"
                preamble_values = "'" + roi_file_name.split("/").last.to_s+"','"+v_subjectid_v_num+"',"+enrollment.id.to_s+","+sp.id.to_s+",'"+v_secondary_key.to_s+"','"+pet_date.to_s+"','"+mri_date.to_s+"','"+log_file_data["PET code version"]+"','"+log_file_data["original t1 MRI file"].to_s+"','"+log_file_data["Bias Corrected T1 MRI file"]+"','"+log_file_data["MNI space T1 MRI"]+"','"+log_file_data["multispectral file"]+"','"+log_file_data["PET log file"]+"','"+log_file_data["coregistration reference file"]+"','"+log_file_data["processed 4D PET file"]+"','"+log_file_data["processed SUM PET file"]+"','"+log_file_data["processed SUVR PET file"]+"','"+log_file_data["MNI space SUVR PET file"]+"','"+log_file_data["PET analysis log file"]+"','"+ecat_file.to_s+"','%{atlas_name}','"+v_age_at_appointment+"','"+v_qc_value+"','"+pet_date_mri_date_diff_days+"'"

                @atlas_map.values.each do |atlas|

                  #This may sacrifice readability for brevity/fanciness, but I'm trying it out. I'm doing this little interp step here to fill 
                  # the atlas name, which we track for each row in the DB. But it's not the mapped table name corresponding to the atlas,
                  # it's the literal atlas name used by Tobey's processing scripts.
                  preamble_values_interpolated = preamble_values % v_roi_hash[atlas].merge({:atlas_name => atlas})

                  column_names = @roi_column_names[atlas]
                  column_values = column_names.map {|cn| "'#{v_roi_hash[atlas][cn]}'" }.join(',')

                  table_name = "cg_pet_#{@pettracer.name.downcase}_roi#{atlas}"
                  sql = "insert into #{table_name}_new (#{preamble_fields.join(",")},#{column_names.join(',')}) values (#{preamble_values_interpolated},#{column_values})"

                  results = @connection.execute(sql)

                  old_sql = "select count(*) from #{table_name}_old"
                  results_old = @connection.execute(old_sql)

                  current_sql = "select count(*) from #{table_name}"
                  results_current = @connection.execute(current_sql)
                  old_count = results_old.first.to_s.to_i
                  present_count = results_current.first.to_s.to_i
                  old_minus_present =old_count-present_count
                  present_minus_old = present_count-old_count

                  # if ( old_minus_present <= 0 or ( old_count > 0 and  (present_minus_old/old_count)>0.7     ) )
                    sql =  "truncate table #{table_name}_old"
                    results = connection.execute(sql)
                    sql = "insert into #{table_name}_old select * from #{table_name}"
                    results = connection.execute(sql)
                  # else
                  #   self.log << " The #{table_name}_old table has 30% more rows than the present #{table_name}\n Not truncating #{table_name}_old "
                  # end

                  #  truncate cg_ and insert cg_new
                  sql =  "truncate table #{table_name}"
                  esults = connection.execute(sql)

                  sql = "insert into #{table_name} (#{preamble_fields.join(",")},#{column_names.join(',')})
                          select distinct #{preamble_values_interpolated},#{column_values} from #{table_name}_new
                          where scan_procedure_id is not null and enrollment_id is not null"
                  results = connection.execute(sql)


                end
              end
            end
          end
        end
      end



      # once everything is in the right cg_pet table, for each of the cg_pet tables:

        # check the _old table to see if it should be truncated. (if it's got 30% more records than the current table)
        

        # if so, truncate it, and select * into _old from current
        # else, send a warning

        # then, truncate the current table, and select * into current from _new
        # Given that we just dregged the whole filesystem for pet data (for this particular tracer), and recorded all of it on 
        # _new, everything should be in there and we shouldn't be losing anything with this process.


    end
  end
  
  def post_harvest(params)
  end

end