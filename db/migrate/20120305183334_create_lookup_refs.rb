class CreateLookupRefs < ActiveRecord::Migration
  def self.up
    create_table :lookup_refs do |t|
      t.integer :ref_value
      t.string :description
      t.integer :display_order
      t.string :label

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_refs
  end
end
