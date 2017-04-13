# encoding: utf-8
class LookupGendersController < ApplicationController   
  
  before_action :set_lookup_gender, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /lookup_genders
  # GET /lookup_genders.xml
  def index
    @lookup_genders = LookupGender.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_genders }
    end
  end

  # GET /lookup_genders/1
  # GET /lookup_genders/1.xml
  def show
    @lookup_gender = LookupGender.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_gender }
    end
  end

  # GET /lookup_genders/new
  # GET /lookup_genders/new.xml
  def new
    @lookup_gender = LookupGender.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_gender }
    end
  end

  # GET /lookup_genders/1/edit
  def edit
    @lookup_gender = LookupGender.find(params[:id])
  end

  # POST /lookup_genders
  # POST /lookup_genders.xml
  def create
    @lookup_gender = LookupGender.new(lookup_gender_params)#params[:lookup_gender])

    respond_to do |format|
      if @lookup_gender.save
        format.html { redirect_to(@lookup_gender, :notice => 'Lookup gender was successfully created.') }
        format.xml  { render :xml => @lookup_gender, :status => :created, :location => @lookup_gender }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_gender.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_genders/1
  # PUT /lookup_genders/1.xml
  def update
    @lookup_gender = LookupGender.find(params[:id])

    respond_to do |format|
      if @lookup_gender.update(lookup_gender_params)#params[:lookup_gender], :without_protection => true)
        format.html { redirect_to(@lookup_gender, :notice => 'Lookup gender was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_gender.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_genders/1
  # DELETE /lookup_genders/1.xml
  def destroy
    @lookup_gender = LookupGender.find(params[:id])
    @lookup_gender.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_genders_url) }
      format.xml  { head :ok }
    end
  end 
  private
    def set_lookup_gender
       @lookup_gender = LookupGender.find(params[:id])
    end
   def lookup_gender_params
          params.require(:lookup_gender).permit(:updated_at,:created_at,:description,:id)
   end
end
