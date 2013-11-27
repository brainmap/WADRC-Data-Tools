class CreateEnrollmentVisitMemberships < ActiveRecord::Migration
  def self.up
    create_table :enrollment_visit_memberships do |t|
      t.integer :enrollment_id
      t.integer :visit_id

      t.timestamps
    end
    say "Associating many-to-many enrollments and visits"
    execute "INSERT INTO enrollment_visit_memberships (enrollment_id, visit_id) SELECT enrollment_id, id FROM visits WHERE enrollment_id <> '';"
    remove_column :visits, :enrollment_id
  end

  def self.down
    add_column :visits, :enrollment_id, :integer
    say "Only preserves first enrollment - Watch out!"
    execute "INSERT INTO visits (enrollment_id) SELECT enrollment_id FROM enrollment_visit_memberships WHERE visit_id = id LIMIT 1;"
    drop_table :enrollment_visit_memberships
  end
end
