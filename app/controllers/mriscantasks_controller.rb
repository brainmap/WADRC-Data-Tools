class MriscantasksController < ApplicationController
  # GET /mriscantasks
  # GET /mriscantasks.xml
  def index
    @mriscantasks = Mriscantask.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @mriscantasks }
    end
  end

  # GET /mriscantasks/1
  # GET /mriscantasks/1.xml
  def show
    @mriscantask = Mriscantask.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @mriscantask }
    end
  end

  # GET /mriscantasks/new
  # GET /mriscantasks/new.xml
  def new
    @mriscantask = Mriscantask.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @mriscantask }
    end
  end

  # GET /mriscantasks/1/edit
  def edit
    @mriscantask = Mriscantask.find(params[:id])
  end

  # POST /mriscantasks
  # POST /mriscantasks.xml
  def create
    @mriscantask = Mriscantask.new(params[:mriscantask])

    respond_to do |format|
      if @mriscantask.save
        format.html { redirect_to(@mriscantask, :notice => 'Mriscantask was successfully created.') }
        format.xml  { render :xml => @mriscantask, :status => :created, :location => @mriscantask }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @mriscantask.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /mriscantasks/1
  # PUT /mriscantasks/1.xml
  def update
    @mriscantask = Mriscantask.find(params[:id])

    respond_to do |format|
      if @mriscantask.update_attributes(params[:mriscantask])
        format.html { redirect_to(@mriscantask, :notice => 'Mriscantask was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mriscantask.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /mriscantasks/1
  # DELETE /mriscantasks/1.xml
  def destroy
    @mriscantask = Mriscantask.find(params[:id])
    @mriscantask.destroy

    respond_to do |format|
      format.html { redirect_to(mriscantasks_url) }
      format.xml  { head :ok }
    end
  end
end
