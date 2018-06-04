class Trtype < ActiveRecord::Base
	has_many :trfiles,:dependent => :destroy
	has_many :tractiontypes,:dependent => :destroy 
	serialize :series_description_type_id         # trying to get multiple series_descrition_type_ids
	#has_and_belongs_to_many :users
  #attr_accessible :description, :parameters, :status_flag, :series_description_type_id, :action_name,:triggers_1   
  private
  def trtype_params
    params.require(:trtype).permit(:description, :parameters, :status_flag, :series_description_type_id, :action_name,:triggers_1)
  end
end
