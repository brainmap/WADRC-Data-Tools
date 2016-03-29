class ConsentFormVgroupsController < ApplicationController
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
    @consent_form_vgroup = ConsentFormVgroup.new(params[:consent_form_vgroup])

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
      if @consent_form_vgroup.update_attributes(params[:consent_form_vgroup])
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
end
