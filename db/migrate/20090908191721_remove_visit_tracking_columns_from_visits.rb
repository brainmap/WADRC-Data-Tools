class RemoveVisitTrackingColumnsFromVisits < ActiveRecord::Migration
  def self.up
    remove_column :visits, :transfer_behavioral_log
    remove_column :visits, :check_imaging
    remove_column :visits, :check_np
    remove_column :visits, :check_MR5_DVD
    remove_column :visits, :burn_DICOM_DVD
    remove_column :visits, :first_score
    remove_column :visits, :second_score
    remove_column :visits, :enter_info_in_db
  end

  def self.down
    add_column :visits, :transfer_behavioral_log, :string
    add_column :visits, :check_imaging,           :string
    add_column :visits, :check_np,                :string
    add_column :visits, :check_MR5_DVD,           :string
    add_column :visits, :burn_DICOM_DVD,          :string
    add_column :visits, :first_score,             :string
    add_column :visits, :second_score,            :string
    add_column :visits, :enter_info_in_db,        :string
  end
end
