class CreateLogFiles < ActiveRecord::Migration
  def self.up
    create_table :log_files do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :log_files
  end
end
