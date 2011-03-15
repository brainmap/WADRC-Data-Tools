class LogFilesController < ApplicationController
  before_filter :set_current_tab
  
  def set_current_tab
    @current_tab = "log_files"
  end
  # GET /log_files
  # GET /log_files.xml
  def index
    @log_files = LogFile.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @log_files }
    end
  end

  # GET /log_files/1
  # GET /log_files/1.xml
  def show
    @response_times = []
    @log_file = LogFile.find(params[:id])
    @log_file.log_file_entries.each do |e|
      begin
        s = Kernel.Float(e.stimulus_time)
        r = Kernel.Float(e.response_time)
        @response_times << r - s
      rescue StandardError
         # One of the quantities is not a number, do nothing.
      end
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @log_file }
    end
  end

  # GET /log_files/new
  # GET /log_files/new.xml
  def new
    @log_file = LogFile.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @log_file }
    end
  end

  # GET /log_files/1/edit
  def edit
    @log_file = LogFile.find(params[:id])
  end

  # POST /log_files
  # POST /log_files.xml
  def create
    @log_file = LogFile.new(params[:log_file])

    respond_to do |format|
      if @log_file.save
        flash[:notice] = 'LogFile was successfully created.'
        format.html { redirect_to(@log_file) }
        format.xml  { render :xml => @log_file, :status => :created, :location => @log_file }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @log_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /log_files/1
  # PUT /log_files/1.xml
  def update
    @log_file = LogFile.find(params[:id])

    respond_to do |format|
      if @log_file.update_attributes(params[:log_file])
        flash[:notice] = 'LogFile was successfully updated.'
        format.html { redirect_to(@log_file) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @log_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /log_files/1
  # DELETE /log_files/1.xml
  def destroy
    @log_file = LogFile.find(params[:id])
    @log_file.destroy

    respond_to do |format|
      format.html { redirect_to(log_files_url) }
      format.xml  { head :ok }
    end
  end
end
