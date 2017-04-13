# encoding: utf-8
class LookupImagingplanesController < ApplicationController
  # GET /lookup_imagingplanes
  # GET /lookup_imagingplanes.xml
  def index
    @lookup_imagingplanes = LookupImagingplane.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_imagingplanes }
    end
  end

  # GET /lookup_imagingplanes/1
  # GET /lookup_imagingplanes/1.xml
  def show
    @lookup_imagingplane = LookupImagingplane.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_imagingplane }
    end
  end

  # GET /lookup_imagingplanes/new
  # GET /lookup_imagingplanes/new.xml
  def new
    @lookup_imagingplane = LookupImagingplane.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_imagingplane }
    end
  end

  # GET /lookup_imagingplanes/1/edit
  def edit
    @lookup_imagingplane = LookupImagingplane.find(params[:id])
  end

  # POST /lookup_imagingplanes
  # POST /lookup_imagingplanes.xml
  def create
    @lookup_imagingplane = LookupImagingplane.new(params[:lookup_imagingplane])

    respond_to do |format|
      if @lookup_imagingplane.save
        format.html { redirect_to(@lookup_imagingplane, :notice => 'Lookup imagingplane was successfully created.') }
        format.xml  { render :xml => @lookup_imagingplane, :status => :created, :location => @lookup_imagingplane }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_imagingplane.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_imagingplanes/1
  # PUT /lookup_imagingplanes/1.xml
  def update
    @lookup_imagingplane = LookupImagingplane.find(params[:id])

    respond_to do |format|
      if @lookup_imagingplane.update(params[:lookup_imagingplane], :without_protection => true)
        format.html { redirect_to(@lookup_imagingplane, :notice => 'Lookup imagingplane was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_imagingplane.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_imagingplanes/1
  # DELETE /lookup_imagingplanes/1.xml
  def destroy
    @lookup_imagingplane = LookupImagingplane.find(params[:id])
    @lookup_imagingplane.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_imagingplanes_url) }
      format.xml  { head :ok }
    end
  end
end
