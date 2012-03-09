class CreateMedicationdetails < ActiveRecord::Migration
  def self.up
    create_table :medicationdetails do |t|
      t.string :genericname
      t.string :brandname
      t.integer :lookup_drugclass_id
      t.integer :prescription
      t.integer :exclusionclass

      t.timestamps
    end
  end

  def self.down
    drop_table :medicationdetails
  end
end
