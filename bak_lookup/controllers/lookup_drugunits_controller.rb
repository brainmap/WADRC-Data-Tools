# encoding: utf-8
class LookupDrugunitsController < ApplicationController
  # GET /lookup_drugunits
  # GET /lookup_drugunits.xml
  def index
    @lookup_drugunits = LookupDrugunit.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_drugunits }
    end
  end

  # GET /lookup_drugunits/1
  # GET /lookup_drugunits/1.xml
  def show
    @lookup_drugunit = LookupDrugunit.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_drugunit }
    end
  end

  # GET /lookup_drugunits/new
  # GET /lookup_drugunits/new.xml
  def new
    @lookup_drugunit = LookupDrugunit.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_drugunit }
    end
  end

  # GET /lookup_drugunits/1/edit
  def edit
    @lookup_drugunit = LookupDrugunit.find(params[:id])
  end

  # POST /lookup_drugunits
  # POST /lookup_drugunits.xml
  def create
    @lookup_drugunit = LookupDrugunit.new(params[:lookup_drugunit])

    respond_to do |format|
      if @lookup_drugunit.save
        format.html { redirect_to(@lookup_drugunit, :notice => 'Lookup drugunit was successfully created.') }
        format.xml  { render :xml => @lookup_drugunit, :status => :created, :location => @lookup_drugunit }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_drugunit.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_drugunits/1
  # PUT /lookup_drugunits/1.xml
  def update
    @lookup_drugunit = LookupDrugunit.find(params[:id])

    respond_to do |format|
      if @lookup_drugunit.update(params[:lookup_drugunit], :without_protection => true)
        format.html { redirect_to(@lookup_drugunit, :notice => 'Lookup drugunit was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_drugunit.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_drugunits/1
  # DELETE /lookup_drugunits/1.xml
  def destroy
    @lookup_drugunit = LookupDrugunit.find(params[:id])
    @lookup_drugunit.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_drugunits_url) }
      format.xml  { head :ok }
    end
  end
end
