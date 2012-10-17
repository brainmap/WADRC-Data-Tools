class CgTnCnsController < ApplicationController
  # GET /cg_tn_cns
  # GET /cg_tn_cns.xml
  def index
    @cg_tn_cns = CgTnCn.find(:all, :order =>"cg_tn_id,display_order")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cg_tn_cns }
    end
  end

  # GET /cg_tn_cns/1
  # GET /cg_tn_cns/1.xml
  def show
    @cg_tn_cn = CgTnCn.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cg_tn_cn }
    end
  end

  # GET /cg_tn_cns/new
  # GET /cg_tn_cns/new.xml
  def new
    @cg_tn_cn = CgTnCn.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cg_tn_cn }
    end
  end

  # GET /cg_tn_cns/1/edit
  def edit
    @cg_tn_cn = CgTnCn.find(params[:id])
  end

  # POST /cg_tn_cns
  # POST /cg_tn_cns.xml
  def create
    @cg_tn_cn = CgTnCn.new(params[:cg_tn_cn])

    respond_to do |format|
      if @cg_tn_cn.save
        format.html { redirect_to(@cg_tn_cn, :notice => 'Cg tn cn was successfully created.') }
        format.xml  { render :xml => @cg_tn_cn, :status => :created, :location => @cg_tn_cn }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cg_tn_cn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cg_tn_cns/1
  # PUT /cg_tn_cns/1.xml
  def update
    @cg_tn_cn = CgTnCn.find(params[:id])

    respond_to do |format|
      if @cg_tn_cn.update_attributes(params[:cg_tn_cn])
        format.html { redirect_to(@cg_tn_cn, :notice => 'Cg tn cn was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cg_tn_cn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cg_tn_cns/1
  # DELETE /cg_tn_cns/1.xml
  def destroy
    @cg_tn_cn = CgTnCn.find(params[:id])
    @cg_tn_cn.destroy

    respond_to do |format|
      format.html { redirect_to(cg_tn_cns_url) }
      format.xml  { head :ok }
    end
  end
end
