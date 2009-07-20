class ChangeSlicesInDatasetToSlicesPerVol < ActiveRecord::Migration
  def self.up
    rename_column :image_datasets, :slices_in_dataset, :slices_per_volume
  end

  def self.down
    rename_column :image_datasets, :slices_per_volume, :slices_in_dataset
  end
end
