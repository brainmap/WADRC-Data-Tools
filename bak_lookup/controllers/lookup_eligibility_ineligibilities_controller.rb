# encoding: utf-8
class LookupEligibilityIneligibilitiesController < ApplicationController
  # GET /lookup_eligibility_ineligibilities
  # GET /lookup_eligibility_ineligibilities.xml
  def index
    @lookup_eligibility_ineligibilities = LookupEligibilityIneligibility.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_eligibility_ineligibilities }
    end
  end

  # GET /lookup_eligibility_ineligibilities/1
  # GET /lookup_eligibility_ineligibilities/1.xml
  def show
    @lookup_eligibility_ineligibility = LookupEligibilityIneligibility.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_eligibility_ineligibility }
    end
  end

  # GET /lookup_eligibility_ineligibilities/new
  # GET /lookup_eligibility_ineligibilities/new.xml
  def new
    @lookup_eligibility_ineligibility = LookupEligibilityIneligibility.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_eligibility_ineligibility }
    end
  end

  # GET /lookup_eligibility_ineligibilities/1/edit
  def edit
    @lookup_eligibility_ineligibility = LookupEligibilityIneligibility.find(params[:id])
  end

  # POST /lookup_eligibility_ineligibilities
  # POST /lookup_eligibility_ineligibilities.xml
  def create
    @lookup_eligibility_ineligibility = LookupEligibilityIneligibility.new(params[:lookup_eligibility_ineligibility])

    respond_to do |format|
      if @lookup_eligibility_ineligibility.save
        format.html { redirect_to(@lookup_eligibility_ineligibility, :notice => 'Lookup eligibility ineligibility was successfully created.') }
        format.xml  { render :xml => @lookup_eligibility_ineligibility, :status => :created, :location => @lookup_eligibility_ineligibility }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_eligibility_ineligibility.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_eligibility_ineligibilities/1
  # PUT /lookup_eligibility_ineligibilities/1.xml
  def update
    @lookup_eligibility_ineligibility = LookupEligibilityIneligibility.find(params[:id])

    respond_to do |format|
      if @lookup_eligibility_ineligibility.update(params[:lookup_eligibility_ineligibility], :without_protection => true)
        format.html { redirect_to(@lookup_eligibility_ineligibility, :notice => 'Lookup eligibility ineligibility was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_eligibility_ineligibility.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_eligibility_ineligibilities/1
  # DELETE /lookup_eligibility_ineligibilities/1.xml
  def destroy
    @lookup_eligibility_ineligibility = LookupEligibilityIneligibility.find(params[:id])
    @lookup_eligibility_ineligibility.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_eligibility_ineligibilities_url) }
      format.xml  { head :ok }
    end
  end
end
