class CreateImageDatasetQualityChecks < ActiveRecord::Migration
  def self.up
    create_table :image_dataset_quality_checks do |t|
      t.string :assessment
      t.string :note
      t.integer :user_id
      t.integer :image_dataset_id

      t.timestamps
    end
  end

  def self.down
    drop_table :image_dataset_quality_checks
  end
end
