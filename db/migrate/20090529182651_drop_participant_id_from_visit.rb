class DropParticipantIdFromVisit < ActiveRecord::Migration
  def self.up
    change_table :visits do |t|
      t.remove :participant_id
    end
  end

  def self.down
    change_table :visits do |t|
      t.references :participant
    end
  end
end
