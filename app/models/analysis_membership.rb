class AnalysisMembership < ActiveRecord::Base
  belongs_to :analysis
  belongs_to :image_dataset
  
  scope :out, :conditions => ['excluded = ?', true]
  scope :in, :conditions => ['excluded = ?', false]
end
