class RenameTransfersTableToVisits < ActiveRecord::Migration
  def self.up
    rename_table :transfers, :visits
  end

  def self.down
    rename_table :visits, :transfers
  end
end