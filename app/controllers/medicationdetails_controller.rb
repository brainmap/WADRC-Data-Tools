# encoding: utf-8
class MedicationdetailsController < ApplicationController
  # GET /medicationdetails
  # GET /medicationdetails.xml
  def index
    @medicationdetails = Medicationdetail.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @medicationdetails }
    end
  end

  # GET /medicationdetails/1
  # GET /medicationdetails/1.xml
  def show
    @medicationdetail = Medicationdetail.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @medicationdetail }
    end
  end

  # GET /medicationdetails/new
  # GET /medicationdetails/new.xml
  def new
    @medicationdetail = Medicationdetail.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @medicationdetail }
    end
  end

  # GET /medicationdetails/1/edit
  def edit
    @medicationdetail = Medicationdetail.find(params[:id])
  end

  # POST /medicationdetails
  # POST /medicationdetails.xml
  def create
    @medicationdetail = Medicationdetail.new(medicationdetail_params)#params[:medicationdetail])

    respond_to do |format|
      if @medicationdetail.save
        format.html { redirect_to(@medicationdetail, :notice => 'Medicationdetail was successfully created.') }
        format.xml  { render :xml => @medicationdetail, :status => :created, :location => @medicationdetail }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @medicationdetail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /medicationdetails/1
  # PUT /medicationdetails/1.xml
  def update
    @medicationdetail = Medicationdetail.find(params[:id])

    respond_to do |format|
      if @medicationdetail.update(medicationdetail_params)#params[:medicationdetail], :without_protection => true)
        format.html { redirect_to(@medicationdetail, :notice => 'Medicationdetail was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @medicationdetail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /medicationdetails/1
  # DELETE /medicationdetails/1.xml
  def destroy
    @medicationdetail = Medicationdetail.find(params[:id])
    @medicationdetail.destroy

    respond_to do |format|
      format.html { redirect_to(medicationdetails_url) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_medicationdetail
       @medicationdetail = Medicationdetail.find(params[:id])
    end
   def medicationdetail_params
          params.require(:medicationdetail).permit(:id,:genericname,:brandname,:lookup_drugclass_id,:prescription,:exclusionclass)
   end
end
