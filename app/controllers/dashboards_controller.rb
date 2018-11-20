class DashboardsController < ApplicationController
  before_action :set_dashboard, only: [:show, :edit, :update, :destroy]

  # GET /dashboards
  # GET /dashboards.json
  def index
    @dashboards = Dashboard.all
  end

  # GET /dashboards/1
  # GET /dashboards/1.json
  def show
  end

  # GET /dashboards/new
  def new
    @dashboard = Dashboard.new
  end

  # GET /dashboards/1/edit
  def edit
  end

  # POST /dashboards
  # POST /dashboards.json
  def dashboard_home

      @conditions = []
      @joins = []
      @tables = ['vgroups']
      @columns = []
      @current_tab = "cg_search"
      params["search_criteria"] =""
      @participant_key_results_hash = Hash.new  # use particiapnt_id and dashboardcontent_id both as keys for results -multi column
      @participant_key_columns_hash = Hash.new  # use particiapnt_id and dashboardcontent_id both as keys for column display names from cg_tn_cn
    @dashboards = Dashboard.where("status_flag ='Y' ").order(:display_name)

    if params[:dashboard_home].nil?
           params[:dashboard_home] =Hash.new
    end

    # collect criteria
    v_reggieid = ""
    v_wrapnum = ""
    if !params[:dashboard_home].blank? and !params[:dashboard_home][:enumber].blank?
      params[:dashboard_home][:enumber] = params[:dashboard_home][:enumber].gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
      if params[:dashboard_home][:enumber].include?(',') # string of enumbers
        v_enumber =  params[:dashboard_home][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
        v_enumber = v_enumber.gsub(/,/,"','")
        condition =" enrollment_vgroup_memberships.vgroup_id = vgroups.id and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"')"         
      else
        condition =" enrollment_vgroup_memberships.vgroup_id = vgroups.id and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:dashboard_home][:enumber].gsub(/[;:'"()=<>]/, '')+"'))"
      end
      @conditions.push(condition)
      @tables.push('enrollment_vgroup_memberships','enrollments')
      @columns.push('enrollments.enumber')
      params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:dashboard_home][:enumber]
    end
    if !params[:dashboard_home].blank? and !params[:dashboard_home][:wrapnum].blank?
      params[:dashboard_home][:wrapnum] = params[:dashboard_home][:wrapnum].gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
      if params[:dashboard_home][:wrapnum].include?(',') # string of enumbers
        v_wrapnum =  params[:dashboard_home][:wrapnum].gsub(/ /,'').gsub(/'/,'').downcase
        v_wrapnum = v_wrapnum.gsub(/,/,"','")
        condition =" vgroups.participant_id = participants.id and lower(participants.wrapnum) in ('"+v_wrapnum.gsub(/[;:"()=<>]/, '')+"')"  

      else
        condition ="vgroups.participant_id = participants.id and lower(participants.wrapnum) in (lower('"+params[:dashboard_home][:wrapnum].gsub(/[;:'"()=<>]/, '')+"'))"
      end
      @conditions.push(condition)
      @tables.push('participants')
      @columns.push('participants.wrapnum')
      params["search_criteria"] = params["search_criteria"] +",  wrapnum "+params[:dashboard_home][:wrapnum]
    end
    if !params[:dashboard_home].blank? and !params[:dashboard_home][:reggieid].blank?
      params[:dashboard_home][:reggieid] = params[:dashboard_home][:reggieid].gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
      if params[:dashboard_home][:reggieid].include?(',') # string of enumbers
        v_reggieid =  params[:dashboard_home][:reggieid].gsub(/ /,'').gsub(/'/,'').downcase
        v_reggieid = v_reggieid.gsub(/,/,"','")

        condition =" vgroups.participant_id = participants.id and lower(participants.reggieid) in ('"+v_reggieid.gsub(/[;:"()=<>]/, '')+"')"         
      else
        v_reggieid = params[:dashboard_home][:reggieid].gsub(/[;:'"()=<>]/, '')
        condition ="vgroups.participant_id = participants.id and lower(participants.reggieid) in (lower('"+params[:dashboard_home][:reggieid].gsub(/[;:'"()=<>]/, '')+"'))"
      end
      @conditions.push(condition)
      @tables.push('participants')
      @columns.push('participants.reggieid')
      params["search_criteria"] = params["search_criteria"] +",  reggieid "+params[:dashboard_home][:reggieid]
    end 
 
   puts "uuuu v_reggieid="+v_reggieid
 puts "params[search_criteria]="+params["search_criteria"]
     # want to loop by participant_id as key 
     # if many could be participant or sp or groups of sp?
     # for now just assumming many=participant

    if  !params[:dashboard_home].blank? and !params[:dashboard_home][:id].blank?
       @dashboard = Dashboard.find(params[:dashboard_home][:id])
       @participants = ""
       if @dashboard.one_or_many_results == 'many' # assume partipant
           if !v_reggieid.blank?
             @participants = Participant.where("reggieid in ('"+v_reggieid+"'")
           elsif !v_wrapnum.blank?
             @participants = Participant.where("wrapnum in ('"+v_wrapnum+"'")
           end
       end
       @dashboardcontents = Dashboardcontent.where("dashboardcontents.dashboard_id in (?)", @dashboard.id).order(:row_display_order)
       # loop thru each dashboardcontent
       @joins_hash = Hash.new
       @tables_hash = Hash.new
       @columns_hash = Hash.new
       @dashboardcontents.each do |content_row|
          v_cg_tn = ""
          v_cg_tn_cn = ""
          if !content_row.cg_query_id.blank?
            v_cg_query = CgQuery.find(content_row.cg_query_id)
            # from line 1277 data_searches_controller
            if !@cg_query.scan_procedure_id_list.blank?
                @sp_array = @cg_query.scan_procedure_id_list.split(",")
            end
            if !@cg_query.pet_tracer_id_list.blank?
                 @pet_tracer_array = @cg_query.pet_tracer_id_list.split(",")
            end

            @cg_query_tns =  CgQueryTn.where("cg_query_id = "+@cg_query.id.to_s).where("cg_tn_id in ( select cg_tns.id from cg_tns where cg_tns.table_type in 
              (SElect table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in (select scan_procedures.protocol_id from scan_procedures where scan_procedures.id in ("+scan_procedure_list+"))))").order("cg_query_tns.display_order")  
        
            @cg_query_tns.each do |cg_query_tn|
              v_tn_id = cg_query_tn.cg_tn_id 
              @cg_query_tn_id_array.push(v_tn_id) # need to retrieve for display on the page
              # if cg table needd to propagate from search to search
              v_cg_tn = CgTn.find(v_tn_id)
              if v_cg_tn.table_type != 'base'  
       puts "zzzzz add_table id = "+v_tn_id.to_s 
                @add_cg_tn_id.push(v_tn_id.to_s) 
              end
              @cg_query_tn_hash[v_tn_id.to_s] = cg_query_tn  
              @cg_query_tn_cns = CgQueryTnCn.where("cg_query_tn_id = "+cg_query_tn.id.to_s) 
              @cg_query_tn_cns.each do |cg_query_tn_cn|
              v_tn_cn_id = cg_query_tn_cn.cg_tn_cn_id.to_s
              @cg_query_cn_hash[v_tn_cn_id] = cg_query_tn_cn
            end 
            @cg_query_tn_cn_hash[v_tn_id.to_s] = @cg_query_cn_hash         
          end

            # assemble columns, tables, joins, conditions from CgQuery parts - 
            # add in report specific conditions - 2526 line in data_searches_controller

            #
         end # ???? 


        # get results 
    
       end
    end


    respond_to do |format|
      format.xls 
      format.html 
    end

  end

  def create
    @dashboard = Dashboard.new(dashboard_params)

    respond_to do |format|
      if @dashboard.save
        format.html { redirect_to @dashboard, notice: 'Dashboard was successfully created.' }
        format.json { render :show, status: :created, location: @dashboard }
      else
        format.html { render :new }
        format.json { render json: @dashboard.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dashboards/1
  # PATCH/PUT /dashboards/1.json
  def update
    respond_to do |format|
      if @dashboard.update(dashboard_params)
        format.html { redirect_to @dashboard, notice: 'Dashboard was successfully updated.' }
        format.json { render :show, status: :ok, location: @dashboard }
      else
        format.html { render :edit }
        format.json { render json: @dashboard.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dashboards/1
  # DELETE /dashboards/1.json
  def destroy
    @dashboard.destroy
    respond_to do |format|
      format.html { redirect_to dashboards_url, notice: 'Dashboard was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dashboard
      @dashboard = Dashboard.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dashboard_params
      params.require(:dashboard).permit(:name, :display_name, :description, :html_col_per_row, :one_or_many_results, :status_flag)
    end
end
