class Study < ActiveRecord::Base
  has_many :recruitment_groups
  
  validates_uniqueness_of :name, :official_name, :prefix, :irb_number
  validates_presence_of :investigator, :raw_directory
end
