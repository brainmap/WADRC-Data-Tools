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

ActiveRecord::Schema.define(:version => 20120126200720) do

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
    t.decimal  "rep_time"
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

  create_table "neuropsych_assessments", :force => true do |t|
    t.decimal  "score"
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
    t.string   "comment_html_1"
    t.string   "comment_html_2"
    t.string   "comment_html_3"
    t.string   "comment_html_4"
    t.string   "comment_html_5"   
    t.string   "comment_header_html_1"
    t.string   "comment_header_html_2"
    t.string   "comment_header_html_3"
    t.string   "comment_header_html_4"
    t.string   "comment_header_html_5"   
    t.string   "comment_text_1"
    t.string   "comment_text_2"
    t.string   "comment_text_3"
    t.string   "comment_text_4"
    t.string   "comment_text_5"
    t.date     "load_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.text     "ignore",            :default => "Don't Ignore"
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

# Could not dump table "users_bak" because of following StandardError
#   Unknown type '' for column 'id'

  create_table "visits", :force => true do |t|
    t.date     "date"
    t.integer  "scan_number"
    t.string   "initials"
    t.string   "rmr"
    t.string   "radiology_outcome",                 :default => "no"
    t.string   "notes"
    t.string   "transfer_mri",                      :default => "no"
    t.string   "transfer_pet",                      :default => "no"
    t.string   "conference",                        :default => "no"
    t.string   "compile_folder",                    :default => "no"
    t.string   "dicom_dvd",                         :default => "no"
    t.integer  "user_id",            :limit => 255
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "radiology_note",                    :default => "no"
    t.string   "research_diagnosis"
    t.string   "consent_form_type"
    t.string   "scanner_source"
    t.integer  "created_by_id"
    t.string   "dicom_study_uid"
    t.date     "compiled_at"
  end

  add_index "visits", ["id"], :name => "index_visits_on_id"

end
