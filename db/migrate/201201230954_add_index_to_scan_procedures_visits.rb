class AddIndexToScanProceduresVisits < ActiveRecord::Migration

    def self.up
       add_index "scan_procedures_visits", ["scan_procedure_id", "visit_id"], :name => "index_scan_procedures_visits_on_scan_procedure_id_visit_id"
    end

    def self.down
       remove_index "scan_procedures_visits", ["scan_procedure_id", "visit_id"]
    end

end