class CreateImageSearchesProtocolsTable < ActiveRecord::Migration
  def self.up
    create_table :image_searches_protocols, :id => false do |t|
      t.references :image_search
      t.references :protocol
      t.timestamps
    end
  end

  def self.down
    drop_table :image_searches_protocols
  end
end
