class SharedUpload::SharedUploadBase

  def self.default_params
	  params = { schedule_name: 'generic_upload',
				base_path: Shared.get_base_path(), 
    			computer: "merida",
    			comment: [],
    			comment_warning: "",
    		}
    end

	def initialize
      @params = self.class.default_params
		  @schedule = Schedule.where("name in ('%{schedule_name}')" % @params).first
    	@schedulerun = Schedulerun.new
    	@schedulerun.schedule_id = @schedule.id
    	@schedulerun.comment ="starting '%{schedule_name}" % @params
    	@schedulerun.save
    	@schedulerun.start_time = @schedulerun.created_at
    	@schedulerun.save
    	
    	@connection = ActiveRecord::Base.connection();

      end

    def close
      puts "closing down"
    	@schedulerun.comment =("successful finish %{schedule_name} %{comment_warning} " % @params + @params[:comment][0..1990].to_s)
    	if @params[:comment].include?("ERROR")
        	@schedulerun.status_flag ="Y"
    	end
    	@schedulerun.save
    	@schedulerun.end_time = @schedulerun.updated_at      
    	@schedulerun.save
      end

    protected
    def r_call(cmd)
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