class RenameEnumToEnumberInImageDatasetSearches < ActiveRecord::Migration
  def self.up
    rename_column :image_searches, :enum, :enumber
  end

  def self.down
    rename_column :image_searches, :enumber, :enum
  end
end
