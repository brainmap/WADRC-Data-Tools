# encoding: utf-8
class LookupDiagnosesController < ApplicationController
  # GET /lookup_diagnoses
  # GET /lookup_diagnoses.xml
  def index
    @lookup_diagnoses = LookupDiagnosis.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_diagnoses }
    end
  end

  # GET /lookup_diagnoses/1
  # GET /lookup_diagnoses/1.xml
  def show
    @lookup_diagnosis = LookupDiagnosis.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_diagnosis }
    end
  end

  # GET /lookup_diagnoses/new
  # GET /lookup_diagnoses/new.xml
  def new
    @lookup_diagnosis = LookupDiagnosis.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_diagnosis }
    end
  end

  # GET /lookup_diagnoses/1/edit
  def edit
    @lookup_diagnosis = LookupDiagnosis.find(params[:id])
  end

  # POST /lookup_diagnoses
  # POST /lookup_diagnoses.xml
  def create
    @lookup_diagnosis = LookupDiagnosis.new(params[:lookup_diagnosis])

    respond_to do |format|
      if @lookup_diagnosis.save
        format.html { redirect_to(@lookup_diagnosis, :notice => 'Lookup diagnosis was successfully created.') }
        format.xml  { render :xml => @lookup_diagnosis, :status => :created, :location => @lookup_diagnosis }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_diagnosis.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_diagnoses/1
  # PUT /lookup_diagnoses/1.xml
  def update
    @lookup_diagnosis = LookupDiagnosis.find(params[:id])

    respond_to do |format|
      if @lookup_diagnosis.update(params[:lookup_diagnosis], :without_protection => true)
        format.html { redirect_to(@lookup_diagnosis, :notice => 'Lookup diagnosis was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_diagnosis.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_diagnoses/1
  # DELETE /lookup_diagnoses/1.xml
  def destroy
    @lookup_diagnosis = LookupDiagnosis.find(params[:id])
    @lookup_diagnosis.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_diagnoses_url) }
      format.xml  { head :ok }
    end
  end
end
