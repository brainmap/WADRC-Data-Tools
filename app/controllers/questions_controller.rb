# encoding: utf-8
class QuestionsController < ApplicationController
  # GET /questions
  # GET /questions.xml
  def index
    @questions = Question.order("id DESC" ).all
    @v_scan_procedure_id = ""
    @v_questionform_id =  ""
    if !params[:questionform_question].nil? 
         if (!params[:questionform_question][:questionform_id].nil?  and !params[:questionform_question][:questionform_id].blank? and !params[:questionform_question][:scan_procedure_id].nil?   and !params[:questionform_question][:scan_procedure_id][:id].nil? and !params[:questionform_question][:scan_procedure_id][:id].blank?  )
              @v_edit_display_order = "Y"
              @v_scan_procedure_id = params[:questionform_question][:scan_procedure_id][:id]
              @v_questionform_id = params[:questionform_question][:questionform_id]
             @questions = Question.where("questions.id in ( select question_id from questionform_questions where questionform_id in (?))",params[:questionform_question][:questionform_id]).where("questions.id in ( select question_id from question_scan_procedures where scan_procedure_id in (?))",params[:questionform_question][:scan_procedure_id][:id])      
         elsif !params[:questionform_question][:questionform_id].nil? and params[:questionform_question][:questionform_id] > ''
             @v_questionform_id = params[:questionform_question][:questionform_id]
             @questions = Question.where("questions.id in ( select question_id from questionform_questions where questionform_id in (?))",params[:questionform_question][:questionform_id])
           
         elsif !params[:questionform_question][:scan_procedure_id].nil? and !params[:questionform_question][:scan_procedure_id][:id].nil? and params[:questionform_question][:scan_procedure_id][:id] > ''
             @v_scan_procedure_id = params[:questionform_question][:scan_procedure_id][:id]
             @questions = Question.where("questions.id in ( select question_id from question_scan_procedures where scan_procedure_id in (?))",params[:questionform_question][:scan_procedure_id][:id])

         end         

     end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questions }
    end
  end

  # GET /questions/1
  # GET /questions/1.xml
  def show
    @question = Question.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @question }
    end
  end

  # GET /questions/new
  # GET /questions/new.xml
  def new
    @question = Question.new
    @question.global_update_1 ='N'
    @question.global_update_2 ='N'
    @question.global_update_3 ='N'
    @question.global_update_insert_1 ='N'
    @question.global_update_insert_2 ='N'
    @question.global_update_insert_3 ='N'
    @question.status = 'active'
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @question }
    end
  end

  # GET /questions/1/edit
  def edit
    @question = Question.find(params[:id])
  end

  def clone 
    @question_original = Question.find(params[:id])
    @question =  @question_original.dup # clone doesn't seem to work anymore 
    @question.description =   @question_original.description+"_CLONE"
    
 respond_to do |format|
   if @question.save
      params[:id] = @question.id
     format.html { redirect_to(edit_question_path(@question), :notice => 'Question was successfully created.') }
     format.xml  { render :xml => @question, :status => :created, :location => @question }
    else
        format.html { render :action => "new" }
        format.xml  { render :xml => @question.errors, :status => :unprocessable_entity }
      end
    end
   
  end


  # POST /questions
  # POST /questions.xml
  def create
    @question = Question.new(params[:question])

    respond_to do |format|
      if @question.save
        format.html { redirect_to(@question, :notice => 'Question was successfully created.') }
        format.xml  { render :xml => @question, :status => :created, :location => @question }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /questions/1
  # PUT /questions/1.xml
  def update
    @question = Question.find(params[:id])

    respond_to do |format|
      if @question.update_attributes(params[:question])
        format.html { redirect_to(@question, :notice => 'Question was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.xml
  def destroy
    @question = Question.find(params[:id])
    @question.destroy

    respond_to do |format|
      format.html { redirect_to(questions_url) }
      format.xml  { head :ok }
    end
  end
end
