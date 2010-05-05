class DropTaggings < ActiveRecord::Migration
  def self.up
    drop_table :taggings
  end

  def self.down
    create_table :taggings do |t|
      t.integer :help_id
      t.integer :tag_id

      t.timestamps
    end
  end
end
