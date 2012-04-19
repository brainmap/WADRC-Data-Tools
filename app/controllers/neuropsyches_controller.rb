class NeuropsychesController < ApplicationController
  # GET /neuropsyches
  # GET /neuropsyches.xml
  def index
    @neuropsyches = Neuropsych.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @neuropsyches }
    end
  end

  # GET /neuropsyches/1
  # GET /neuropsyches/1.xml
  def show
    @neuropsych = Neuropsych.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @neuropsych }
    end
  end

  # GET /neuropsyches/new
  # GET /neuropsyches/new.xml
  def new
    @neuropsych = Neuropsych.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @neuropsych }
    end
  end

  # GET /neuropsyches/1/edit
  def edit
    @neuropsych = Neuropsych.find(params[:id])
  end

  # POST /neuropsyches
  # POST /neuropsyches.xml
  def create
    @neuropsych = Neuropsych.new(params[:neuropsych])

    respond_to do |format|
      if @neuropsych.save
        format.html { redirect_to(@neuropsych, :notice => 'Neuropsych was successfully created.') }
        format.xml  { render :xml => @neuropsych, :status => :created, :location => @neuropsych }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @neuropsych.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /neuropsyches/1
  # PUT /neuropsyches/1.xml
  def update
    @neuropsych = Neuropsych.find(params[:id])

    respond_to do |format|
      if @neuropsych.update_attributes(params[:neuropsych])
        format.html { redirect_to(@neuropsych, :notice => 'Neuropsych was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @neuropsych.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /neuropsyches/1
  # DELETE /neuropsyches/1.xml
  def destroy
    @neuropsych = Neuropsych.find(params[:id])
    @neuropsych.destroy

    respond_to do |format|
      format.html { redirect_to(neuropsyches_url) }
      format.xml  { head :ok }
    end
  end
end
