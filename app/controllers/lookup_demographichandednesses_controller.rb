class LookupDemographichandednessesController < ApplicationController
  # GET /lookup_demographichandednesses
  # GET /lookup_demographichandednesses.xml
  def index
    @lookup_demographichandednesses = LookupDemographichandedness.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_demographichandednesses }
    end
  end

  # GET /lookup_demographichandednesses/1
  # GET /lookup_demographichandednesses/1.xml
  def show
    @lookup_demographichandedness = LookupDemographichandedness.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_demographichandedness }
    end
  end

  # GET /lookup_demographichandednesses/new
  # GET /lookup_demographichandednesses/new.xml
  def new
    @lookup_demographichandedness = LookupDemographichandedness.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_demographichandedness }
    end
  end

  # GET /lookup_demographichandednesses/1/edit
  def edit
    @lookup_demographichandedness = LookupDemographichandedness.find(params[:id])
  end

  # POST /lookup_demographichandednesses
  # POST /lookup_demographichandednesses.xml
  def create
    @lookup_demographichandedness = LookupDemographichandedness.new(params[:lookup_demographichandedness])

    respond_to do |format|
      if @lookup_demographichandedness.save
        format.html { redirect_to(@lookup_demographichandedness, :notice => 'Lookup demographichandedness was successfully created.') }
        format.xml  { render :xml => @lookup_demographichandedness, :status => :created, :location => @lookup_demographichandedness }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_demographichandedness.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_demographichandednesses/1
  # PUT /lookup_demographichandednesses/1.xml
  def update
    @lookup_demographichandedness = LookupDemographichandedness.find(params[:id])

    respond_to do |format|
      if @lookup_demographichandedness.update_attributes(params[:lookup_demographichandedness])
        format.html { redirect_to(@lookup_demographichandedness, :notice => 'Lookup demographichandedness was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_demographichandedness.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_demographichandednesses/1
  # DELETE /lookup_demographichandednesses/1.xml
  def destroy
    @lookup_demographichandedness = LookupDemographichandedness.find(params[:id])
    @lookup_demographichandedness.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_demographichandednesses_url) }
      format.xml  { head :ok }
    end
  end
end
