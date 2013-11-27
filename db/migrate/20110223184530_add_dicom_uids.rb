class AddDicomUids < ActiveRecord::Migration
  def self.up
    add_column :visits, :dicom_study_uid, :string
    add_column :image_datasets, :dicom_series_uid, :string
    add_column :image_datasets, :dicom_taghash, :text
  end

  def self.down
    remove_column :visits, :dicom_study_uid
    remove_column :image_datasets, :dicom_series_uid
    remove_column :image_datasets, :dicom_taghash
  end
end
