class Networkgroup < ActiveRecord::Base # ApplicationRecord
	has_many :usrnetworkgroups,:dependent => :destroy
end
