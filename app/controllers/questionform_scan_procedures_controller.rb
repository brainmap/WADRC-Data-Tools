class QuestionformScanProceduresController < ApplicationController
  # GET /questionform_scan_procedures
  # GET /questionform_scan_procedures.xml
  def index
    @questionform_scan_procedures = QuestionformScanProcedure.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questionform_scan_procedures }
    end
  end

  # GET /questionform_scan_procedures/1
  # GET /questionform_scan_procedures/1.xml
  def show
    @questionform_scan_procedure = QuestionformScanProcedure.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @questionform_scan_procedure }
    end
  end

  # GET /questionform_scan_procedures/new
  # GET /questionform_scan_procedures/new.xml
  def new
    @questionform_scan_procedure = QuestionformScanProcedure.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @questionform_scan_procedure }
    end
  end

  # GET /questionform_scan_procedures/1/edit
  def edit
    @questionform_scan_procedure = QuestionformScanProcedure.find(params[:id])
  end

  # POST /questionform_scan_procedures
  # POST /questionform_scan_procedures.xml
  def create
    @questionform_scan_procedure = QuestionformScanProcedure.new(params[:questionform_scan_procedure])

    respond_to do |format|
      if @questionform_scan_procedure.save
        format.html { redirect_to(@questionform_scan_procedure, :notice => 'Questionform scan procedure was successfully created.') }
        format.xml  { render :xml => @questionform_scan_procedure, :status => :created, :location => @questionform_scan_procedure }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @questionform_scan_procedure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /questionform_scan_procedures/1
  # PUT /questionform_scan_procedures/1.xml
  def update
    @questionform_scan_procedure = QuestionformScanProcedure.find(params[:id])

    respond_to do |format|
      if @questionform_scan_procedure.update_attributes(params[:questionform_scan_procedure])
        format.html { redirect_to(@questionform_scan_procedure, :notice => 'Questionform scan procedure was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @questionform_scan_procedure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /questionform_scan_procedures/1
  # DELETE /questionform_scan_procedures/1.xml
  def destroy
    @questionform_scan_procedure = QuestionformScanProcedure.find(params[:id])
    @questionform_scan_procedure.destroy

    respond_to do |format|
      format.html { redirect_to(questionform_scan_procedures_url) }
      format.xml  { head :ok }
    end
  end
end
