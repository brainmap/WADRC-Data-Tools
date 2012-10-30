class CgTnsController < ApplicationController
  # GET /cg_tns
  # GET /cg_tns.xml
  def index
    @cg_tns = CgTn.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cg_tns }
    end
  end

  # GET /cg_tns/1
  # GET /cg_tns/1.xml
  def show
    @cg_tn = CgTn.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cg_tn }
    end
  end

  # GET /cg_tns/new
  # GET /cg_tns/new.xml
  def new
    @cg_tn = CgTn.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cg_tn }
    end
  end

  # GET /cg_tns/1/edit
  def edit
    @cg_tn = CgTn.find(params[:id])
  end

  # POST /cg_tns
  # POST /cg_tns.xml
  def create
    params[:cg_tn][:tn] =  params[:cg_tn][:tn].downcase 
    params[:cg_tn][:join_left_parent_tn] =  params[:cg_tn][:join_left_parent_tn].downcase
    @cg_tn = CgTn.new(params[:cg_tn])

    respond_to do |format|
      if @cg_tn.save
        format.html { redirect_to(@cg_tn, :notice => 'Cg tn was successfully created.') }
        format.xml  { render :xml => @cg_tn, :status => :created, :location => @cg_tn }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cg_tn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cg_tns/1
  # PUT /cg_tns/1.xml
  def update
    @cg_tn = CgTn.find(params[:id])
     params[:cg_tn][:tn] =  params[:cg_tn][:tn].downcase 
     params[:cg_tn][:join_left_parent_tn] =  params[:cg_tn][:join_left_parent_tn].downcase
    respond_to do |format|
      if @cg_tn.update_attributes(params[:cg_tn])
        format.html { redirect_to(@cg_tn, :notice => 'Cg tn was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cg_tn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cg_tns/1
  # DELETE /cg_tns/1.xml
  def destroy
    @cg_tn = CgTn.find(params[:id])
    @cg_tn.destroy

    respond_to do |format|
      format.html { redirect_to(cg_tns_url) }
      format.xml  { head :ok }
    end
  end
end
