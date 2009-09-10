class Enrollment < ActiveRecord::Base
  has_many :visits
  belongs_to :recruitment_group
  belongs_to :participant
  
  validates_uniqueness_of :enum, :allow_nil => true
  
  validates_format_of :enum, :with => /.*\d{3,}\Z/, :message => "Enum must end with at least 3 digits to be valid."
  
  def withdrawn?
    not withdrawl_reason.blank?
  end
end
