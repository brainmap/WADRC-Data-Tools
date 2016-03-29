class ConsentForm < ActiveRecord::Base
  attr_accessible :description, :id, :status_flag
  has_many :consent_form_scan_procedures,:dependent => :destroy
  has_many :scan_procedures, :through => :consent_form_scan_procedures, :uniq => true
end
