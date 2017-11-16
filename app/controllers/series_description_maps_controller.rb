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
     #if params[:series_description_map_search].nil?  
      # puts "ffff NIL"
      #    params[:series_description_map_search] =Hash.new 
      # else
      #   puts "gggggg "+params[:series_description_map_search][:series_description_type_id].join(", ")
     # end  
     if !params[:series_description_map_search].nil? and !params[:series_description_map_search][:series_description_type_id].nil? and !params[:series_description_map_search][:scan_procedure_id].nil? and !params[:series_description_map_search][:series_description_type_id][0].blank?  and !params[:series_description_map_search][:scan_procedure_id][0].blank? 
  @series_description_maps = SeriesDescriptionMap.where("series_description_type_id in (?) and trim(series_description_maps.series_description) in (select trim(series_descriptions.long_description) from series_descriptions, series_description_scan_procedures where series_descriptions.id = series_description_scan_procedures.series_description_id  and series_description_scan_procedures.scan_procedure_id in (?))",params[:series_description_map_search][:series_description_type_id],params[:series_description_map_search][:scan_procedure_id])
     

     elsif !params[:series_description_map_search].nil? and !params[:series_description_map_search][:series_description_type_id].nil? and !params[:series_description_map_search][:series_description_type_id][0].blank? 
       @series_description_maps = SeriesDescriptionMap.where("series_description_type_id in (?)",params[:series_description_map_search][:series_description_type_id])
     elsif !params[:series_description_map_search].nil? and !params[:series_description_map_search][:scan_procedure_id].nil? and !params[:series_description_map_search][:scan_procedure_id][0].blank? 
       @series_description_maps = SeriesDescriptionMap.where("trim(series_description_maps.series_description) in (select trim(series_descriptions.long_description) from series_descriptions, series_description_scan_procedures where series_descriptions.id = series_description_scan_procedures.series_description_id  and series_description_scan_procedures.scan_procedure_id in (?))",params[:series_description_map_search][:scan_procedure_id])
     else
       @series_description_maps = SeriesDescriptionMap.all
     end

     if !params[:series_description_map_search].nil? and !params[:series_description_map_search][:series_description].blank?
           @series_description_maps = @series_description_maps.where("trim(series_description_maps.series_description) like '%"+params[:series_description_map_search][:series_description]+"%'")
     end
     if !params[:series_description_map_search].nil?  and (params[:series_description_map_search][:unmapped_series_descriptions] == "1")
      #and !params[:series_description_map_search][:unmapped_series_descriptions].try(:length).nil?
      puts "rrrrrr == 1"
           @series_description_maps = @series_description_maps.where("series_description_maps.series_description_type_id is NULL")
     end

     puts "DDDDDD ="+params[:series_description_map_search][:unmapped_series_descriptions]+"="


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
