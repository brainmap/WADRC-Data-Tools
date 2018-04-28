class ConsentForm < ActiveRecord::Base
 # attr_accessible :description, :id, :status_flag
  has_many :consent_form_scan_procedures,:dependent => :destroy
  #has_many :scan_procedures, :through => :consent_form_scan_procedures, :uniq => true  
  has_many :scan_procedures, -> { distinct }, :through => :consent_form_scan_procedures 
  
  private
  def consent_form_params
    params.require(:consent_form).permit(:description, :id, :status_flag )
  end
end
