class Appointment < ActiveRecord::Base
  
  belongs_to :vgroup
  belongs_to :user
  
  has_many :visits, :class_name =>"Visit",:dependent => :destroy
  has_many :petscans, :class_name =>"Petscan",:dependent => :destroy
  has_many :neuropsyches,:dependent => :destroy
  has_many :lumbarpunctures,:dependent => :destroy
  has_many :blooddraws,:dependent => :destroy
  has_many :vitals,:dependent => :destroy

  has_many :appointment_tubetypes

  has_many :tubes, :through => :appointment_tubetypes, :source => :lookup_ref
  
 # has_many :vitals,:class_name =>"Vital",:dependent => :destroy

 	has_one :sharing, :as => :shareable, :dependent => :destroy


 def shareable?(category=nil)
 	!sharing.nil? ? sharing.sharable?(category) : vgroup.shareable?(category)
 end

 def heal_sharing

    if self.sharing.nil?
      self.sharing = Sharing.new(:shareable => self)
      self.sharing.save
    end

    # self.sharing.inherit

    children = []

   	if appointment_type == 'lumbar_puncture'
   		children = Lumbarpuncture.where(:appointment_id => id)
   	elsif appointment_type == 'mri'
   		children = Visit.where(:appointment_id => id)
   	elsif appointment_type == 'pet_scan'
   		children = Petscan.where(:appointment_id => id)
   	end
 	
   	children.each do |child|
   		child.heal_sharing
   		child.sharing.parent = self.sharing
   		child.sharing.save
   	end
 end

end
