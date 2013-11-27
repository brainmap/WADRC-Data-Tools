class Mriscantask < ActiveRecord::Base
   belongs_to :visit
   
   has_many :mriperformances,:dependent => :destroy
end
