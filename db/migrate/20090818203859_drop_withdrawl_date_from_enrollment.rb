class DropWithdrawlDateFromEnrollment < ActiveRecord::Migration
  def self.up
    change_table :enrollments do |t|
      t.remove :withdrawl_date
      t.remove :withdrawn
    end
  end

  def self.down
    change_table :enrollments do |t|
      t.date :withdrawl_date
      t.boolean :withdrawn
    end
  end
end
