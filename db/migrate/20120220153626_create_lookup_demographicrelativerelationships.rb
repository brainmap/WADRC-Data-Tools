class CreateLookupDemographicrelativerelationships < ActiveRecord::Migration
  def self.up
    create_table :lookup_demographicrelativerelationships do |t|
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :lookup_demographicrelativerelationships
  end
end
