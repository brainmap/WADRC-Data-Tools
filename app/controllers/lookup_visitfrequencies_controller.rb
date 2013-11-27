# encoding: utf-8
class LookupVisitfrequenciesController < ApplicationController
  # GET /lookup_visitfrequencies
  # GET /lookup_visitfrequencies.xml
  def index
    @lookup_visitfrequencies = LookupVisitfrequency.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_visitfrequencies }
    end
  end

  # GET /lookup_visitfrequencies/1
  # GET /lookup_visitfrequencies/1.xml
  def show
    @lookup_visitfrequency = LookupVisitfrequency.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_visitfrequency }
    end
  end

  # GET /lookup_visitfrequencies/new
  # GET /lookup_visitfrequencies/new.xml
  def new
    @lookup_visitfrequency = LookupVisitfrequency.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_visitfrequency }
    end
  end

  # GET /lookup_visitfrequencies/1/edit
  def edit
    @lookup_visitfrequency = LookupVisitfrequency.find(params[:id])
  end

  # POST /lookup_visitfrequencies
  # POST /lookup_visitfrequencies.xml
  def create
    @lookup_visitfrequency = LookupVisitfrequency.new(params[:lookup_visitfrequency])

    respond_to do |format|
      if @lookup_visitfrequency.save
        format.html { redirect_to(@lookup_visitfrequency, :notice => 'Lookup visitfrequency was successfully created.') }
        format.xml  { render :xml => @lookup_visitfrequency, :status => :created, :location => @lookup_visitfrequency }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_visitfrequency.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_visitfrequencies/1
  # PUT /lookup_visitfrequencies/1.xml
  def update
    @lookup_visitfrequency = LookupVisitfrequency.find(params[:id])

    respond_to do |format|
      if @lookup_visitfrequency.update_attributes(params[:lookup_visitfrequency])
        format.html { redirect_to(@lookup_visitfrequency, :notice => 'Lookup visitfrequency was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_visitfrequency.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_visitfrequencies/1
  # DELETE /lookup_visitfrequencies/1.xml
  def destroy
    @lookup_visitfrequency = LookupVisitfrequency.find(params[:id])
    @lookup_visitfrequency.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_visitfrequencies_url) }
      format.xml  { head :ok }
    end
  end
end
