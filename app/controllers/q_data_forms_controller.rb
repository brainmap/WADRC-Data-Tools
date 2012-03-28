class QDataFormsController < ApplicationController
  # GET /q_data_forms
  # GET /q_data_forms.xml
  def index
    @q_data_forms = QDataForm.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @q_data_forms }
    end
  end

  # GET /q_data_forms/1
  # GET /q_data_forms/1.xml
  def show
    @q_data_form = QDataForm.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @q_data_form }
    end
  end

  # GET /q_data_forms/new
  # GET /q_data_forms/new.xml
  def new
    @q_data_form = QDataForm.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @q_data_form }
    end
  end

  # GET /q_data_forms/1/edit
  def edit
    @q_data_form = QDataForm.find(params[:id])
  end

  # POST /q_data_forms
  # POST /q_data_forms.xml
  def create
    @q_data_form = QDataForm.new(params[:q_data_form])

    respond_to do |format|
      if @q_data_form.save
        format.html { redirect_to(@q_data_form, :notice => 'Q data form was successfully created.') }
        format.xml  { render :xml => @q_data_form, :status => :created, :location => @q_data_form }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @q_data_form.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /q_data_forms/1
  # PUT /q_data_forms/1.xml
  def update
    @q_data_form = QDataForm.find(params[:id])

    respond_to do |format|
      if @q_data_form.update_attributes(params[:q_data_form])
        format.html { redirect_to(@q_data_form, :notice => 'Q data form was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @q_data_form.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /q_data_forms/1
  # DELETE /q_data_forms/1.xml
  def destroy
    @q_data_form = QDataForm.find(params[:id])
    @q_data_form.destroy

    respond_to do |format|
      format.html { redirect_to(q_data_forms_url) }
      format.xml  { head :ok }
    end
  end
end
