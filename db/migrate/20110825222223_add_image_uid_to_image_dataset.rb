class AddImageUidToImageDataset < ActiveRecord::Migration
  def self.up
    add_column :image_datasets, :image_uid, :string
  end

  def self.down
    remove_column :image_datasets, :image_uid
  end
end
