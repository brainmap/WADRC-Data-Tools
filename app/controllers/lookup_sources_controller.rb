# encoding: utf-8
class LookupSourcesController < ApplicationController
  # GET /lookup_sources
  # GET /lookup_sources.xml
  def index
    @lookup_sources = LookupSource.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_sources }
    end
  end

  # GET /lookup_sources/1
  # GET /lookup_sources/1.xml
  def show
    @lookup_source = LookupSource.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_source }
    end
  end

  # GET /lookup_sources/new
  # GET /lookup_sources/new.xml
  def new
    @lookup_source = LookupSource.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_source }
    end
  end

  # GET /lookup_sources/1/edit
  def edit
    @lookup_source = LookupSource.find(params[:id])
  end

  # POST /lookup_sources
  # POST /lookup_sources.xml
  def create
    @lookup_source = LookupSource.new(params[:lookup_source])

    respond_to do |format|
      if @lookup_source.save
        format.html { redirect_to(@lookup_source, :notice => 'Lookup source was successfully created.') }
        format.xml  { render :xml => @lookup_source, :status => :created, :location => @lookup_source }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_source.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_sources/1
  # PUT /lookup_sources/1.xml
  def update
    @lookup_source = LookupSource.find(params[:id])

    respond_to do |format|
      if @lookup_source.update_attributes(params[:lookup_source])
        format.html { redirect_to(@lookup_source, :notice => 'Lookup source was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_source.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_sources/1
  # DELETE /lookup_sources/1.xml
  def destroy
    @lookup_source = LookupSource.find(params[:id])
    @lookup_source.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_sources_url) }
      format.xml  { head :ok }
    end
  end
end
