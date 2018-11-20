class Dashboard < ActiveRecord::Base #ApplicationRecord
	has_many :dashboardcontents,:class_name =>"Dashboardcontent", :dependent => :destroy 
	has_many :dashboard_defaults,:class_name =>"DashboardDefault", :dependent => :destroy 
end
