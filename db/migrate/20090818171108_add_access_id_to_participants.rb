class AddAccessIdToParticipants < ActiveRecord::Migration
  def self.up
    change_table :participants do |t|
      t.integer :access_id
    end
  end

  def self.down
    change_table :participants do |t|
      t.remove :access_id
    end
  end
end
