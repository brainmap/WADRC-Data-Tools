class AddNosConcernsToImageDatasetQualityChecks < ActiveRecord::Migration
  def self.up
    add_column :image_dataset_quality_checks, :nos_concerns, :string
    add_column :image_dataset_quality_checks, :nos_concerns_comment, :text
  end

  def self.down
    remove_column :image_dataset_quality_checks, :nos_concerns_comment
    remove_column :image_dataset_quality_checks, :nos_concerns
  end
end
