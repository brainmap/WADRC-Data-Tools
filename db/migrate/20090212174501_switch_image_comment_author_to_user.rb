class SwitchImageCommentAuthorToUser < ActiveRecord::Migration
  def self.up
    add_column :image_comments, :user_id, :integer
    remove_column :image_comments, :name
  end

  def self.down
    remove_column :image_comments, :user_id
    add_column :image_comments, :name, :string
  end
end
