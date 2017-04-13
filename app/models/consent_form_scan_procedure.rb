class ConsentFormScanProcedure < ActiveRecord::Base
  #attr_accessible :consent_form_id, :scan_procedure_id
  belongs_to :scan_procedure
  belongs_to  :consent_form   
  private
  def consent_form_scan_procedure_params
    params.require(:consent_form_scan_procedure).permit(:consent_form_id, :scan_procedure_id )
  end
end
