class VgroupsController < ApplicationController
  # GET /vgroups
  # GET /vgroups.xml
  def index
    @vgroups = Vgroup.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vgroups }
    end
  end

  # GET /vgroups/1
  # GET /vgroups/1.xml
  def show
    @vgroup = Vgroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vgroup }
    end
  end

  # GET /vgroups/new
  # GET /vgroups/new.xml
  def new
    @vgroup = Vgroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vgroup }
    end
  end

  # GET /vgroups/1/edit
  def edit
    @vgroup = Vgroup.find(params[:id])
  end

  # POST /vgroups
  # POST /vgroups.xml
  def create
    @vgroup = Vgroup.new(params[:vgroup])

    respond_to do |format|
      if @vgroup.save
        format.html { redirect_to(@vgroup, :notice => 'Vgroup was successfully created.') }
        format.xml  { render :xml => @vgroup, :status => :created, :location => @vgroup }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vgroup.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vgroups/1
  # PUT /vgroups/1.xml
  def update
    @vgroup = Vgroup.find(params[:id])

    respond_to do |format|
      if @vgroup.update_attributes(params[:vgroup])
        format.html { redirect_to(@vgroup, :notice => 'Vgroup was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vgroup.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vgroups/1
  # DELETE /vgroups/1.xml
  def destroy
    @vgroup = Vgroup.find(params[:id])
    @vgroup.destroy

    respond_to do |format|
      format.html { redirect_to(vgroups_url) }
      format.xml  { head :ok }
    end
  end
end
