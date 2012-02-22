class AddIndexToVisits < ActiveRecord::Migration

    def self.up
       add_index "visits", ["id"], :name => "index_visits_on_id"
    end

    def self.down
       remove_index "visits", ["id"]
    end


end