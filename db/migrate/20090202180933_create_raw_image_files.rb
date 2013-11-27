class CreateRawImageFiles < ActiveRecord::Migration
  def self.up
    create_table :raw_image_files do |t|
      t.string :filename
      t.string :header_reader
      t.string :file_type
      t.timestamp :timestamp
      t.string :source
      t.string :rmr_number
      t.string :series_description
      t.string :gender
      t.integer :num_slices
      t.decimal :slice_thickness
      t.decimal :slice_spacing
      t.decimal :reconstruction_diameter
      t.integer :acquisition_matrix_x
      t.integer :acquisition_matrix_y
      t.decimal :rep_time
      t.integer :bold_reps

      t.timestamps
    end
  end

  def self.down
    drop_table :raw_image_files
  end
end
