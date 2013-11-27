class CreateLookupDrugunits < ActiveRecord::Migration
  def self.up
    create_table :lookup_drugunits do |t|
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_drugunits
  end
end
