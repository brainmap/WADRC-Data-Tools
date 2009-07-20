class SeriesDescriptionsController < ApplicationController
  # GET /series_descriptions
  # GET /series_descriptions.xml
  def index
    @series_descriptions = SeriesDescription.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @series_descriptions }
    end
  end

  # GET /series_descriptions/1
  # GET /series_descriptions/1.xml
  def show
    @series_description = SeriesDescription.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @series_description }
    end
  end

  # GET /series_descriptions/new
  # GET /series_descriptions/new.xml
  def new
    @series_description = SeriesDescription.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @series_description }
    end
  end

  # GET /series_descriptions/1/edit
  def edit
    @series_description = SeriesDescription.find(params[:id])
  end

  # POST /series_descriptions
  # POST /series_descriptions.xml
  def create
    @series_description = SeriesDescription.new(params[:series_description])

    respond_to do |format|
      if @series_description.save
        flash[:notice] = 'SeriesDescription was successfully created.'
        format.html { redirect_to(@series_description) }
        format.xml  { render :xml => @series_description, :status => :created, :location => @series_description }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @series_description.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /series_descriptions/1
  # PUT /series_descriptions/1.xml
  def update
    @series_description = SeriesDescription.find(params[:id])

    respond_to do |format|
      if @series_description.update_attributes(params[:series_description])
        flash[:notice] = 'SeriesDescription was successfully updated.'
        format.html { redirect_to(@series_description) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @series_description.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /series_descriptions/1
  # DELETE /series_descriptions/1.xml
  def destroy
    @series_description = SeriesDescription.find(params[:id])
    @series_description.destroy

    respond_to do |format|
      format.html { redirect_to(series_descriptions_url) }
      format.xml  { head :ok }
    end
  end
end
