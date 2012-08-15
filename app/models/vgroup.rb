class Vgroup < ActiveRecord::Base 
  
  acts_as_reportable
  default_scope :order => 'vgroup_date DESC' 
  paginates_per 50
  
  attr_accessor :move_appointemnt_id, :target_vgroup_id

#  has_many :enrollment_vgroup_memberships
#  has_many :enrollments, :through => :enrollment_vgroup_memberships, :uniq => true
#  accepts_nested_attributes_for :enrollments, :reject_if => :all_blank, :allow_destroy => true
#  before_validation :lookup_enrollments
# delegate :enumber, :to => :enrollment, :prefix => true
 
   belongs_to :user 
     belongs_to :created_by, :class_name => "User"
     scope :assigned_to, lambda { |user_id|
       { :conditions => { :user_id => user_id } }
     }
  
  has_many :appointments,  :class_name =>"Appointment",:dependent => :destroy
  has_and_belongs_to_many :scan_procedures
  

  
  def participant
    @participant ||= nil
    return @participant if @participant
    if !self.participant_id.blank?
      @participant = Participant.find(self.participant_id)
    end
    return @participant
  end
  
  def enrollments
    @enrollments ||= nil
    #@visit = Visit.where("visits.appointment_id in (select appointments.id from appointments where appointments.vgroup_id in (?))",self.id).first
    #@enrollments = @visit.enrollments # @visit.blank? ? "" : @visit.enrollments.collect {|e| e.enumber }.join(", ")
    @enrollments = Enrollment.where("enrollments.id in (select enrollment_vgroup_memberships.enrollment_id from enrollment_vgroup_memberships 
                                   where enrollment_vgroup_memberships.vgroup_id in (?)  )",self.id)
    return @enrollments
  end
     
end
