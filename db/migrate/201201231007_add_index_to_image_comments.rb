class AddIndexToImageComments < ActiveRecord::Migration

    def self.up
       add_index "image_comments", ["image_dataset_id","id"], :name => "index_image_comments_on_image_dataset_id_id"
    end

    def self.down
       remove_index "image_comments", ["image_dataset_id","id"]
    end

end