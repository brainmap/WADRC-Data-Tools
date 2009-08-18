class Enrollment < ActiveRecord::Base
  has_many :visits
  belongs_to :recruitment_group
  belongs_to :participant
  
  validates_uniqueness_of :enum, :allow_nil => true
  
  def withdrawn?
    not withdrawl_reason.blank?
  end
end
