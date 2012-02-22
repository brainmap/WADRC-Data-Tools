class CreateLookupHardwares < ActiveRecord::Migration
  def self.up
    create_table :lookup_hardwares do |t|
      t.string :hardwaretype
      t.string :hardwaregroup

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_hardwares
  end
end
