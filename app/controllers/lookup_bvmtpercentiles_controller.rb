# encoding: utf-8
class LookupBvmtpercentilesController < ApplicationController
  # GET /lookup_bvmtpercentiles
  # GET /lookup_bvmtpercentiles.xml
  def index
    @lookup_bvmtpercentiles = LookupBvmtpercentile.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_bvmtpercentiles }
    end
  end

  # GET /lookup_bvmtpercentiles/1
  # GET /lookup_bvmtpercentiles/1.xml
  def show
    @lookup_bvmtpercentile = LookupBvmtpercentile.find(params[:id])
    # test sending email
    begin
          puts "aaaaaa before test email"
          puts "AAAAA="+PandaMailer.test_email({:send_to => "noreply_johnson_lab@medicine.wisc.edu"}).deliver.to_s
          puts "bbbbbb after test email"
          flash[:notice] = "Email was succesfully sent."
    rescue StandardError => error
      logger.info error
      flash[:error] = "Sorry, your email was not delivered: " + error.to_s
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_bvmtpercentile }
    end
  end

  # GET /lookup_bvmtpercentiles/new
  # GET /lookup_bvmtpercentiles/new.xml
  def new
    @lookup_bvmtpercentile = LookupBvmtpercentile.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_bvmtpercentile }
    end
  end

  # GET /lookup_bvmtpercentiles/1/edit
  def edit
    @lookup_bvmtpercentile = LookupBvmtpercentile.find(params[:id])
  end

  # POST /lookup_bvmtpercentiles
  # POST /lookup_bvmtpercentiles.xml
  def create
    @lookup_bvmtpercentile = LookupBvmtpercentile.new(params[:lookup_bvmtpercentile])

    respond_to do |format|
      if @lookup_bvmtpercentile.save
        format.html { redirect_to(@lookup_bvmtpercentile, :notice => 'Lookup bvmtpercentile was successfully created.') }
        format.xml  { render :xml => @lookup_bvmtpercentile, :status => :created, :location => @lookup_bvmtpercentile }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_bvmtpercentile.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_bvmtpercentiles/1
  # PUT /lookup_bvmtpercentiles/1.xml
  def update
    @lookup_bvmtpercentile = LookupBvmtpercentile.find(params[:id])

    respond_to do |format|
      if @lookup_bvmtpercentile.update_attributes(params[:lookup_bvmtpercentile])
        format.html { redirect_to(@lookup_bvmtpercentile, :notice => 'Lookup bvmtpercentile was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_bvmtpercentile.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_bvmtpercentiles/1
  # DELETE /lookup_bvmtpercentiles/1.xml
  def destroy
    @lookup_bvmtpercentile = LookupBvmtpercentile.find(params[:id])
    @lookup_bvmtpercentile.destroy

    respond_to do |format|
      format.html { redirect_to(lookup_bvmtpercentiles_url) }
      format.xml  { head :ok }
    end
  end
end
