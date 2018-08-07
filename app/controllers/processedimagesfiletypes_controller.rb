class ProcessedimagesfiletypesController < ApplicationController
  before_action :set_processedimagesfiletype, only: [:show, :edit, :update, :destroy]

  # GET /processedimagesfiletypes
  # GET /processedimagesfiletypes.json
  def index
    @processedimagesfiletypes = Processedimagesfiletype.all
  end

  # GET /processedimagesfiletypes/1
  # GET /processedimagesfiletypes/1.json
  def show
  end

  # GET /processedimagesfiletypes/new
  def new
    @processedimagesfiletype = Processedimagesfiletype.new
  end

  # GET /processedimagesfiletypes/1/edit
  def edit
  end

  # POST /processedimagesfiletypes
  # POST /processedimagesfiletypes.json
  def create
    @processedimagesfiletype = Processedimagesfiletype.new(processedimagesfiletype_params)

    respond_to do |format|
      if @processedimagesfiletype.save
        format.html { redirect_to @processedimagesfiletype, notice: 'Processedimagesfiletype was successfully created.' }
        format.json { render :show, status: :created, location: @processedimagesfiletype }
      else
        format.html { render :new }
        format.json { render json: @processedimagesfiletype.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /processedimagesfiletypes/1
  # PATCH/PUT /processedimagesfiletypes/1.json
  def update
    respond_to do |format|
      if @processedimagesfiletype.update(processedimagesfiletype_params)
        format.html { redirect_to @processedimagesfiletype, notice: 'Processedimagesfiletype was successfully updated.' }
        format.json { render :show, status: :ok, location: @processedimagesfiletype }
      else
        format.html { render :edit }
        format.json { render json: @processedimagesfiletype.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /processedimagesfiletypes/1
  # DELETE /processedimagesfiletypes/1.json
  def destroy
    @processedimagesfiletype.destroy
    respond_to do |format|
      format.html { redirect_to processedimagesfiletypes_url, notice: 'Processedimagesfiletype was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_processedimagesfiletype
      @processedimagesfiletype = Processedimagesfiletype.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def processedimagesfiletype_params
      params.require(:processedimagesfiletype).permit(:file_type,:image_linkage_type)
    end
end
