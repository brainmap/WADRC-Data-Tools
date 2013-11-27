class ScanProcedure < ActiveRecord::Base
  has_and_belongs_to_many :visits  
  has_and_belongs_to_many :vgroups  
  validates_uniqueness_of :codename
end
