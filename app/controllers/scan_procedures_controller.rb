# encoding: utf-8
class ScanProceduresController <  AuthorizedController #  ApplicationController
load_and_authorize_resource
  
  before_action :set_current_tab  
  before_action :set_scan_procedure, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  
  def set_current_tab
    @current_tab = "enroll_parti_sp"
  end
  
  # GET /scan_procedures
  # GET /scan_procedures.xml
  def index
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
    @scan_procedures = ScanProcedure.where("scan_procedures.id in (?)", scan_procedure_array).order(:codename).all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @scan_procedures }
    end
  end

  # GET /scan_procedures/1
  # GET /scan_procedures/1.xml
  def show
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
    @scan_procedure = ScanProcedure.where("scan_procedures.id in (?)", scan_procedure_array).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @scan_procedure }
    end
  end

  # GET /scan_procedures/new
  # GET /scan_procedures/new.xml
  def new
    @scan_procedure = ScanProcedure.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @scan_procedure }
    end
  end

  # GET /scan_procedures/1/edit
  def edit
    @scan_procedure = ScanProcedure.find(params[:id])
  end

  # POST /scan_procedures
  # POST /scan_procedures.xml
  def create
    @scan_procedure = ScanProcedure.new(scan_procedure_params)#params[:scan_procedure])

    respond_to do |format|
      if @scan_procedure.save
        flash[:notice] = 'Scan procedure was successfully created.'
        format.html { redirect_to(@scan_procedure) }
        format.xml  { render :xml => @scan_procedure, :status => :created, :location => @scan_procedure }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @scan_procedure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /scan_procedures/1
  # PUT /scan_procedures/1.xml
  def update
    @scan_procedure = ScanProcedure.find(params[:id])

    respond_to do |format|
      if @scan_procedure.update(scan_procedure_params)#params[:scan_procedure], :without_protection => true)
        flash[:notice] = 'Scan procedure was successfully updated.'
        format.html { redirect_to(@scan_procedure) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @scan_procedure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /scan_procedures/1
  # DELETE /scan_procedures/1.xml
  def destroy
    @scan_procedure = ScanProcedure.find(params[:id])
    @scan_procedure.destroy

    respond_to do |format|
      format.html { redirect_to(scan_procedures_url) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_scan_procedure
       @scan_procedure = ScanProcedure.find(params[:id])
    end
   def scan_procedure_params
          params.require(:scan_procedure).permit(:petscan_tracer_path,:rmraic_reggieid_flag,:make_participant_flag,:rmr_dicom_field,:petscan_tracer_file_size,:subjectid_base,:petscan_flag,:protocol_id,:description,:codename,:id,:permission_type)
   end     
    
  
  #   def set_scan_procedures_visit
  #      @scan_procedures_visit = Scan_procedures_visit.find(params[:id])
  #   end
  #  def scan_procedures_visit_params
  #         params.require(:scan_procedures_visit).permit(:scan_procedure_id,:visit_id)
  #  end
   
   #  def set_scan_procedures_vgroup
   #     @scan_procedures_vgroup = Scan_procedures_vgroup.find(params[:id])
   #  end
   # def scan_procedures_vgroup_params
   #        params.require(:scan_procedures_vgroup).permit(:vgroup_id,:scan_procedure_id)
   # end
end
