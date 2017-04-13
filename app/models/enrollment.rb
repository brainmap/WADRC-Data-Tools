class Enrollment < ActiveRecord::Base
  has_many :enrollment_visit_memberships
  #has_many :visits, :through => :enrollment_visit_memberships, :uniq => true  
  has_many :visits, -> { distinct }, :through => :enrollment_visit_memberships 
  
  has_many :enrollment_vgroup_memberships
  #has_many :vgroups, :through => :enrollment_vgroup_memberships, :uniq => true 
  has_many :vgroups, -> { distinct }, :through => :enrollment_vgroup_memberships 
  
  belongs_to :recruitment_group
  belongs_to :participant
  
  validates_uniqueness_of :enumber, :allow_nil => true
  # removing for DSAmyloid validates_format_of :enumber, :with => /.*\d{3,}\Z/, :message => "must end with at least 3 digits to be valid."
  
  acts_as_reportable
  paginates_per 50 

  def withdrawn?
    not withdrawl_reason.blank?
  end
end
          

 