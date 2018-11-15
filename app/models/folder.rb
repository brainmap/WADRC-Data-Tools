require 'open3'
class Folder < ActiveRecord::Base #ApplicationRecord
	has_many :folderpermissions,:class_name =>"Folderpermission", :dependent => :destroy 
end
