class CreateNeuropsychSessions < ActiveRecord::Migration
  def self.up
    create_table :neuropsych_sessions do |t|
      t.date :date
      t.text :note
      t.string :procedure
      
      t.references :visit

      t.timestamps
    end
  end

  def self.down
    drop_table :neuropsych_sessions
  end
end
