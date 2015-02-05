class SeriesDescriptionScanProceduresController < ApplicationController
  # GET /series_description_scan_procedures
  # GET /series_description_scan_procedures.json
  def index
    @series_description_scan_procedures = SeriesDescriptionScanProcedure.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @series_description_scan_procedures }
    end
  end

  # GET /series_description_scan_procedures/1
  # GET /series_description_scan_procedures/1.json
  def show
    @series_description_scan_procedure = SeriesDescriptionScanProcedure.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @series_description_scan_procedure }
    end
  end

  # GET /series_description_scan_procedures/new
  # GET /series_description_scan_procedures/new.json
  def new
    @series_description_scan_procedure = SeriesDescriptionScanProcedure.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @series_description_scan_procedure }
    end
  end

  # GET /series_description_scan_procedures/1/edit
  def edit
    @series_description_scan_procedure = SeriesDescriptionScanProcedure.find(params[:id])
  end

  # POST /series_description_scan_procedures
  # POST /series_description_scan_procedures.json
  def create
    @series_description_scan_procedure = SeriesDescriptionScanProcedure.new(params[:series_description_scan_procedure])

    respond_to do |format|
      if @series_description_scan_procedure.save
        format.html { redirect_to @series_description_scan_procedure, notice: 'Series description scan procedure was successfully created.' }
        format.json { render json: @series_description_scan_procedure, status: :created, location: @series_description_scan_procedure }
      else
        format.html { render action: "new" }
        format.json { render json: @series_description_scan_procedure.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /series_description_scan_procedures/1
  # PUT /series_description_scan_procedures/1.json
  def update
    @series_description_scan_procedure = SeriesDescriptionScanProcedure.find(params[:id])

    respond_to do |format|
      if @series_description_scan_procedure.update_attributes(params[:series_description_scan_procedure])
        format.html { redirect_to @series_description_scan_procedure, notice: 'Series description scan procedure was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @series_description_scan_procedure.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /series_description_scan_procedures/1
  # DELETE /series_description_scan_procedures/1.json
  def destroy
    @series_description_scan_procedure = SeriesDescriptionScanProcedure.find(params[:id])
    @series_description_scan_procedure.destroy

    respond_to do |format|
      format.html { redirect_to series_description_scan_procedures_url }
      format.json { head :no_content }
    end
  end
end
