class CreateLookupPettracers < ActiveRecord::Migration
  def self.up
    create_table :lookup_pettracers do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_pettracers
  end
end
