class PhysiologyTextFile < ActiveRecord::Base
  belongs_to :image_dataset
  validates_uniqueness_of :filepath
end
