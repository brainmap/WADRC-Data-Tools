class AddCreatedByIdToVisits < ActiveRecord::Migration
  def self.up
    add_column :visits, :created_by_id, :integer
  end

  def self.down
    remove_column :visits, :created_by_id
  end
end
