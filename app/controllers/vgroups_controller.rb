class VgroupsController < ApplicationController
  # GET /vgroups
  # GET /vgroups.xml
  def index
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroups = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vgroups }
    end
  end

  # GET /vgroups/1
  # GET /vgroups/1.xml
  def show
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

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
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
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
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

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
  
  # GET /vgroups/:scope
  def index_by_scope

    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @search = Vgroup.send(params[:scope]).search(params[:search])
    @visits = @search.relation.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    @collection_title = "All #{params[:scope].to_s.gsub('_',' ')} Visits"
    render :template => "vgroups/home"
  end
  
  def assigned_to_who
    redirect_to assigned_to_vgroup_path( :user_login => params[:user][:username] )
  end
  
  # GET /vgroups/assigned_to/:user_login
  def index_by_user_id

    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    
    @user = User.find(params[:user_login])
    @search = Vgroup.assigned_to(@user.id).search
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Vgroup.unscoped.search(params[:search]) 
    else
      @search = Vgroup.search(params[:search]) 
    end

    @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))
                          and vgroups.user_id in (?)", 
                              scan_procedure_array,@user.id).page(params[:page])

    
    @collection_title = "All Visits assigned " # to #{params[:user_login]}"
    render :template => "vgroups/home"
  end
  
  def in_scan_procedure
    redirect_to in_scan_procedure_vgroup_path( :scan_procedure_id => params[:scan_procedure][:id] )
  end

  def index_by_scan_procedure  
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Vgroup.unscoped.search(params[:search]) 
    else
      @search = Vgroup.search(params[:search]) 
    end
    if !params[:scan_procedure_id].blank? 
       @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?) and scan_procedure_id in (?))", 
                              scan_procedure_array,params[:scan_procedure_id]).page(params[:page])
    else
      @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    end
    @collection_title = "All Visits enrolled in #{ScanProcedure.find_by_id(params[:scan_procedure_id]).codename}"
    render :template => "vgroups/home"

  end
  
  
  def visit_search
     render :template => "vgroups/home"
  end
  
  
  def home
    
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    # Remove default scope if sorting has been requested.
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Vgroup.unscoped.search(params[:search]) 
    else
      @search = Vgroup.search(params[:search]) 
    end
    @vgroups = @search.relation.where(" vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    @collection_title = 'All Visits'
    
    respond_to do |format|
      format.html # home.html.erb
      format.xml  { render :xml => @visits }
    end
    #  render :template => "vgroups/home"
  end

  # DELETE /vgroups/1
  # DELETE /vgroups/1.xml
  def destroy
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @vgroup.destroy

    respond_to do |format|
      format.html { redirect_to(vgroups_url) }
      format.xml  { head :ok }
    end
  end
end
