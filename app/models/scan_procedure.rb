class ScanProcedure < ActiveRecord::Base
  has_and_belongs_to_many :visits  
  has_and_belongs_to_many :vgroups  
  validates_uniqueness_of :codename
  has_many :consent_form_scan_procedures,:dependent => :destroy
  #has_and_belongs_to_many :consent_form    -- was causing delete error - looking for consent_formS_scan_procedures

end
