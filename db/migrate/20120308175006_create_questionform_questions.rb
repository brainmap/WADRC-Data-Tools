class CreateQuestionformQuestions < ActiveRecord::Migration
  def self.up
    create_table :questionform_questions do |t|
      t.integer :questionform_id
      t.integer :question_id

      t.timestamps
    end
  end

  def self.down
    drop_table :questionform_questions
  end
end
