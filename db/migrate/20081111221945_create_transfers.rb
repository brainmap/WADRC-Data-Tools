class CreateTransfers < ActiveRecord::Migration
  def self.up
    create_table :transfers do |t|
      t.date :date
      t.integer :protocol_id, :null => false
      t.integer :scan_number
      t.string :enum, :initials, :rmr, :rad_review, :notes
      t.string :transfer_mri
      t.string :transfer_pet
      t.string :transfer_behavioral_log
      t.string :check_imaging
      t.string :check_np
      t.string :check_MR5_DVD
      t.string :burn_DICOM_DVD
      t.string :first_score, :second_score
      t.string :enter_info_in_db
      t.string :conference
      t.string :compile_folder
    end
  end

  def self.down
    drop_table :transfers
  end
end
