class ConsentFormVgroup < ActiveRecord::Base
  #attr_accessible :consent_date, :consent_form_id, :status_flag, :user_id, :vgroup_id
  belongs_to  :vgroup
  belongs_to  :consent_form   
  private
  def consent_form_vgroup_params
    params.require(:consent_form_vgroup).permit(:consent_date, :consent_form_id, :status_flag, :user_id, :vgroup_id)
  end
end
