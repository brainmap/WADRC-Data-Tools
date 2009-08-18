class DropAgeFromParticipants < ActiveRecord::Migration
  def self.up
    change_table :participants do |t|
      t.remove :age
    end
  end

  def self.down
    change_table :participants do |t|
      t.integer :age
    end
  end
end
