class DropAttributesFromAnalyses < ActiveRecord::Migration
  def self.up
    remove_column :analyses, :timestamp
    remove_column :analyses, :start_date
    remove_column :analyses, :end_date
    remove_column :analyses, :series_description
  end

  def self.down
    add_column :analyses, :timestamp, :timestamp
    add_column :analyses, :start_date, :timestamp
    add_column :analyses, :end_date, :end_date
    add_column :analyses, :series_description, :string
  end
end
