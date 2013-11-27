class ChangeWrapnumToString < ActiveRecord::Migration
  def self.up
    change_table :participants do |t|
      t.change :wrapnum, :string
    end
  end

  def self.down
    change_table :participants do |t|
      t.change :wrapnum, :integer
    end
  end
end
