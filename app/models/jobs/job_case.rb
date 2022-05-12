class Jobs::JobCase < ActiveRecord::Base

  belongs_to :job_run
  belongs_to :pipeline
  belongs_to :enrollment
  belongs_to :scan_procedure

end

# CREATE TABLE `job_cases` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `pipeline_id` int DEFAULT NULL,
#   `job_run_id` int DEFAULT NULL,
#   `enrollment_id` int DEFAULT NULL,
#   `enumber` varchar(20) DEFAULT NULL,
#   `scan_procedure_id` int DEFAULT NULL,
#   `scan_procedure` varchar(100) DEFAULT NULL,
#   `status` varchar(20) DEFAULT 'started',
#   `created_at` datetime DEFAULT NULL,
#   `updated_at` datetime DEFAULT NULL,
#   `exclusion_message` text,
#   `enqueued_at` datetime DEFAULT NULL,
#   `completed_at` datetime DEFAULT NULL,
#   `failure_message` text,
#   PRIMARY KEY (`id`)
# )