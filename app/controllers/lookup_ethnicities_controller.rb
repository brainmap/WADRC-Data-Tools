# encoding: utf-8
class LookupEthnicitiesController < ApplicationController
  # GET /lookup_ethnicities
  # GET /lookup_ethnicities.xml
  def index
    @lookup_ethnicities = LookupEthnicity.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_ethnicities }
    end
  end

  # GET /lookup_ethnicities/1
  # GET /lookup_ethnicities/1.xml
  def show
    @lookup_ethnicity = LookupEthnicity.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_ethnicity }
    end
  end

  # GET /lookup_ethnicities/new
  # GET /lookup_ethnicities/new.xml
  def new
    @lookup_ethnicity = LookupEthnicity.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_ethnicity }
    end
  end

  # GET /lookup_ethnicities/1/edit
  def edit
    @lookup_ethnicity = LookupEthnicity.find(params[:id])
  end

  # POST /lookup_ethnicities
  # POST /lookup_ethnicities.xml
  def create
    @lookup_ethnicity = LookupEthnicity.new(params[:lookup_ethnicity])

    respond_to do |format|
      if @lookup_ethnicity.save
        format.html { redirect_to(@lookup_ethnicity, :notice => 'Lookup ethnicity was successfully created.') }
        format.xml  { render :xml => @lookup_ethnicity, :status => :created, :location => @lookup_ethnicity }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_ethnicity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_ethnicities/1
  # PUT /lookup_ethnicities/1.xml
  def update
    @lookup_ethnicity = LookupEthnicity.find(params[:id])

    respond_to do |format|
      if @lookup_ethnicity.update_attributes(params[:lookup_ethnicity])
        format.html { redirect_to(@lookup_ethnicity, :notice => 'Lookup ethnicity was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_ethnicity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_ethnicities/1
  # DELETE /lookup_ethnicities/1.xml
  def destroy
    @lookup_ethnicity = LookupEthnicity.find(params[:id])
    @lookup_ethnicity.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_ethnicities_url) }
      format.xml  { head :ok }
    end
  end
end
