class AddTimestampsToVisitsTable < ActiveRecord::Migration
  def self.up
    change_table :visits do |t|
      t.timestamps
    end
  end

  def self.down
    remove_column :visits, :created_at
    remove_column :visits, :updated_at
  end
end
