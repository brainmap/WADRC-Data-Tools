# encoding: utf-8
class LookupCogstatusesController < ApplicationController
  # GET /lookup_cogstatuses
  # GET /lookup_cogstatuses.xml
  def index
    @lookup_cogstatuses = LookupCogstatus.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_cogstatuses }
    end
  end

  # GET /lookup_cogstatuses/1
  # GET /lookup_cogstatuses/1.xml
  def show
    @lookup_cogstatus = LookupCogstatus.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_cogstatus }
    end
  end

  # GET /lookup_cogstatuses/new
  # GET /lookup_cogstatuses/new.xml
  def new
    @lookup_cogstatus = LookupCogstatus.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_cogstatus }
    end
  end

  # GET /lookup_cogstatuses/1/edit
  def edit
    @lookup_cogstatus = LookupCogstatus.find(params[:id])
  end

  # POST /lookup_cogstatuses
  # POST /lookup_cogstatuses.xml
  def create
    @lookup_cogstatus = LookupCogstatus.new(params[:lookup_cogstatus])

    respond_to do |format|
      if @lookup_cogstatus.save
        format.html { redirect_to(@lookup_cogstatus, :notice => 'Lookup cogstatus was successfully created.') }
        format.xml  { render :xml => @lookup_cogstatus, :status => :created, :location => @lookup_cogstatus }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_cogstatus.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_cogstatuses/1
  # PUT /lookup_cogstatuses/1.xml
  def update
    @lookup_cogstatus = LookupCogstatus.find(params[:id])

    respond_to do |format|
      if @lookup_cogstatus.update_attributes(params[:lookup_cogstatus])
        format.html { redirect_to(@lookup_cogstatus, :notice => 'Lookup cogstatus was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_cogstatus.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_cogstatuses/1
  # DELETE /lookup_cogstatuses/1.xml
  def destroy
    @lookup_cogstatus = LookupCogstatus.find(params[:id])
    @lookup_cogstatus.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_cogstatuses_url) }
      format.xml  { head :ok }
    end
  end
end
