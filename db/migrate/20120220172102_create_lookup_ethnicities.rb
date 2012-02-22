class CreateLookupEthnicities < ActiveRecord::Migration
  def self.up
    create_table :lookup_ethnicities do |t|
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_ethnicities
  end
end
