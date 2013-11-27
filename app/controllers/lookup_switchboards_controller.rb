# encoding: utf-8
class LookupSwitchboardsController < ApplicationController
  # GET /lookup_switchboards
  # GET /lookup_switchboards.xml
  def index
    @lookup_switchboards = LookupSwitchboard.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_switchboards }
    end
  end

  # GET /lookup_switchboards/1
  # GET /lookup_switchboards/1.xml
  def show
    @lookup_switchboard = LookupSwitchboard.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_switchboard }
    end
  end

  # GET /lookup_switchboards/new
  # GET /lookup_switchboards/new.xml
  def new
    @lookup_switchboard = LookupSwitchboard.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_switchboard }
    end
  end

  # GET /lookup_switchboards/1/edit
  def edit
    @lookup_switchboard = LookupSwitchboard.find(params[:id])
  end

  # POST /lookup_switchboards
  # POST /lookup_switchboards.xml
  def create
    @lookup_switchboard = LookupSwitchboard.new(params[:lookup_switchboard])

    respond_to do |format|
      if @lookup_switchboard.save
        format.html { redirect_to(@lookup_switchboard, :notice => 'Lookup switchboard was successfully created.') }
        format.xml  { render :xml => @lookup_switchboard, :status => :created, :location => @lookup_switchboard }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_switchboard.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_switchboards/1
  # PUT /lookup_switchboards/1.xml
  def update
    @lookup_switchboard = LookupSwitchboard.find(params[:id])

    respond_to do |format|
      if @lookup_switchboard.update_attributes(params[:lookup_switchboard])
        format.html { redirect_to(@lookup_switchboard, :notice => 'Lookup switchboard was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_switchboard.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_switchboards/1
  # DELETE /lookup_switchboards/1.xml
  def destroy
    @lookup_switchboard = LookupSwitchboard.find(params[:id])
    @lookup_switchboard.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_switchboards_url) }
      format.xml  { head :ok }
    end
  end
end
