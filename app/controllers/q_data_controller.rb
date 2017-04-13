# encoding: utf-8
class QDataController < ApplicationController
  # GET /q_data
  # GET /q_data.xml
  def index
    @q_data = QDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @q_data }
    end
  end

  # GET /q_data/1
  # GET /q_data/1.xml
  def show
    @q_datum = QDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @q_datum }
    end
  end

  # GET /q_data/new
  # GET /q_data/new.xml
  def new
    @q_datum = QDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @q_datum }
    end
  end

  # GET /q_data/1/edit
  def edit
    @q_datum = QDatum.find(params[:id])
  end

  # POST /q_data
  # POST /q_data.xml
  def create
    @q_datum = QDatum.new(q_datum_params)#params[:q_datum])

    respond_to do |format|
      if @q_datum.save
        format.html { redirect_to(@q_datum, :notice => 'Q datum was successfully created.') }
        format.xml  { render :xml => @q_datum, :status => :created, :location => @q_datum }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @q_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /q_data/1
  # PUT /q_data/1.xml
  def update
    @q_datum = QDatum.find(params[:id])

    respond_to do |format|
      if @q_datum.update(q_datum_params)#params[:q_datum], :without_protection => true)
        format.html { redirect_to(@q_datum, :notice => 'Q datum was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @q_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /q_data/1
  # DELETE /q_data/1.xml
  def destroy
    @q_datum = QDatum.find(params[:id])
    @q_datum.destroy

    respond_to do |format|
      format.html { redirect_to(q_data_url) }
      format.xml  { head :ok }
    end
  end   
  private
    def set_q_datum
       @q_datum = QDatum.find(params[:id])
    end
   def q_datum_params
          params.require(:q_datum).permit(:value_3,:value_2,:value_1,:value_link,:question_id,:q_data_form_id,:id)
   end
end
