class QuestionformsController < ApplicationController
  # GET /questionforms
  # GET /questionforms.xml
  def index
    @questionforms = Questionform.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questionforms }
    end
  end

  # GET /questionforms/1
  # GET /questionforms/1.xml
  def show
    @questionform = Questionform.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @questionform }
    end
  end

  # GET /questionforms/new
  # GET /questionforms/new.xml
  def new
    @questionform = Questionform.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @questionform }
    end
  end
  
  def displayform
    
     render :template => "questionforms/displayform"
  end
  
  def editform
     render :template => "questionforms/editform"
  end

  # GET /questionforms/1/edit
  def edit
    @questionform = Questionform.find(params[:id])
  end

  # POST /questionforms
  # POST /questionforms.xml
  def create
    @questionform = Questionform.new(params[:questionform])

    respond_to do |format|
      if @questionform.save
        format.html { redirect_to(@questionform, :notice => 'Questionform was successfully created.') }
        format.xml  { render :xml => @questionform, :status => :created, :location => @questionform }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @questionform.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /questionforms/1
  # PUT /questionforms/1.xml
  def update
    @questionform = Questionform.find(params[:id])

    respond_to do |format|
      if @questionform.update_attributes(params[:questionform])
        format.html { redirect_to(@questionform, :notice => 'Questionform was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @questionform.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /questionforms/1
  # DELETE /questionforms/1.xml
  def destroy
    @questionform = Questionform.find(params[:id])
    @questionform.destroy

    respond_to do |format|
      format.html { redirect_to(questionforms_url) }
      format.xml  { head :ok }
    end
  end
  
  def question_enter
    # NEED TO GET THE PARAMETERS, 
    #questionform_id
    #q_data_form_id 
    # questionform[1textarea_1]  = params["questionform"]["1textarea_1"]
    # 1dropdown_3[ref_value] = params["1dropdown_3"]["ref_value"]  --- question_id = 3
    # questionform[2text_3] = params["questionform"]["2text_3"]   ---part 2 question_id = 3
    # questionform[1dropdown_3]
    #1checkbox_6 ?????  -- just getting one checkbox with params["1checkbox_6"]
    # 1radio_5
puts "AAAAAAAAAAAAAA==="+params["1checkbox_6"][0] .to_s+"AAAAAAAAAAAAAA==="+params["1checkbox_6"][3] .to_s
    
    # GET NAME OF PARAMETER --> question_id, [part 1, 2, 3]
    # insert or update
    # global update
    # redirect to original form or saved page
     @questionform = Questionform.find(params[:questionform_id])

    respond_to do |format|
      format.html { redirect_to(@questionform, :notice => 'Questionform was successfully updated.') }
      format.xml  { render :xml => @questionforms }
    end    
  end
  
end
