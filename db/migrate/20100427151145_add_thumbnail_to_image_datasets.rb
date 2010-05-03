class AddThumbnailToImageDatasets < ActiveRecord::Migration
  def self.up
    add_column :image_datasets, :thumbnail_file_name, :string  
    add_column :image_datasets, :thumbnail_content_type, :string  
    add_column :image_datasets, :thumbnail_file_size, :integer  
    add_column :image_datasets, :thumbnail_updated_at, :datetime
  end

  def self.down
    remove_column :image_datasets, :thumbnail_file_name, :string  
    remove_column :image_datasets, :thumbnail_content_type, :string  
    remove_column :image_datasets, :thumbnail_file_size, :integer  
    remove_column :image_datasets, :thumbnail_updated_at, :datetime
  end
end
