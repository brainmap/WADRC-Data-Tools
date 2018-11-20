class Dashboardcontent <  ActiveRecord::Base #ApplicationRecord
		belongs_to :dashboard
	    has_many :dashboardcontentconditions,:class_name =>"Dashboardcontentcondition", :dependent => :destroy 
end
