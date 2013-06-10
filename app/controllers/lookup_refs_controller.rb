# encoding: utf-8
class LookupRefsController < ApplicationController
  # GET /lookup_refs
  # GET /lookup_refs.xml
  def index
    @lookup_refs = LookupRef.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_refs }
    end
  end

  # GET /lookup_refs/1
  # GET /lookup_refs/1.xml
  def show
    @lookup_ref = LookupRef.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_ref }
    end
  end

  # GET /lookup_refs/new
  # GET /lookup_refs/new.xml
  def new
    @lookup_ref = LookupRef.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_ref }
    end
  end

  # GET /lookup_refs/1/edit
  def edit
    @lookup_ref = LookupRef.find(params[:id])
  end

  # POST /lookup_refs
  # POST /lookup_refs.xml
  def create
    @lookup_ref = LookupRef.new(params[:lookup_ref])

    respond_to do |format|
      if @lookup_ref.save
        format.html { redirect_to(@lookup_ref, :notice => 'Lookup ref was successfully created.') }
        format.xml  { render :xml => @lookup_ref, :status => :created, :location => @lookup_ref }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_ref.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_refs/1
  # PUT /lookup_refs/1.xml
  def update
    @lookup_ref = LookupRef.find(params[:id])

    respond_to do |format|
      if @lookup_ref.update_attributes(params[:lookup_ref])
        format.html { redirect_to(@lookup_ref, :notice => 'Lookup ref was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_ref.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_refs/1
  # DELETE /lookup_refs/1.xml
  def destroy
    @lookup_ref = LookupRef.find(params[:id])
    @lookup_ref.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_refs_url) }
      format.xml  { head :ok }
    end
  end
end
