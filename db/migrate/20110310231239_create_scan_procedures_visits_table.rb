class CreateScanProceduresVisitsTable < ActiveRecord::Migration
  def self.up
    create_table :scan_procedures_visits, :id => false do |t|
      t.integer :scan_procedure_id
      t.integer :visit_id
    end
    say "Associating many-to-many scan_procedures and visits"
    execute "INSERT INTO scan_procedures_visits (scan_procedure_id, visit_id) SELECT scan_procedure_id, id FROM visits;"
    remove_column :visits, :scan_procedure_id
  end
  
  def self.down
    add_column :visits, :scan_procedure_id, :integer
    say "Only preserves first scan procedure - Watch out!"
    execute "INSERT INTO visits (scan_procedure_id) SELECT scan_procedure_id FROM scan_procedures_visits WHERE visit_id = id LIMIT 1;"
    drop_table :scan_procedures_visits
  end
end
