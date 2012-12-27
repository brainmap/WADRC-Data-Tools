class SchedulerunsController < ApplicationController
  # GET /scheduleruns
  # GET /scheduleruns.xml
  def index
    @scheduleruns = Schedulerun.all

    respond_to do |format|
      format.html # index.html.erb
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
      format.html { redirect_to(scheduleruns_url) }
      format.xml  { head :ok }
    end
  end
end
