class AddLogFileEntriesLogFileId < ActiveRecord::Migration
  def self.up
    add_column :log_file_entries, :log_file_id, :integer
  end

  def self.down
    remove_column :log_file_entries, :log_file_id
  end
end
