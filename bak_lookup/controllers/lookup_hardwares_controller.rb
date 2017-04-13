# encoding: utf-8
class LookupHardwaresController < ApplicationController
  # GET /lookup_hardwares
  # GET /lookup_hardwares.xml
  def index
    @lookup_hardwares = LookupHardware.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_hardwares }
    end
  end

  # GET /lookup_hardwares/1
  # GET /lookup_hardwares/1.xml
  def show
    @lookup_hardware = LookupHardware.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_hardware }
    end
  end

  # GET /lookup_hardwares/new
  # GET /lookup_hardwares/new.xml
  def new
    @lookup_hardware = LookupHardware.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_hardware }
    end
  end

  # GET /lookup_hardwares/1/edit
  def edit
    @lookup_hardware = LookupHardware.find(params[:id])
  end

  # POST /lookup_hardwares
  # POST /lookup_hardwares.xml
  def create
    @lookup_hardware = LookupHardware.new(params[:lookup_hardware])

    respond_to do |format|
      if @lookup_hardware.save
        format.html { redirect_to(@lookup_hardware, :notice => 'Lookup hardware was successfully created.') }
        format.xml  { render :xml => @lookup_hardware, :status => :created, :location => @lookup_hardware }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_hardware.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_hardwares/1
  # PUT /lookup_hardwares/1.xml
  def update
    @lookup_hardware = LookupHardware.find(params[:id])

    respond_to do |format|
      if @lookup_hardware.update(params[:lookup_hardware], :without_protection => true)
        format.html { redirect_to(@lookup_hardware, :notice => 'Lookup hardware was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_hardware.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_hardwares/1
  # DELETE /lookup_hardwares/1.xml
  def destroy
    @lookup_hardware = LookupHardware.find(params[:id])
    @lookup_hardware.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_hardwares_url) }
      format.xml  { head :ok }
    end
  end
end
