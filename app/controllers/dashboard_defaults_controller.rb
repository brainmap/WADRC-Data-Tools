class DashboardDefaultsController < ApplicationController
  before_action :set_dashboard_default, only: [:show, :edit, :update, :destroy]

  # GET /dashboard_defaults
  # GET /dashboard_defaults.json
  def index
    @dashboard_defaults = DashboardDefault.all
  end

  # GET /dashboard_defaults/1
  # GET /dashboard_defaults/1.json
  def show
  end

  # GET /dashboard_defaults/new
  def new
    @dashboard_default = DashboardDefault.new
  end

  # GET /dashboard_defaults/1/edit
  def edit
  end

  # POST /dashboard_defaults
  # POST /dashboard_defaults.json
  def create
    @dashboard_default = DashboardDefault.new(dashboard_default_params)
  

    respond_to do |format|
      if @dashboard_default.save
        format.html { redirect_to @dashboard_default, notice: 'Dashboard default was successfully created.' }
        format.json { render :show, status: :created, location: @dashboard_default }
      else
        format.html { render :new }
        format.json { render json: @dashboard_default.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dashboard_defaults/1
  # PATCH/PUT /dashboard_defaults/1.json
  def update
    respond_to do |format|
      if @dashboard_default.update(dashboard_default_params)
        format.html { redirect_to @dashboard_default, notice: 'Dashboard default was successfully updated.' }
        format.json { render :show, status: :ok, location: @dashboard_default }
      else
        format.html { render :edit }
        format.json { render json: @dashboard_default.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dashboard_defaults/1
  # DELETE /dashboard_defaults/1.json
  def destroy
    @dashboard_default.destroy
    respond_to do |format|
      format.html { redirect_to dashboard_defaults_url, notice: 'Dashboard default was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dashboard_default
      @dashboard_default = DashboardDefault.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dashboard_default_params
      params.require(:dashboard_default).permit(:dashboard_id, :default_type, :status_flag, :description)
    end
end
