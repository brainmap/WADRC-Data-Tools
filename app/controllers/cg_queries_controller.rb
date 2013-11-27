# encoding: utf-8
class CgQueriesController < ApplicationController
  # GET /cg_queries
  # GET /cg_queries.xml
  def index
    @cg_queries = CgQuery.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cg_queries }
    end
  end

  # GET /cg_queries/1
  # GET /cg_queries/1.xml
  def show
    @cg_query = CgQuery.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cg_query }
    end
  end

  # GET /cg_queries/new
  # GET /cg_queries/new.xml
  def new
    @cg_query = CgQuery.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cg_query }
    end
  end

  # GET /cg_queries/1/edit
  def edit
    @cg_query = CgQuery.find(params[:id])
  end

  # POST /cg_queries
  # POST /cg_queries.xml
  def create
    @cg_query = CgQuery.new(params[:cg_query])

    respond_to do |format|
      if @cg_query.save
        format.html { redirect_to(@cg_query, :notice => 'Cg query was successfully created.') }
        format.xml  { render :xml => @cg_query, :status => :created, :location => @cg_query }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cg_query.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cg_queries/1
  # PUT /cg_queries/1.xml
  def update
    @cg_query = CgQuery.find(params[:id])

    respond_to do |format|
      if @cg_query.update_attributes(params[:cg_query])
        format.html { redirect_to(@cg_query, :notice => 'Cg query was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cg_query.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cg_queries/1
  # DELETE /cg_queries/1.xml
  def destroy
    @cg_query = CgQuery.find(params[:id])
    @cg_query.destroy

    respond_to do |format|
      format.html { redirect_to(cg_queries_url) }
      format.xml  { head :ok }
    end
  end
end
