class CreateLookupDrugclasses < ActiveRecord::Migration
  def self.up
    create_table :lookup_drugclasses do |t|
      t.string :epodrugclass
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_drugclasses
  end
end
