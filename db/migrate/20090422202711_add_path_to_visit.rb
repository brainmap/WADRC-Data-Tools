class AddPathToVisit < ActiveRecord::Migration
  def self.up
    add_column :visits, :path, :string
  end

  def self.down
    remove_column :visits, :path
  end
end
