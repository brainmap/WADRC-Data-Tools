class CreateLookupEligibilityIneligibilities < ActiveRecord::Migration
  def self.up
    create_table :lookup_eligibility_ineligibilities do |t|
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_eligibility_ineligibilities
  end
end
