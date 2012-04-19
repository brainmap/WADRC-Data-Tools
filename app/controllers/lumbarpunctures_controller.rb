class LumbarpuncturesController < ApplicationController
  # GET /lumbarpunctures
  # GET /lumbarpunctures.xml
  def index
    @lumbarpunctures = Lumbarpuncture.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lumbarpunctures }
    end
  end

  # GET /lumbarpunctures/1
  # GET /lumbarpunctures/1.xml
  def show
    @lumbarpuncture = Lumbarpuncture.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lumbarpuncture }
    end
  end

  # GET /lumbarpunctures/new
  # GET /lumbarpunctures/new.xml
  def new
    @lumbarpuncture = Lumbarpuncture.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lumbarpuncture }
    end
  end

  # GET /lumbarpunctures/1/edit
  def edit
    @lumbarpuncture = Lumbarpuncture.find(params[:id])
  end

  # POST /lumbarpunctures
  # POST /lumbarpunctures.xml
  def create
    @lumbarpuncture = Lumbarpuncture.new(params[:lumbarpuncture])

    respond_to do |format|
      if @lumbarpuncture.save
        format.html { redirect_to(@lumbarpuncture, :notice => 'Lumbarpuncture was successfully created.') }
        format.xml  { render :xml => @lumbarpuncture, :status => :created, :location => @lumbarpuncture }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lumbarpuncture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lumbarpunctures/1
  # PUT /lumbarpunctures/1.xml
  def update
    @lumbarpuncture = Lumbarpuncture.find(params[:id])

    respond_to do |format|
      if @lumbarpuncture.update_attributes(params[:lumbarpuncture])
        format.html { redirect_to(@lumbarpuncture, :notice => 'Lumbarpuncture was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lumbarpuncture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lumbarpunctures/1
  # DELETE /lumbarpunctures/1.xml
  def destroy
    @lumbarpuncture = Lumbarpuncture.find(params[:id])
    @lumbarpuncture.destroy

    respond_to do |format|
      format.html { redirect_to(lumbarpunctures_url) }
      format.xml  { head :ok }
    end
  end
end
