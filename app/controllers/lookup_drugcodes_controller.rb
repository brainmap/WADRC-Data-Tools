# encoding: utf-8
class LookupDrugcodesController < ApplicationController
  # GET /lookup_drugcodes
  # GET /lookup_drugcodes.xml
  def index
    @lookup_drugcodes = LookupDrugcode.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_drugcodes }
    end
  end

  # GET /lookup_drugcodes/1
  # GET /lookup_drugcodes/1.xml
  def show
    @lookup_drugcode = LookupDrugcode.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_drugcode }
    end
  end

  # GET /lookup_drugcodes/new
  # GET /lookup_drugcodes/new.xml
  def new
    @lookup_drugcode = LookupDrugcode.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_drugcode }
    end
  end

  # GET /lookup_drugcodes/1/edit
  def edit
    @lookup_drugcode = LookupDrugcode.find(params[:id])
  end

  # POST /lookup_drugcodes
  # POST /lookup_drugcodes.xml
  def create
    @lookup_drugcode = LookupDrugcode.new(params[:lookup_drugcode])

    respond_to do |format|
      if @lookup_drugcode.save
        format.html { redirect_to(@lookup_drugcode, :notice => 'Lookup drugcode was successfully created.') }
        format.xml  { render :xml => @lookup_drugcode, :status => :created, :location => @lookup_drugcode }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_drugcode.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_drugcodes/1
  # PUT /lookup_drugcodes/1.xml
  def update
    @lookup_drugcode = LookupDrugcode.find(params[:id])

    respond_to do |format|
      if @lookup_drugcode.update_attributes(params[:lookup_drugcode])
        format.html { redirect_to(@lookup_drugcode, :notice => 'Lookup drugcode was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_drugcode.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_drugcodes/1
  # DELETE /lookup_drugcodes/1.xml
  def destroy
    @lookup_drugcode = LookupDrugcode.find(params[:id])
    @lookup_drugcode.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_drugcodes_url) }
      format.xml  { head :ok }
    end
  end
end
