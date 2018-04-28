class TreditAction < ActiveRecord::Base
	belongs_to :tredit
  ###attr_accessible :status_flag, :tractiontype_id, :tredit_id, :value
  private
  def tredit_action_params
    params.require(:tredit_action).permit(:status_flag, :tractiontype_id, :tredit_id, :value)
  end
end
