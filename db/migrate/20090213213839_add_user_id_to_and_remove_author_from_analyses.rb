class AddUserIdToAndRemoveAuthorFromAnalyses < ActiveRecord::Migration
  def self.up
    remove_column :analyses, :author
    add_column :analyses, :user_id, :integer
  end

  def self.down
    remove_column :analyses, :user_id
    add_column :analyses, :author, :string
  end
end
