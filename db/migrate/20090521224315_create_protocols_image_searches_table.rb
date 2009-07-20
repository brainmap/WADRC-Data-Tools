class CreateProtocolsImageSearchesTable < ActiveRecord::Migration
  def self.up
    create_table :protocols_image_searches, :id => false do |t|
      t.references :image_search
      t.references :protocol
      t.timestamps
    end
  end

  def self.down
    drop_table :protocols_image_searches
  end
end
