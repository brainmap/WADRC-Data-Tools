class RemoveUserInitialsColumn < ActiveRecord::Migration
  def self.up
    remove_column :users, :initials
  end

  def self.down
    add_column :users, :initials, :string
  end
end
