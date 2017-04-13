class AnalysisMembership < ActiveRecord::Base
  belongs_to :analysis
  belongs_to :image_dataset
  
  #scope :out, :conditions => ['excluded = ?', true]
  #scope :in, :conditions => ['excluded = ?', false]  
  scope :out, -> { where('excluded = ?', true)}
  scope :in, -> { where('excluded = ?', false)}
end
