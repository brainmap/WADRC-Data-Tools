# encoding: utf-8
class LookupSetsController < ApplicationController  
    before_action :set_lookup_set, only: [:show, :edit, :update, :destroy]  
    	respond_to :html  
  # GET /lookup_sets
  # GET /lookup_sets.xml
  def index
    @lookup_sets = LookupSet.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_sets }
    end
  end

  # GET /lookup_sets/1
  # GET /lookup_sets/1.xml
  def show
    @lookup_set = LookupSet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_set }
    end
  end

  # GET /lookup_sets/new
  # GET /lookup_sets/new.xml
  def new
    @lookup_set = LookupSet.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_set }
    end
  end

  # GET /lookup_sets/1/edit
  def edit
    @lookup_set = LookupSet.find(params[:id])
  end

  # POST /lookup_sets
  # POST /lookup_sets.xml
  def create
    @lookup_set = LookupSet.new(lookup_set_params) #params[:lookup_set])

    respond_to do |format|
      if @lookup_set.save
        format.html { redirect_to(@lookup_set, :notice => 'Lookup set was successfully created.') }
        format.xml  { render :xml => @lookup_set, :status => :created, :location => @lookup_set }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_sets/1
  # PUT /lookup_sets/1.xml
  def update
    @lookup_set = LookupSet.find(lookup_set_params) # params[:id])

    respond_to do |format|
      if @lookup_set.update(params[:lookup_set], :without_protection => true)
        format.html { redirect_to(@lookup_set, :notice => 'Lookup set was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_sets/1
  # DELETE /lookup_sets/1.xml
  def destroy
    @lookup_set = LookupSet.find(params[:id])
    @lookup_set.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_sets_url) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_lookup_set
       @lookup_set = LookupSet.find(params[:id])
    end
   def lookup_set_params
          params.require(:lookup_set).permit(:updated_at,:created_at,:description,:name,:id)
   end
end
