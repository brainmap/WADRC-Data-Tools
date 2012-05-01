class MriperformancesController < ApplicationController
  # GET /mriperformances
  # GET /mriperformances.xml
  def index
    @mriperformances = Mriperformance.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @mriperformances }
    end
  end

  # GET /mriperformances/1
  # GET /mriperformances/1.xml
  def show
    @mriperformance = Mriperformance.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @mriperformance }
    end
  end

  # GET /mriperformances/new
  # GET /mriperformances/new.xml
  def new
    @mriperformance = Mriperformance.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @mriperformance }
    end
  end

  # GET /mriperformances/1/edit
  def edit
    @mriperformance = Mriperformance.find(params[:id])
  end

  # POST /mriperformances
  # POST /mriperformances.xml
  def create
    @mriperformance = Mriperformance.new(params[:mriperformance])

    respond_to do |format|
      if @mriperformance.save
        format.html { redirect_to(@mriperformance, :notice => 'Mriperformance was successfully created.') }
        format.xml  { render :xml => @mriperformance, :status => :created, :location => @mriperformance }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @mriperformance.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /mriperformances/1
  # PUT /mriperformances/1.xml
  def update
    @mriperformance = Mriperformance.find(params[:id])

    respond_to do |format|
      if @mriperformance.update_attributes(params[:mriperformance])
        format.html { redirect_to(@mriperformance, :notice => 'Mriperformance was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mriperformance.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /mriperformances/1
  # DELETE /mriperformances/1.xml
  def destroy
    @mriperformance = Mriperformance.find(params[:id])
    @mriperformance.destroy

    respond_to do |format|
      format.html { redirect_to(mriperformances_url) }
      format.xml  { head :ok }
    end
  end
end
