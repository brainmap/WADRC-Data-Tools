class AddAssigneeToVisitTable < ActiveRecord::Migration
  def self.up
     add_column :visits, :assignee, :string
   end

   def self.down
     remove_column :visits, :assignee
   end
end
