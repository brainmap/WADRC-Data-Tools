class Jobs::JobRun < ActiveRecord::Base

  has_many :job_cases

  serialize :params

  belongs_to :created_by_user, :class_name => "User"
  belongs_to :job_category, :class_name => "Jobs::JobCategory"

end

# CREATE TABLE `job_runs` (
#   `id` int(11) NOT NULL AUTO_INCREMENT,
#   `job_category_id` int(11) DEFAULT NULL,
#   `start_time` datetime DEFAULT NULL,
#   `end_time` datetime DEFAULT NULL,
#   `status_flag` varchar(11) DEFAULT 'started',
#   `created_at` datetime DEFAULT NULL,
#   `updated_at` datetime DEFAULT NULL,
#   `params` text,
#   `created_by_user_id` int(11) DEFAULT NULL,
#   PRIMARY KEY (`id`)
# )