class ScanProcedure < ActiveRecord::Base
  has_many :visits
  
  validates_uniqueness_of :codename
  validates_numericality_of :version
end
