class CreateLookupSwitchboards < ActiveRecord::Migration
  def self.up
    create_table :lookup_switchboards do |t|
      t.string :description
      t.integer :item_number
      t.string :command
      t.string :argument

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_switchboards
  end
end
