class ConsentFormVgroupsController < ApplicationController  
  before_action :set_consent_form_vgroup, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /consent_form_vgroups
  # GET /consent_form_vgroups.json
  def index
    @consent_form_vgroups = ConsentFormVgroup.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @consent_form_vgroups }
    end
  end

  # GET /consent_form_vgroups/1
  # GET /consent_form_vgroups/1.json
  def show
    @consent_form_vgroup = ConsentFormVgroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @consent_form_vgroup }
    end
  end

  # GET /consent_form_vgroups/new
  # GET /consent_form_vgroups/new.json
  def new
    @consent_form_vgroup = ConsentFormVgroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @consent_form_vgroup }
    end
  end

  # GET /consent_form_vgroups/1/edit
  def edit
    @consent_form_vgroup = ConsentFormVgroup.find(params[:id])
  end

  # POST /consent_form_vgroups
  # POST /consent_form_vgroups.json
  def create
    @consent_form_vgroup = ConsentFormVgroup.new(consent_form_vgroup_params)#params[:consent_form_vgroup])

    respond_to do |format|
      if @consent_form_vgroup.save
        format.html { redirect_to @consent_form_vgroup, notice: 'Consent form vgroup was successfully created.' }
        format.json { render json: @consent_form_vgroup, status: :created, location: @consent_form_vgroup }
      else
        format.html { render action: "new" }
        format.json { render json: @consent_form_vgroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /consent_form_vgroups/1
  # PUT /consent_form_vgroups/1.json
  def update
    @consent_form_vgroup = ConsentFormVgroup.find(params[:id])

    respond_to do |format|
      if @consent_form_vgroup.update(consent_form_vgroup_params)#params[:consent_form_vgroup], :without_protection => true)
        format.html { redirect_to @consent_form_vgroup, notice: 'Consent form vgroup was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @consent_form_vgroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /consent_form_vgroups/1
  # DELETE /consent_form_vgroups/1.json
  def destroy
    @consent_form_vgroup = ConsentFormVgroup.find(params[:id])
    @consent_form_vgroup.destroy

    respond_to do |format|
      format.html { redirect_to consent_form_vgroups_url }
      format.json { head :no_content }
    end
  end 
  private
    def set_consent_form_vgroup
       @consent_form_vgroup = ConsentFormVgroup.find(params[:id])
    end
   def consent_form_vgroup_params
          params.require(:consent_form_vgroup).permit(:status_flag,:user_id,:consent_date,:consent_form_id,:vgroup_id,:id)
   end
end
