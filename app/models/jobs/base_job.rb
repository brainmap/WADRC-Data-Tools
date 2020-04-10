class Jobs::BaseJob

    attr_accessor :log
    attr_accessor :inputs
    attr_accessor :exclusions
    attr_accessor :outputs
    attr_accessor :error_log

    # The thinking here is that anything that's used as an input should be recoded in inputs. 
    # I.e. when doing PET processing, we'll take a list of subjects as the input, then
    # some of those people will be excluded because they don't meet criteria for processing.
    # If an item is represented in inputs, it should also be represented in either outputs
    # (successful products), or exclusions (inputs that didn't meet criteria).

    attr_accessor :job_run

    def self.default_params
	    params = { :schedule_name => 'BaseJob', :run_by_user => 'panda_user'}
        params.default = ''
        params
    end

	def initialize
        @params = self.class.default_params

    	job_category = Jobs::JobCategory.find_or_create_by(:name => "%{schedule_name}" % @params)
        self.job_run = Jobs::JobRun.new
        self.job_run.category = job_category
        self.job_run.params = @params
        self.job_run.status_flag = "started"
        self.job_run.created_by_user = User.find_by(:username => @params[:run_by_user])

        self.log = Jobs::JobLog.new()
        self.log << "starting '{schedule_name}" % @params

        self.inputs = Jobs::JobLog.new()
        self.outputs = Jobs::JobLog.new()
        self.exclusions = Jobs::JobLog.new()
        self.error_log = Jobs::JobLog.new()

        self.job_run.start_time = DateTime.now()
        self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)
        	
        @connection = ActiveRecord::Base.connection();

    end

    def close (params)

        self.log << "closing down"
        self.log << "successful finish %{schedule_name}" % @params
    	
        self.job_run.status_flag = "complete"

    	self.job_run.end_time = DateTime.now()
    	self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)

    end

    def close_fail (params, err)

        self.log << "failed %{schedule_name} with errors " % @params
        self.error_log << "Error: #{err.message}, #{err.backtrace}"
        
        self.job_run.status_flag = "failed"

        self.job_run.end_time = DateTime.now()
        self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)
        
    end

    protected
    def r_call (cmd)
        begin
        	stdin, stdout, stderr = Open3.popen3(cmd)
        while !stdout.eof?
        	puts stdout.read 1024    
        end
        stdin.close
        stdout.close
        stderr.close
        rescue => msg
        end
    end
end