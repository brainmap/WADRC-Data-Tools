class AddDicomDvd < ActiveRecord::Migration
  def self.up
    add_column :transfers, :dicom_dvd, :text
  end

  def self.down
    remove_column :transfers, :dicom_dvd
  end
end