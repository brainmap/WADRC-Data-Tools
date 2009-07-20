class AddFieldInhomogeneityCommentToQualityCheck < ActiveRecord::Migration
  def self.up
    change_table :image_dataset_quality_checks do |t|
      t.text :field_inhomogeneity_comment
    end
  end

  def self.down
    change_table :image_dataset_quality_checks do |t|
      t.remove :field_inhomogeneity_comment
    end
  end
end
