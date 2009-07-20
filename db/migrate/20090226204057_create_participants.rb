class CreateParticipants < ActiveRecord::Migration
  def self.up
    create_table :participants do |t|
      t.integer :wrapenroll, :quality_redflag, :age, :ed_years, :apoe_e1, :apoe_e2, :gender
      t.string :wrapnum, :apoe_comment, :apoe_processor
      t.date :dob
      t.timestamps
    end
  end

  def self.down
    drop_table :participants
  end
end
