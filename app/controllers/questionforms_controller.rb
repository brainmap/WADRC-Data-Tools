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
    #get participant_id, visit_id, appointment_id from form level and insert into q_data
    #params["questionform_id"]
    #params["q_data_form_id"]
    #params["value_link"]["participant_id"]
    #params["value_link"]["visit_id"]
    #params["value_link"]["enrollment_id"]
    #params["value_link"]["appointment_id"]
    #params["value_link"]["scan_procedures"]

    # insert or update   if the q_data_forms.id is null
    # insert or update if q_data.id is null
    # global update or base_table.base_column update with value_link
    # redirect to original form or saved page
    
    # GET THE QUESTUIONS
    question_list = params["question_id"]
    question_list.each do |q_id| 

      if !params["value_1"][q_id].blank? 
        puts "AAAAAAAAAAAAAAAAAA= "+params["value_1"][q_id].to_a.join(',')
      end
      if !params["value_2"][q_id].blank? 
        puts "BBBBBBBBBBBBBBBBBBBB="+params["value_2"][q_id].to_a.join(',')
      end
      if !params["value_3"][q_id].blank? 
    #    puts "CCCCCCCCCCCCCCCCC="+params["value_3"][q_id].to_a.join(',')
      end

    end

    
     @questionform = Questionform.find(params["questionform_id"])

    respond_to do |format|
      format.html { redirect_to(@questionform, :notice => 'Questionform was successfully updated.') }
      format.xml  { render :xml => @questionforms }
    end    
  end
  
end
