class Vgroup < ActiveRecord::Base 
  
  acts_as_reportable
  default_scope :order => 'vgroup_date DESC' 
  paginates_per 50
  # attr_accessible  :transfer_mri  --- if this is added, add all the fields which should be updated from vgroup edit/create form 
  attr_accessor :move_appointemnt_id, :target_vgroup_id

  has_many :enrollment_vgroup_memberships,:dependent => :destroy
  has_many :enrollments, :through => :enrollment_vgroup_memberships, :uniq => true
  accepts_nested_attributes_for :enrollments, :reject_if => :all_blank, :allow_destroy => true
#  before_validation :lookup_enrollments
  delegate :enumber, :to => :enrollment, :prefix => true
  

 
   belongs_to :user 
     belongs_to :created_by, :class_name => "User"
     scope :assigned_to, lambda { |user_id|
       { :conditions => { :user_id => user_id } }
     }
  
  has_many :appointments,  :class_name =>"Appointment",:dependent => :destroy
  has_and_belongs_to_many :scan_procedures
  
  def get_base_path()  # this is a duplicate of visit model function --- need a common location
  	# look for mount to adrc image server - different on linux vs mac os , and different on mac os delending on login order
  	# check for
  	# Linux /home/USER/adrcdata,   /Data/vtrak1   
  	#Mac  /Volumnes/team*  /Volumnes/team*/preprocessed   /Volumnes/team*/raw
  	base_path =""
  	#user = ENV['USER']

  	if File.directory?("/Volumes/team")
  		 base_path ="/Volumes/team"
  	elsif File.directory?("/Volumes/team-1")
  		 base_path ="/Volumes/team-1"
  	elsif File.directory?("/Volumes/team-2")
  		 base_path ="/Volumes/team-2"	
  	elsif File.directory?("/Volumes/team-3")
  		 base_path ="/Volumes/team-3"
   	elsif File.directory?("/Volumes/team-4")
   		 base_path ="/Volumes/team-4"
   	elsif File.directory?("/Volumes/team-5")
   		 base_path ="/Volumes/team-5"
   	elsif File.directory?("/Volumes/team-6")
   		 base_path ="/Volumes/team-6"
  	else
  		base_path ="/Volumes/team"	
    end

  	return base_path
  end
  
  def nii_file_cnt(p_start_id, p_end_id)  ## duplicate of vgroup_controller function 
    @v_start_id=""
    @v_end_id = "" 
    if !p_start_id.blank? and !p_end_id.blank?
         @v_start_id = p_start_id
         @v_end_id = p_end_id
         @vgroups = Vgroup.where( " id between "+@v_start_id+" and "+@v_end_id ).where("( nii_file_count is null or nii_file_count = 0 )")
         v_vgroup = nil
         @vgroups.each do |vg|
           if !vg.blank? and v_vgroup.blank?
             v_vgroup = vg
           end
         end
         if v_vgroup.blank?
           puts "v_vgroup is blank"
         end
         v_base_path = v_vgroup.get_base_path
         v_glob = '*.nii'
         @vgroups.each do |vg|
            # could be multiple sp
            vg.scan_procedures.each do |sp| 
              v_sp = sp.codename
              # could be multiple subject_id
              vg.enrollments.each do |s|
                v_subject_id = s.enumber
                v_path = v_base_path+"/preprocessed/visits/"+v_sp+"/"+v_subject_id+"/unknown/"
                v_count = `cd #{v_path};ls -1 #{v_glob}| wc -l`.to_i   #
                if v_count > 0 
                  @vgroup = Vgroup.find(vg.id)
                  @vgroup.nii_file_count = v_count
                  @vgroup.save
                end
              end
            end      
          end
     end
      return "ok"
  end
  
    def lookup_enrollments
      # get from visits--- now get from vgroups
    end
  
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
