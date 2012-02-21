class LookupConsentcohortsController < ApplicationController
  # GET /lookup_consentcohorts
  # GET /lookup_consentcohorts.xml
  def index
    @lookup_consentcohorts = LookupConsentcohort.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_consentcohorts }
    end
  end

  # GET /lookup_consentcohorts/1
  # GET /lookup_consentcohorts/1.xml
  def show
    @lookup_consentcohort = LookupConsentcohort.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_consentcohort }
    end
  end

  # GET /lookup_consentcohorts/new
  # GET /lookup_consentcohorts/new.xml
  def new
    @lookup_consentcohort = LookupConsentcohort.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_consentcohort }
    end
  end

  # GET /lookup_consentcohorts/1/edit
  def edit
    @lookup_consentcohort = LookupConsentcohort.find(params[:id])
  end

  # POST /lookup_consentcohorts
  # POST /lookup_consentcohorts.xml
  def create
    @lookup_consentcohort = LookupConsentcohort.new(params[:lookup_consentcohort])

    respond_to do |format|
      if @lookup_consentcohort.save
        format.html { redirect_to(@lookup_consentcohort, :notice => 'Lookup consentcohort was successfully created.') }
        format.xml  { render :xml => @lookup_consentcohort, :status => :created, :location => @lookup_consentcohort }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_consentcohort.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_consentcohorts/1
  # PUT /lookup_consentcohorts/1.xml
  def update
    @lookup_consentcohort = LookupConsentcohort.find(params[:id])

    respond_to do |format|
      if @lookup_consentcohort.update_attributes(params[:lookup_consentcohort])
        format.html { redirect_to(@lookup_consentcohort, :notice => 'Lookup consentcohort was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_consentcohort.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_consentcohorts/1
  # DELETE /lookup_consentcohorts/1.xml
  def destroy
    @lookup_consentcohort = LookupConsentcohort.find(params[:id])
    @lookup_consentcohort.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_consentcohorts_url) }
      format.xml  { head :ok }
    end
  end
end
