class AddDefaultsToVisits < ActiveRecord::Migration
  def self.up
    change_table :visits do |t|
      t.change :radiology_outcome, :string, :default => 'no'
      t.change :transfer_mri, :string, :default => 'no'
      t.change :transfer_pet, :string, :default => 'no'
      t.change :transfer_behavioral_log, :string, :default => 'no'
      t.change :check_imaging, :string, :default => 'no'
      t.change :check_np, :string, :default => 'no'
      t.change :check_MR5_DVD, :string, :default => 'no'
      t.change :burn_DICOM_DVD, :string, :default => 'no'
      t.change :first_score, :string, :default => 'no'
      t.change :second_score, :string, :default => 'no'
      t.change :enter_info_in_db, :string, :default => 'no'
      t.change :conference, :string, :default => 'no'
      t.change :compile_folder, :string, :default => 'no'
      t.change :dicom_dvd, :string, :default => 'no'
      t.change :radiology_note, :text, :default => 'no'
    end
  end

  def self.down
    change_table :visits do |t|
      t.change :radiology_outcome, :string
      t.change :transfer_mri, :string
      t.change :transfer_pet, :string
      t.change :transfer_behavioral_log, :string
      t.change :check_imaging, :string
      t.change :check_np, :string
      t.change :check_MR5_DVD, :string
      t.change :burn_DICOM_DVD, :string
      t.change :first_score, :string
      t.change :second_score, :string
      t.change :enter_info_in_db, :string
      t.change :conference, :string
      t.change :compile_folder, :string
      t.change :dicom_dvd, :string
      t.change :radiology_note, :text
    end
  end
end
