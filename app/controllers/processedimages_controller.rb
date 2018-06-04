class ProcessedimagesController < ApplicationController
  before_action :set_processedimage, only: [:show, :edit, :update, :destroy]

  # GET /processedimages
  # GET /processedimages.json
  def index
    @processedimages = Processedimage.all
  end

  # GET /processedimages/1
  # GET /processedimages/1.json
  def show
  end

  # GET /processedimages/new
  def new
    @processedimage = Processedimage.new
  end

  # GET /processedimages/1/edit
  def edit
  end

  # POST /processedimages
  # POST /processedimages.json
  def create
    @processedimage = Processedimage.new(processedimage_params)

    respond_to do |format|
      if @processedimage.save
        format.html { redirect_to @processedimage, notice: 'Processedimage was successfully created.' }
        format.json { render :show, status: :created, location: @processedimage }
      else
        format.html { render :new }
        format.json { render json: @processedimage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /processedimages/1
  # PATCH/PUT /processedimages/1.json
  def update
    respond_to do |format|
      if @processedimage.update(processedimage_params)
        format.html { redirect_to @processedimage, notice: 'Processedimage was successfully updated.' }
        format.json { render :show, status: :ok, location: @processedimage }
      else
        format.html { render :edit }
        format.json { render json: @processedimage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /processedimages/1
  # DELETE /processedimages/1.json
  def destroy
    @processedimage.destroy
    respond_to do |format|
      format.html { redirect_to processedimages_url, notice: 'Processedimage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_processedimage
      @processedimage = Processedimage.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def processedimage_params
      params.require(:processedimage).permit(:file_name, :file_path, :comment, :file_type, :status_flag, :exists_flag)
    end
end
