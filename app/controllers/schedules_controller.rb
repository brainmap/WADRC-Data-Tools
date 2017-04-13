# encoding: utf-8
class SchedulesController < ApplicationController
  # GET /schedules
  # GET /schedules.xml
  def index
    @schedules = Schedule.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @schedules }
    end
  end

  # GET /schedules/1
  # GET /schedules/1.xml
  def show
    @schedule = Schedule.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @schedule }
    end
  end
  
  def run_schedule
    # check permissions
    
    @schedule = Schedule.find(params[:id])
    if @schedule.users.include?( current_user) or (current_user.role == 'Admin_High' or current_user.role == 'Admin_Low')
      # find location of first cd, trim to before that -- the cronjob times
    #   v_run_command = @schedule.run_command[@schedule.run_command.index('cd')..@schedule.run_command.length]
      # need to spawn child process
     #  exec v_run_command  -- moved from cron interface to shared function
      if !@schedule.shared_function_name.blank?
         v_shared = Shared.new
         # v_shared.send(@schedule.shared_function_name)
         v_shared.send(@schedule.shared_function_name)    # should this be instance_eval
      end
      respond_to do |format|
        format.html { redirect_to(schedulerun_search_url) }
        format.xml  { head :ok }
      end
     end
  
  end
  
  
  def stop_schedule
    # check permissions
    visit = Visit.find(3)  #  need to get base path without visit
    v_base_path = visit.get_base_path()
    @schedule = Schedule.find(params[:id])
    v_file_path = v_base_path+"/preprocessed/logs/"+@schedule.name+"_stop"
    if @schedule.users.include?( current_user) or (current_user.role == 'Admin_High' or current_user.role == 'Admin_Low')
      # find location of first cd, trim to before that -- the cronjob times
    #   v_run_command = @schedule.run_command[@schedule.run_command.index('cd')..@schedule.run_command.length]
      # need to spawn child process
     #  exec v_run_command  -- moved from cron interface to shared function
      if !@schedule.name.blank?
         v_shared = Shared.new
         v_shared.make_schedule_process_stop_file(v_file_path)
      end
      respond_to do |format|
        format.html { redirect_to(schedulerun_search_url) }
        format.xml  { head :ok }
      end
     end
  
  end

  # GET /schedules/new
  # GET /schedules/new.xml
  def new
    @schedule = Schedule.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @schedule }
    end
  end

  # GET /schedules/1/edit
  def edit
    @schedule = Schedule.find(params[:id])
  end

  # POST /schedules
  # POST /schedules.xml
  def create
    @schedule = Schedule.new(schedule_params)#params[:schedule])

    respond_to do |format|
      if @schedule.save
        @schedule.target_table = (@schedule.target_table).strip
        @schedule.save
        format.html { redirect_to(@schedule, :notice => 'Schedule was successfully created.') }
        format.xml  { render :xml => @schedule, :status => :created, :location => @schedule }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @schedule.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /schedules/1
  # PUT /schedules/1.xml
  def update
    @schedule = Schedule.find(params[:id])

    respond_to do |format|
      
      if @schedule.update(schedule_params)#params[:schedule], :without_protection => true)
        if params[:schedule][:user_ids].blank?
           params[:schedule][:user_ids]=""
           @schedule.update(schedule_params) #params[:schedule], :without_protection => true)
        end
        @schedule.target_table = (@schedule.target_table).strip
        @schedule.save
        format.html { redirect_to(@schedule, :notice => 'Schedule was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @schedule.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /schedules/1
  # DELETE /schedules/1.xml
  def destroy
    @schedule = Schedule.find(params[:id])
    @schedule.destroy

    respond_to do |format|
      format.html { redirect_to(schedules_url) }
      format.xml  { head :ok }
    end
  end 
  private
    def set_schedule
       @schedule = Schedule.find(params[:id])
    end
   def schedule_params
          params.require(:schedule).permit(:file_columns_included,:file_key_source_column,:file_path,:key_type,:target_table_columns,:process_stop_file_flag,:run_as_user,:run_on_machine,:make_unique_export_id,:file_header,:file_upload_flag,:shared_function_name,:id,:run_command,:parameters,:description,:run_time_length_min,:status_flag,:target_table,:target_column,:name,user_ids: [])
   end 

#    def set_schedules_user
#       @schedules_user = SchedulesUser.find(params[:id])
#    end
#   def schedules_user_params
#          params.require(:schedules_user).permit(:schedule_id,:user_id)
#   end
end
