# encoding: utf-8
class AnalysesController < ApplicationController
  before_action :set_analysis, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  PER_PAGE = 50
  
  before_action :set_current_tab
  
  def set_current_tab
    @current_tab = "analyses"
  end
  
  # GET /analyses
  # GET /analyses.xml
  def index
    @analyses = Analysis.includes(:user).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @analyses }
    end
  end

  # GET /analyses/1
  # GET /analyses/1.xml
  def show

    @analysis = Analysis.includes(:analysis_memberships).includes(:image_datasets).find(params[:id])
    @all_analysis_members = @analysis.analysis_memberships
    @paginated_analysis_members = @all_analysis_members.page(params[:page]).per(50)
    @total_count = @all_analysis_members.size
    @author = @analysis.user
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @analysis }
    end
  end

  # GET /analyses/new
  # GET /analyses/new.xml
  def new
    @analysis = Analysis.new
    @analysis.timestamp = DateTime.now
    @analysis.user = @current_user

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @analysis }
    end
  end

  # GET /analyses/1/edit
  def edit
    @analysis = Analysis.find_by_id(params[:id], :include => [ { :analysis_memberships => :image_dataset } ] )
  end

  # POST /analyses
  # POST /analyses.xml
  def create
    @analysis = Analysis.new( analyse_params)#params[:analysis])
    @analysis.user = current_user
    # 
    #   @analysis.datasets_in_analysis.each do |ds|
    #     @analysis.analysis_memberships.build(:image_dataset_id => ds.id)
    #   end

    respond_to do |format|
      if @analysis.save
        flash[:notice] = 'Analysis was successfully created.'
        format.html { redirect_to(@analysis) }
        format.xml  { render :xml => @analysis, :status => :created, :location => @analysis }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @analysis.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /analyses/1
  # PUT /analyses/1.xml
  def update
    @analysis = Analysis.find_by_id(params[:id], :include => [ :analysis_memberships => :image_dataset ] )
    
    respond_to do |format|
       if @analysis.update( analyse_params)#params[:analysis], :without_protection => true)
         flash[:notice] = 'Analysis was successfully updated.'
         format.html { redirect_to(@analysis) }
         format.xml  { head :ok }
       else
         format.html { render :action => "edit" }
         format.xml  { render :xml => @analysis.errors, :status => :unprocessable_entity }
       end
     end
  end

  # DELETE /analyses/1
  # DELETE /analyses/1.xml
  def destroy
    @analysis = Analysis.find(params[:id])
    @analysis.destroy

    respond_to do |format|
      format.html { redirect_to(analyses_url) }
      format.xml  { head :ok }
    end
  end 
  private
    def set_analyse
       @analyse = Analyse.find(params[:id])
    end
   def analyse_params
          params.require(:analyse).permit(:id,:description,:user_id,:image_search_id)
   end
end
