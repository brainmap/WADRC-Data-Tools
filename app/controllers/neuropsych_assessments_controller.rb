# encoding: utf-8
class NeuropsychAssessmentsController < ApplicationController  
  before_action :set_neuropsych_assessment, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /neuropsych_assessments
  # GET /neuropsych_assessments.xml
  def index
    @neuropsych_assessments = NeuropsychAssessment.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @neuropsych_assessments }
    end
  end

  # GET /neuropsych_assessments/1
  # GET /neuropsych_assessments/1.xml
  def show
    @neuropsych_assessment = NeuropsychAssessment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @neuropsych_assessment }
    end
  end

  # GET /neuropsych_assessments/new
  # GET /neuropsych_assessments/new.xml
  def new
    @neuropsych_assessment = NeuropsychAssessment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @neuropsych_assessment }
    end
  end

  # GET /neuropsych_assessments/1/edit
  def edit
    @neuropsych_assessment = NeuropsychAssessment.find(params[:id])
  end

  # POST /neuropsych_assessments
  # POST /neuropsych_assessments.xml
  def create
    @neuropsych_assessment = NeuropsychAssessment.new(neuropsych_assessment_params)#params[:neuropsych_assessment])

    respond_to do |format|
      if @neuropsych_assessment.save
        flash[:notice] = 'NeuropsychAssessment was successfully created.'
        format.html { redirect_to(@neuropsych_assessment) }
        format.xml  { render :xml => @neuropsych_assessment, :status => :created, :location => @neuropsych_assessment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @neuropsych_assessment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /neuropsych_assessments/1
  # PUT /neuropsych_assessments/1.xml
  def update
    @neuropsych_assessment = NeuropsychAssessment.find(params[:id])

    respond_to do |format|
      if @neuropsych_assessment.update(neuropsych_assessment_params)#params[:neuropsych_assessment], :without_protection => true)
        flash[:notice] = 'NeuropsychAssessment was successfully updated.'
        format.html { redirect_to(@neuropsych_assessment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @neuropsych_assessment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /neuropsych_assessments/1
  # DELETE /neuropsych_assessments/1.xml
  def destroy
    @neuropsych_assessment = NeuropsychAssessment.find(params[:id])
    @neuropsych_assessment.destroy

    respond_to do |format|
      format.html { redirect_to(neuropsych_assessments_url) }
      format.xml  { head :ok }
    end
  end 
  private
    def set_neuropsych_assessment
       @neuropsych_assessment = NeuropsychAssessment.find(params[:id])
    end
   def neuropsych_assessment_params
          params.require(:neuropsych_assessment).permit(:test_name,:neuropsych_session_id,:id,:score,:score_type,:note)
   end
end
