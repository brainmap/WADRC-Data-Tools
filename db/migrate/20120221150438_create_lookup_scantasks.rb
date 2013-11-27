class CreateLookupScantasks < ActiveRecord::Migration
  def self.up
    create_table :lookup_scantasks do |t|
      t.string :description
      t.string :name
      t.string :pulse_sequence_code
      t.string :bold_reps
      t.integer :task_code
      t.integer :set_id

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_scantasks
  end
end
