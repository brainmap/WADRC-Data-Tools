class AddParticipantIdToVisits < ActiveRecord::Migration
  def self.up
    add_column :visits, :participant_id, :integer
  end

  def self.down
    remove_column :visits, :participant_id
  end
end
