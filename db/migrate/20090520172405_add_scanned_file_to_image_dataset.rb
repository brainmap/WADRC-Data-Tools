class AddScannedFileToImageDataset < ActiveRecord::Migration
  def self.up
    add_column :image_datasets, :scanned_file, :string
  end

  def self.down
    remove_column :image_datasets, :scanned_file
  end
end
