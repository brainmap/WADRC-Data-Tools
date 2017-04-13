class Petfile < ActiveRecord::Base
  #attr_accessible :file_name, :id, :note, :path, :petscan_id
  belongs_to :petscan    
  private
  def petfile_params
    params.require(:petfile).permit(:file_name, :id, :note, :path, :petscan_id )
  end
end
