class AddColumnsToProtocols < ActiveRecord::Migration
  def self.up
    add_column :protocols, :investigator, :string
    add_column :protocols, :study, :string
    add_column :protocols, :visit_number, :integer
    add_column :protocols, :procedure, :string 
  end

  def self.down
    remove_column :protocols, :investigator
    remove_column :protocols, :study
    remove_column :protocols, :visit_number
    remove_column :protocols, :procedure
  end
end
