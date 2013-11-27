class AddUserIdToImageSearches < ActiveRecord::Migration
  def self.up
    add_column :image_searches, :user_id, :integer
  end

  def self.down
    remove_column :image_searches, :user_id
  end
end
