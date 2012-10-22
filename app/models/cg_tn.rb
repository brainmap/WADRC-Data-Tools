class CgTn < ActiveRecord::Base
   has_many :cg_tn_cns,:dependent => :destroy
end
