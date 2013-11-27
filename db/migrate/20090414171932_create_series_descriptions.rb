class CreateSeriesDescriptions < ActiveRecord::Migration
  def self.up
    create_table :series_descriptions do |t|
      t.string :long_description
      t.string :short_description
      t.string :anat_type
      t.string :acq_plane

      t.timestamps
    end
  end

  def self.down
    drop_table :series_descriptions
  end
end
