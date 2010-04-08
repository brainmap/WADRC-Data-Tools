class AddQuestionToHelps < ActiveRecord::Migration
  def self.up
    add_column :helps, :question, :string
    add_column :helps, :answer, :string
  end

  def self.down
    remove_column :helps, :question
    remove_column :helps, :answer
  end
end
