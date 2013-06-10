# encoding: utf-8
class LookupScantasksController < ApplicationController
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
    @lookup_scantask = LookupScantask.new(params[:lookup_scantask])

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
      if @lookup_scantask.update_attributes(params[:lookup_scantask])
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
end
