class AddCompiledAtDateToVisits < ActiveRecord::Migration
  def self.up
    add_column :visits, :compiled_at, :date
  end

  def self.down
    remove_column :visits, :compiled_at
  end
end
