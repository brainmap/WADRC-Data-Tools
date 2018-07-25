class NetworkgroupsController < ApplicationController
  before_action :set_networkgroup, only: [:show, :edit, :update, :destroy]

  # GET /networkgroups
  # GET /networkgroups.json
  def index
    @networkgroups = Networkgroup.all.order('networkgroup_type desc,name')
  end

  # GET /networkgroups/1
  # GET /networkgroups/1.json
  def show
  end

  # GET /networkgroups/new
  def new
    @networkgroup = Networkgroup.new
  end

  # GET /networkgroups/1/edit
  def edit
  end

  # POST /networkgroups
  # POST /networkgroups.json
  def create
    @networkgroup = Networkgroup.new(networkgroup_params)

    respond_to do |format|
      if @networkgroup.save
        format.html { redirect_to @networkgroup, notice: 'Networkgroup was successfully created.' }
        format.json { render :show, status: :created, location: @networkgroup }
      else
        format.html { render :new }
        format.json { render json: @networkgroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /networkgroups/1
  # PATCH/PUT /networkgroups/1.json
  def update
    respond_to do |format|
      if @networkgroup.update(networkgroup_params)
        format.html { redirect_to @networkgroup, notice: 'Networkgroup was successfully updated.' }
        format.json { render :show, status: :ok, location: @networkgroup }
      else
        format.html { render :edit }
        format.json { render json: @networkgroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /networkgroups/1
  # DELETE /networkgroups/1.json
  def destroy
    @networkgroup.destroy
    respond_to do |format|
      format.html { redirect_to networkgroups_url, notice: 'Networkgroup was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_networkgroup
      @networkgroup = Networkgroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def networkgroup_params
      params.require(:networkgroup).permit(:name, :networkgroup_type, :status_flag, :comment)
    end
end
