class Trfile < ActiveRecord::Base
	belongs_to :trtype 
	# trying to get mulit select but not lose existing values 
	serialize :image_dataset_id
	has_many :tredits,:dependent => :destroy
	has_many :trfileimages,:dependent => :destroy
	has_and_belongs_to_many :tr_tags
  #attr_accessible :enrollment_id, :image_dataset_id, :scan_procedure_id, :status_flag, :subjectid, :trtype_id,:qc_value,:qc_notes,:file_completed_flag,:secondary_key   
  private
  def trfile_params
    params.require(:trfile).permit(:enrollment_id, :image_dataset_id, :scan_procedure_id, :status_flag, :subjectid, :trtype_id,:qc_value,:qc_notes,:file_completed_flag,:secondary_key )
  end
end
