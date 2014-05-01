# encoding: utf-8
class LookupPettracersController < ApplicationController
  # GET /lookup_pettracers
  # GET /lookup_pettracers.xml
  def index
    @lookup_pettracers = LookupPettracer.all
    # all sams ids done - 43,22,37,38,44,41,45
    @image_datasets = ImageDataset.where("image_datasets.visit_id in ( select visits.id from visits , appointments, scan_procedures_vgroups 
                                                                 where visits.appointment_id = appointments.id 
                                                                 and appointments.vgroup_id = scan_procedures_vgroups.vgroup_id
                                                                 and scan_procedures_vgroups.scan_procedure_id in (43))")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_pettracers }
    end
  end

  # GET /lookup_pettracers/1
  # GET /lookup_pettracers/1.xml
  def show
    @lookup_pettracer = LookupPettracer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_pettracer }
    end
  end

  # GET /lookup_pettracers/new
  # GET /lookup_pettracers/new.xml
  def new
    @lookup_pettracer = LookupPettracer.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_pettracer }
    end
  end

  # GET /lookup_pettracers/1/edit
  def edit
    @lookup_pettracer = LookupPettracer.find(params[:id])
  end

  # POST /lookup_pettracers
  # POST /lookup_pettracers.xml
  def create
    @lookup_pettracer = LookupPettracer.new(params[:lookup_pettracer])

    respond_to do |format|
      if @lookup_pettracer.save
        format.html { redirect_to(@lookup_pettracer, :notice => 'Lookup pettracer was successfully created.') }
        format.xml  { render :xml => @lookup_pettracer, :status => :created, :location => @lookup_pettracer }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_pettracer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_pettracers/1
  # PUT /lookup_pettracers/1.xml
  def update
    @lookup_pettracer = LookupPettracer.find(params[:id])

    respond_to do |format|
      if @lookup_pettracer.update_attributes(params[:lookup_pettracer])
        format.html { redirect_to(@lookup_pettracer, :notice => 'Lookup pettracer was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_pettracer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_pettracers/1
  # DELETE /lookup_pettracers/1.xml
  def destroy
    @lookup_pettracer = LookupPettracer.find(params[:id])
    @lookup_pettracer.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_pettracers_url) }
      format.xml  { head :ok }
    end
  end
end
