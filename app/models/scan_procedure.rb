class ScanProcedure < ActiveRecord::Base
  has_and_belongs_to_many :visits  
  validates_uniqueness_of :codename
end
