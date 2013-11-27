class ChangeAssigneeToUserId < ActiveRecord::Migration
  def self.up
    change_column(:visits, :assignee, :integer)
    rename_column(:visits, :assignee, :user_id)
  end

  def self.down
    rename_column(:visits, :user_id, :assignee)
    change_column(:visits, :assignee, :string)
  end
end
