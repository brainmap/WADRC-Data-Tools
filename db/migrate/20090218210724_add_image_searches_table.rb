class AddImageSearchesTable < ActiveRecord::Migration
  def self.up
    create_table :image_searches do |t|
      t.string :rmr
      t.string :series_description
      t.string :path
      t.datetime :earliest_timestamp
      t.datetime :latest_timestamp

      t.timestamps
    end
  end

  def self.down
    drop_table :image_searches
  end
end
