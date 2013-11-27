class CreateLookupStatuses < ActiveRecord::Migration
  def self.up
    create_table :lookup_statuses do |t|
      t.string :description
      t.integer :status_type

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_statuses
  end
end
