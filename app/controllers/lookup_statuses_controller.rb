class LookupStatusesController < ApplicationController
  # GET /lookup_statuses
  # GET /lookup_statuses.xml
  def index
    @lookup_statuses = LookupStatus.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_statuses }
    end
  end

  # GET /lookup_statuses/1
  # GET /lookup_statuses/1.xml
  def show
    @lookup_status = LookupStatus.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_status }
    end
  end

  # GET /lookup_statuses/new
  # GET /lookup_statuses/new.xml
  def new
    @lookup_status = LookupStatus.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_status }
    end
  end

  # GET /lookup_statuses/1/edit
  def edit
    @lookup_status = LookupStatus.find(params[:id])
  end

  # POST /lookup_statuses
  # POST /lookup_statuses.xml
  def create
    @lookup_status = LookupStatus.new(params[:lookup_status])

    respond_to do |format|
      if @lookup_status.save
        format.html { redirect_to(@lookup_status, :notice => 'Lookup status was successfully created.') }
        format.xml  { render :xml => @lookup_status, :status => :created, :location => @lookup_status }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_status.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_statuses/1
  # PUT /lookup_statuses/1.xml
  def update
    @lookup_status = LookupStatus.find(params[:id])

    respond_to do |format|
      if @lookup_status.update_attributes(params[:lookup_status])
        format.html { redirect_to(@lookup_status, :notice => 'Lookup status was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_status.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_statuses/1
  # DELETE /lookup_statuses/1.xml
  def destroy
    @lookup_status = LookupStatus.find(params[:id])
    @lookup_status.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_statuses_url) }
      format.xml  { head :ok }
    end
  end
end
