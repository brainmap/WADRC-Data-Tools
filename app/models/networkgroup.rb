class Networkgroup < ActiveRecord::Base # ApplicationRecord
	has_many :usernetworkgroups,:dependent => :destroy
end
