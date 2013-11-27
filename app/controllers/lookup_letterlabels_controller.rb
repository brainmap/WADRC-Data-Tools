# encoding: utf-8
class LookupLetterlabelsController < ApplicationController
  # GET /lookup_letterlabels
  # GET /lookup_letterlabels.xml
  def index
    @lookup_letterlabels = LookupLetterlabel.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_letterlabels }
    end
  end

  # GET /lookup_letterlabels/1
  # GET /lookup_letterlabels/1.xml
  def show
    @lookup_letterlabel = LookupLetterlabel.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_letterlabel }
    end
  end

  # GET /lookup_letterlabels/new
  # GET /lookup_letterlabels/new.xml
  def new
    @lookup_letterlabel = LookupLetterlabel.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_letterlabel }
    end
  end

  # GET /lookup_letterlabels/1/edit
  def edit
    @lookup_letterlabel = LookupLetterlabel.find(params[:id])
  end

  # POST /lookup_letterlabels
  # POST /lookup_letterlabels.xml
  def create
    @lookup_letterlabel = LookupLetterlabel.new(params[:lookup_letterlabel])

    respond_to do |format|
      if @lookup_letterlabel.save
        format.html { redirect_to(@lookup_letterlabel, :notice => 'Lookup letterlabel was successfully created.') }
        format.xml  { render :xml => @lookup_letterlabel, :status => :created, :location => @lookup_letterlabel }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_letterlabel.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_letterlabels/1
  # PUT /lookup_letterlabels/1.xml
  def update
    @lookup_letterlabel = LookupLetterlabel.find(params[:id])

    respond_to do |format|
      if @lookup_letterlabel.update_attributes(params[:lookup_letterlabel])
        format.html { redirect_to(@lookup_letterlabel, :notice => 'Lookup letterlabel was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_letterlabel.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_letterlabels/1
  # DELETE /lookup_letterlabels/1.xml
  def destroy
    @lookup_letterlabel = LookupLetterlabel.find(params[:id])
    @lookup_letterlabel.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_letterlabels_url) }
      format.xml  { head :ok }
    end
  end
end
