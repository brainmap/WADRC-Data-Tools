class AddIndexToImageDatasets < ActiveRecord::Migration
  def self.up
    add_index :image_datasets, :dicom_series_uid, :unique => true
    # add_index :image_datasets, :path, :unique => true
  end

  def self.down
    remove_index :image_datasets, :dicom_series_uid
    # remove_index :image_datasets, :path
  end
end
