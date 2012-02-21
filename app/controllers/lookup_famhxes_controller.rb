class LookupFamhxesController < ApplicationController
  # GET /lookup_famhxes
  # GET /lookup_famhxes.xml
  def index
    @lookup_famhxes = LookupFamhx.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_famhxes }
    end
  end

  # GET /lookup_famhxes/1
  # GET /lookup_famhxes/1.xml
  def show
    @lookup_famhx = LookupFamhx.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_famhx }
    end
  end

  # GET /lookup_famhxes/new
  # GET /lookup_famhxes/new.xml
  def new
    @lookup_famhx = LookupFamhx.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_famhx }
    end
  end

  # GET /lookup_famhxes/1/edit
  def edit
    @lookup_famhx = LookupFamhx.find(params[:id])
  end

  # POST /lookup_famhxes
  # POST /lookup_famhxes.xml
  def create
    @lookup_famhx = LookupFamhx.new(params[:lookup_famhx])

    respond_to do |format|
      if @lookup_famhx.save
        format.html { redirect_to(@lookup_famhx, :notice => 'Lookup famhx was successfully created.') }
        format.xml  { render :xml => @lookup_famhx, :status => :created, :location => @lookup_famhx }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_famhx.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_famhxes/1
  # PUT /lookup_famhxes/1.xml
  def update
    @lookup_famhx = LookupFamhx.find(params[:id])

    respond_to do |format|
      if @lookup_famhx.update_attributes(params[:lookup_famhx])
        format.html { redirect_to(@lookup_famhx, :notice => 'Lookup famhx was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_famhx.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_famhxes/1
  # DELETE /lookup_famhxes/1.xml
  def destroy
    @lookup_famhx = LookupFamhx.find(params[:id])
    @lookup_famhx.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_famhxes_url) }
      format.xml  { head :ok }
    end
  end
end
