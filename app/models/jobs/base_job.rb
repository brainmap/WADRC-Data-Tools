class Jobs::BaseJob

    attr_accessor :log
    attr_accessor :inputs
    attr_accessor :exclusions
    attr_accessor :outputs
    attr_accessor :error_log

    # This is a backport of the jobs code in the new version of the panda

    attr_accessor :job_run

    def self.default_params
	    params = { :schedule_name => 'BaseJob', :run_by_user => 'panda_user'}
        params.default = ''
        params
    end

	def initialize(params=nil)
        if params.nil?
            @params = self.class.default_params
        else
            @params = params
        end

    	# job_category = Jobs::JobCategory.find_or_create_by(:name => "%{schedule_name}" % @params)

        schedule = Schedule.where(:name => @params[:schedule_name]).first
        self.job_run = Schedulerun.new
        self.job_run.schedule_id = schedule.id
        self.job_run.comment ="starting #{@params[:schedule_name]}"
        self.job_run.save
        self.job_run.start_time = self.job_run.created_at
        self.job_run.save

        # self.job_run.params = @params
        # self.job_run.status_flag = "started"
        # self.job_run.created_by_user = User.find_by(:username => @params[:run_by_user])

        self.log = []
        self.log << "starting #{@params[:schedule_name]}"

        self.inputs = []
        self.outputs = []
        self.exclusions = []
        self.error_log = []

        # self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)
        	
        @connection = ActiveRecord::Base.connection();

    end

    def close (params)

        self.log << "closing down"
        self.log << "successful finish %{schedule_name}" % params
    	
        self.job_run.comment = self.log.join("\n")[0..64000]
        self.job_run.status_flag = "Y"

    	self.job_run.end_time = DateTime.now()
        self.job_run.save
    	# self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)

    end

    def close_fail (params, err)

        self.log << "failed %{schedule_name} with errors " % params
        self.error_log << "Error: #{err.message}, #{err.backtrace}"
        
        self.job_run.comment = self.log.join("\n")[0..64000]
        self.job_run.status_flag = "N"

        self.job_run.end_time = DateTime.now()
        self.job_run.save
        # self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)
        
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