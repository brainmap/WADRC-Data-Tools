class ScanProcedure < ActiveRecord::Base
  has_many :visits
  
  validates_uniqueness_of :codename
end
