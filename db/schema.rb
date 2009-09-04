# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090904162510) do

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

  create_table "enrollments", :force => true do |t|
    t.date     "enroll_date"
    t.string   "enum"
    t.string   "recruitment_source"
    t.integer  "recruitment_group_id"
    t.integer  "participant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "withdrawl_reason"
  end

  create_table "image_comments", :force => true do |t|
    t.integer  "image_dataset_id", :null => false
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

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
  end

  create_table "image_searches", :force => true do |t|
    t.string   "rmr"
    t.string   "series_description"
    t.string   "path"
    t.datetime "earliest_timestamp"
    t.datetime "latest_timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "enum"
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

  create_table "recruitment_groups", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scan_procedures", :force => true do |t|
    t.string   "codename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
  end

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
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "first_name"
    t.string   "last_name"
  end

  create_table "visits", :force => true do |t|
    t.date     "date"
    t.integer  "scan_procedure_id",                                        :null => false
    t.integer  "scan_number"
    t.string   "initials"
    t.string   "rmr"
    t.string   "radiology_outcome",                      :default => "no"
    t.string   "notes"
    t.string   "transfer_mri",                           :default => "no"
    t.string   "transfer_pet",                           :default => "no"
    t.string   "transfer_behavioral_log",                :default => "no"
    t.string   "check_imaging",                          :default => "no"
    t.string   "check_np",                               :default => "no"
    t.string   "check_MR5_DVD",                          :default => "no"
    t.string   "burn_DICOM_DVD",                         :default => "no"
    t.string   "first_score",                            :default => "no"
    t.string   "second_score",                           :default => "no"
    t.string   "enter_info_in_db",                       :default => "no"
    t.string   "conference",                             :default => "no"
    t.string   "compile_folder",                         :default => "no"
    t.string   "dicom_dvd",                              :default => "no"
    t.integer  "user_id",                 :limit => 255
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "radiology_note",                         :default => "no"
    t.integer  "enrollment_id"
    t.string   "research_diagnosis"
    t.string   "consent_form_type"
    t.string   "scanner_source"
  end

end
