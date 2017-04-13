# encoding: utf-8
class ImageCommentsController < ApplicationController
  
  before_action :set_current_tab      
  before_action :set_image_comment, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  
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
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
#    @image_comment = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets where image_datasets.visit_id in 
#              (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)))", scan_procedure_array).find(params[:id])
    @image_comment = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets,scan_procedures_visits
         where image_datasets.visit_id = scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

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
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
#    @image_comment = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets where image_datasets.visit_id in 
#              (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)))", scan_procedure_array).find(params[:id])
    @image_comment = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets,scan_procedures_visits
          where image_datasets.visit_id = scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
  end

  def create
          #  # removed :remote => true, and got single insert and page reload !!! 
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @image_dataset = ImageDataset.where("image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:image_dataset_id])
    @image_comment = @image_dataset.image_comments.build(image_comment_params)#params[:image_comment])  
    @image_comment.user = current_user
    

     @image_comment.save  
      respond_to do |format|
        format.html { redirect_to(@image_dataset) and return }
        format.js
        format.xml  { head :ok }
      end
 
# got rid of the rjs error, but doing a double render/redirect and still not reloading the page
# removed :remote => true, from form definition and worked

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
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
 #   @image_comment = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets where image_datasets.visit_id in 
 #              (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)))", scan_procedure_array).find(params[:id])
      @image_comment = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets, scan_procedures_visits
             where image_datasets.visit_id = scan_procedures_visits.visit_id and  scan_procedures_visits.scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
                        
    respond_to do |format|
      if @image_comment.update(image_comment_params)#params[:image_comment], :without_protection => true)
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
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
#    @image_comment = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets where image_datasets.visit_id in 
#              (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)))", scan_procedure_array).find(params[:id])
    @image_comment = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets, scan_procedures_visits 
             where image_datasets.visit_id =scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

              
              
    @image_dataset = @image_comment.image_dataset
    @image_comment.destroy

    respond_to do |format|  
      if @image_comment.destroy
        format.html { return(redirect_to(@image_dataset)) }
         format.js
        format.xml  { head :ok }  
      end
    end
  end  
  private
    def set_image_comment
       @image_comment = ImageComment.find(params[:id])
    end
   def image_comment_params
          params.require(:image_comment).permit(:user_id,:comment,:image_dataset_id,:id)
   end
end
