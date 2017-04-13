# encoding: utf-8
class LookupDrugclassesController < ApplicationController  
  before_action :set_lookup_drugclass, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /lookup_drugclasses
  # GET /lookup_drugclasses.xml
  def index
    @lookup_drugclasses = LookupDrugclass.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_drugclasses }
    end
  end

  # GET /lookup_drugclasses/1
  # GET /lookup_drugclasses/1.xml
  def show
    @lookup_drugclass = LookupDrugclass.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_drugclass }
    end
  end

  # GET /lookup_drugclasses/new
  # GET /lookup_drugclasses/new.xml
  def new
    @lookup_drugclass = LookupDrugclass.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_drugclass }
    end
  end

  # GET /lookup_drugclasses/1/edit
  def edit
    @lookup_drugclass = LookupDrugclass.find(params[:id])
  end

  # POST /lookup_drugclasses
  # POST /lookup_drugclasses.xml
  def create
    @lookup_drugclass = LookupDrugclass.new( lookup_drugclass_params)#params[:lookup_drugclass])

    respond_to do |format|
      if @lookup_drugclass.save
        format.html { redirect_to(@lookup_drugclass, :notice => 'Lookup drugclass was successfully created.') }
        format.xml  { render :xml => @lookup_drugclass, :status => :created, :location => @lookup_drugclass }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_drugclass.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_drugclasses/1
  # PUT /lookup_drugclasses/1.xml
  def update
    @lookup_drugclass = LookupDrugclass.find(params[:id])

    respond_to do |format|
      if @lookup_drugclass.update( lookup_drugclass_params)#params[:lookup_drugclass], :without_protection => true)
        format.html { redirect_to(@lookup_drugclass, :notice => 'Lookup drugclass was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_drugclass.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_drugclasses/1
  # DELETE /lookup_drugclasses/1.xml
  def destroy
    @lookup_drugclass = LookupDrugclass.find(params[:id])
    @lookup_drugclass.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_drugclasses_url) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_lookup_drugclass
       @lookup_drugclass = LookupDrugclass.find(params[:id])
    end
   def lookup_drugclass_params
          params.require(:lookup_drugclass).permit(:id,:epodrugclass,:description,:created_at,:updated_at)
   end
end
