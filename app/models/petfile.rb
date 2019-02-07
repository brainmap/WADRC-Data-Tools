class Petfile < ActiveRecord::Base
  #attr_accessible :file_name, :id, :note, :path, :petscan_id
  belongs_to :petscan   
   serialize :dicom_taghash#, Hash # not working as hash? 
  private
  def petfile_params
    params.require(:petfile).permit(:file_name, :id, :note, :path, :petscan_id,:dicom_taghash )
  end
end
