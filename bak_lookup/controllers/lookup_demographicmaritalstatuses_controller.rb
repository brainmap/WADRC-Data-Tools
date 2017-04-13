# encoding: utf-8
class LookupDemographicmaritalstatusesController < ApplicationController
  # GET /lookup_demographicmaritalstatuses
  # GET /lookup_demographicmaritalstatuses.xml
  def index
    @lookup_demographicmaritalstatuses = LookupDemographicmaritalstatus.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_demographicmaritalstatuses }
    end
  end

  # GET /lookup_demographicmaritalstatuses/1
  # GET /lookup_demographicmaritalstatuses/1.xml
  def show
    @lookup_demographicmaritalstatus = LookupDemographicmaritalstatus.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_demographicmaritalstatus }
    end
  end

  # GET /lookup_demographicmaritalstatuses/new
  # GET /lookup_demographicmaritalstatuses/new.xml
  def new
    @lookup_demographicmaritalstatus = LookupDemographicmaritalstatus.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_demographicmaritalstatus }
    end
  end

  # GET /lookup_demographicmaritalstatuses/1/edit
  def edit
    @lookup_demographicmaritalstatus = LookupDemographicmaritalstatus.find(params[:id])
  end

  # POST /lookup_demographicmaritalstatuses
  # POST /lookup_demographicmaritalstatuses.xml
  def create
    @lookup_demographicmaritalstatus = LookupDemographicmaritalstatus.new(params[:lookup_demographicmaritalstatus])

    respond_to do |format|
      if @lookup_demographicmaritalstatus.save
        format.html { redirect_to(@lookup_demographicmaritalstatus, :notice => 'Lookup demographicmaritalstatus was successfully created.') }
        format.xml  { render :xml => @lookup_demographicmaritalstatus, :status => :created, :location => @lookup_demographicmaritalstatus }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_demographicmaritalstatus.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_demographicmaritalstatuses/1
  # PUT /lookup_demographicmaritalstatuses/1.xml
  def update
    @lookup_demographicmaritalstatus = LookupDemographicmaritalstatus.find(params[:id])

    respond_to do |format|
      if @lookup_demographicmaritalstatus.update(params[:lookup_demographicmaritalstatus], :without_protection => true)
        format.html { redirect_to(@lookup_demographicmaritalstatus, :notice => 'Lookup demographicmaritalstatus was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_demographicmaritalstatus.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_demographicmaritalstatuses/1
  # DELETE /lookup_demographicmaritalstatuses/1.xml
  def destroy
    @lookup_demographicmaritalstatus = LookupDemographicmaritalstatus.find(params[:id])
    @lookup_demographicmaritalstatus.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_demographicmaritalstatuses_url) }
      format.xml  { head :ok }
    end
  end
end
