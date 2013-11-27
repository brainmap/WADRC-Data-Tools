class CreateImageDatasets < ActiveRecord::Migration
  def self.up
    create_table :image_datasets do |t|
      t.string :rmr
      t.string :series_description
      t.string :path
      t.datetime :timestamp


      t.timestamps
    end
  end

  def self.down
    drop_table :image_datasets
  end
end
