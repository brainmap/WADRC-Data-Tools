class Participant < ActiveRecord::Base
  has_many :enrollments
  
  validates_uniqueness_of :access_id, :allow_nil => true
  acts_as_reportable
  
  EXCLUDED_REPORT_ATTRIBUTES = [:dob ,:apoe_e1,:apoe_e2,:created_at,:updated_at,:access_id]
  def visits
    @visits ||= []
    return @visits unless @visits.blank?
    @visits = enrollments.collect {|e| e.visits }.flatten
  end
  
  def self.csv_download(participants, include_options = {})
    participants.report_table(:all, 
      :except => Participant::EXCLUDED_REPORT_ATTRIBUTES, 
      :include => include_options
    ).to_csv
  end

  
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
  
  def genetic_status(format = :csv)
    prefix = (format == :html) ? "&epsilon;4 " : "e4 "
    if apoe_e1 == 4 or apoe_e2 == 4
      if format == :csv then "1" else "#{prefix}+" end
    elsif apoe_e1 == nil or apoe_e1 == 0 or apoe_e2 == nil or apoe_e2 == 0
      ""
    else
      if format == :csv then "0" else "#{prefix}-" end
    end
  end
end
