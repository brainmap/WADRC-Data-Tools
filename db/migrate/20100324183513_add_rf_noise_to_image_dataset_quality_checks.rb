class AddRfNoiseToImageDatasetQualityChecks < ActiveRecord::Migration
  def self.up
    add_column :image_dataset_quality_checks, :rf_noise, :string
    add_column :image_dataset_quality_checks, :rf_noise_comment, :text
  end

  def self.down
    remove_column :image_dataset_quality_checks, :rf_noise
    remove_column :image_dataset_quality_checks, :rf_noise_comment
  end
end
