# encoding: utf-8
class LookupLumbarpuncturesController < ApplicationController
  # GET /lookup_lumbarpunctures
  # GET /lookup_lumbarpunctures.xml
  def index
    @lookup_lumbarpunctures = LookupLumbarpuncture.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_lumbarpunctures }
    end
  end

  # GET /lookup_lumbarpunctures/1
  # GET /lookup_lumbarpunctures/1.xml
  def show
    @lookup_lumbarpuncture = LookupLumbarpuncture.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_lumbarpuncture }
    end
  end

  # GET /lookup_lumbarpunctures/new
  # GET /lookup_lumbarpunctures/new.xml
  def new
    @lookup_lumbarpuncture = LookupLumbarpuncture.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_lumbarpuncture }
    end
  end

  # GET /lookup_lumbarpunctures/1/edit
  def edit
    @lookup_lumbarpuncture = LookupLumbarpuncture.find(params[:id])
  end

  # POST /lookup_lumbarpunctures
  # POST /lookup_lumbarpunctures.xml
  def create
    @lookup_lumbarpuncture = LookupLumbarpuncture.new(params[:lookup_lumbarpuncture])

    respond_to do |format|
      if @lookup_lumbarpuncture.save
        format.html { redirect_to(@lookup_lumbarpuncture, :notice => 'Lookup lumbarpuncture was successfully created.') }
        format.xml  { render :xml => @lookup_lumbarpuncture, :status => :created, :location => @lookup_lumbarpuncture }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_lumbarpuncture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_lumbarpunctures/1
  # PUT /lookup_lumbarpunctures/1.xml
  def update
    @lookup_lumbarpuncture = LookupLumbarpuncture.find(params[:id])

    respond_to do |format|
      if @lookup_lumbarpuncture.update_attributes(params[:lookup_lumbarpuncture])
        format.html { redirect_to(@lookup_lumbarpuncture, :notice => 'Lookup lumbarpuncture was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_lumbarpuncture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_lumbarpunctures/1
  # DELETE /lookup_lumbarpunctures/1.xml
  def destroy
    @lookup_lumbarpuncture = LookupLumbarpuncture.find(params[:id])
    @lookup_lumbarpuncture.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_lumbarpunctures_url) }
      format.xml  { head :ok }
    end
  end
end
