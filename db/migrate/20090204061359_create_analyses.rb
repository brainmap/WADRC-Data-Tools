class CreateAnalyses < ActiveRecord::Migration
  def self.up
    create_table :analyses do |t|
      t.string :author
      t.datetime :timestamp
      t.string :description
      t.datetime :start_date
      t.datetime :end_date
      t.string :series_description

      t.timestamps
    end
  end

  def self.down
    drop_table :analyses
  end
end
