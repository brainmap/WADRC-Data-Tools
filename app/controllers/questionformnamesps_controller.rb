class QuestionformnamespsController < ApplicationController
  # GET /questionformnamesps
  # GET /questionformnamesps.json
  def index
    @questionformnamesps = Questionformnamesp.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @questionformnamesps }
    end
  end

  # GET /questionformnamesps/1
  # GET /questionformnamesps/1.json
  def show
    @questionformnamesp = Questionformnamesp.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @questionformnamesp }
    end
  end

  # GET /questionformnamesps/new
  # GET /questionformnamesps/new.json
  def new
    @questionformnamesp = Questionformnamesp.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @questionformnamesp }
    end
  end

  # GET /questionformnamesps/1/edit
  def edit
    @questionformnamesp = Questionformnamesp.find(params[:id])
  end

  # POST /questionformnamesps
  # POST /questionformnamesps.json
  def create
    @questionformnamesp = Questionformnamesp.new(questionformnamesp_params)#params[:questionformnamesp])

    respond_to do |format|
      if @questionformnamesp.save
        format.html { redirect_to @questionformnamesp, notice: 'Questionformnamesp was successfully created.' }
        format.json { render json: @questionformnamesp, status: :created, location: @questionformnamesp }
      else
        format.html { render action: "new" }
        format.json { render json: @questionformnamesp.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /questionformnamesps/1
  # PUT /questionformnamesps/1.json
  def update
    @questionformnamesp = Questionformnamesp.find(params[:id])

    respond_to do |format|
      if @questionformnamesp.update(questionformnamesp_params)#params[:questionformnamesp], :without_protection => true)
        format.html { redirect_to @questionformnamesp, notice: 'Questionformnamesp was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @questionformnamesp.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /questionformnamesps/1
  # DELETE /questionformnamesps/1.json
  def destroy
    @questionformnamesp = Questionformnamesp.find(params[:id])
    @questionformnamesp.destroy

    respond_to do |format|
      format.html { redirect_to questionformnamesps_url }
      format.json { head :no_content }
    end
  end   
  private
    def set_questionformnamesp
       @questionformnamesp = Questionformnamesp.find(params[:id])
    end
   def questionformnamesp_params
          params.require(:questionformnamesp).permit(:form_name,:scan_procedure_id,:questionform_id,:id)
   end
end
