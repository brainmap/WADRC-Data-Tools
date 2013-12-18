class TrtypesController < ApplicationController
  # GET /trtypes
  # GET /trtypes.json
  def index
    @trtypes = Trtype.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trtypes }
    end
  end

  # GET /trtypes/1
  # GET /trtypes/1.json
  def show
    @trtype = Trtype.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trtype }
    end
  end

  # GET /trtypes/new
  # GET /trtypes/new.json
  def new
    @trtype = Trtype.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trtype }
    end
  end

  # GET /trtypes/1/edit
  def edit
    @trtype = Trtype.find(params[:id])
  end

  # POST /trtypes
  # POST /trtypes.json
  def create
    @trtype = Trtype.new(params[:trtype])

    respond_to do |format|
      if @trtype.save
        format.html { redirect_to @trtype, notice: 'Trtype was successfully created.' }
        format.json { render json: @trtype, status: :created, location: @trtype }
      else
        format.html { render action: "new" }
        format.json { render json: @trtype.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trtypes/1
  # PUT /trtypes/1.json
  def update
    @trtype = Trtype.find(params[:id])

    respond_to do |format|
      if @trtype.update_attributes(params[:trtype])
        format.html { redirect_to @trtype, notice: 'Trtype was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trtype.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trtypes/1
  # DELETE /trtypes/1.json
  def destroy
    @trtype = Trtype.find(params[:id])
    @trtype.destroy

    respond_to do |format|
      format.html { redirect_to trtypes_url }
      format.json { head :no_content }
    end
  end
end
