class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.string :heading_1
      t.string :phrase_a_1
      t.string :value_type_1
      t.string :ref_table_a_1
      t.string :ref_table_b_1
      t.string :phrase_b_1
      t.string :phrase_c_1
      t.string :required_y_n_1
      t.string :heading_2
      t.string :phrase_a_2
      t.string :value_type_2
      t.string :ref_table_a_2
      t.string :ref_table_b_2
      t.string :phrase_b_2
      t.string :phrase_c_2
      t.string :required_y_n_2
      t.string :heading_3
      t.string :phrase_a_3
      t.string :value_type_3
      t.string :ref_table_a_3
      t.string :ref_table_b_3
      t.string :phrase_b_3
      t.string :phrase_c_3
      t.string :required_y_n_3
      t.integer :display_order
      t.string :status
      t.integer :parent_question_id
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :questions
  end
end
