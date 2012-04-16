class QuestionformQuestionsController < ApplicationController
  # GET /questionform_questions
  # GET /questionform_questions.xml
  def index
    # WANT TO SORT BY QUESTIONFORM DESC , NOT BY ID
    @questionform_questions = QuestionformQuestion.all.sort_by(&:questionform_id).sort_by(&:display_order)

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
    @questionform_question = QuestionformQuestion.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @questionform_question }
    end
  end

  # GET /questionform_questions/1/edit
  def edit
    @questionform_question = QuestionformQuestion.find(params[:id])
  end

  # POST /questionform_questions
  # POST /questionform_questions.xml
  def create
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
    @questionform_question = QuestionformQuestion.new(params[:questionform_question])

    respond_to do |format|
      if @questionform_question.save
        format.html { redirect_to(@questionform_question, :notice => 'Questionform question was successfully created.') }
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
    @questionform_question = QuestionformQuestion.find(params[:id])

    respond_to do |format|
      if @questionform_question.update_attributes(params[:questionform_question])
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
    @questionform_question = QuestionformQuestion.find(params[:id])
    @questionform_question.destroy

    respond_to do |format|
      format.html { redirect_to(questionform_questions_url) }
      format.xml  { head :ok }
    end
  end
end
