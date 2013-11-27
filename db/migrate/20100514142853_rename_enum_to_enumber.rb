class RenameEnumToEnumber < ActiveRecord::Migration
  def self.up
    rename_column :enrollments, :enum, :enumber
  end

  def self.down
    rename_column :enrollments, :enumber, :enum
  end
end
