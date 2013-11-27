class CreateLookupFamhxes < ActiveRecord::Migration
  def self.up
    create_table :lookup_famhxes do |t|
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_famhxes
  end
end
