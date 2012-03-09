class CreateQuestionformScanProcedures < ActiveRecord::Migration
  def self.up
    create_table :questionform_scan_procedures do |t|
      t.integer :questionform_id
      t.integer :scan_procedure_id
      t.string :include_exclude

      t.timestamps
    end
  end

  def self.down
    drop_table :questionform_scan_procedures
  end
end
