class SeriesDescriptionMapsController < ApplicationController
  before_action :set_series_description_map, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /series_description_maps
  # GET /series_description_maps.xml
  def index
    @series_description_maps = SeriesDescriptionMap.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @series_description_maps }
    end
  end    
  def series_description_map_search
      puts "dddddd"
     if params[:series_description_map_search].nil?  
       puts "ffff NIL"
          params[:series_description_map_search] =Hash.new 
       else
         puts "gggggg "+params[:series_description_map_search][:series_description_type_id].join(", ")
     end  
     if !params[:series_description_map_search].nil? and !params[:series_description_map_search][:series_description_type_id][0].blank? 
       puts "hhhhhhhh"
       @series_description_maps = SeriesDescriptionMap.where("series_description_type_id in (?)",params[:series_description_map_search][:series_description_type_id])
     else
       @series_description_maps = SeriesDescriptionMap.all
     end
     respond_to do |format|
       format.html   
       format.xml  { render :xml => @series_description_maps }
     end
  end

  # GET /series_description_maps/1
  # GET /series_description_maps/1.xml
  def show
    @series_description_map = SeriesDescriptionMap.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @series_description_map }
    end
  end

  # GET /series_description_maps/new
  # GET /series_description_maps/new.xml
  def new
    @series_description_map = SeriesDescriptionMap.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @series_description_map }
    end
  end

  # GET /series_description_maps/1/edit
  def edit
    @series_description_map = SeriesDescriptionMap.find(params[:id])
  end

  # POST /series_description_maps
  # POST /series_description_maps.xml
  def create
    @series_description_map = SeriesDescriptionMap.new(series_description_map_params)#params[:series_description_map])

    respond_to do |format|
      if @series_description_map.save
        format.html { redirect_to(@series_description_map, :notice => 'Series description map was successfully created.') }
        format.xml  { render :xml => @series_description_map, :status => :created, :location => @series_description_map }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @series_description_map.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /series_description_maps/1
  # PUT /series_description_maps/1.xml
  def update
    @series_description_map = SeriesDescriptionMap.find(params[:id])

    respond_to do |format|
      if @series_description_map.update(series_description_map_params)#params[:series_description_map], :without_protection => true)
        format.html { redirect_to(@series_description_map, :notice => 'Series description map was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @series_description_map.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /series_description_maps/1
  # DELETE /series_description_maps/1.xml
  def destroy
    @series_description_map = SeriesDescriptionMap.find(params[:id])
    @series_description_map.destroy

    respond_to do |format|
      format.html { redirect_to(series_description_maps_url) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_series_description_map
       @series_description_map = SeriesDescriptionMap.find(params[:id])
    end
   def series_description_map_params
          params.require(:series_description_map).permit(:series_description_type_id,:series_description_type,:series_description,:id)
   end 
   def series_description_map_search_params
          params.require(:series_description_map_search).permit(series_description_type_id: [])
   end
end
