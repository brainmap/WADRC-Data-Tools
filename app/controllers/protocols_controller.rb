# encoding: utf-8
class ProtocolsController <  AuthorizedController #  ApplicationController
load_and_authorize_resource  
before_action :set_protocol, only: [:show, :edit, :update, :destroy]   
respond_to :html
  # GET /protocols
  # GET /protocols.xml
  def index
    @protocols = Protocol.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @protocols }
    end
  end

  # GET /protocols/1
  # GET /protocols/1.xml
  def show
    @protocol = Protocol.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @protocol }
    end
  end

  # GET /protocols/new
  # GET /protocols/new.xml
  def new
    @protocol = Protocol.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @protocol }
    end
  end

  # GET /protocols/1/edit
  def edit
    @protocol = Protocol.find(params[:id])

    puts "Hey, it's the #{@protocol.name} protocol"
    puts "Sharing is: #{@protocol.sharing}"

    @sharing = @protocol.sharing
  end

  # POST /protocols
  # POST /protocols.xml
  def create
    @protocol = Protocol.new(protocol_params ) #params[:protocol])

    respond_to do |format|
      if @protocol.save
        format.html { redirect_to(@protocol, :notice => 'Protocol was successfully created.') }
        format.xml  { render :xml => @protocol, :status => :created, :location => @protocol }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @protocol.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /protocols/1
  # PUT /protocols/1.xml
  def update
    @protocol = Protocol.find(params[:id])

    respond_to do |format|
      if @protocol.update(protocol_params ) #params[:protocol], :without_protection => true)
        format.html { redirect_to(@protocol, :notice => 'Protocol was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @protocol.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /protocols/1
  # DELETE /protocols/1.xml
  def destroy
    @protocol = Protocol.find(params[:id])
    @protocol.destroy

    respond_to do |format|
      format.html { redirect_to(protocols_url) }
      format.xml  { head :ok }
    end
  end 
  private
    def set_protocol
      @protocol = Protocol.find(params[:id])
    end
  def protocol_params
    params.require(:protocol).permit(:id, :name, :abbr, :path, :description, :parent_protocol_id, :hide_date_flag)
  end
end
