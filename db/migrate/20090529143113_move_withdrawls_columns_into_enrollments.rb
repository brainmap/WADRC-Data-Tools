class MoveWithdrawlsColumnsIntoEnrollments < ActiveRecord::Migration
  def self.up
    change_table :enrollments do |t|
      t.date     :withdrawl_date
      t.text     :withdrawl_reason
      t.boolean  :withdrawn
    end
    
    drop_table   :withdrawls
  end

  def self.down
    create_table :withdrawls do |t|
      t.date     :withdrawl_date
      t.text     :reason
      t.integer  :enrollment_id
      t.timestamps
    end
    
    change_table :enrollments do |t|
      t.remove :withdrawl_date
      t.remove :withdrawl_reason
      t.remove :withdrawn
    end
  end
end
