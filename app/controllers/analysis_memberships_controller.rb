# encoding: utf-8
class AnalysisMembershipsController < ApplicationController
  # GET /analysis_memberships
  # GET /analysis_memberships.xml
  def index
    @analysis_memberships = AnalysisMembership.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @analysis_memberships }
    end
  end

  # GET /analysis_memberships/1
  # GET /analysis_memberships/1.xml
  def show
    @analysis_membership = AnalysisMembership.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @analysis_membership }
    end
  end

  # GET /analysis_memberships/new
  # GET /analysis_memberships/new.xml
  def new
    @analysis_membership = AnalysisMembership.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @analysis_membership }
    end
  end

  # GET /analysis_memberships/1/edit
  def edit
    @analysis_membership = AnalysisMembership.find(params[:id])
    respond_to do |format|
        format.html
        format.xml  { render :xml => @analysis_membership.errors, :status => :unprocessable_entity }
    end
  end

  # POST /analysis_memberships
  # POST /analysis_memberships.xml
  def create
    @analysis_membership = AnalysisMembership.new(params[:analysis_membership])

    respond_to do |format|
      if @analysis_membership.save
        flash[:notice] = 'AnalysisMembership was successfully created.'
        format.html { redirect_to(@analysis_membership) }
        format.xml  { render :xml => @analysis_membership, :status => :created, :location => @analysis_membership }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @analysis_membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /analysis_memberships/1
  # PUT /analysis_memberships/1.xml
  def update
    @analysis_membership = AnalysisMembership.find(params[:id])

    respond_to do |format|
      if @analysis_membership.update_attributes(params[:analysis_membership])
        flash[:notice] = 'AnalysisMembership was successfully updated.'
        format.html { redirect_to(@analysis_membership.analysis) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @analysis_membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /analysis_memberships/1
  # DELETE /analysis_memberships/1.xml
  def destroy
    @analysis_membership = AnalysisMembership.find(params[:id])
    @analysis_membership.destroy

    respond_to do |format|
      format.html { redirect_to(analysis_memberships_url) }
      format.xml  { head :ok }
    end
  end
end
