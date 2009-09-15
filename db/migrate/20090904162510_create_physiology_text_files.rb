class CreatePhysiologyTextFiles < ActiveRecord::Migration
  def self.up
    create_table :physiology_text_files do |t|
      t.string :filepath
      t.integer :image_dataset_id
      t.timestamps
    end
  end

  def self.down
    drop_table :physiology_text_files
  end
end
