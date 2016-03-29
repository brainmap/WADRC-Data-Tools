class ConsentFormScanProceduresController < ApplicationController
  # GET /consent_form_scan_procedures
  # GET /consent_form_scan_procedures.json
  def index
    @consent_form_scan_procedures = ConsentFormScanProcedure.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @consent_form_scan_procedures }
    end
  end

  # GET /consent_form_scan_procedures/1
  # GET /consent_form_scan_procedures/1.json
  def show
    @consent_form_scan_procedure = ConsentFormScanProcedure.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @consent_form_scan_procedure }
    end
  end

  # GET /consent_form_scan_procedures/new
  # GET /consent_form_scan_procedures/new.json
  def new
    @consent_form_scan_procedure = ConsentFormScanProcedure.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @consent_form_scan_procedure }
    end
  end

  # GET /consent_form_scan_procedures/1/edit
  def edit
    @consent_form_scan_procedure = ConsentFormScanProcedure.find(params[:id])
  end

  # POST /consent_form_scan_procedures
  # POST /consent_form_scan_procedures.json
  def create
    @consent_form_scan_procedure = ConsentFormScanProcedure.new(params[:consent_form_scan_procedure])

    respond_to do |format|
      if @consent_form_scan_procedure.save
        format.html { redirect_to @consent_form_scan_procedure, notice: 'Consent form scan procedure was successfully created.' }
        format.json { render json: @consent_form_scan_procedure, status: :created, location: @consent_form_scan_procedure }
      else
        format.html { render action: "new" }
        format.json { render json: @consent_form_scan_procedure.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /consent_form_scan_procedures/1
  # PUT /consent_form_scan_procedures/1.json
  def update
    @consent_form_scan_procedure = ConsentFormScanProcedure.find(params[:id])

    respond_to do |format|
      if @consent_form_scan_procedure.update_attributes(params[:consent_form_scan_procedure])
        format.html { redirect_to @consent_form_scan_procedure, notice: 'Consent form scan procedure was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @consent_form_scan_procedure.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /consent_form_scan_procedures/1
  # DELETE /consent_form_scan_procedures/1.json
  def destroy
    # destroy being done by consent_form model
   # @consent_form_scan_procedure = ConsentFormScanProcedure.find(params[:id])
  #  @consent_form_scan_procedure.destroy

    respond_to do |format|
      format.html { redirect_to consent_form_scan_procedures_url }
      format.json { head :no_content }
    end
  end
end
