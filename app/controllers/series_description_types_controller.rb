class SeriesDescriptionTypesController < ApplicationController
  # GET /series_description_types
  # GET /series_description_types.xml
  def index
    @series_description_types = SeriesDescriptionType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @series_description_types }
    end
  end

  # GET /series_description_types/1
  # GET /series_description_types/1.xml
  def show
    @series_description_type = SeriesDescriptionType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @series_description_type }
    end
  end

  # GET /series_description_types/new
  # GET /series_description_types/new.xml
  def new
    @series_description_type = SeriesDescriptionType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @series_description_type }
    end
  end

  # GET /series_description_types/1/edit
  def edit
    @series_description_type = SeriesDescriptionType.find(params[:id])
  end

  # POST /series_description_types
  # POST /series_description_types.xml
  def create
    @series_description_type = SeriesDescriptionType.new(params[:series_description_type])

    respond_to do |format|
      if @series_description_type.save
        format.html { redirect_to(@series_description_type, :notice => 'Series description type was successfully created.') }
        format.xml  { render :xml => @series_description_type, :status => :created, :location => @series_description_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @series_description_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /series_description_types/1
  # PUT /series_description_types/1.xml
  def update
    @series_description_type = SeriesDescriptionType.find(params[:id])

    respond_to do |format|
      if @series_description_type.update_attributes(params[:series_description_type])
        format.html { redirect_to(@series_description_type, :notice => 'Series description type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @series_description_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /series_description_types/1
  # DELETE /series_description_types/1.xml
  def destroy
    @series_description_type = SeriesDescriptionType.find(params[:id])
    @series_description_type.destroy

    respond_to do |format|
      format.html { redirect_to(series_description_types_url) }
      format.xml  { head :ok }
    end
  end
end
