class ConsentFormVgroup < ActiveRecord::Base
  attr_accessible :consent_date, :consent_form_id, :status_flag, :user_id, :vgroup_id
  belongs_to  :vgroup
  belongs_to  :consent_form
end
