class Jobs::BaseJob

    attr_accessor :log
    attr_accessor :inputs
    attr_accessor :exclusions
    attr_accessor :outputs
    attr_accessor :error_log
    attr_accessor :connection

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

	def initialize(params = nil)
        if params.nil?
            @params = self.class.default_params
        else
            @params = params
        end

    	job_category = Jobs::JobCategory.find_or_create_by(:name => "%{schedule_name}" % @params)
        @job_run = Jobs::JobRun.new
        @job_run.job_category = job_category
        @job_run.params = @params
        @job_run.status_flag = "started"
        @job_run.created_by_user = User.find_by(:username => @params[:run_by_user])


        @log = Logger.new("#{Rails.root}/log/pipelines.log")
        @log.info(@params[:schedule_name]) { "starting" }

        @inputs = []
        @outputs = []
        @exclusions = []
        @error_log = Jobs::JobLog.new()

        @job_run.start_time = DateTime.now()
        @job_run.save
        	
        @connection = ActiveRecord::Base.connection();

    end

    def close (params)

        @log.info(@params[:schedule_name]) { "closing down" }
        @log.info(@params[:schedule_name]) { "successful finish" }
    	
        @job_run.status_flag = "complete"

    	@job_run.end_time = DateTime.now()
    	@job_run.save

    end

    def close_fail (params, err)

        @log.error(@params[:schedule_name]) { "failed with errors" }
        @log.error(@params[:schedule_name]) { "Error: #{err.message}, #{err.backtrace}" }
        @error_log << {:message => "Error: #{err.message}, #{err.backtrace}"}
        
        @job_run.status_flag = "failed"

        @job_run.end_time = DateTime.now()
        @job_run.save
        
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
