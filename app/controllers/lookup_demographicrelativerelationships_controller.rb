# encoding: utf-8
class LookupDemographicrelativerelationshipsController < ApplicationController
  # GET /lookup_demographicrelativerelationships
  # GET /lookup_demographicrelativerelationships.xml
  def index
    @lookup_demographicrelativerelationships = LookupDemographicrelativerelationship.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_demographicrelativerelationships }
    end
  end

  # GET /lookup_demographicrelativerelationships/1
  # GET /lookup_demographicrelativerelationships/1.xml
  def show
    @lookup_demographicrelativerelationship = LookupDemographicrelativerelationship.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_demographicrelativerelationship }
    end
  end

  # GET /lookup_demographicrelativerelationships/new
  # GET /lookup_demographicrelativerelationships/new.xml
  def new
    @lookup_demographicrelativerelationship = LookupDemographicrelativerelationship.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_demographicrelativerelationship }
    end
  end

  # GET /lookup_demographicrelativerelationships/1/edit
  def edit
    @lookup_demographicrelativerelationship = LookupDemographicrelativerelationship.find(params[:id])
  end

  # POST /lookup_demographicrelativerelationships
  # POST /lookup_demographicrelativerelationships.xml
  def create
    @lookup_demographicrelativerelationship = LookupDemographicrelativerelationship.new(params[:lookup_demographicrelativerelationship])

    respond_to do |format|
      if @lookup_demographicrelativerelationship.save
        format.html { redirect_to(@lookup_demographicrelativerelationship, :notice => 'Lookup demographicrelativerelationship was successfully created.') }
        format.xml  { render :xml => @lookup_demographicrelativerelationship, :status => :created, :location => @lookup_demographicrelativerelationship }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_demographicrelativerelationship.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_demographicrelativerelationships/1
  # PUT /lookup_demographicrelativerelationships/1.xml
  def update
    @lookup_demographicrelativerelationship = LookupDemographicrelativerelationship.find(params[:id])

    respond_to do |format|
      if @lookup_demographicrelativerelationship.update_attributes(params[:lookup_demographicrelativerelationship])
        format.html { redirect_to(@lookup_demographicrelativerelationship, :notice => 'Lookup demographicrelativerelationship was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_demographicrelativerelationship.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_demographicrelativerelationships/1
  # DELETE /lookup_demographicrelativerelationships/1.xml
  def destroy
    @lookup_demographicrelativerelationship = LookupDemographicrelativerelationship.find(params[:id])
    @lookup_demographicrelativerelationship.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_demographicrelativerelationships_url) }
      format.xml  { head :ok }
    end
  end
end
