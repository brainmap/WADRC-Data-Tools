class LookupCohortsController < ApplicationController
  # GET /lookup_cohorts
  # GET /lookup_cohorts.xml
  def index
    @lookup_cohorts = LookupCohort.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_cohorts }
    end
  end

  # GET /lookup_cohorts/1
  # GET /lookup_cohorts/1.xml
  def show
    @lookup_cohort = LookupCohort.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_cohort }
    end
  end

  # GET /lookup_cohorts/new
  # GET /lookup_cohorts/new.xml
  def new
    @lookup_cohort = LookupCohort.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_cohort }
    end
  end

  # GET /lookup_cohorts/1/edit
  def edit
    @lookup_cohort = LookupCohort.find(params[:id])
  end

  # POST /lookup_cohorts
  # POST /lookup_cohorts.xml
  def create
    @lookup_cohort = LookupCohort.new(params[:lookup_cohort])

    respond_to do |format|
      if @lookup_cohort.save
        format.html { redirect_to(@lookup_cohort, :notice => 'Lookup cohort was successfully created.') }
        format.xml  { render :xml => @lookup_cohort, :status => :created, :location => @lookup_cohort }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_cohort.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_cohorts/1
  # PUT /lookup_cohorts/1.xml
  def update
    @lookup_cohort = LookupCohort.find(params[:id])

    respond_to do |format|
      if @lookup_cohort.update_attributes(params[:lookup_cohort])
        format.html { redirect_to(@lookup_cohort, :notice => 'Lookup cohort was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_cohort.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_cohorts/1
  # DELETE /lookup_cohorts/1.xml
  def destroy
    @lookup_cohort = LookupCohort.find(params[:id])
    @lookup_cohort.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_cohorts_url) }
      format.xml  { head :ok }
    end
  end
end
