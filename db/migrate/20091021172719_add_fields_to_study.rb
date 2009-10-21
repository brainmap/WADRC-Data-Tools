class AddFieldsToStudy < ActiveRecord::Migration
  def self.up
    add_column :studies, :official_name, :string
    add_column :studies, :irb_number, :string
    add_column :studies, :prefix, :string
    add_column :studies, :raw_directory, :string
  end

  def self.down
    remove_column :studies, :raw_directory
    remove_column :studies, :prefix
    remove_column :studies, :irb_number
    remove_column :studies, :official_name
  end
end
