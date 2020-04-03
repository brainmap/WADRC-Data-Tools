class Jobs::JobCategory < ActiveRecord::Base

	has_many :job_runs
  
end


# CREATE TABLE `job_categories` (
#   `id` int(11) NOT NULL AUTO_INCREMENT,
#   `name` varchar(100) DEFAULT NULL,
#   `run_on_machine` varchar(20) DEFAULT NULL,
#   `parameters` varchar(2000) DEFAULT NULL,
#   `description` varchar(2000) DEFAULT NULL,
#   PRIMARY KEY (`id`)
# )