class Vgroup < ActiveRecord::Base 
  
  acts_as_reportable
  default_scope :order => 'vgroup_date DESC' 
  paginates_per 50
  
#  has_and_belongs_to_many :scan_procedures
#  has_many :enrollment_vgroup_memberships
#  has_many :enrollments, :through => :enrollment_vgroup_memberships, :uniq => true
#  accepts_nested_attributes_for :enrollments, :reject_if => :all_blank, :allow_destroy => true
#  before_validation :lookup_enrollments
 
   belongs_to :user 
     belongs_to :created_by, :class_name => "User"
     scope :assigned_to, lambda { |user_id|
       { :conditions => { :user_id => user_id } }
     }
  
  has_many :appointments,  :class_name =>"Appointment",:dependent => :destroy

     
end
