class AddScannerSourceToVisits < ActiveRecord::Migration
  def self.up
    change_table :visits do |t|
      t.string :scanner_source
    end
  end

  def self.down
    change_table :visits do |t|
      t.remove :scanner_source
    end
  end
end
