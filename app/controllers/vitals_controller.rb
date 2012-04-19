class VitalsController < ApplicationController
  # GET /vitals
  # GET /vitals.xml
  def index
    @vitals = Vital.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vitals }
    end
  end

  # GET /vitals/1
  # GET /vitals/1.xml
  def show
    @vital = Vital.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vital }
    end
  end

  # GET /vitals/new
  # GET /vitals/new.xml
  def new
    @vital = Vital.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vital }
    end
  end

  # GET /vitals/1/edit
  def edit
    @vital = Vital.find(params[:id])
  end

  # POST /vitals
  # POST /vitals.xml
  def create
    @vital = Vital.new(params[:vital])

    respond_to do |format|
      if @vital.save
        format.html { redirect_to(@vital, :notice => 'Vital was successfully created.') }
        format.xml  { render :xml => @vital, :status => :created, :location => @vital }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vital.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vitals/1
  # PUT /vitals/1.xml
  def update
    @vital = Vital.find(params[:id])

    respond_to do |format|
      if @vital.update_attributes(params[:vital])
        format.html { redirect_to(@vital, :notice => 'Vital was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vital.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vitals/1
  # DELETE /vitals/1.xml
  def destroy
    @vital = Vital.find(params[:id])
    @vital.destroy

    respond_to do |format|
      format.html { redirect_to(vitals_url) }
      format.xml  { head :ok }
    end
  end
end
