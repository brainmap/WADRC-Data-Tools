# encoding: utf-8
class LumbarpunctureResultsController < ApplicationController  
  before_action :set_lumbarpuncture_result, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /lumbarpuncture_results
  # GET /lumbarpuncture_results.xml
  def index
    @lumbarpuncture_results = LumbarpunctureResult.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lumbarpuncture_results }
    end
  end

  # GET /lumbarpuncture_results/1
  # GET /lumbarpuncture_results/1.xml
  def show
    @lumbarpuncture_result = LumbarpunctureResult.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lumbarpuncture_result }
    end
  end

  # GET /lumbarpuncture_results/new
  # GET /lumbarpuncture_results/new.xml
  def new
    @lumbarpuncture_result = LumbarpunctureResult.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lumbarpuncture_result }
    end
  end

  # GET /lumbarpuncture_results/1/edit
  def edit
    @lumbarpuncture_result = LumbarpunctureResult.find(params[:id])
  end

  # POST /lumbarpuncture_results
  # POST /lumbarpuncture_results.xml
  def create
    @lumbarpuncture_result = LumbarpunctureResult.new( lumbarpuncture_result_params)#params[:lumbarpuncture_result])

    respond_to do |format|
      if @lumbarpuncture_result.save
        format.html { redirect_to(@lumbarpuncture_result, :notice => 'Lumbarpuncture result was successfully created.') }
        format.xml  { render :xml => @lumbarpuncture_result, :status => :created, :location => @lumbarpuncture_result }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lumbarpuncture_result.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lumbarpuncture_results/1
  # PUT /lumbarpuncture_results/1.xml
  def update
    @lumbarpuncture_result = LumbarpunctureResult.find(params[:id])

    respond_to do |format|
      if @lumbarpuncture_result.update( lumbarpuncture_result_params)#params[:lumbarpuncture_result], :without_protection => true)
        format.html { redirect_to(@lumbarpuncture_result, :notice => 'Lumbarpuncture result was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lumbarpuncture_result.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lumbarpuncture_results/1
  # DELETE /lumbarpuncture_results/1.xml
  def destroy
    @lumbarpuncture_result = LumbarpunctureResult.find(params[:id])
    @lumbarpuncture_result.destroy

    respond_to do |format|
      format.html { redirect_to(lumbarpuncture_results_url) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_lumbarpuncture_result
       @lumbarpuncture_result = LumbarpunctureResult.find(params[:id])
    end
   def lumbarpuncture_result_params
          params.require(:lumbarpuncture_result).permit(:lumbarpuncture_id,:value_string,:value,:lookup_lumbarpuncture_id,:id)
   end
end
