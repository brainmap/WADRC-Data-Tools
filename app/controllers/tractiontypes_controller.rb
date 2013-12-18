class TractiontypesController < ApplicationController
  # GET /tractiontypes
  # GET /tractiontypes.json
  def index
    @tractiontypes = Tractiontype.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tractiontypes }
    end
  end

  # GET /tractiontypes/1
  # GET /tractiontypes/1.json
  def show
    @tractiontype = Tractiontype.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tractiontype }
    end
  end

  # GET /tractiontypes/new
  # GET /tractiontypes/new.json
  def new
    @tractiontype = Tractiontype.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tractiontype }
    end
  end

  # GET /tractiontypes/1/edit
  def edit
    @tractiontype = Tractiontype.find(params[:id])
  end

  # POST /tractiontypes
  # POST /tractiontypes.json
  def create
    @tractiontype = Tractiontype.new(params[:tractiontype])

    respond_to do |format|
      if @tractiontype.save
        format.html { redirect_to @tractiontype, notice: 'Tractiontype was successfully created.' }
        format.json { render json: @tractiontype, status: :created, location: @tractiontype }
      else
        format.html { render action: "new" }
        format.json { render json: @tractiontype.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tractiontypes/1
  # PUT /tractiontypes/1.json
  def update
    @tractiontype = Tractiontype.find(params[:id])

    respond_to do |format|
      if @tractiontype.update_attributes(params[:tractiontype])
        format.html { redirect_to @tractiontype, notice: 'Tractiontype was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tractiontype.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tractiontypes/1
  # DELETE /tractiontypes/1.json
  def destroy
    @tractiontype = Tractiontype.find(params[:id])
    @tractiontype.destroy

    respond_to do |format|
      format.html { redirect_to tractiontypes_url }
      format.json { head :no_content }
    end
  end
end
