class AnalysisMembership < ActiveRecord::Base
  belongs_to :analysis
  belongs_to :image_dataset
  
  named_scope :out, :conditions => ['excluded = ?', true]
  named_scope :in, :conditions => ['excluded = ?', false]
end
