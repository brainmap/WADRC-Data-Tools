class Questionformnamesp < ActiveRecord::Base
  #attr_accessible :form_name, :questionform_id, :scan_procedure_id  
  private
  def questionformnamesp_params
    params.require(:questionformnamesp).permit(:form_name, :questionform_id, :scan_procedure_id)
  end
end
