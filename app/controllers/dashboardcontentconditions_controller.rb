class DashboardcontentconditionsController < ApplicationController
  before_action :set_dashboardcontentcondition, only: [:show, :edit, :update, :destroy]

  # GET /dashboardcontentconditions
  # GET /dashboardcontentconditions.json
  def index
    @dashboardcontentconditions = Dashboardcontentcondition.all
  end

  # GET /dashboardcontentconditions/1
  # GET /dashboardcontentconditions/1.json
  def show
  end

  # GET /dashboardcontentconditions/new
  def new
    @dashboardcontentcondition = Dashboardcontentcondition.new
  end

  # GET /dashboardcontentconditions/1/edit
  def edit
  end

  # POST /dashboardcontentconditions
  # POST /dashboardcontentconditions.json
  def create
    @dashboardcontentcondition = Dashboardcontentcondition.new(dashboardcontentcondition_params)

    respond_to do |format|
      if @dashboardcontentcondition.save
        format.html { redirect_to @dashboardcontentcondition, notice: 'Dashboardcontentcondition was successfully created.' }
        format.json { render :show, status: :created, location: @dashboardcontentcondition }
      else
        format.html { render :new }
        format.json { render json: @dashboardcontentcondition.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dashboardcontentconditions/1
  # PATCH/PUT /dashboardcontentconditions/1.json
  def update
    respond_to do |format|
      if @dashboardcontentcondition.update(dashboardcontentcondition_params)
        format.html { redirect_to @dashboardcontentcondition, notice: 'Dashboardcontentcondition was successfully updated.' }
        format.json { render :show, status: :ok, location: @dashboardcontentcondition }
      else
        format.html { render :edit }
        format.json { render json: @dashboardcontentcondition.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dashboardcontentconditions/1
  # DELETE /dashboardcontentconditions/1.json
  def destroy
    @dashboardcontentcondition.destroy
    respond_to do |format|
      format.html { redirect_to dashboardcontentconditions_url, notice: 'Dashboardcontentcondition was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dashboardcontentcondition
      @dashboardcontentcondition = Dashboardcontentcondition.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dashboardcontentcondition_params
      params.require(:dashboardcontentcondition).permit(:dashboardcontent_id, :select_condition, :value_1, :value_2, :status_flag)
    end
end
