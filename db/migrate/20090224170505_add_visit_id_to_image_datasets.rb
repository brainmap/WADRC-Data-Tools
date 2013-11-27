class AddVisitIdToImageDatasets < ActiveRecord::Migration
  def self.up
    add_column :image_datasets, :visit_id, :integer
  end

  def self.down
    remove_column :image_datasets, :visit_id
  end
end
