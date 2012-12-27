class Schedulerun < ActiveRecord::Base
  belongs_to :schedule
  
  acts_as_reportable
   
end
