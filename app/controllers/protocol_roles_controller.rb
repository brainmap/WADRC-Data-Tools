class ProtocolRolesController < AuthorizedController #  ApplicationController
load_and_authorize_resource
  # GET /protocol_roles
  # GET /protocol_roles.xml
  def index
     @catch = params[:protocol_role]

    if params[:protocol_role].blank?
    @protocol_roles = ProtocolRole.all
  else
    if !params[:protocol_role][:user_id].blank? && params[:protocol_role][:protocol_id].blank?
    @protocol_roles = ProtocolRole.where("user_id in  (?)", params[:protocol_role][:user_id]).all  
   elsif  params[:protocol_role][:user_id].blank? && !params[:protocol_role][:protocol_id].blank?
     @protocol_roles = ProtocolRole.where("protocol_id in  (?)", params[:protocol_role][:protocol_id]).all
   elsif  !params[:protocol_role][:user_id].blank? && !params[:protocol_role][:protocol_id].blank?
     @protocol_roles = ProtocolRole.where("user_id in  (?) and protocol_id in (?)", params[:protocol_role][:user_id], params[:protocol_role][:protocol_id]).all      
    end
   end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @protocol_roles }
    end
  end



  # GET /protocol_roles/1
  # GET /protocol_roles/1.xml
  def show
    @protocol_role = ProtocolRole.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @protocol_role }
    end
  end

  # GET /protocol_roles/new
  # GET /protocol_roles/new.xml
  def new
    @protocol_role = ProtocolRole.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @protocol_role }
    end
  end

  # GET /protocol_roles/1/edit
  def edit
    @protocol_role = ProtocolRole.find(params[:id])
  end

  # POST /protocol_roles
  # POST /protocol_roles.xml
  def create
    @protocol_role = ProtocolRole.new(params[:protocol_role])

    respond_to do |format|
      if @protocol_role.save
        format.html { redirect_to(@protocol_role, :notice => 'Protocol role was successfully created.') }
        format.xml  { render :xml => @protocol_role, :status => :created, :location => @protocol_role }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @protocol_role.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /protocol_roles/1
  # PUT /protocol_roles/1.xml
  def update
    @protocol_role = ProtocolRole.find(params[:id])

    respond_to do |format|
      if @protocol_role.update_attributes(params[:protocol_role])
        format.html { redirect_to(@protocol_role, :notice => 'Protocol role was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @protocol_role.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /protocol_roles/1
  # DELETE /protocol_roles/1.xml
  # Could not find table 'protocol_roles_protocols'
  def destroy
    @protocol_role = ProtocolRole.find(params[:id])
    @protocol_role.destroy

    respond_to do |format|
      format.html { redirect_to(protocol_roles_url) }
      format.xml  { head :ok }
    end
  end
  
  # ????????
  def authorize_parent
    authorize! :read, (@protocol)
  end
  
end
