class TreditAction < ActiveRecord::Base
	belongs_to :tredit
  attr_accessible :status_flag, :tractiontype_id, :tredit_id, :value
end
