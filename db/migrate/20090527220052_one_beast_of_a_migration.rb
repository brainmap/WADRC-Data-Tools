class OneBeastOfAMigration < ActiveRecord::Migration
  def self.up
    
    change_table :image_dataset_quality_checks do |t|
      t.remove :assessment
      t.remove :note
      
      t.string :incomplete_series, :garbled_series, :fov_cutoff, :field_inhomogeneity, :ghosting_wrapping
      t.string :banding, :registration_risk, :motion_warning, :omnibus_f, :spm_mask
      t.text   :incomplete_series_comment, :garbled_series_comment, :fov_cutoff_comment, :ghosting_wrapping_comment
      t.text   :banding_comment, :registration_risk_comment, :motion_warning_comment, :omnibus_f_comment, :spm_mask_comment
      t.text   :other_issues
    end
=begin
    change_table :protocols do |t|
      t.remove :investigator
      t.remove :study
      t.remove :visit_number
      
      t.rename :name, :codename
      t.rename :procedure, :description
      
      t.decimal :version
    end
    rename_table :protocols, :scan_procedures
=end  
    change_table :visits do |t|
      t.remove :enum
      
      t.rename :protocol_id, :scan_procedure_id
      t.rename :rad_review, :radiology_outcome
      
      t.text    :radiology_note
      t.integer :enrollment_id
      t.string  :research_diagnosis
      t.string  :consent_form_type
    end
    
    change_table :participants do |t|
      t.remove :quality_redflag
      t.remove :wrapenroll
      t.remove :wrapnum
    end
    
    change_table :log_files do |t|
      t.integer  :image_dataset_id
      t.integer  :visit_id
    end
    
    change_table :image_searches_protocols do |t|
      t.rename :protocol_id, :scan_procedure_id
    end
    rename_table :image_searches_protocols, :image_searches_scan_procedures
    
    create_table :enrollments do |t|
      t.date        :enroll_date
      t.string      :enum
      t.string      :recruitment_source
      t.integer     :wrapnum
      t.references  :recruitment_group
      t.references  :participant
      t.timestamps
    end
    
    create_table :withdrawls do |t|
      t.date        :withdrawl_date
      t.text        :reason
      t.references  :enrollment
      t.timestamps
    end
    
    create_table :recruitment_groups do |t|
      t.string      :name
      t.text        :description
      t.references  :study
      t.timestamps
    end
    
    create_table :studies do |t|
      t.string     :name
      t.text       :description
      t.string     :investigator
      t.timestamps
    end
  end

  def self.down
    
    drop_table :studies
    drop_table :recruitment_groups
    drop_table :withdrawls
    drop_table :enrollments
    
    rename_table :image_searches_scan_procedures, :image_searches_protocols
    change_table :image_searches_protocols do |t|
      t.rename :scan_procedure_id, :protocol_id
    end
    
    change_table :log_files do |t|
      t.remove :visit_id
      t.remove :image_dataset_id
    end
    
    change_table :participants do |t|
      t.string  :wrapnum
      t.integer :wrapenroll
      t.integer :quality_redflag
    end
    
    change_table :visits do |t|
      t.string :enum
      
      t.rename :scan_procedure_id, :protocol_id
      t.rename :radiology_outcome, :rad_review
      
      t.remove :radiology_note
      t.remove :enrollment_id
      t.remove :research_diagnosis
      t.remove :consent_form_type
    end
    
    rename_table :scan_procedures, :protocols
    change_table :protocols do |t|
      t.string  :investigator
      t.string  :study
      t.integer :visit_number
      
      t.rename :codename, :name
      t.rename :description, :procedure
      
      t.remove :version
    end
    
    change_table :image_dataset_quality_checks do |t|
      t.string :assessment
      t.text   :note
      
      t.remove :incomplete_series, :garbled_series, :fov_cutoff, :field_inhomogeneity, :ghosting_wrapping
      t.remove :banding, :registration_risk, :motion_warning, :omnibus_f, :spm_mask
      t.remove :incomplete_series_comment, :garbled_series_comment, :fov_cutoff_comment, :ghosting_wrapping_comment
      t.remove :banding_comment, :registration_risk_comment, :motion_warning_comment, :omnibus_f_comment, :spm_mask_comment
      t.remove :other_issues
    end
    
  end
end
