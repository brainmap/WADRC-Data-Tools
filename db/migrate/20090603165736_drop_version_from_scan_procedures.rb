class DropVersionFromScanProcedures < ActiveRecord::Migration
=begin
  def self.up
    change_table :scan_procedures do |t|
      t.remove :version
    end
  end

  def self.down
    change_table :scan_procedures do |t|
      t.decimal :version
    end
  end
=end
end
