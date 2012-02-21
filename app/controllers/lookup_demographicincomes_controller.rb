class LookupDemographicincomesController < ApplicationController
  # GET /lookup_demographicincomes
  # GET /lookup_demographicincomes.xml
  def index
    @lookup_demographicincomes = LookupDemographicincome.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_demographicincomes }
    end
  end

  # GET /lookup_demographicincomes/1
  # GET /lookup_demographicincomes/1.xml
  def show
    @lookup_demographicincome = LookupDemographicincome.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_demographicincome }
    end
  end

  # GET /lookup_demographicincomes/new
  # GET /lookup_demographicincomes/new.xml
  def new
    @lookup_demographicincome = LookupDemographicincome.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_demographicincome }
    end
  end

  # GET /lookup_demographicincomes/1/edit
  def edit
    @lookup_demographicincome = LookupDemographicincome.find(params[:id])
  end

  # POST /lookup_demographicincomes
  # POST /lookup_demographicincomes.xml
  def create
    @lookup_demographicincome = LookupDemographicincome.new(params[:lookup_demographicincome])

    respond_to do |format|
      if @lookup_demographicincome.save
        format.html { redirect_to(@lookup_demographicincome, :notice => 'Lookup demographicincome was successfully created.') }
        format.xml  { render :xml => @lookup_demographicincome, :status => :created, :location => @lookup_demographicincome }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_demographicincome.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_demographicincomes/1
  # PUT /lookup_demographicincomes/1.xml
  def update
    @lookup_demographicincome = LookupDemographicincome.find(params[:id])

    respond_to do |format|
      if @lookup_demographicincome.update_attributes(params[:lookup_demographicincome])
        format.html { redirect_to(@lookup_demographicincome, :notice => 'Lookup demographicincome was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_demographicincome.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_demographicincomes/1
  # DELETE /lookup_demographicincomes/1.xml
  def destroy
    @lookup_demographicincome = LookupDemographicincome.find(params[:id])
    @lookup_demographicincome.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_demographicincomes_url) }
      format.xml  { head :ok }
    end
  end
end
