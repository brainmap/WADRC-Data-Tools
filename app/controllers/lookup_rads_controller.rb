class LookupRadsController < ApplicationController
  # GET /lookup_rads
  # GET /lookup_rads.xml
  def index
    @lookup_rads = LookupRad.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_rads }
    end
  end

  # GET /lookup_rads/1
  # GET /lookup_rads/1.xml
  def show
    @lookup_rad = LookupRad.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_rad }
    end
  end

  # GET /lookup_rads/new
  # GET /lookup_rads/new.xml
  def new
    @lookup_rad = LookupRad.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_rad }
    end
  end

  # GET /lookup_rads/1/edit
  def edit
    @lookup_rad = LookupRad.find(params[:id])
  end

  # POST /lookup_rads
  # POST /lookup_rads.xml
  def create
    @lookup_rad = LookupRad.new(params[:lookup_rad])

    respond_to do |format|
      if @lookup_rad.save
        format.html { redirect_to(@lookup_rad, :notice => 'Lookup rad was successfully created.') }
        format.xml  { render :xml => @lookup_rad, :status => :created, :location => @lookup_rad }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_rad.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_rads/1
  # PUT /lookup_rads/1.xml
  def update
    @lookup_rad = LookupRad.find(params[:id])

    respond_to do |format|
      if @lookup_rad.update_attributes(params[:lookup_rad])
        format.html { redirect_to(@lookup_rad, :notice => 'Lookup rad was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_rad.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_rads/1
  # DELETE /lookup_rads/1.xml
  def destroy
    @lookup_rad = LookupRad.find(params[:id])
    @lookup_rad.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_rads_url) }
      format.xml  { head :ok }
    end
  end
end
