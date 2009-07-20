class DropVersionFromScanProcedures < ActiveRecord::Migration
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
end
