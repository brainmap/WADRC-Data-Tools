class AddIndexToImageDatasetsMore < ActiveRecord::Migration

    def self.up
       add_index "image_datasets", ["visit_id","id"], :name => "index_image_datasets_on_visit_id_id"
    end

    def self.down
       remove_index "image_datasets", ["visit_id","id"]
    end

# image_datasets    visit_id, id

end