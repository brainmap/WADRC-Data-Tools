class ProcessedimagessourcesController < ApplicationController
  before_action :set_processedimagessource, only: [:show, :edit, :update, :destroy]

  # GET /processedimagessources
  # GET /processedimagessources.json
  def index
    @processedimagessources = Processedimagessource.all
  end

  # GET /processedimagessources/1
  # GET /processedimagessources/1.json
  def show
  end

  # GET /processedimagessources/new
  def new
    @processedimagessource = Processedimagessource.new
  end

  # GET /processedimagessources/1/edit
  def edit
  end

  # POST /processedimagessources
  # POST /processedimagessources.json
  def create
    @processedimagessource = Processedimagessource.new(processedimagessource_params)

    respond_to do |format|
      if @processedimagessource.save
        format.html { redirect_to @processedimagessource, notice: 'Processedimagessource was successfully created.' }
        format.json { render :show, status: :created, location: @processedimagessource }
      else
        format.html { render :new }
        format.json { render json: @processedimagessource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /processedimagessources/1
  # PATCH/PUT /processedimagessources/1.json
  def update
    respond_to do |format|
      if @processedimagessource.update(processedimagessource_params)
        format.html { redirect_to @processedimagessource, notice: 'Processedimagessource was successfully updated.' }
        format.json { render :show, status: :ok, location: @processedimagessource }
      else
        format.html { render :edit }
        format.json { render json: @processedimagessource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /processedimagessources/1
  # DELETE /processedimagessources/1.json
  def destroy
    @processedimagessource.destroy
    respond_to do |format|
      format.html { redirect_to processedimagessources_url, notice: 'Processedimagessource was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_processedimagessource
      @processedimagessource = Processedimagessource.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def processedimagessource_params
      params.require(:processedimagessource).permit(:file_name, :file_path, :source_image_id, :source_image_type, :processedimage_id, :comment)
    end
end
