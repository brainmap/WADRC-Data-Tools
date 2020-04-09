class Jobs::BaseJob

    attr_accessor :log
    attr_accessor :inputs
    attr_accessor :exclusions
    attr_accessor :outputs
    attr_accessor :error_log

    # This is a stud for code in the new version of the panda that's meant to replace 
    # ScheduleRun. In order for this to work right with the backported code, I'm going 
    # to have this class just wrap ScheduleRun. 

    attr_accessor :schedulerun

    def self.default_params
	    params = { :schedule_name => 'BaseJob', :run_by_user => 'panda_user'}
        params.default = ''
        params
    end

	def initialize
        @params = self.class.default_params

    	# job_category = Jobs::JobCategory.find_or_create_by(:name => "%{schedule_name}" % @params)
     #    self.job_run = Jobs::JobRun.new
     #    self.job_run.category = job_category
     #    self.job_run.params = @params
     #    self.job_run.status_flag = "started"
     #    self.job_run.created_by_user = User.find_by(:username => @params[:run_by_user])

        schedule = Schedule.where(:name => @params[:schedule_name]).first
        @schedulerun = Schedulerun.new
        @schedulerun.schedule_id = schedule.id
        @schedulerun.comment ="starting #{@params[:schedule_name]}"
        @schedulerun.save
        @schedulerun.start_time = @schedulerun.created_at
        @schedulerun.save

        self.log = []
        self.log << "starting '%{schedule_name}" % @params

        self.inputs = []
        self.outputs = []
        self.exclusions = []
        self.error_log = []

     #    self.job_run.start_time = DateTime.now()
     #    self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)
        	
        @connection = ActiveRecord::Base.connection();

    end

    def close (params)

        self.log << "closing down"
        self.log << "successful finish %{schedule_name}" % @params
    	

    @schedulerun.comment = self.log.join("\n")
    @schedulerun.status_flag ="Y"
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save          
     #    self.job_run.status_flag = "complete"

    	# self.job_run.end_time = DateTime.now()
    	# self.job_run.save_with_logs(self.log, self.inputs, self.outputs, self.exclusions, self.error_log)

    end

    def close_fail (params, err)

        self.log << "failed %{schedule_name} with errors " % @params
        self.error_log << "Error: #{err.message}, #{err.backtrace}"
        
    @schedulerun.comment = self.log.join("\n")
    @schedulerun.status_flag ="N"
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save          

        # self.job_run.end_time = DateTime.now()
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