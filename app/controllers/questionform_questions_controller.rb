# encoding: utf-8
class QuestionformQuestionsController < ApplicationController
  # GET /questionform_questions
  # GET /questionform_questions.xml
  def index_sp_questions 
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:edit_low_scan_procedure_array]
     # copy all the questions from one sp/questionform to another sp,
       # exclude ones already there
     if !params[:questionform_question][:scan_procedure_id].nil? and !params[:questionform_question][:scan_procedure_id][:id].nil? and params[:questionform_question][:scan_procedure_id][:id] > ''
             v_new_scan_procedure_id = params[:questionform_question][:scan_procedure_id][:id]
             v_orig_scan_procedure_id = params[:orig_scan_procedure_id]
             v_questionform_id = params[:questionform_question][:questionform_id]
             v_question_scan_procedures = QuestionScanProcedure.where("question_id in ( select question_id from question_scan_procedures where scan_procedure_id in (?))
                                                             and question_id not in (select question_id from question_scan_procedures where scan_procedure_id in (?))
                                                             and question_id in ( select question_id from questionform_questions where questionform_id in (?))",
                                                             v_orig_scan_procedure_id,v_new_scan_procedure_id,v_questionform_id ) 
             v_question_scan_procedures.each do |qfq|
                v_question_scan_procedure = QuestionScanProcedure.new
                v_question_scan_procedure.question_id = qfq.question_id
                v_question_scan_procedure.include_exclude = qfq.include_exclude
                v_question_scan_procedure.scan_procedure_id = v_new_scan_procedure_id
                v_question_scan_procedure.save
             end
      end
      @questionform_questions = QuestionformQuestion.find_by_sql("select questionforms.description,questionform_questions.id,questionform_questions.questionform_id,questionform_questions.question_id,
             questionform_questions.display_order from questionform_questions, questionforms where questionform_questions.questionform_id=questionforms.id
             and questionform_questions.questionform_id in ("+params[:questionform_question][:questionform_id]+")
              order by  questionform_questions.display_order,questionforms.description ")
        @v_edit_display_order = "N" # only allow display order edit if questionform and scan_procedure both selected
        @v_scan_procedure_id = ""
        @v_questionform_id =  params[:questionform_question][:questionform_id]
        if !params[:questionform_question].nil? and  !params[:questionform_question][:scan_procedure_id].nil? and !params[:questionform_question][:scan_procedure_id][:id].nil? and params[:questionform_question][:scan_procedure_id][:id] > ''
              @v_scan_procedure_id = params[:questionform_question][:scan_procedure_id][:id]
              @v_edit_display_order =  "Y"
             @questionform_questions = QuestionformQuestion.where("question_id in ( select question_id from questionform_questions where questionform_id in (?))",params[:questionform_question][:questionform_id]).where("question_id in ( select question_id from question_scan_procedures where scan_procedure_id in (?))",params[:questionform_question][:scan_procedure_id][:id]).order(:display_order)   

         end
         # not carrying over the params to index -- need to then do re-search
    respond_to do |format|
      format.html { redirect_to('/questionform_questions') }
      format.xml  { render :xml => @questionform_questions }
    end
  end

  def index
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:edit_low_scan_procedure_array]
    # update display order 
    if !params[:questionform_question].nil?  and !params[:questionform_question][:questionform_id].blank? and !params[:questionform_question][:scan_procedure_id].nil?   and !params[:questionform_question][:scan_procedure_id][:id].nil? and !params[:questionform_question][:scan_procedure_id][:id].blank?  and !params[:question_id].nil?
              params[:question_id].each do |q_id|
                @questionform_questions_disp_order = QuestionformQuestion.where("question_id in (?)", q_id).where("question_id in ( select question_id from questionform_questions where questionform_id in (?))",params[:questionform_question][:questionform_id]).where("question_id in ( select question_id from question_scan_procedures where scan_procedure_id in (?))",params[:questionform_question][:scan_procedure_id][:id])
                @questionform_questions_disp_order[0].display_order = params[:display_order][q_id]
                @questionform_questions_disp_order[0].save
             end
    end

    # default to most recently edited form
    if params[:questionform_question].blank? or params[:questionform_question] == ''
      @questionform_questions = QuestionformQuestion.find_by_sql("select questionforms.description,questionform_questions.id,questionform_questions.questionform_id,questionform_questions.question_id,
             questionform_questions.display_order from questionform_questions, questionforms where questionform_questions.questionform_id=questionforms.id
             and questionform_questions.questionform_id in (select distinct questionform_id from questionform_questions where updated_at in (select max(updated_at) from questionform_questions))
              order by questionform_questions.display_order,questionforms.description ")
    else  
      @questionform_questions = QuestionformQuestion.find_by_sql("select questionforms.description,questionform_questions.id,questionform_questions.questionform_id,questionform_questions.question_id,
             questionform_questions.display_order from questionform_questions, questionforms where questionform_questions.questionform_id=questionforms.id
             and questionform_questions.questionform_id in ("+params[:questionform_question][:questionform_id]+")
              order by  questionform_questions.display_order,questionforms.description ")
    end
  
    #@questionform_questions = QuestionformQuestion.all
        @v_edit_display_order = "N" # only allow display order edit if questionform and scan_procedure both selected
        @v_scan_procedure_id = ""
        @v_questionform_id =  ""
        if !params[:questionform_question].nil? 
         if (!params[:questionform_question][:questionform_id].nil?  and !params[:questionform_question][:questionform_id].blank? and !params[:questionform_question][:scan_procedure_id].nil?   and !params[:questionform_question][:scan_procedure_id][:id].nil? and !params[:questionform_question][:scan_procedure_id][:id].blank?  )
              @v_scan_procedure_id = params[:questionform_question][:scan_procedure_id][:id]
              @v_questionform_id = params[:questionform_question][:questionform_id]
              @v_edit_display_order =  "Y"
             @questionform_questions = QuestionformQuestion.where("question_id in ( select question_id from questionform_questions where questionform_id in (?))",params[:questionform_question][:questionform_id]).where("question_id in ( select question_id from question_scan_procedures where scan_procedure_id in (?))",params[:questionform_question][:scan_procedure_id][:id]).order(:display_order)      
         elsif !params[:questionform_question][:questionform_id].nil? and params[:questionform_question][:questionform_id] > ''
             @v_questionform_id = params[:questionform_question][:questionform_id]
             @questionform_questions = QuestionformQuestion.where("question_id in ( select question_id from questionform_questions where questionform_id in (?))",params[:questionform_question][:questionform_id]).order(:display_order) 
           
         elsif !params[:questionform_question][:scan_procedure_id].nil? and !params[:questionform_question][:scan_procedure_id][:id].nil? and params[:questionform_question][:scan_procedure_id][:id] > ''
             @v_scan_procedure_id = params[:questionform_question][:scan_procedure_id][:id]
             @questionform_questions = QuestionformQuestion.where("question_id in ( select question_id from question_scan_procedures where scan_procedure_id in (?))",params[:questionform_question][:scan_procedure_id][:id]).order(:display_order) 

         end         

     end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questionform_questions }
    end
  end

  # GET /questionform_questions/1
  # GET /questionform_questions/1.xml
  def show
    @questionform_question = QuestionformQuestion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @questionform_question }
    end
  end

  # GET /questionform_questions/new
  # GET /questionform_questions/new.xml
  def new
    @scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ')
    @questionform_question = QuestionformQuestion.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @questionform_question }
    end
  end

  # GET /questionform_questions/1/edit
  def edit
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:edit_low_scan_procedure_array]
    @questionform_question = QuestionformQuestion.find(params[:id])
  end

  # POST /questionform_questions
  # POST /questionform_questions.xml
  def create
    @scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ')
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:edit_low_scan_procedure_array]
    sql ="select ifnull(max(display_order),0) display_order from questionform_questions where questionform_id = "+params[:questionform_question][:questionform_id]
    connection = ActiveRecord::Base.connection();
    results = connection.execute(sql)
    temp_display_order = 0
    results.each do |vl| 
      temp_display_order = vl[0]
    end
    if params[:questionform_question][:display_order].blank?
      params[:questionform_question][:display_order] = (temp_display_order + 1).to_s
    end
    @questionform_question = QuestionformQuestion.new(questionform_question_params)# params[:questionform_question])

    respond_to do |format|
      if @questionform_question.save
        #format.html { redirect_to(@questionform_question, :notice => 'Questionform question was successfully created.') }
        #@questionform_question.display_order = @questionform_question.display_order +1
        format.html{ redirect_to('/questionform_questions/new', :notice => 'Questionform question was successfully created.')}
        format.xml  { render :xml => @questionform_question, :status => :created, :location => @questionform_question }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @questionform_question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /questionform_questions/1
  # PUT /questionform_questions/1.xml
  def update
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:edit_low_scan_procedure_array]
    @questionform_question = QuestionformQuestion.find(params[:id])

    respond_to do |format|
      if @questionform_question.update(questionform_question_params)# params[:questionform_question], :without_protection => true)
        format.html { redirect_to(@questionform_question, :notice => 'Questionform question was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @questionform_question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /questionform_questions/1
  # DELETE /questionform_questions/1.xml
  def destroy
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:edit_low_scan_procedure_array]
    @questionform_question = QuestionformQuestion.find(params[:id])
    @questionform_question.destroy

    respond_to do |format|
      format.html { redirect_to(questionform_questions_url) }
      format.xml  { head :ok }
    end
  end 
  private
    def set_questionform_question
       @questionform_question = QuestionformQuestion.find(params[:id])
    end
   def questionform_question_params
          params.require(:questionform_question).permit(:questionform_id,:display_order,:question_id,:id)
   end
end
