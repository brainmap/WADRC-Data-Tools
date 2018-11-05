class FolderpermissionsController < ApplicationController
  before_action :set_folderpermission, only: [:show, :edit, :update, :destroy]

  # GET /folderpermissions
  # GET /folderpermissions.json
  def index
    @folderpermissions = Folderpermission.all
  end

  # GET /folderpermissions/1
  # GET /folderpermissions/1.json
  def show
  end

  # GET /folderpermissions/new
  def new
    @folderpermission = Folderpermission.new
  end

  # GET /folderpermissions/1/edit
  def edit
  end

  # POST /folderpermissions
  # POST /folderpermissions.json
  def create
    @folderpermission = Folderpermission.new(folderpermission_params)

    respond_to do |format|
      if @folderpermission.save
        format.html { redirect_to @folderpermission, notice: 'Folderpermission was successfully created.' }
        format.json { render :show, status: :created, location: @folderpermission }
      else
        format.html { render :new }
        format.json { render json: @folderpermission.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /folderpermissions/1
  # PATCH/PUT /folderpermissions/1.json
  def update
    respond_to do |format|
      if @folderpermission.update(folderpermission_params)
        format.html { redirect_to @folderpermission, notice: 'Folderpermission was successfully updated.' }
        format.json { render :show, status: :ok, location: @folderpermission }
      else
        format.html { render :edit }
        format.json { render json: @folderpermission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /folderpermissions/1
  # DELETE /folderpermissions/1.json
  def destroy
    @folderpermission.destroy
    respond_to do |format|
      format.html { redirect_to folderpermissions_url, notice: 'Folderpermission was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_folderpermission
      @folderpermission = Folderpermission.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def folderpermission_params
      params.require(:folderpermission).permit(:actual_vs_planned, :network_user, :network_group, :permission_read, :permission_write, :permission_execute, :folder_id)
    end
end
