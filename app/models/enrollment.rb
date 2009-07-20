class Enrollment < ActiveRecord::Base
  has_many :visits
  belongs_to :recruitment_group
  belongs_to :participant
  
  def withdrawn?
    withdrawn
  end
end
