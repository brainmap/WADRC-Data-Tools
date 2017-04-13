# encoding: utf-8
class LookupRelationshipsController < ApplicationController
  # GET /lookup_relationships
  # GET /lookup_relationships.xml
  def index
    @lookup_relationships = LookupRelationship.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_relationships }
    end
  end

  # GET /lookup_relationships/1
  # GET /lookup_relationships/1.xml
  def show
    @lookup_relationship = LookupRelationship.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_relationship }
    end
  end

  # GET /lookup_relationships/new
  # GET /lookup_relationships/new.xml
  def new
    @lookup_relationship = LookupRelationship.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_relationship }
    end
  end

  # GET /lookup_relationships/1/edit
  def edit
    @lookup_relationship = LookupRelationship.find(params[:id])
  end

  # POST /lookup_relationships
  # POST /lookup_relationships.xml
  def create
    @lookup_relationship = LookupRelationship.new(params[:lookup_relationship])

    respond_to do |format|
      if @lookup_relationship.save
        format.html { redirect_to(@lookup_relationship, :notice => 'Lookup relationship was successfully created.') }
        format.xml  { render :xml => @lookup_relationship, :status => :created, :location => @lookup_relationship }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_relationship.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_relationships/1
  # PUT /lookup_relationships/1.xml
  def update
    @lookup_relationship = LookupRelationship.find(params[:id])

    respond_to do |format|
      if @lookup_relationship.update(params[:lookup_relationship], :without_protection => true)
        format.html { redirect_to(@lookup_relationship, :notice => 'Lookup relationship was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_relationship.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_relationships/1
  # DELETE /lookup_relationships/1.xml
  def destroy
    @lookup_relationship = LookupRelationship.find(params[:id])
    @lookup_relationship.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_relationships_url) }
      format.xml  { head :ok }
    end
  end
end
