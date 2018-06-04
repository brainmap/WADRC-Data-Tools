class Trfileimage < ActiveRecord::Base
	 belongs_to :trfile 
	   private
  def trfile_params
    params.require(:trfileimage).permit(:trfile_id, :image_id, :image_category)
  end
end
