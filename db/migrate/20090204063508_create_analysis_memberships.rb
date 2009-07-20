class CreateAnalysisMemberships < ActiveRecord::Migration
  def self.up
    create_table :analysis_memberships do |t|
      t.integer :analysis_id
      t.integer :image_dataset_id
      t.boolean :excluded, :default => false
      t.string :exclusion_comment

      t.timestamps
    end
  end

  def self.down
    drop_table :analysis_memberships
  end
end
