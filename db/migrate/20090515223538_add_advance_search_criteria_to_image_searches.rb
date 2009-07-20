class AddAdvanceSearchCriteriaToImageSearches < ActiveRecord::Migration
  def self.up
    add_column :image_searches, :enum, :string
    add_column :image_searches, :gender, :integer
    add_column :image_searches, :min_age, :integer
    add_column :image_searches, :max_age, :integer
    add_column :image_searches, :min_ed_years, :integer
    add_column :image_searches, :max_ed_years, :integer
    add_column :image_searches, :apoe_status, :integer
  end

  def self.down
    remove_column :image_searches, :enum
    remove_column :image_searches, :gender 
    remove_column :image_searches, :min_age
    remove_column :image_searches, :max_age
    remove_column :image_searches, :min_ed_years
    remove_column :image_searches, :max_ed_years
    remove_column :image_searches, :apoe_status 
  end
end
