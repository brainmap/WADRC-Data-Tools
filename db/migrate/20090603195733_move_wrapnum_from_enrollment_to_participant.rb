class MoveWrapnumFromEnrollmentToParticipant < ActiveRecord::Migration
  def self.up
    change_table :enrollments do |t|
      t.remove :wrapnum
    end
    
    change_table :participants do |t|
      t.integer :wrapnum
    end
  end

  def self.down
    change_table :participants do |t|
      t.remove :wrapnum
    end
    
    change_table :enrollments do |t|
      t.integer :wrapnum
    end
  end
end
