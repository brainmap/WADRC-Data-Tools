# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120412210643) do

  create_table "analyses", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "image_search_id"
  end

  create_table "analysis_memberships", :force => true do |t|
    t.integer  "analysis_id"
    t.integer  "image_dataset_id"
    t.boolean  "excluded",          :default => false
    t.string   "exclusion_comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "appointments", :force => true do |t|
    t.date     "appointment_date"
    t.integer  "vgroup_id"
    t.string   "comment"
    t.string   "appointment_type"
    t.integer  "employee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "employees", :force => true do |t|
    t.string   "first_name"
    t.string   "mi"
    t.string   "last_name"
    t.string   "status"
    t.string   "initials"
    t.integer  "lookup_status_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "enrollment_visit_memberships", :force => true do |t|
    t.integer  "enrollment_id"
    t.integer  "visit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "enrollment_visit_memberships", ["visit_id", "enrollment_id"], :name => "index_enrollment_visit_memberships_on_visit_id_enrollment_id"

  create_table "enrollments", :force => true do |t|
    t.date     "enroll_date"
    t.string   "enumber"
    t.string   "recruitment_source"
    t.integer  "recruitment_group_id"
    t.integer  "participant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "withdrawl_reason"
  end

  add_index "enrollments", ["id", "participant_id"], :name => "index_enrollments_on_id_participant_id"

  create_table "image_comments", :force => true do |t|
    t.integer  "image_dataset_id", :null => false
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "image_comments", ["image_dataset_id", "id"], :name => "index_image_comments_on_image_dataset_id_id"

  create_table "image_dataset_quality_checks", :force => true do |t|
    t.integer  "user_id"
    t.integer  "image_dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "incomplete_series"
    t.string   "garbled_series"
    t.string   "fov_cutoff"
    t.string   "field_inhomogeneity"
    t.string   "ghosting_wrapping"
    t.string   "banding"
    t.string   "registration_risk"
    t.string   "motion_warning"
    t.string   "omnibus_f"
    t.string   "spm_mask"
    t.text     "incomplete_series_comment"
    t.text     "garbled_series_comment"
    t.text     "fov_cutoff_comment"
    t.text     "ghosting_wrapping_comment"
    t.text     "banding_comment"
    t.text     "registration_risk_comment"
    t.text     "motion_warning_comment"
    t.text     "omnibus_f_comment"
    t.text     "spm_mask_comment"
    t.text     "other_issues"
    t.text     "field_inhomogeneity_comment"
    t.string   "nos_concerns"
    t.text     "nos_concerns_comment"
  end

  create_table "image_datasets", :force => true do |t|
    t.string   "rmr"
    t.string   "series_description"
    t.string   "path"
    t.datetime "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "visit_id"
    t.string   "glob"
    t.decimal  "rep_time",               :precision => 10, :scale => 0
    t.integer  "bold_reps"
    t.integer  "slices_per_volume"
    t.string   "scanned_file"
    t.string   "thumbnail_file_name"
    t.string   "thumbnail_content_type"
    t.integer  "thumbnail_file_size"
    t.datetime "thumbnail_updated_at"
    t.string   "dicom_series_uid"
    t.text     "dicom_taghash"
    t.string   "image_uid"
  end

  add_index "image_datasets", ["dicom_series_uid"], :name => "index_image_datasets_on_dicom_series_uid", :unique => true
  add_index "image_datasets", ["visit_id", "id"], :name => "index_image_datasets_on_visit_id_id"

  create_table "image_searches", :force => true do |t|
    t.string   "rmr"
    t.string   "series_description"
    t.string   "path"
    t.datetime "earliest_timestamp"
    t.datetime "latest_timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "enumber"
    t.integer  "gender"
    t.integer  "min_age"
    t.integer  "max_age"
    t.integer  "min_ed_years"
    t.integer  "max_ed_years"
    t.integer  "apoe_status"
    t.string   "scanner_source"
  end

  create_table "image_searches_scan_procedures", :id => false, :force => true do |t|
    t.integer  "image_search_id"
    t.integer  "scan_procedure_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invites", :force => true do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.string   "email"
    t.string   "invite_code", :limit => 40
    t.datetime "invited_at"
    t.datetime "redeemed_at"
  end

  create_table "log_file_entries", :force => true do |t|
    t.string   "filename"
    t.string   "stimulus_type"
    t.string   "response_type"
    t.integer  "stimulus_code"
    t.integer  "stimulus_time"
    t.integer  "response_code"
    t.integer  "response_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "log_file_id"
  end

  create_table "log_files", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filename"
    t.integer  "image_dataset_id"
    t.integer  "visit_id"
  end

  create_table "lookup_bvmtpercentiles", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_cogstatuses", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_cohorts", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_consentcohorts", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_consentforms", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_demographichandednesses", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_demographicincomes", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_demographicmaritalstatuses", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_demographicrelativerelationships", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_diagnoses", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_drugclasses", :force => true do |t|
    t.string   "epodrugclass"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_drugcodes", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_drugfreqs", :force => true do |t|
    t.string   "frequency"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_drugunits", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_eligibility_ineligibilities", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_eligibilityoutcomes", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_ethnicities", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_famhxes", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_genders", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_hardwares", :force => true do |t|
    t.string   "hardwaretype"
    t.string   "hardwaregroup"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_imagingplanes", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_letterlabels", :force => true do |t|
    t.string   "description"
    t.integer  "protocol_id"
    t.integer  "doccategory"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_pettracers", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_rads", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_recruitsources", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_refs", :force => true do |t|
    t.integer  "ref_value"
    t.string   "description"
    t.integer  "display_order"
    t.string   "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_relationships", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_scantasks", :force => true do |t|
    t.string   "description"
    t.string   "name"
    t.string   "pulse_sequence_code"
    t.string   "bold_reps"
    t.integer  "task_code"
    t.integer  "set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_sets", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_sources", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_statuses", :force => true do |t|
    t.string   "description"
    t.integer  "status_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_switchboards", :force => true do |t|
    t.string   "description"
    t.integer  "item_number"
    t.string   "command"
    t.string   "argument"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_truthtables", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_visitfrequencies", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "medicationdetails", :force => true do |t|
    t.string   "genericname"
    t.string   "brandname"
    t.integer  "lookup_drugclass_id"
    t.integer  "prescription"
    t.integer  "exclusionclass"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "neuropsych_assessments", :force => true do |t|
    t.decimal  "score",                 :precision => 10, :scale => 0
    t.string   "score_type"
    t.string   "test_name"
    t.text     "note"
    t.integer  "neuropsych_session_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "neuropsych_sessions", :force => true do |t|
    t.date     "date"
    t.text     "note"
    t.string   "procedure"
    t.integer  "visit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "participants", :force => true do |t|
    t.integer  "ed_years"
    t.integer  "apoe_e1"
    t.integer  "apoe_e2"
    t.integer  "gender"
    t.string   "note"
    t.string   "apoe_processor"
    t.date     "dob"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wrapnum"
    t.integer  "access_id"
    t.integer  "reggieid"
  end

  create_table "participants_bak_20120229", :id => false, :force => true do |t|
    t.integer  "id",             :default => 0, :null => false
    t.integer  "ed_years"
    t.integer  "apoe_e1"
    t.integer  "apoe_e2"
    t.integer  "gender"
    t.string   "note"
    t.string   "apoe_processor"
    t.date     "dob"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wrapnum"
    t.integer  "access_id"
    t.integer  "reggieid"
  end

  create_table "physiology_text_files", :force => true do |t|
    t.string   "filepath"
    t.integer  "image_dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "protocol_roles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "protocol_id"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "protocols", :force => true do |t|
    t.string   "name"
    t.string   "abbr"
    t.string   "path"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "q_data", :force => true do |t|
    t.integer  "q_data_form_id"
    t.integer  "question_id"
    t.integer  "value_link"
    t.string   "value_1"
    t.string   "value_2"
    t.string   "value_3"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "q_data", ["value_link", "question_id", "q_data_form_id"], :name => "ind_q_data"

  create_table "q_data_forms", :force => true do |t|
    t.integer  "questionform_id"
    t.integer  "participant_id"
    t.integer  "visit_id"
    t.integer  "appointment_id"
    t.integer  "scan_procedure_id"
    t.integer  "enrollment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "question_scan_procedures", :force => true do |t|
    t.integer  "question_id"
    t.integer  "scan_procedure_id"
    t.string   "include_exclude"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questionform_questions", :force => true do |t|
    t.integer  "questionform_id"
    t.integer  "question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "display_order"
  end

  add_index "questionform_questions", ["questionform_id"], :name => "ind_qform_questions"

  create_table "questionform_scan_procedures", :force => true do |t|
    t.integer  "questionform_id"
    t.integer  "scan_procedure_id"
    t.string   "include_exclude"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questionforms", :force => true do |t|
    t.string   "description"
    t.string   "long_description"
    t.integer  "display_order"
    t.integer  "parent_questionform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "entrance_page_type"
  end

  create_table "questions", :force => true do |t|
    t.string   "heading_1"
    t.string   "phrase_a_1"
    t.string   "value_type_1"
    t.string   "ref_table_a_1"
    t.string   "ref_table_b_1"
    t.string   "phrase_b_1"
    t.string   "phrase_c_1"
    t.string   "required_y_n_1"
    t.string   "heading_2"
    t.string   "phrase_a_2"
    t.string   "value_type_2"
    t.string   "ref_table_a_2"
    t.string   "ref_table_b_2"
    t.string   "phrase_b_2"
    t.string   "phrase_c_2"
    t.string   "required_y_n_2"
    t.string   "heading_3"
    t.string   "phrase_a_3"
    t.string   "value_type_3"
    t.string   "ref_table_a_3"
    t.string   "ref_table_b_3"
    t.string   "phrase_b_3"
    t.string   "phrase_c_3"
    t.string   "required_y_n_3"
    t.string   "status"
    t.integer  "parent_question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description",        :limit => 200
    t.string   "js_1"
    t.string   "js_2"
    t.string   "js_3"
    t.string   "value_link"
    t.string   "prompt_1"
    t.string   "prompt_2"
    t.string   "prompt_3"
    t.string   "default_val_1"
    t.string   "default_val_2"
    t.string   "default_val_3"
    t.string   "base_table_1"
    t.string   "base_column_1"
    t.string   "base_table_2"
    t.string   "base_column_2"
    t.string   "base_table_3"
    t.string   "base_column_3"
    t.string   "global_update_1",    :limit => 50
    t.string   "global_update_2",    :limit => 50
    t.string   "global_update_3",    :limit => 50
    t.string   "access_table_1"
    t.string   "access_column_1"
    t.string   "access_table_2"
    t.string   "access_column_2"
    t.string   "access_table_3"
    t.string   "access_column_3"
    t.string   "col_span_1"
    t.string   "col_span_2"
    t.string   "col_span_3"
    t.string   "align_1"
    t.string   "align_2"
    t.string   "align_3"
  end

  add_index "questions", ["id", "status"], :name => "ind_questions"

  create_table "radiology_comments", :force => true do |t|
    t.integer  "visit_id"
    t.string   "rmr"
    t.integer  "scan_number"
    t.string   "rmr_rad"
    t.integer  "scan_number_rad"
    t.string   "editable_flag"
    t.string   "rad_path"
    t.string   "q1_flag"
    t.string   "q2_flag"
    t.string   "comment_html_1",        :limit => 500
    t.string   "comment_html_2",        :limit => 500
    t.string   "comment_text_1",        :limit => 500
    t.string   "comment_text_2",        :limit => 500
    t.date     "load_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "comment_html",          :limit => 500
    t.string   "comment_html_3",        :limit => 500
    t.string   "comment_text_3",        :limit => 500
    t.string   "comment_html_4",        :limit => 500
    t.string   "comment_html_5",        :limit => 500
    t.string   "comment_text_4",        :limit => 500
    t.string   "comment_text_5",        :limit => 500
    t.string   "comment_header_html_1", :limit => 500
    t.string   "comment_header_html_2", :limit => 500
    t.string   "comment_header_html_3", :limit => 500
    t.string   "comment_header_html_4", :limit => 500
    t.string   "comment_header_html_5", :limit => 500
    t.string   "comment_header_html_6", :limit => 500
  end

  add_index "radiology_comments", ["visit_id"], :name => "ind_radiology_comments_visit_id"

  create_table "recruitment_groups", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "role"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scan_procedures", :force => true do |t|
    t.string   "codename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.integer  "protocol_id"
  end

  add_index "scan_procedures", ["protocol_id", "id"], :name => "index_scan_procedures_on_protocol_id_id"

  create_table "scan_procedures_visits", :id => false, :force => true do |t|
    t.integer "scan_procedure_id"
    t.integer "visit_id"
  end

  add_index "scan_procedures_visits", ["scan_procedure_id", "visit_id"], :name => "index_scan_procedures_visits_on_scan_procedure_id_visit_id"

  create_table "series_descriptions", :force => true do |t|
    t.string   "long_description"
    t.string   "short_description"
    t.string   "anat_type"
    t.string   "acq_plane"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ignore",            :default => "Don't Ignore"
  end

  create_table "studies", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "investigator"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "official_name"
    t.string   "irb_number"
    t.string   "prefix"
    t.string   "raw_directory"
  end

  create_table "t_access_panda_match_20120227", :id => false, :force => true do |t|
    t.integer "pkProtocolid_access",                  :default => 0, :null => false
    t.string  "access_enum",                                         :null => false
    t.integer "fkDBID"
    t.string  "panda_enumber"
    t.integer "participant_id"
    t.integer "enrollment_id",                        :default => 0, :null => false
    t.integer "fkdbid_panda"
    t.integer "reggieID_access"
    t.string  "rmr_panda",              :limit => 50
    t.string  "rmr_access_1",           :limit => 50
    t.string  "rmr_access_2",           :limit => 50
    t.string  "rmr_access_3",           :limit => 50
    t.string  "rmr_access_4",           :limit => 50
    t.string  "rmr_access_5",           :limit => 50
    t.string  "wrapnum_access",         :limit => 5
    t.string  "wrapnum_panda",          :limit => 50
    t.string  "initials_access",        :limit => 50
    t.string  "initials_panda",         :limit => 50
    t.date    "dob_access"
    t.date    "dob_panda"
    t.integer "gender_access"
    t.integer "gender_panda"
    t.string  "withdrawlReason_access", :limit => 50
    t.string  "withdrawl_reason_panda"
    t.integer "apoee1_access"
    t.integer "apoee1_panda"
    t.integer "apoee2_access"
    t.integer "apoee2_panda"
    t.string  "apoe_processor_access",  :limit => 50
    t.string  "apoe_processor_panda"
    t.string  "apoe_note_access"
    t.string  "apoe_note_panda"
    t.integer "ed_years_access"
    t.integer "ed_years_panda"
    t.string  "rmr_access_6",           :limit => 50
    t.integer "new_participant_id"
  end

  create_table "t_map_vgroup_tblVisitTable_mriscan", :id => false, :force => true do |t|
    t.integer  "pkMriScanID",                                 :default => 0,     :null => false
    t.integer  "fkAppointmentID"
    t.string   "RMR",                                                            :null => false
    t.integer  "MriTech"
    t.datetime "MriStartTime"
    t.datetime "MriEndTime"
    t.integer  "Goggles",                                     :default => 0
    t.integer  "ButtonBox",                                   :default => 0
    t.boolean  "CompletedMriFast",                            :default => false
    t.string   "ArchiveDVD",            :limit => 50
    t.integer  "pkVisitID",                                   :default => 0,     :null => false
    t.integer  "fkProtocolID",                                                   :null => false
    t.datetime "VisitDate"
    t.datetime "PCVisitDate2"
    t.integer  "VisitNumber",                                 :default => 1
    t.integer  "ResearchDiagnosis"
    t.integer  "CognitiveStatus"
    t.integer  "FamHx"
    t.boolean  "CompletedScan",                               :default => false
    t.datetime "LastEdited"
    t.string   "ScanNote"
    t.boolean  "EnteredScan",                                 :default => false
    t.datetime "EnteredScanDate"
    t.integer  "EnteredScanWho"
    t.boolean  "CompetedVitalsAndMeds",                       :default => false
    t.string   "VitalsAndMedsNote"
    t.boolean  "EnteredVitals",                               :default => false
    t.datetime "EnteredVMDate"
    t.integer  "EnteredVitalsWho"
    t.boolean  "CompletedBloodDraw",                          :default => false
    t.string   "BloodDrawNote"
    t.boolean  "EnteredBlood",                                :default => false
    t.datetime "EnteredBloodDate"
    t.integer  "EnteredBloodWho"
    t.boolean  "CompletedNPTesting",                          :default => false
    t.string   "NPTestingNote"
    t.boolean  "EnteredNP",                                   :default => false
    t.datetime "EnteredNPDate"
    t.integer  "EnteredNPWho"
    t.boolean  "SimulationScan",                              :default => false
    t.string   "SimulationScanNote"
    t.string   "RadiologyNote",         :limit => 75
    t.boolean  "EnteredRadiology",                            :default => false
    t.datetime "EnteredRadiologyDate"
    t.integer  "EnteredRadiologyWho"
    t.boolean  "FurtherStudies",                              :default => false
    t.integer  "ClinicDx",                                    :default => 0
    t.integer  "StudyDx",                                     :default => 0
    t.boolean  "CompletedFast",                               :default => false
    t.string   "FastNote"
    t.boolean  "CompletedPetScan",                            :default => false
    t.string   "PetScanNote"
    t.boolean  "EnteredPetScan",                              :default => false
    t.datetime "EnteredPetScanDate"
    t.integer  "EnteredPetScanWho"
    t.boolean  "CompletedLP",                                 :default => false
    t.string   "LPNote"
    t.boolean  "EnteredLP",                                   :default => false
    t.datetime "EnteredLPDate"
    t.integer  "EnteredLPWho"
    t.integer  "pkAppointmentID",                             :default => 0,     :null => false
    t.integer  "fkVisitID",                                                      :null => false
    t.datetime "AppointmentDate"
    t.text     "AppointmentComment",    :limit => 2147483647
    t.integer  "Researcher"
    t.integer  "pkProtocolID",                                :default => 0,     :null => false
    t.integer  "fkDBID"
    t.string   "ENUM",                                                           :null => false
    t.integer  "DX",                                                             :null => false
    t.integer  "ConsentCohort"
    t.integer  "Cohort",                                      :default => 0
    t.integer  "ResearchDX"
    t.integer  "ResearchDX_Cohort"
    t.integer  "fkProtocolTypeID"
    t.integer  "RESEARCH"
    t.string   "dem notes",             :limit => 50
    t.datetime "enrolldate"
    t.integer  "fkSubjectStatusID",                           :default => 3
    t.string   "WithdrawalReason",      :limit => 50
    t.string   "Recruitsource",         :limit => 50
    t.boolean  "REPSUP",                                      :default => false
    t.boolean  "CompletedEligibility",                        :default => false
    t.boolean  "EnteredEligibility",                          :default => false
    t.boolean  "CompletedDemo&Meds",                          :default => false
    t.boolean  "EnteredDemo",                                 :default => false
    t.boolean  "EnteredMeds",                                 :default => false
    t.string   "PCScreenNum",           :limit => 50
    t.boolean  "SelfControlSet",                              :default => false
    t.integer  "ConsentForm",                                 :default => 0
    t.integer  "vgroup_id"
  end

  create_table "t_map_visit", :id => false, :force => true do |t|
    t.integer  "access_protocolid",                   :default => 0, :null => false
    t.integer  "access_id"
    t.string   "access_enum",                                        :null => false
    t.datetime "access_visit_date"
    t.integer  "access_visit_id",                     :default => 0, :null => false
    t.integer  "access_appointment_id",               :default => 0, :null => false
    t.string   "access_rmr",                                         :null => false
    t.integer  "panda_visit_id"
    t.date     "panda_date"
    t.string   "panda_initials",        :limit => 20
    t.string   "panda_rmr",             :limit => 50
    t.string   "access_initials",       :limit => 20
  end

  create_table "t_new_participants_20120229", :id => false, :force => true do |t|
    t.string  "rmr"
    t.string  "initials"
    t.integer "enrollment_id"
    t.integer "participant_id"
  end

  create_table "t_protocol_access_panda_map", :id => false, :force => true do |t|
    t.integer "pkprotocoltypeid",               :default => 0, :null => false
    t.string  "protocolname",     :limit => 50
    t.integer "protocol_id",                    :default => 0, :null => false
    t.string  "name"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email",                                    :default => "", :null => false
    t.string   "encrypted_password",        :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                            :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "role"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "vgroups", :force => true do |t|
    t.date     "vgroup_date"
    t.integer  "participant_id"
    t.string   "note"
    t.string   "transfer_mri"
    t.string   "transfer_pet"
    t.string   "blood_draw"
    t.string   "np_testing"
    t.string   "lumbar_punture"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "visits", :force => true do |t|
    t.date     "date"
    t.integer  "scan_number"
    t.string   "initials"
    t.string   "rmr"
    t.string   "radiology_outcome",                  :default => "no"
    t.string   "notes",              :limit => 2000
    t.string   "transfer_mri",                       :default => "no"
    t.string   "transfer_pet",                       :default => "no"
    t.string   "conference",                         :default => "no"
    t.string   "compile_folder",                     :default => "no"
    t.string   "dicom_dvd",                          :default => "no"
    t.integer  "user_id"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "radiology_note",                     :default => "no"
    t.string   "research_diagnosis"
    t.string   "consent_form_type"
    t.string   "scanner_source"
    t.integer  "created_by_id"
    t.string   "dicom_study_uid"
    t.date     "compiled_at"
    t.integer  "vgroup_id"
    t.integer  "appointment_id"
    t.integer  "temp_fkMRIscanid"
  end

  add_index "visits", ["id"], :name => "index_visits_on_id"

end
