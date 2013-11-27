class AddDatasetKeyToRawImageDatasets < ActiveRecord::Migration
  def self.up
    add_column :image_datasets, :dataset_key, :string
  end

  def self.down
    remove_column :image_datasets, :dataset_key
  end
end
