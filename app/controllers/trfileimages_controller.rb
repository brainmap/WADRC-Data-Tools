class TrfileimagesController < ApplicationController
  before_action :set_trfileimage, only: [:show, :edit, :update, :destroy]

  # GET /trfileimages
  # GET /trfileimages.json
  def index
    @trfileimages = Trfileimage.all
  end

  # GET /trfileimages/1
  # GET /trfileimages/1.json
  def show
  end

  # GET /trfileimages/new
  def new
    @trfileimage = Trfileimage.new
  end

  # GET /trfileimages/1/edit
  def edit
  end

  # POST /trfileimages
  # POST /trfileimages.json
  def create
    @trfileimage = Trfileimage.new(trfileimage_params)

    respond_to do |format|
      if @trfileimage.save
        format.html { redirect_to @trfileimage, notice: 'Trfileimage was successfully created.' }
        format.json { render :show, status: :created, location: @trfileimage }
      else
        format.html { render :new }
        format.json { render json: @trfileimage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trfileimages/1
  # PATCH/PUT /trfileimages/1.json
  def update
    respond_to do |format|
      if @trfileimage.update(trfileimage_params)
        format.html { redirect_to @trfileimage, notice: 'Trfileimage was successfully updated.' }
        format.json { render :show, status: :ok, location: @trfileimage }
      else
        format.html { render :edit }
        format.json { render json: @trfileimage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trfileimages/1
  # DELETE /trfileimages/1.json
  def destroy
    @trfileimage.destroy
    respond_to do |format|
      format.html { redirect_to trfileimages_url, notice: 'Trfileimage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trfileimage
      @trfileimage = Trfileimage.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trfileimage_params
      params.require(:trfileimage).permit(:trfile_id, :image_id, :image_category)
    end
end
