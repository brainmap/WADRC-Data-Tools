# encoding: utf-8
class QuestionScanProceduresController < ApplicationController
  # GET /question_scan_procedures
  # GET /question_scan_procedures.xml
  def index
    @question_scan_procedures = QuestionScanProcedure.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @question_scan_procedures }
    end
  end

  # GET /question_scan_procedures/1
  # GET /question_scan_procedures/1.xml
  def show
    @question_scan_procedure = QuestionScanProcedure.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @question_scan_procedure }
    end
  end

  # GET /question_scan_procedures/new
  # GET /question_scan_procedures/new.xml
  def new
    @question_scan_procedure = QuestionScanProcedure.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @question_scan_procedure }
    end
  end

  # GET /question_scan_procedures/1/edit
  def edit
    @question_scan_procedure = QuestionScanProcedure.find(params[:id])
  end

  # POST /question_scan_procedures
  # POST /question_scan_procedures.xml
  def create
    @question_scan_procedure = QuestionScanProcedure.new(params[:question_scan_procedure])

    respond_to do |format|
      if @question_scan_procedure.save
        format.html { redirect_to(@question_scan_procedure, :notice => 'Question scan procedure was successfully created.') }
        format.xml  { render :xml => @question_scan_procedure, :status => :created, :location => @question_scan_procedure }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @question_scan_procedure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /question_scan_procedures/1
  # PUT /question_scan_procedures/1.xml
  def update
    @question_scan_procedure = QuestionScanProcedure.find(params[:id])

    respond_to do |format|
      if @question_scan_procedure.update_attributes(params[:question_scan_procedure])
        format.html { redirect_to(@question_scan_procedure, :notice => 'Question scan procedure was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @question_scan_procedure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /question_scan_procedures/1
  # DELETE /question_scan_procedures/1.xml
  def destroy
    @question_scan_procedure = QuestionScanProcedure.find(params[:id])
    @question_scan_procedure.destroy

    respond_to do |format|
      format.html { redirect_to(question_scan_procedures_url) }
      format.xml  { head :ok }
    end
  end
end
