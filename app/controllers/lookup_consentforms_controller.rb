# encoding: utf-8
class LookupConsentformsController < ApplicationController
  # GET /lookup_consentforms
  # GET /lookup_consentforms.xml
  def index
    @lookup_consentforms = LookupConsentform.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_consentforms }
    end
  end

  # GET /lookup_consentforms/1
  # GET /lookup_consentforms/1.xml
  def show
    @lookup_consentform = LookupConsentform.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_consentform }
    end
  end

  # GET /lookup_consentforms/new
  # GET /lookup_consentforms/new.xml
  def new
    @lookup_consentform = LookupConsentform.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_consentform }
    end
  end

  # GET /lookup_consentforms/1/edit
  def edit
    @lookup_consentform = LookupConsentform.find(params[:id])
  end

  # POST /lookup_consentforms
  # POST /lookup_consentforms.xml
  def create
    @lookup_consentform = LookupConsentform.new(params[:lookup_consentform])

    respond_to do |format|
      if @lookup_consentform.save
        format.html { redirect_to(@lookup_consentform, :notice => 'Lookup consentform was successfully created.') }
        format.xml  { render :xml => @lookup_consentform, :status => :created, :location => @lookup_consentform }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_consentform.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_consentforms/1
  # PUT /lookup_consentforms/1.xml
  def update
    @lookup_consentform = LookupConsentform.find(params[:id])

    respond_to do |format|
      if @lookup_consentform.update_attributes(params[:lookup_consentform])
        format.html { redirect_to(@lookup_consentform, :notice => 'Lookup consentform was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_consentform.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_consentforms/1
  # DELETE /lookup_consentforms/1.xml
  def destroy
    @lookup_consentform = LookupConsentform.find(params[:id])
    @lookup_consentform.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_consentforms_url) }
      format.xml  { head :ok }
    end
  end
end
