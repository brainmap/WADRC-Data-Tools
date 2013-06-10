# encoding: utf-8
class SchedulerunsController < ApplicationController
  # GET /scheduleruns
  # GET /scheduleruns.xml
  def index
    @scheduleruns = Schedulerun.order("id DESC")

    respond_to do |format|
      format.html {@scheduleruns = Kaminari.paginate_array(@scheduleruns).page(params[:page]).per(50)}# index.html.erb
      format.xml  { render :xml => @scheduleruns }
    end
  end

  # GET /scheduleruns/1
  # GET /scheduleruns/1.xml
  def show
    @schedulerun = Schedulerun.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @schedulerun }
    end
  end

  # GET /scheduleruns/new
  # GET /scheduleruns/new.xml
  def new
    @schedulerun = Schedulerun.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @schedulerun }
    end
  end

  # GET /scheduleruns/1/edit
  def edit
    @schedulerun = Schedulerun.find(params[:id])
  end

  # POST /scheduleruns
  # POST /scheduleruns.xml
  def create
    @schedulerun = Schedulerun.new(params[:schedulerun])

    respond_to do |format|
      if @schedulerun.save
        format.html { redirect_to(@schedulerun, :notice => 'Schedulerun was successfully created.') }
        format.xml  { render :xml => @schedulerun, :status => :created, :location => @schedulerun }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @schedulerun.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /scheduleruns/1
  # PUT /scheduleruns/1.xml
  def update
    @schedulerun = Schedulerun.find(params[:id])

    respond_to do |format|
      if @schedulerun.update_attributes(params[:schedulerun])
        format.html { redirect_to(@schedulerun, :notice => 'Schedulerun was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @schedulerun.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /scheduleruns/1
  # DELETE /scheduleruns/1.xml
  def destroy
    @schedulerun = Schedulerun.find(params[:id])
    @schedulerun.destroy

    respond_to do |format|
      format.html { redirect_to(schedulerun_search_url) }
      format.xml  { head :ok }
    end
  end
  
  def schedulerun_search
    @schedules = Schedule.order("name")
    @conditions = []
    @current_tab = "vgroups"
    params["search_criteria"] =""

    if params[:schedulerun_search].nil?
         params[:schedulerun_search] =Hash.new  
    end
    if current_user.role == 'Admin_High' or current_user.role == 'Admin_Low' 
      # no limit
    else
      condition =" scheduleruns.schedule_id in ( select schedules_users.schedule_id from schedules_users where user_id in ("+current_user.id.to_s+")) "
      @conditions.push(condition)
    end
    
    if !params[:schedulerun_search][:status_flag].blank?
        var = params[:schedulerun_search][:status_flag]
        condition =" scheduleruns.status_flag  = '"+var.gsub(/[;:'"()=<>]/, '')+"' "
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +", Status flag= "+params[:schedulerun_search][:status_flag]
    end
    
    if !params[:schedulerun_search][:schedule_id].blank?
        var = params[:schedulerun_search][:schedule_id]
        condition =" scheduleruns.schedule_id  = '"+var.gsub(/[;:'"()=<>]/, '')+"' "
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +", Schedule= "+Schedule.find(params[:schedulerun_search][:schedule_id]).name
    end
    
    #  build expected date format --- between, >, < 
    v_date_latest =""
    #want all three date parts
    if !params[:schedulerun_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:schedulerun_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:schedulerun_search]["#{'latest_timestamp'}(3i)"].blank?
         v_date_latest = params[:schedulerun_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:schedulerun_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:schedulerun_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
    end
    v_date_earliest =""
    #want all three date parts
    if !params[:schedulerun_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:schedulerun_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:schedulerun_search]["#{'earliest_timestamp'}(3i)"].blank?
          v_date_earliest = params[:schedulerun_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:schedulerun_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:schedulerun_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
     end
    v_date_latest = v_date_latest.gsub(/[;:'"()=<>]/, '')
    v_date_earliest = v_date_earliest.gsub(/[;:'"()=<>]/, '')
    if v_date_latest.length>0 && v_date_earliest.length >0
      condition ="   scheduleruns.start_time between '"+v_date_earliest+"' and '"+v_date_latest+"' "
      @conditions.push(condition)
      params["search_criteria"] = params["search_criteria"] +",  run date between "+v_date_earliest+" and "+v_date_latest
    elsif v_date_latest.length>0
      condition ="  scheduleruns.start_time < '"+v_date_latest+"'  "
       @conditions.push(condition)
       params["search_criteria"] = params["search_criteria"] +",  run time before "+v_date_latest 
    elsif  v_date_earliest.length >0
      condition ="  scheduleruns.start_time > '"+v_date_earliest+"' "
       @conditions.push(condition)
       params["search_criteria"] = params["search_criteria"] +",  run time after "+v_date_earliest
     end   
      @tables =['scheduleruns'] # trigger joins --- vgroups and appointments by default
      @order_by =["scheduleruns.id DESC"]
       sql = "select scheduleruns.id from "+@tables.join(",")
       if @conditions.size > 0
             sql = sql +" WHERE  "+@conditions.join(' and ')
       end
      #conditions - feed thru ActiveRecord? stop sql injection -- replace : ; " ' ( ) = < > - others?
       if @order_by.size > 0
         sql = sql +" ORDER BY "+@order_by.join(',')
       end
       connection = ActiveRecord::Base.connection();
       @results = connection.execute(sql)

     @results_total = @results # pageination makes result count wrong
      @results_total_size = @results.size

     t = Time.now 
     @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
    @scheduleruns = Schedulerun.order("id DESC")
    
    respond_to do |format|
      format.xls # pet_search.xls.erb
      format.html {@results = Kaminari.paginate_array(@results.to_a).page(params[:page]).per(50)}# index.html.erb
      format.xml  { render :xml => @scheduleruns }
    end
    
  end
end
