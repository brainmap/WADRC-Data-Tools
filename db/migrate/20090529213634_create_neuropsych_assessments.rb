class CreateNeuropsychAssessments < ActiveRecord::Migration
  def self.up
    create_table :neuropsych_assessments do |t|
      t.decimal :score
      t.string :score_type
      t.string :test_name
      t.text :note
      
      t.references :neuropsych_session

      t.timestamps
    end
  end

  def self.down
    drop_table :neuropsych_assessments
  end
end
