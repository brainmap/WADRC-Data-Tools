class ConsentFormScanProcedure < ActiveRecord::Base
  attr_accessible :consent_form_id, :scan_procedure_id
  belongs_to :scan_procedure
  belongs_to  :consent_form
end
