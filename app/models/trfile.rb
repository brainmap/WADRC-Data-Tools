class Trfile < ActiveRecord::Base
	belongs_to :trtype
	has_many :tredits,:dependent => :destroy
  attr_accessible :enrollment_id, :image_dataset_id, :scan_procedure_id, :status_flag, :subjectid, :trtype_id,:qc_value
end
