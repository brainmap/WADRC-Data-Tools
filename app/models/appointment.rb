class Appointment < ActiveRecord::Base
  
  belongs_to :vgroup
  belongs_to :user
  
  has_many :visits, :class_name =>"Visit",:dependent => :destroy
  has_many :petscans, :class_name =>"Petscan",:dependent => :destroy
  has_many :neuropsyches,:dependent => :destroy
  has_many :lumbarpunctures,:dependent => :destroy
  has_many :blooddraws,:dependent => :destroy
  
 # has_many :vitals,:class_name =>"Vital",:dependent => :destroy

end
