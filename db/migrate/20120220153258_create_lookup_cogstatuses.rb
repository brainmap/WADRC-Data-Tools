class CreateLookupCogstatuses < ActiveRecord::Migration
  def self.up
    create_table :lookup_cogstatuses do |t|
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_cogstatuses
  end
end
