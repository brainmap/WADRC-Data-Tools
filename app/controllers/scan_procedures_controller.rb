class ScanProceduresController <  AuthorizedController #  ApplicationController
load_and_authorize_resource
  
  before_filter :set_current_tab
  
  def set_current_tab
    @current_tab = "Scan Procedures"
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
    @scan_procedure = ScanProcedure.new(params[:scan_procedure])

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
      if @scan_procedure.update_attributes(params[:scan_procedure])
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
end
