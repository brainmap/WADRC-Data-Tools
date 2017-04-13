# encoding: utf-8
class LookupStatusesController < ApplicationController    
  before_action :set_lookup_status, only: [:show, :edit, :update, :destroy]   
	respond_to :html
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
    @lookup_status = LookupStatus.new(lookup_status_params)#params[:lookup_status])

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
      if @lookup_status.update(lookup_status_params)#params[:lookup_status], :without_protection => true)
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
  private
    def set_lookup_status
       @lookup_status = LookupStatus.find(params[:id])
    end
   def lookup_status_params
          params.require(:lookup_status).permit(:updated_at,:created_at,:status_type,:description,:id)
   end
end
