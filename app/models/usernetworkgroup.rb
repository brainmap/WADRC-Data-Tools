class Usernetworkgroup <  ActiveRecord::Base  #ApplicationRecord
	  belongs_to :user
	  belongs_to :networkgroup
end
