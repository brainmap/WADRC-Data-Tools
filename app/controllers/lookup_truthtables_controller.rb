class LookupTruthtablesController < ApplicationController
  # GET /lookup_truthtables
  # GET /lookup_truthtables.xml
  def index
    @lookup_truthtables = LookupTruthtable.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_truthtables }
    end
  end

  # GET /lookup_truthtables/1
  # GET /lookup_truthtables/1.xml
  def show
    @lookup_truthtable = LookupTruthtable.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_truthtable }
    end
  end

  # GET /lookup_truthtables/new
  # GET /lookup_truthtables/new.xml
  def new
    @lookup_truthtable = LookupTruthtable.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_truthtable }
    end
  end

  # GET /lookup_truthtables/1/edit
  def edit
    @lookup_truthtable = LookupTruthtable.find(params[:id])
  end

  # POST /lookup_truthtables
  # POST /lookup_truthtables.xml
  def create
    @lookup_truthtable = LookupTruthtable.new(params[:lookup_truthtable])

    respond_to do |format|
      if @lookup_truthtable.save
        format.html { redirect_to(@lookup_truthtable, :notice => 'Lookup truthtable was successfully created.') }
        format.xml  { render :xml => @lookup_truthtable, :status => :created, :location => @lookup_truthtable }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_truthtable.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_truthtables/1
  # PUT /lookup_truthtables/1.xml
  def update
    @lookup_truthtable = LookupTruthtable.find(params[:id])

    respond_to do |format|
      if @lookup_truthtable.update_attributes(params[:lookup_truthtable])
        format.html { redirect_to(@lookup_truthtable, :notice => 'Lookup truthtable was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_truthtable.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_truthtables/1
  # DELETE /lookup_truthtables/1.xml
  def destroy
    @lookup_truthtable = LookupTruthtable.find(params[:id])
    @lookup_truthtable.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_truthtables_url) }
      format.xml  { head :ok }
    end
  end
end
