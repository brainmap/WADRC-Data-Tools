class CreateLookupRelationships < ActiveRecord::Migration
  def self.up
    create_table :lookup_relationships do |t|
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_relationships
  end
end
