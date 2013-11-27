class DropDatasetKeyFromImageDatasets < ActiveRecord::Migration
  def self.up
    remove_column :image_datasets, :dataset_key
  end

  def self.down
    add_column :image_datasets, :dataset_key, :string
  end
end
