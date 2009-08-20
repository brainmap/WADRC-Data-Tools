class Participant < ActiveRecord::Base
  has_many :enrollments
  has_many :visits, :through => :enrollments
  
  def wrapenrolled?
    not wrapnum.blank?
  end
  
  def gender_prompt
    if gender == 1
      return "M"
    elsif gender == 2
      return "F"
    else
      return "unknown"
    end
  end
  
  def genetic_status
    if apoe_e1 == 4 or apoe_e2 == 4
      "&epsilon;4 +"
    elsif apoe_e1 == nil or apoe_e1 == 0 or apoe_e2 == nil or apoe_e2 == 0
      ""
    else
      "&epsilon;4 –"
    end
  end
end
