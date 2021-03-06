# encoding: utf-8
class ImageDatasetQualityChecksController < ApplicationController # AuthorizedController #  ApplicationController  
  before_action :set_image_dataset_quality_check, only: [:show, :edit, :update, :destroy]   
	respond_to :html
 #  load_and_authorize_resource
  # GET /image_dataset_quality_checks
  # GET /image_dataset_quality_checks.xml
  def index
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
    @image_dataset = ImageDataset.where("image_datasets.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:image_dataset_id]) if params[:image_dataset_id]
    @image_dataset_quality_checks = @image_dataset ? @image_dataset.image_dataset_quality_checks : ImageDatasetQualityCheck.includes(:user).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @image_dataset_quality_checks }
    end
  end

  # GET /image_dataset_quality_checks/1
  # GET /image_dataset_quality_checks/1.xml
  def show
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @idqc = ImageDatasetQualityCheck.where("image_dataset_quality_checks.image_dataset_id in ( select image_datasets.id from image_datasets where image_datasets.visit_id in 
              (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)))", scan_procedure_array).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @idqc }
    end
  end

  # GET /image_dataset_quality_checks/new
  # GET /image_dataset_quality_checks/new.xml
  def new
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
    @image_dataset = ImageDataset.where("image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:image_dataset_id])
    @image_dataset_quality_check = @image_dataset.image_dataset_quality_checks.build
    @image_dataset_quality_check.user = current_user

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @image_dataset_quality_check }
    end
  end

  # GET /image_dataset_quality_checks/1/edit
  def edit
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @image_dataset_quality_check = ImageDatasetQualityCheck.where("image_dataset_quality_checks.image_dataset_id in ( select image_datasets.id from image_datasets where image_datasets.visit_id in 
              (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)))", scan_procedure_array).find(params[:id])
  # .where("image_dataset_quality_checks.image_dataset_id in ( select image_dataset_id from image_datasets where image_datasets.visit_id in 
  #          (select visit_id from scan_procedures_visits where scan_procedure_id in (?)))", scan_procedure_array)
   
    @image_dataset = @image_dataset_quality_check.image_dataset
    # respond_to do |format|
    #       if (@current_user.username != @image_dataset_quality_check.user.username)
    #         flash[:notice] = 'Only the creator of an image quality check can edit it.'
    #         redirect_to(image_dataset_quality_checks_path)
    #       else
    #         format.html # edit.html.erb
    #       end
    #     end
  end

  # POST /image_dataset_quality_checks
  # POST /image_dataset_quality_checks.xml
  def create
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @image_dataset = ImageDataset.where("image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:image_dataset_id])
    @image_dataset_quality_check = ImageDatasetQualityCheck.new(image_dataset_quality_check_params)#params[:image_dataset_quality_check])
    @image_dataset_quality_check.user = current_user

    respond_to do |format|
      if @image_dataset_quality_check.save
         if @image_dataset_quality_check.incomplete_series == "Incomplete" 
            v_image_dataset = ImageDataset.find(@image_dataset_quality_check.image_dataset_id)
            v_image_dataset.do_not_share_scans_flag = 'Y' # Y means do not share
            v_image_dataset.save
         end
        flash[:notice] = 'ImageDatasetQualityCheck was successfully created.'
        format.html { redirect_to(@image_dataset_quality_check) }
        format.xml  { render :xml => @image_dataset_quality_check, :status => :created, :location => @image_dataset_quality_check }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @image_dataset_quality_check.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /image_dataset_quality_checks/1
  # PUT /image_dataset_quality_checks/1.xml
  def update
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
#    @image_dataset_quality_check = ImageDatasetQualityCheck.where("image_dataset_quality_checks.image_dataset_id in ( select image_datasets.id from image_datasets where image_datasets.visit_id in 
#              (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)))", scan_procedure_array).find(params[:id])
    @image_dataset_quality_check = ImageDatasetQualityCheck.where("image_dataset_quality_checks.image_dataset_id in ( select image_datasets.id from image_datasets, scan_procedures_visits 
                where image_datasets.visit_id = scan_procedures_visits.visit_id  and scan_procedures_visits.scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    v_orig_incomplete_series = @image_dataset_quality_check.incomplete_series
    respond_to do |format|
      if @image_dataset_quality_check.update(image_dataset_quality_check_params)#params[:image_dataset_quality_check], :without_protection => true)
        if @image_dataset_quality_check.incomplete_series == "Incomplete" and v_orig_incomplete_series != "Incomplete" 
            v_image_dataset = ImageDataset.find(@image_dataset_quality_check.image_dataset_id)
            v_image_dataset.do_not_share_scans_flag = 'Y' # Y means do not share
            v_image_dataset.save
         end
        flash[:notice] = 'ImageDatasetQualityCheck was successfully updated.'
        format.html { redirect_to(@image_dataset_quality_check) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @image_dataset_quality_check.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /image_dataset_quality_checks/1
  # DELETE /image_dataset_quality_checks/1.xml
  def destroy
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
#    @image_dataset_quality_check = ImageDatasetQualityCheck.where("image_dataset_quality_checks.image_dataset_id in ( select image_datasets.id from image_datasets where image_datasets.visit_id in 
#              (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)))", scan_procedure_array).find(params[:id])
    @image_dataset_quality_check = ImageDatasetQualityCheck.where("image_dataset_quality_checks.image_dataset_id in ( select image_datasets.id from image_datasets, scan_procedures_visits
                 where image_datasets.visit_id = scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    im_ds = @image_dataset_quality_check.image_dataset
    @image_dataset_quality_check.destroy

    respond_to do |format|
      format.html { redirect_to(im_ds) }
      format.xml  { head :ok }
    end
  end 
  private
    def set_image_dataset_quality_check
       @image_dataset_quality_check = ImageDatasetQualityCheck.find(params[:id])
    end
   def image_dataset_quality_check_params
          params.require(:image_dataset_quality_check).permit(:motion_warning,:registration_risk,:banding,:ghosting_wrapping,:field_inhomogeneity,:fov_cutoff,:omnibus_f_comment,:garbled_series,:incomplete_series,:image_dataset_id,:user_id,:id,:omnibus_f,:spm_mask,:nos_concerns,:nos_concerns_comment,:other_issues,:spm_mask_comment,:field_inhomogeneity_comment,:motion_warning_comment,:registration_risk_comment,:banding_comment,:ghosting_wrapping_comment,:fov_cutoff_comment,:garbled_series_comment,:incomplete_series_comment)
   end
end
