class LookupRefsChangeLogsController < ApplicationController
  before_action :set_lookup_refs_change_log, only: [:show, :edit, :update, :destroy]

  # GET /lookup_refs_change_logs
  # GET /lookup_refs_change_logs.json
  def index
    @lookup_refs_change_logs = LookupRefsChangeLog.all
  end

  # GET /lookup_refs_change_logs/1
  # GET /lookup_refs_change_logs/1.json
  def show
  end

  # GET /lookup_refs_change_logs/new
  def new
    @lookup_refs_change_log = LookupRefsChangeLog.new
  end

  # GET /lookup_refs_change_logs/1/edit
  def edit
  end

  # POST /lookup_refs_change_logs
  # POST /lookup_refs_change_logs.json
  def create
    @lookup_refs_change_log = LookupRefsChangeLog.new(lookup_refs_change_log_params)

    respond_to do |format|
      if @lookup_refs_change_log.save
        format.html { redirect_to @lookup_refs_change_log, notice: 'Lookup refs change log was successfully created.' }
        format.json { render :show, status: :created, location: @lookup_refs_change_log }
      else
        format.html { render :new }
        format.json { render json: @lookup_refs_change_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lookup_refs_change_logs/1
  # PATCH/PUT /lookup_refs_change_logs/1.json
  def update
    respond_to do |format|
      if @lookup_refs_change_log.update(lookup_refs_change_log_params)
        format.html { redirect_to @lookup_refs_change_log, notice: 'Lookup refs change log was successfully updated.' }
        format.json { render :show, status: :ok, location: @lookup_refs_change_log }
      else
        format.html { render :edit }
        format.json { render json: @lookup_refs_change_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_refs_change_logs/1
  # DELETE /lookup_refs_change_logs/1.json
  def destroy
    @lookup_refs_change_log.destroy
    respond_to do |format|
      format.html { redirect_to lookup_refs_change_logs_url, notice: 'Lookup refs change log was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_lookup_refs_change_log
      @lookup_refs_change_log = LookupRefsChangeLog.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def lookup_refs_change_log_params
      params.require(:lookup_refs_change_log).permit(:modified_by_user_id, :original_ref_value, :ref_value, :original_display_order, :display_order, :original_description, :description, :original_label, :label,:original_id)
    end
end
