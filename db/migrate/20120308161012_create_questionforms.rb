class CreateQuestionforms < ActiveRecord::Migration
  def self.up
    create_table :questionforms do |t|
      t.string :description
      t.string :long_description
      t.integer :display_order
      t.integer :parent_questionform_id

      t.timestamps
    end
  end

  def self.down
    drop_table :questionforms
  end
end
