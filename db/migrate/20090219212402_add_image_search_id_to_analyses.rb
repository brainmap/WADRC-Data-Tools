class AddImageSearchIdToAnalyses < ActiveRecord::Migration
  def self.up
    add_column :analyses, :image_search_id, :integer
  end

  def self.down
    remove_column :analyses, :image_search_id
  end
end
