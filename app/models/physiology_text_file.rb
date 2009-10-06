class PhysiologyTextFile < ActiveRecord::Base
  belongs_to :image_dataset
  validates_uniqueness_of :filepath
  
  validates_format_of :filepath, :with => /^\/Data\/vtrak1\/raw\//, :message => "must begin with '/Data/vtrak1/raw'"

end
