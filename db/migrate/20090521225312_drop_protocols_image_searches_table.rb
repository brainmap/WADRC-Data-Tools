class DropProtocolsImageSearchesTable < ActiveRecord::Migration
  def self.up
    drop_table :protocols_image_searches
  end

  def self.down
    create_table :protocols_image_searches, :id => false do |t|
      t.references :image_search
      t.references :protocol
      t.timestamps
    end
  end
end
