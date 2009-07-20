class AddFunctionalParamsToImageDataset < ActiveRecord::Migration
  def self.up
    add_column :image_datasets, :rep_time, :decimal
    add_column :image_datasets, :bold_reps, :integer
    add_column :image_datasets, :slices_in_dataset, :integer
  end

  def self.down
    remove_column :image_datasets, :rep_time
    remove_column :image_datasets, :bold_reps
    remove_column :image_datasets, :slices_in_dataset
  end
end
