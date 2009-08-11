class ImageSearchesController < ApplicationController
  
  PER_PAGE = 50
  
  before_filter :set_current_tab
  
  def set_current_tab
    @current_tab = "image_searches"
  end
  
  def index
    @image_searches = ImageSearch.all
  end
  
  def show
    @image_search = ImageSearch.find_by_id(params[:id])
    @all_image_matches = @image_search.matching_images
    @paginated_image_matches = @all_image_matches.paginate(:page => params[:page], :per_page => PER_PAGE)
    @total_count = @all_image_matches.size
    @analysis = Analysis.new
    @total_count.times { @analysis.analysis_memberships.build }

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @protocol }
    end
  end
  
  def create
    @image_search = ImageSearch.new(params[:image_search])
    @image_search.user = @current_user
    @image_search.scan_procedures = Array.new
    
    respond_to do |format|
      if @image_search.save
        unless params['scan_procedure'].nil?
          params['scan_procedure']['ids'].each do |scan_procedure_id|
            @image_search.scan_procedures << ScanProcedure.find_by_id(scan_procedure_id)
          end
        end
        flash[:notice] = 'Image Search was successfully created.'
        format.html { redirect_to(@image_search) }
        format.xml  { render :xml => @image_search, :status => :created, :location => @image_search }
      else
        flash[:notice] = 'Failed to create new Image Search'
        format.html { render :action => "new" }
        format.xml  { render :xml => @image_search.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @image_search = ImageSearch.find(params[:id])
    unless @image_search.analyses.empty?
      flash[:notice] = 'Image Search could not be deleted because it is in use by active analyses.'
      redirect_to(image_searches_url)
      return
    end
    
    @image_search.destroy

    respond_to do |format|
      flash[:notice] = 'Image Search was successfully deleted.'
      format.html { redirect_to(image_searches_url) }
      format.xml  { head :ok }
    end
  end

  def new
    @image_search = ImageSearch.new
    @image_search.user = @current_user
    @scanner_sources = Visit.scanner_sources
  end
  
  def import_to_analysis
    @image_search = ImageSearch.find_by_id(params[:id])
    @image_matches = @image_search.matching_images
    @analysis = Analysis.new
    @analysis.image_search = @image_search
    @analysis.description = params[:description]
    @analysis.user_id = params[:user_id]
    
    @image_matches.each do |image|
      analysis_membership = AnalysisMembership.new
      analysis_membership.analysis = @analysis
      analysis_membership.image_dataset = image
      analysis_membership.save
    end
    
    respond_to do |format|
      if @analysis.save
        flash[:notice] = 'Sucessfully created new analysis.'
        format.html { redirect_to @analysis }
      else
        flash[:notice] = 'Unable to create new analysis.'
        format.html { redirect_to @image_search }
      end
    end
  end

end
