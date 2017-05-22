class Mriscantask < ActiveRecord::Base
   belongs_to :visit
   belongs_to :image_dataset
   has_many :mriperformances,:dependent => :destroy
end
