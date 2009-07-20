class AddGlobToImageDatasets < ActiveRecord::Migration
  def self.up
    add_column :image_datasets, :glob, :string
  end

  def self.down
    remove_column :image_datasets, :glob
  end
end
