class CreateLookupDrugfreqs < ActiveRecord::Migration
  def self.up
    create_table :lookup_drugfreqs do |t|
      t.string :frequency
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_drugfreqs
  end
end
