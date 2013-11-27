# encoding: utf-8
class CgQueryTnCnsController < ApplicationController
  # GET /cg_query_tn_cns
  # GET /cg_query_tn_cns.xml
  def index
    @cg_query_tn_cns = CgQueryTnCn.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cg_query_tn_cns }
    end
  end

  # GET /cg_query_tn_cns/1
  # GET /cg_query_tn_cns/1.xml
  def show
    @cg_query_tn_cn = CgQueryTnCn.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cg_query_tn_cn }
    end
  end

  # GET /cg_query_tn_cns/new
  # GET /cg_query_tn_cns/new.xml
  def new
    @cg_query_tn_cn = CgQueryTnCn.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cg_query_tn_cn }
    end
  end

  # GET /cg_query_tn_cns/1/edit
  def edit
    @cg_query_tn_cn = CgQueryTnCn.find(params[:id])
  end

  # POST /cg_query_tn_cns
  # POST /cg_query_tn_cns.xml
  def create
    @cg_query_tn_cn = CgQueryTnCn.new(params[:cg_query_tn_cn])

    respond_to do |format|
      if @cg_query_tn_cn.save
        format.html { redirect_to(@cg_query_tn_cn, :notice => 'Cg query tn cn was successfully created.') }
        format.xml  { render :xml => @cg_query_tn_cn, :status => :created, :location => @cg_query_tn_cn }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cg_query_tn_cn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cg_query_tn_cns/1
  # PUT /cg_query_tn_cns/1.xml
  def update
    @cg_query_tn_cn = CgQueryTnCn.find(params[:id])

    respond_to do |format|
      if @cg_query_tn_cn.update_attributes(params[:cg_query_tn_cn])
        format.html { redirect_to(@cg_query_tn_cn, :notice => 'Cg query tn cn was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cg_query_tn_cn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cg_query_tn_cns/1
  # DELETE /cg_query_tn_cns/1.xml
  def destroy
    @cg_query_tn_cn = CgQueryTnCn.find(params[:id])
    @cg_query_tn_cn.destroy

    respond_to do |format|
      format.html { redirect_to(cg_query_tn_cns_url) }
      format.xml  { head :ok }
    end
  end
end
