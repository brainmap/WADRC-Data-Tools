# encoding: utf-8
class CgQueryTnsController < ApplicationController
  # GET /cg_query_tns
  # GET /cg_query_tns.xml
  def index
    @cg_query_tns = CgQueryTn.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cg_query_tns }
    end
  end

  # GET /cg_query_tns/1
  # GET /cg_query_tns/1.xml
  def show
    @cg_query_tn = CgQueryTn.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cg_query_tn }
    end
  end

  # GET /cg_query_tns/new
  # GET /cg_query_tns/new.xml
  def new
    @cg_query_tn = CgQueryTn.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cg_query_tn }
    end
  end

  # GET /cg_query_tns/1/edit
  def edit
    @cg_query_tn = CgQueryTn.find(params[:id])
  end

  # POST /cg_query_tns
  # POST /cg_query_tns.xml
  def create
    @cg_query_tn = CgQueryTn.new(params[:cg_query_tn])

    respond_to do |format|
      if @cg_query_tn.save
        format.html { redirect_to(@cg_query_tn, :notice => 'Cg query tn was successfully created.') }
        format.xml  { render :xml => @cg_query_tn, :status => :created, :location => @cg_query_tn }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cg_query_tn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cg_query_tns/1
  # PUT /cg_query_tns/1.xml
  def update
    @cg_query_tn = CgQueryTn.find(params[:id])

    respond_to do |format|
      if @cg_query_tn.update_attributes(params[:cg_query_tn])
        format.html { redirect_to(@cg_query_tn, :notice => 'Cg query tn was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cg_query_tn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cg_query_tns/1
  # DELETE /cg_query_tns/1.xml
  def destroy
    @cg_query_tn = CgQueryTn.find(params[:id])
    @cg_query_tn.destroy

    respond_to do |format|
      format.html { redirect_to(cg_query_tns_url) }
      format.xml  { head :ok }
    end
  end
end
