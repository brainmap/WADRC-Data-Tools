class RemoveRfNoiseFromImageDatasetQualityChecks < ActiveRecord::Migration
  def self.up
    remove_column :image_dataset_quality_checks, :rf_noise
    remove_column :image_dataset_quality_checks, :rf_noise_comment
  end

  def self.down
    add_column :image_dataset_quality_checks, :rf_noise, :string
    add_column :image_dataset_quality_checks, :rf_noise_comment, :text
  end
end
