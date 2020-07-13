class Jobs::JobRun < ActiveRecord::Base
  # has_one_attached :log
  # has_one_attached :inputs
  # has_one_attached :outputs
  # has_one_attached :exclusions
  # has_one_attached :error_log

  serialize :params

  belongs_to :created_by_user, :class_name => "User"
  belongs_to :category, :class_name => "JobCategory"

  def save_with_logs(log_obj=nil, inputs_obj=nil, outputs_obj=nil, exclusions_obj=nil, errors_obj=nil)
    
    timestamp = DateTime.now().strftime("%Y-%m-%d_%H:%M:%S")
    output_directory = ''
  	if !log_obj.nil? or !inputs_obj.nil? or !outputs_obj.nil? or !exclusions_obj.nil? or !errors_obj.nil?
		  
    	output_directory = Dir.mktmpdir
    end
  	
    attach_log(log_obj, 'log', timestamp, output_directory)
    attach_log(inputs_obj, 'inputs', timestamp, output_directory)
    attach_log(outputs_obj, 'outputs', timestamp, output_directory)
    attach_log(exclusions_obj, 'exclusions', timestamp, output_directory)
    attach_log(errors_obj, 'error_log', timestamp, output_directory)

  	self.save
  end

  def attach_log(log_data, attribute, timestamp, output_directory)
    # puts "do we have anything to attach?"

    # puts "is it nil? #{log_data.nil? ? 'yes' : 'no'}"
    # puts "is it a log?  #{(log_data.class.to_s == 'Jobs::JobLog') ? 'yes' : "no (#{log_data.class})"}"
    # puts "does it have content? #{(!log_data.nil? and log_data.serialize.length > 0) ? 'yes' : 'no'}"
    
    if !log_data.nil? and log_data.class.to_s == 'Jobs::JobLog' and log_data.serialize.length > 0

      # puts "attaching log: #{attribute}"
      filename = "#{attribute}_#{timestamp}"

      log_path = File.join(output_directory, filename + '.log')
      log_path_expanded = File.expand_path(log_path)
      File.write(log_path_expanded, log_data.serialize)
      log = File.open(log_path_expanded)

      self.send(attribute).attach(io: log, filename:filename + '.log', content_type: "text/plain")
      # puts "is it attached? #{self.send(attribute).attached? ? 'no' : 'yes'}"

    end

  end

end

# CREATE TABLE `job_runs` (
#   `id` int(11) NOT NULL AUTO_INCREMENT,
#   `category_id` int(11) DEFAULT NULL,
#   `start_time` datetime DEFAULT NULL,
#   `end_time` datetime DEFAULT NULL,
#   `status_flag` varchar(11) DEFAULT 'started',
#   `created_at` datetime DEFAULT NULL,
#   `updated_at` datetime DEFAULT NULL,
#   `params` text,
#   `created_by_user_id` int(11) DEFAULT NULL,
#   PRIMARY KEY (`id`)
# )