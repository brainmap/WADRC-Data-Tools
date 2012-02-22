class AddIndexToEnrollments < ActiveRecord::Migration

    def self.up
       add_index "enrollments", ["id","participant_id"], :name => "index_enrollments_on_id_participant_id"
    end

    def self.down
       remove_index "enrollments", ["id","participant_id"]
    end

end