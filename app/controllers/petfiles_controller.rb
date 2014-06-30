class PetfilesController < ApplicationController
  # GET /petfiles
  # GET /petfiles.json
  def index
    @petfiles = Petfile.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @petfiles }
    end
  end

  # GET /petfiles/1
  # GET /petfiles/1.json
  def show
    @petfile = Petfile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @petfile }
    end
  end

  # GET /petfiles/new
  # GET /petfiles/new.json
  def new
    @petfile = Petfile.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @petfile }
    end
  end

  # GET /petfiles/1/edit
  def edit
    @petfile = Petfile.find(params[:id])
  end

  # POST /petfiles
  # POST /petfiles.json
  def create
    @petfile = Petfile.new(params[:petfile])

    respond_to do |format|
      if @petfile.save
        format.html { redirect_to @petfile, notice: 'Petfile was successfully created.' }
        format.json { render json: @petfile, status: :created, location: @petfile }
      else
        format.html { render action: "new" }
        format.json { render json: @petfile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /petfiles/1
  # PUT /petfiles/1.json
  def update
    @petfile = Petfile.find(params[:id])

    respond_to do |format|
      if @petfile.update_attributes(params[:petfile])
        format.html { redirect_to @petfile, notice: 'Petfile was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @petfile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /petfiles/1
  # DELETE /petfiles/1.json
  def destroy
    @petfile = Petfile.find(params[:id])
    @petfile.destroy

    respond_to do |format|
      format.html { redirect_to petfiles_url }
      format.json { head :no_content }
    end
  end
end
