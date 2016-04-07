class Tredit < ActiveRecord::Base
	belongs_to :trfile
	has_many :tredit_actions,:dependent => :destroy
  attr_accessible  :status_flag, :trfile_id, :user_id,:edit_completed_flag
end
