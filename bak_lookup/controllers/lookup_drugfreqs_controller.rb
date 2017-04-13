# encoding: utf-8
class LookupDrugfreqsController < ApplicationController
  # GET /lookup_drugfreqs
  # GET /lookup_drugfreqs.xml
  def index
    @lookup_drugfreqs = LookupDrugfreq.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_drugfreqs }
    end
  end

  # GET /lookup_drugfreqs/1
  # GET /lookup_drugfreqs/1.xml
  def show
    @lookup_drugfreq = LookupDrugfreq.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_drugfreq }
    end
  end

  # GET /lookup_drugfreqs/new
  # GET /lookup_drugfreqs/new.xml
  def new
    @lookup_drugfreq = LookupDrugfreq.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_drugfreq }
    end
  end

  # GET /lookup_drugfreqs/1/edit
  def edit
    @lookup_drugfreq = LookupDrugfreq.find(params[:id])
  end

  # POST /lookup_drugfreqs
  # POST /lookup_drugfreqs.xml
  def create
    @lookup_drugfreq = LookupDrugfreq.new(params[:lookup_drugfreq])

    respond_to do |format|
      if @lookup_drugfreq.save
        format.html { redirect_to(@lookup_drugfreq, :notice => 'Lookup drugfreq was successfully created.') }
        format.xml  { render :xml => @lookup_drugfreq, :status => :created, :location => @lookup_drugfreq }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_drugfreq.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_drugfreqs/1
  # PUT /lookup_drugfreqs/1.xml
  def update
    @lookup_drugfreq = LookupDrugfreq.find(params[:id])

    respond_to do |format|
      if @lookup_drugfreq.update(params[:lookup_drugfreq], :without_protection => true)
        format.html { redirect_to(@lookup_drugfreq, :notice => 'Lookup drugfreq was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_drugfreq.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_drugfreqs/1
  # DELETE /lookup_drugfreqs/1.xml
  def destroy
    @lookup_drugfreq = LookupDrugfreq.find(params[:id])
    @lookup_drugfreq.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_drugfreqs_url) }
      format.xml  { head :ok }
    end
  end
end
