class AddImageDatasetId < ActiveRecord::Migration
  def self.up
    add_column :raw_image_files, :image_dataset_id, :integer
  end

  def self.down
    remove_column :raw_image_files, :image_dataset_id
  end
end
