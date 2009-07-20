class NeuropsychSessionsController < ApplicationController
  # GET /neuropsych_sessions
  # GET /neuropsych_sessions.xml
  def index
    @neuropsych_sessions = NeuropsychSession.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @neuropsych_sessions }
    end
  end

  # GET /neuropsych_sessions/1
  # GET /neuropsych_sessions/1.xml
  def show
    @neuropsych_session = NeuropsychSession.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @neuropsych_session }
    end
  end

  # GET /neuropsych_sessions/new
  # GET /neuropsych_sessions/new.xml
  def new
    @neuropsych_session = NeuropsychSession.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @neuropsych_session }
    end
  end

  # GET /neuropsych_sessions/1/edit
  def edit
    @neuropsych_session = NeuropsychSession.find(params[:id])
  end

  # POST /neuropsych_sessions
  # POST /neuropsych_sessions.xml
  def create
    @neuropsych_session = NeuropsychSession.new(params[:neuropsych_session])

    respond_to do |format|
      if @neuropsych_session.save
        flash[:notice] = 'NeuropsychSession was successfully created.'
        format.html { redirect_to(@neuropsych_session) }
        format.xml  { render :xml => @neuropsych_session, :status => :created, :location => @neuropsych_session }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @neuropsych_session.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /neuropsych_sessions/1
  # PUT /neuropsych_sessions/1.xml
  def update
    @neuropsych_session = NeuropsychSession.find(params[:id])

    respond_to do |format|
      if @neuropsych_session.update_attributes(params[:neuropsych_session])
        flash[:notice] = 'NeuropsychSession was successfully updated.'
        format.html { redirect_to(@neuropsych_session) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @neuropsych_session.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /neuropsych_sessions/1
  # DELETE /neuropsych_sessions/1.xml
  def destroy
    @neuropsych_session = NeuropsychSession.find(params[:id])
    @neuropsych_session.destroy

    respond_to do |format|
      format.html { redirect_to(neuropsych_sessions_url) }
      format.xml  { head :ok }
    end
  end
end
