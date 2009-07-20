class CreateImageComments < ActiveRecord::Migration
  def self.up
    create_table :image_comments do |t|
      t.references :image_dataset, :null => false
      t.string :name
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :image_comments
  end
end
