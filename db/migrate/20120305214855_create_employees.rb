class CreateEmployees < ActiveRecord::Migration
  def self.up
    create_table :employees do |t|
      t.string :first_name
      t.string :mi
      t.string :last_name
      t.string :status
      t.string :initials
      t.integer :lookup_status_id
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :employees
  end
end
