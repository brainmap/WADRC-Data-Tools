class ImageCommentsController < ApplicationController
  
  before_filter :set_current_tab
  
  def set_current_tab
    @current_tab = "image_comments"
  end
  
  # GET /image_comments GET /image_comments.xml
  def index
    @image_comments = ImageComment.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @image_comments }
    end
  end

  # GET /image_comments/1 GET /image_comments/1.xml
  def show
    @image_comment = ImageComment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @image_comment }
    end
  end

  # GET /image_comments/new GET /image_comments/new.xml
  def new
    @image_comment = ImageComment.new
    @image_comment.user = current_user

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @image_comment }
    end
  end

  # GET /image_comments/1/edit
  def edit
    @image_comment = ImageComment.find(params[:id])
  end

  def create
    @image_dataset = ImageDataset.find(params[:image_dataset_id])
    @image_comment = @image_dataset.image_comments.build(params[:image_comment])
    @image_comment.user = current_user
    
    respond_to do |format|
      format.html { redirect_to(@image_dataset) }
      format.js
      format.xml  { head :ok }
    end
# got rid of the rjs error, but doing a double render/redirect and still not reloading the page
#  problems where in  image_comments controller but need image_datasets show
# copied the 4 lines above from destroy

#    respond_to do |format|
#      if @image_comment.save
#        format.html { redirect_to @image_dataset }
#        format.js
#      else
#       format.html { redirect_to @image_dataset }
#        format.js do
#          render :update do |page|
#            format.redirect_to @image_dataset
#          end
#        end
        # #flash[:error] = @image_comment.errors.full_messages.to_sentence
        # #format.html { redirect_to @image }
#      end
#    end
  end
  # POST /image_comments POST /image_comments.xml
  #  def create
  #    @image_comment = ImageComment.new(params[:image_comment])
  #
  #    respond_to do |format|
  #      if @image_comment.save
  #        flash[:notice] = 'ImageComment was successfully created.'
  #        format.html { redirect_to(@image_comment) }
  #        format.xml  { render :xml => @image_comment, :status => :created, :location => @image_comment }
  #      else
  #        format.html { render :action => "new" }
  #        format.xml  { render :xml => @image_comment.errors, :status => :unprocessable_entity }
  #      end
  #    end
  #  end

  # PUT /image_comments/1 PUT /image_comments/1.xml
  def update
    @image_comment = ImageComment.find(params[:id])

    respond_to do |format|
      if @image_comment.update_attributes(params[:image_comment])
        flash[:notice] = 'Image Comment was successfully updated.'
        format.html { redirect_to(@image_comment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @image_comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /image_comments/1 DELETE /image_comments/1.xml
  def destroy
    @image_comment = ImageComment.find(params[:id])
    @image_dataset = @image_comment.image_dataset
    @image_comment.destroy

    respond_to do |format|
      format.html { redirect_to(@image_dataset) }
      format.js
      format.xml  { head :ok }
    end
  end
end
