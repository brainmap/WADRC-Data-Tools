class ImageDatasetsController < ApplicationController
  
  PER_PAGE = 50
  
  before_filter :set_current_tab
  
  def set_current_tab
    @current_tab = "image_datasets"
  end
  
  def check_image_quality
    @image_dataset = ImageDataset.find(params[:id])
    @qc = ImageDatasetQualityCheck.new
    @qc.user = @current_user
    @qc.image_dataset = @image_dataset
    
    respond_to do |format|
      format.html # check_image_quality.html.erb
    end
  end
  
  # GET /image_datasets
  # GET /image_datasets.xml
  def index
    @image_datasets = ImageDataset.all.paginate(:page => params[:page], :per_page => PER_PAGE)
    @total_count = all_images.size
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @image_datasets }
    end
  end

  # GET /image_datasets/1
  # GET /image_datasets/1.xml
  def show
    @image_dataset = ImageDataset.find(params[:id])
    @image_comment = ImageComment.new
    @image_comments = @image_dataset.image_comments

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @image_dataset }
    end
  end

  # GET /image_datasets/new
  # GET /image_datasets/new.xml
  def new
    @image_dataset = ImageDataset.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @image_dataset }
    end
  end

  # GET /image_datasets/1/edit
  def edit
    @image_dataset = ImageDataset.find(params[:id])
  end

  # POST /image_datasets
  # POST /image_datasets.xml
  def create
    @image_dataset = ImageDataset.new(params[:image_dataset])

    respond_to do |format|
      if @image_dataset.save
        flash[:notice] = 'ImageDataset was successfully created.'
        format.html { redirect_to(@image_dataset) }
        format.xml  { render :xml => @image_dataset, :status => :created, :location => @image_dataset }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @image_dataset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /image_datasets/1
  # PUT /image_datasets/1.xml
  def update
    @image_dataset = ImageDataset.find(params[:id])

    respond_to do |format|
      if @image_dataset.update_attributes(params[:image_dataset])
        flash[:notice] = 'ImageDataset was successfully updated.'
        format.html { redirect_to(@image_dataset) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @image_dataset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /image_datasets/1
  # DELETE /image_datasets/1.xml
  def destroy
    @image_dataset = ImageDataset.find(params[:id])
    @image_dataset.destroy

    respond_to do |format|
      format.html { redirect_to(image_datasets_url) }
      format.xml  { head :ok }
    end
  end
end
