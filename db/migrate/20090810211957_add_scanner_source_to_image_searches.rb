class AddScannerSourceToImageSearches < ActiveRecord::Migration
  def self.up
    change_table :image_searches do |t|
      t.string :scanner_source
    end
  end

  def self.down
    change_table :image_searches do |t|
      t.remove :scanner_source
    end
  end
end
