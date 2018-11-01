class FolderpremissionsController < ApplicationController
  before_action :set_folderpremission, only: [:show, :edit, :update, :destroy]

  # GET /folderpremissions
  # GET /folderpremissions.json
  def index
    @folderpremissions = Folderpremission.all
  end

  # GET /folderpremissions/1
  # GET /folderpremissions/1.json
  def show
  end

  # GET /folderpremissions/new
  def new
    @folderpremission = Folderpremission.new
  end

  # GET /folderpremissions/1/edit
  def edit
  end

  # POST /folderpremissions
  # POST /folderpremissions.json
  def create
    @folderpremission = Folderpremission.new(folderpremission_params)

    respond_to do |format|
      if @folderpremission.save
        format.html { redirect_to @folderpremission, notice: 'Folderpremission was successfully created.' }
        format.json { render :show, status: :created, location: @folderpremission }
      else
        format.html { render :new }
        format.json { render json: @folderpremission.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /folderpremissions/1
  # PATCH/PUT /folderpremissions/1.json
  def update
    respond_to do |format|
      if @folderpremission.update(folderpremission_params)
        format.html { redirect_to @folderpremission, notice: 'Folderpremission was successfully updated.' }
        format.json { render :show, status: :ok, location: @folderpremission }
      else
        format.html { render :edit }
        format.json { render json: @folderpremission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /folderpremissions/1
  # DELETE /folderpremissions/1.json
  def destroy
    @folderpremission.destroy
    respond_to do |format|
      format.html { redirect_to folderpremissions_url, notice: 'Folderpremission was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_folderpremission
      @folderpremission = Folderpremission.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def folderpremission_params
      params.require(:folderpremission).permit(:actual_vs_planned, :network_user, :network_group, :permission_read, :permission_write, :permission_execute, :folder_id)
    end
end
