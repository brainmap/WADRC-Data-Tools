class ImageSearch < ActiveRecord::Base
  has_many :analyses, :dependent => :destroy
  belongs_to :user
  has_and_belongs_to_many :scan_procedures
  
  validates_presence_of :user
  
  def matching_images
    conditions, qualifiers = get_conditions
    ImageDataset.find(:all, :include => [{:visit => :scan_procedure}, 
                                         {:visit => {:enrollment => :participant}}, 
                                         :analysis_memberships, :image_dataset_quality_checks], 
                            :conditions => [conditions, *qualifiers])
  end
  
  def get_conditions
    conditions = []
    qualifiers = []
    unless rmr.empty?
      conditions << "rmr LIKE ?"
      qualifiers << "%#{rmr}%"
    end
    unless series_description.empty?
      conditions << "series_description LIKE ?"
      qualifiers << "%#{series_description}%"
    end
    unless path.empty?
      conditions << "path LIKE ?"
      qualifiers << "#{path}"
    end
    unless earliest_timestamp.nil?
      conditions << "timestamp > ?"
      qualifiers << "#{earliest_timestamp}"
    end
    unless latest_timestamp.nil?
      conditions << "timestamp < ?"
      qualifiers << "#{latest_timestamp}"
    end
    unless enum.empty?
      conditions << "enrollments.enum LIKE ?"
      qualifiers << "%#{enum}%"
    end
    unless gender.nil?
      conditions << "participants.gender = ?"
      qualifiers << "#{gender}"
    end
    unless min_age.nil?
      conditions << "participants.dob > ?"
      qualifiers << "#{birthdate(min_age)}"
    end
    unless max_age.nil?
      conditions << "participants.dob < ?"
      qualifiers << "#{birthdate(max_age)}"
    end
    unless min_ed_years.nil?
      conditions << "participants.ed_years > ?"
      qualifiers << "#{min_ed_years}"
    end
    unless max_ed_years.nil?
      conditions << "participants.ed_years < ?"
      qualifiers << "#{max_ed_years}"
    end
    unless apoe_status.nil?
      if apoe_status == 1
        conditions << "(participants.apoe_e1 = ? OR participants.apoe_e2 = ?)"
      else
        conditions << "(participants.apoe_e1 != ? AND participants.apoe_e2 != ?)"
      end
      qualifiers << "4"
      qualifiers << "4"
    end
    unless scan_procedures.empty?
      spconditions = []
      scan_procedures.each do |sp|
        spconditions << "scan_procedures.id = ?"
        qualifiers << sp.id
      end
      conditions << "(" + spconditions.join(" OR ") + ")"
    end
    unless scanner_source.empty?
      conditions << "visits.scanner_source = ?"
      qualifiers << "#{scanner_source}"
    end
    conditions = conditions.join(" AND ")
    return [conditions, qualifiers]
  end
  
  def birthdate(age)
    Time.now - age.years
  end
  
  def gender_letter
    return "" if gender.nil?
    gender == 1 ? "M" : "F"
  end
  
  def apoe_status_prompt
    return "" if apoe_status.nil?
    apoe_status == 1 ? "positive" : "negative"
  end
  
  def scan_procedure_names
    scan_procedures.map { |sp| sp.codename }
  end
end