# encoding: utf-8
class LookupScantasksController < ApplicationController   
  before_action :set_lookup_scantask, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /lookup_scantasks
  # GET /lookup_scantasks.xml
  def index
    @lookup_scantasks = LookupScantask.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_scantasks }
    end
  end

  # GET /lookup_scantasks/1
  # GET /lookup_scantasks/1.xml
  def show
    @lookup_scantask = LookupScantask.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_scantask }
    end
  end

  # GET /lookup_scantasks/new
  # GET /lookup_scantasks/new.xml
  def new
    @lookup_scantask = LookupScantask.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_scantask }
    end
  end

  # GET /lookup_scantasks/1/edit
  def edit
    @lookup_scantask = LookupScantask.find(params[:id])
  end

  # POST /lookup_scantasks
  # POST /lookup_scantasks.xml
  def create
    @lookup_scantask = LookupScantask.new(lookup_scantask_params)#params[:lookup_scantask])

    respond_to do |format|
      if @lookup_scantask.save
        format.html { redirect_to(@lookup_scantask, :notice => 'Lookup scantask was successfully created.') }
        format.xml  { render :xml => @lookup_scantask, :status => :created, :location => @lookup_scantask }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_scantask.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_scantasks/1
  # PUT /lookup_scantasks/1.xml
  def update
    @lookup_scantask = LookupScantask.find(params[:id])

    respond_to do |format|
      if @lookup_scantask.update(lookup_scantask_params)#params[:lookup_scantask], :without_protection => true)
        format.html { redirect_to(@lookup_scantask, :notice => 'Lookup scantask was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_scantask.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_scantasks/1
  # DELETE /lookup_scantasks/1.xml
  def destroy
    @lookup_scantask = LookupScantask.find(params[:id])
    @lookup_scantask.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_scantasks_url) }
      format.xml  { head :ok }
    end
  end 
  private
    def set_lookup_scantask
       @lookup_scantask = LookupScantask.find(params[:id])
    end
   def lookup_scantask_params
          params.require(:lookup_scantask).permit(:updated_at,:created_at,:set_id,:task_code,:bold_reps,:pulse_sequence_code,:name,:description,:id)
   end
end
