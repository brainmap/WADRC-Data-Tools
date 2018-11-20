class DashboardcontentsController < ApplicationController
  before_action :set_dashboardcontent, only: [:show, :edit, :update, :destroy]

  # GET /dashboardcontents
  # GET /dashboardcontents.json
  def index
    @dashboardcontents = Dashboardcontent.all
  end

  # GET /dashboardcontents/1
  # GET /dashboardcontents/1.json
  def show
  end

  # GET /dashboardcontents/new
  def new
    @dashboardcontent = Dashboardcontent.new
    sql = "select  concat(cg_name,' - ',users.username,' - ', date_format(cg_queries.created_at,'%Y %m %d')) name,cg_queries.id  
      from cg_queries, users where status_flag != 'N' and cg_queries.user_id = users.id  and cg_queries.cg_name like '%Dashboard%' 
         order by save_flag desc, users.username, date_format(cg_queries.created_at,'%Y %m %d') desc"
      connection = ActiveRecord::Base.connection();
      @results_stored_search = connection.execute(sql)
      @data_for_select_stored_search = @results_stored_search.each { |hash| [hash[0], hash[1]] }
  end

  # GET /dashboardcontents/1/edit
  def edit
    sql = "select  concat(cg_name,' - ',users.username,' - ', date_format(cg_queries.created_at,'%Y %m %d')) name,cg_queries.id  
      from cg_queries, users where status_flag != 'N' and cg_queries.user_id = users.id  and cg_queries.cg_name like '%Dashboard%' 
         order by save_flag desc, users.username, date_format(cg_queries.created_at,'%Y %m %d') desc"
      connection = ActiveRecord::Base.connection();
      @results_stored_search = connection.execute(sql)
      @data_for_select_stored_search = @results_stored_search.each { |hash| [hash[0], hash[1]] }
  end

  # POST /dashboardcontents
  # POST /dashboardcontents.json
  def create
    @dashboardcontent = Dashboardcontent.new(dashboardcontent_params)
    sql = "select  concat(cg_name,' - ',users.username,' - ', date_format(cg_queries.created_at,'%Y %m %d')) name,cg_queries.id  
      from cg_queries, users where status_flag != 'N' and cg_queries.user_id = users.id  and cg_queries.cg_name like '%Dashboard%' 
         order by save_flag desc, users.username, date_format(cg_queries.created_at,'%Y %m %d') desc"
      connection = ActiveRecord::Base.connection();
      @results_stored_search = connection.execute(sql)
      @data_for_select_stored_search = @results_stored_search.each { |hash| [hash[0], hash[1]] }

    respond_to do |format|
      if @dashboardcontent.save
        format.html { redirect_to @dashboardcontent, notice: 'Dashboardcontent was successfully created.' }
        format.json { render :show, status: :created, location: @dashboardcontent }
      else
        format.html { render :new }
        format.json { render json: @dashboardcontent.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dashboardcontents/1
  # PATCH/PUT /dashboardcontents/1.json
  def update
    respond_to do |format|
      if @dashboardcontent.update(dashboardcontent_params)
        format.html { redirect_to @dashboardcontent, notice: 'Dashboardcontent was successfully updated.' }
        format.json { render :show, status: :ok, location: @dashboardcontent }
      else
        format.html { render :edit }
        format.json { render json: @dashboardcontent.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dashboardcontents/1
  # DELETE /dashboardcontents/1.json
  def destroy
    @dashboardcontent.destroy
    respond_to do |format|
      format.html { redirect_to dashboardcontents_url, notice: 'Dashboardcontent was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dashboardcontent
      @dashboardcontent = Dashboardcontent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dashboardcontent_params
      params.require(:dashboardcontent).permit(:dashboard_id, :status_flag, :contact, :cg_query_id, :display_header_1_large, :display_header_1_small, :display_text_1, :display_label, :display_text_2, :display_text_3, :print_header_1_large, :print_header_1_small, :print_text_1, :print_label, :print_text_2, :print_text_3, :html_size, :html_bold, :html_color, :html_col_span, :html_break_between_row, :row_display_order, :sql_return_one_or_many, :sql_group_by, :sql_order_by, :sql_date_override_by_dashboard_search, :sql_join_type)
    end
end
