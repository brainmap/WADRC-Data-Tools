class CgTn < ActiveRecord::Base
   has_many :cg_tn_cns,:dependent => :destroy
   has_and_belongs_to_many :users
end
