class CreateLookupLetterlabels < ActiveRecord::Migration
  def self.up
    create_table :lookup_letterlabels do |t|
      t.string :description
      t.integer :protocol_id
      t.integer :doccategory

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_letterlabels
  end
end
