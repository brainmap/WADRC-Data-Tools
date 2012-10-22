class CgQueryTn < ActiveRecord::Base
   has_many :cg_query_tn_cns,:dependent => :destroy
   belongs_to :cg_query
end
