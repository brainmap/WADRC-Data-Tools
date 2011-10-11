class CreateInvites < ActiveRecord::Migration
  def self.up
    create_table :invites do |t|
      t.string :firstname
      t.string :lastname
      t.string :email
      t.string :invite_code, :limit => 40
      t.datetime :invited_at
      t.datetime :redeemed_at
      # t.index [:id, :email]
      # t.index [:id, :invite_code]
    end
  end

  def self.down
    drop_table :invites
  end
end