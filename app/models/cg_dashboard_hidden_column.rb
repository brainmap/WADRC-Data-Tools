class CgDashboardHiddenColumn < ActiveRecord::Base
   belongs_to :user
   belongs_to :cg_tn_cn

end

# CREATE TABLE `cg_dashboard_hidden_columns` (
#   `user_id` int DEFAULT NULL,
#   `cg_tn_cn_id` int DEFAULT NULL,
#   `active` int(1) DEFAULT 1
# )

# 1 is active, 0 is inactive

# insert into cg_dashboard_hidden_columns (user_id, cg_tn_cn_id, active) values (265,