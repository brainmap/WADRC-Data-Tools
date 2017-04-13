# encoding: utf-8
class NeuropsychSessionsController < ApplicationController 
  before_action :set_neuropsych_session, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /neuropsych_sessions
  # GET /neuropsych_sessions.xml
  def index
    @neuropsych_sessions = NeuropsychSession.all

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
    @neuropsych_session = NeuropsychSession.new(neuropsych_session_params)#params[:neuropsych_session])

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
      if @neuropsych_session.update(neuropsych_session_params)#params[:neuropsych_session], :without_protection => true)
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
  private
    def set_neuropsych_session
       @neuropsych_session = NeuropsychSession.find(params[:id])
    end
   def neuropsych_session_params
          params.require(:neuropsych_session).permit(:visit_id,:id,:date,:note,:procedure)
   end
end
