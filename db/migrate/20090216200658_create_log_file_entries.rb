class CreateLogFileEntries < ActiveRecord::Migration
  def self.up
    create_table :log_file_entries do |t|
      t.string :filename, :stimulus_type, :response_type
      t.integer :stimulus_code, :stimulus_time, :response_code, :response_time
      t.timestamps
    end
  end

  def self.down
    drop_table :log_file_entries
  end
end
