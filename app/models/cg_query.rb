class CgQuery < ActiveRecord::Base
   has_many :cg_query_tns,:dependent => :destroy
end
