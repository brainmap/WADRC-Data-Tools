# encoding: utf-8
class LookupEligibilityoutcomesController < ApplicationController
  # GET /lookup_eligibilityoutcomes
  # GET /lookup_eligibilityoutcomes.xml
  def index
    @lookup_eligibilityoutcomes = LookupEligibilityoutcome.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_eligibilityoutcomes }
    end
  end

  # GET /lookup_eligibilityoutcomes/1
  # GET /lookup_eligibilityoutcomes/1.xml
  def show
    @lookup_eligibilityoutcome = LookupEligibilityoutcome.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_eligibilityoutcome }
    end
  end

  # GET /lookup_eligibilityoutcomes/new
  # GET /lookup_eligibilityoutcomes/new.xml
  def new
    @lookup_eligibilityoutcome = LookupEligibilityoutcome.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_eligibilityoutcome }
    end
  end

  # GET /lookup_eligibilityoutcomes/1/edit
  def edit
    @lookup_eligibilityoutcome = LookupEligibilityoutcome.find(params[:id])
  end

  # POST /lookup_eligibilityoutcomes
  # POST /lookup_eligibilityoutcomes.xml
  def create
    @lookup_eligibilityoutcome = LookupEligibilityoutcome.new(params[:lookup_eligibilityoutcome])

    respond_to do |format|
      if @lookup_eligibilityoutcome.save
        format.html { redirect_to(@lookup_eligibilityoutcome, :notice => 'Lookup eligibilityoutcome was successfully created.') }
        format.xml  { render :xml => @lookup_eligibilityoutcome, :status => :created, :location => @lookup_eligibilityoutcome }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_eligibilityoutcome.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_eligibilityoutcomes/1
  # PUT /lookup_eligibilityoutcomes/1.xml
  def update
    @lookup_eligibilityoutcome = LookupEligibilityoutcome.find(params[:id])

    respond_to do |format|
      if @lookup_eligibilityoutcome.update_attributes(params[:lookup_eligibilityoutcome])
        format.html { redirect_to(@lookup_eligibilityoutcome, :notice => 'Lookup eligibilityoutcome was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_eligibilityoutcome.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_eligibilityoutcomes/1
  # DELETE /lookup_eligibilityoutcomes/1.xml
  def destroy
    @lookup_eligibilityoutcome = LookupEligibilityoutcome.find(params[:id])
    @lookup_eligibilityoutcome.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_eligibilityoutcomes_url) }
      format.xml  { head :ok }
    end
  end
end
