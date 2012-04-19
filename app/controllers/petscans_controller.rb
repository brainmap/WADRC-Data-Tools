class PetscansController < ApplicationController
  # GET /petscans
  # GET /petscans.xml
  def index
    @petscans = Petscan.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @petscans }
    end
  end

  # GET /petscans/1
  # GET /petscans/1.xml
  def show
    @petscan = Petscan.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @petscan }
    end
  end

  # GET /petscans/new
  # GET /petscans/new.xml
  def new
    @petscan = Petscan.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @petscan }
    end
  end

  # GET /petscans/1/edit
  def edit
    @petscan = Petscan.find(params[:id])
  end

  # POST /petscans
  # POST /petscans.xml
  def create
    @petscan = Petscan.new(params[:petscan])

    respond_to do |format|
      if @petscan.save
        format.html { redirect_to(@petscan, :notice => 'Petscan was successfully created.') }
        format.xml  { render :xml => @petscan, :status => :created, :location => @petscan }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @petscan.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /petscans/1
  # PUT /petscans/1.xml
  def update
    @petscan = Petscan.find(params[:id])

    respond_to do |format|
      if @petscan.update_attributes(params[:petscan])
        format.html { redirect_to(@petscan, :notice => 'Petscan was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @petscan.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /petscans/1
  # DELETE /petscans/1.xml
  def destroy
    @petscan = Petscan.find(params[:id])
    @petscan.destroy

    respond_to do |format|
      format.html { redirect_to(petscans_url) }
      format.xml  { head :ok }
    end
  end
end
