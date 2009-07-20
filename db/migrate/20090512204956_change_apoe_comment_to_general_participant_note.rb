class ChangeApoeCommentToGeneralParticipantNote < ActiveRecord::Migration
  def self.up
    rename_column :participants, :apoe_comment, :note
  end

  def self.down
    rename_column :participants, :note, :apoe_comment
  end
end
