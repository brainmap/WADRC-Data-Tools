class UsernetworkgroupsController < ApplicationController
  before_action :set_usernetworkgroup, only: [:show, :edit, :update, :destroy]

  # GET /usernetworkgroups
  # GET /usernetworkgroups.json
  def index
    @usernetworkgroups = Usernetworkgroup.all
  end

  # GET /usernetworkgroups/1
  # GET /usernetworkgroups/1.json
  def show
  end

  # GET /usernetworkgroups/new
  def new
    @usernetworkgroup = Usernetworkgroup.new
  end

  # GET /usernetworkgroups/1/edit
  def edit
  end

  # POST /usernetworkgroups
  # POST /usernetworkgroups.json
  def create
    @usernetworkgroup = Usernetworkgroup.new(usernetworkgroup_params)

    respond_to do |format|
      if @usernetworkgroup.save
        format.html { redirect_to @usernetworkgroup, notice: 'Usernetworkgroup was successfully created.' }
        format.json { render :show, status: :created, location: @usernetworkgroup }
      else
        format.html { render :new }
        format.json { render json: @usernetworkgroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /usernetworkgroups/1
  # PATCH/PUT /usernetworkgroups/1.json
  def update
    respond_to do |format|
      if @usernetworkgroup.update(usernetworkgroup_params)
        format.html { redirect_to @usernetworkgroup, notice: 'Usernetworkgroup was successfully updated.' }
        format.json { render :show, status: :ok, location: @usernetworkgroup }
      else
        format.html { render :edit }
        format.json { render json: @usernetworkgroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /usernetworkgroups/1
  # DELETE /usernetworkgroups/1.json
  def destroy
    @usernetworkgroup.destroy
    respond_to do |format|
      format.html { redirect_to usernetworkgroups_url, notice: 'Usernetworkgroup was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_usernetworkgroup
      @usernetworkgroup = Usernetworkgroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def usernetworkgroup_params
      params.require(:usernetworkgroup).permit(:user_id, :networkgroup_id, :status_flag, :comment)
    end
end
