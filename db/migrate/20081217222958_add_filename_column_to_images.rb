class AddFilenameColumnToImages < ActiveRecord::Migration
  def self.up
    #add_column :images, :file, :text
  end

  def self.down
    #remove_column :images, :file
  end
end
