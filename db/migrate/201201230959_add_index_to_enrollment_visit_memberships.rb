
class AddIndexToEnrollmentVisitMemberships < ActiveRecord::Migration

    def self.up
       add_index "enrollment_visit_memberships", ["visit_id", "enrollment_id"], :name => "index_enrollment_visit_memberships_on_visit_id_enrollment_id"
    end

    def self.down
       remove_index "enrollment_visit_memberships", ["visit_id", "enrollment_id"]
    end


   # enrollment_visit_memberships    enrollment_id,visit_id 

end