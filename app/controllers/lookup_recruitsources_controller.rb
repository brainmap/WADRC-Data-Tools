class LookupRecruitsourcesController < ApplicationController
  # GET /lookup_recruitsources
  # GET /lookup_recruitsources.xml
  def index
    @lookup_recruitsources = LookupRecruitsource.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_recruitsources }
    end
  end

  # GET /lookup_recruitsources/1
  # GET /lookup_recruitsources/1.xml
  def show
    @lookup_recruitsource = LookupRecruitsource.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_recruitsource }
    end
  end

  # GET /lookup_recruitsources/new
  # GET /lookup_recruitsources/new.xml
  def new
    @lookup_recruitsource = LookupRecruitsource.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_recruitsource }
    end
  end

  # GET /lookup_recruitsources/1/edit
  def edit
    @lookup_recruitsource = LookupRecruitsource.find(params[:id])
  end

  # POST /lookup_recruitsources
  # POST /lookup_recruitsources.xml
  def create
    @lookup_recruitsource = LookupRecruitsource.new(params[:lookup_recruitsource])

    respond_to do |format|
      if @lookup_recruitsource.save
        format.html { redirect_to(@lookup_recruitsource, :notice => 'Lookup recruitsource was successfully created.') }
        format.xml  { render :xml => @lookup_recruitsource, :status => :created, :location => @lookup_recruitsource }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_recruitsource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_recruitsources/1
  # PUT /lookup_recruitsources/1.xml
  def update
    @lookup_recruitsource = LookupRecruitsource.find(params[:id])

    respond_to do |format|
      if @lookup_recruitsource.update_attributes(params[:lookup_recruitsource])
        format.html { redirect_to(@lookup_recruitsource, :notice => 'Lookup recruitsource was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_recruitsource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_recruitsources/1
  # DELETE /lookup_recruitsources/1.xml
  def destroy
    @lookup_recruitsource = LookupRecruitsource.find(params[:id])
    @lookup_recruitsource.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_recruitsources_url) }
      format.xml  { head :ok }
    end
  end
end
