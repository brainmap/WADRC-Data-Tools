class Petfile < ActiveRecord::Base
  #attr_accessible :file_name, :id, :note, :path, :petscan_id
  belongs_to :petscan   
   serialize :dicom_taghash#, Hash # not working as hash? 

  def path_ok?

  	if !path.nil? and !path.blank?
  		if File.file?(path) or File.directory?(path)
  			return true
  		end
  	end

  	return false

  end

  def path_dir?
  	File.directory?(path)
  end

  def path_file?
  	File.file?(path)
  end
  
  private
  def petfile_params
    params.require(:petfile).permit(:file_name, :id, :note, :path, :petscan_id,:dicom_taghash )
  end

end
