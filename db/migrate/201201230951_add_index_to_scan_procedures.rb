class AddIndexToScanProcedures < ActiveRecord::Migration

    def self.up
       add_index "scan_procedures", ["protocol_id", "id"], :name => "index_scan_procedures_on_protocol_id_id"
    end

    def self.down
       remove_index "scan_procedures", ["protocol_id", "id"]
    end


end
