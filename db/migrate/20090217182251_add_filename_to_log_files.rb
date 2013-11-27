class AddFilenameToLogFiles < ActiveRecord::Migration
  def self.up
    add_column :log_files, :filename, :string
  end

  def self.down
    remove_co.umn :log_files, :filename
  end
end
