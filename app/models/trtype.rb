class Trtype < ActiveRecord::Base
	has_many :trfiles,:dependent => :destroy
	#has_and_belongs_to_many :users
  attr_accessible :description, :parameters, :status_flag, :series_description_type_id
end
