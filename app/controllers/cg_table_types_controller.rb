class CgTableTypesController < ApplicationController
  # GET /cg_table_types
  # GET /cg_table_types.json
  def index
    @cg_table_types = CgTableType.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @cg_table_types }
    end
  end

  # GET /cg_table_types/1
  # GET /cg_table_types/1.json
  def show
    @cg_table_type = CgTableType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @cg_table_type }
    end
  end

  # GET /cg_table_types/new
  # GET /cg_table_types/new.json
  def new
    @cg_table_type = CgTableType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @cg_table_type }
    end
  end

  # GET /cg_table_types/1/edit
  def edit
    @cg_table_type = CgTableType.find(params[:id])
  end

  # POST /cg_table_types
  # POST /cg_table_types.json
  def create
    @cg_table_type = CgTableType.new(cg_table_type_params)#params[:cg_table_type])

    respond_to do |format|
      if @cg_table_type.save
        format.html { redirect_to @cg_table_type, notice: 'Cg table type was successfully created.' }
        format.json { render json: @cg_table_type, status: :created, location: @cg_table_type }
      else
        format.html { render action: "new" }
        format.json { render json: @cg_table_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /cg_table_types/1
  # PUT /cg_table_types/1.json
  def update
    @cg_table_type = CgTableType.find(params[:id])

    respond_to do |format|
      if @cg_table_type.update(cg_table_type_params)#params[:cg_table_type], :without_protection => true)
        format.html { redirect_to @cg_table_type, notice: 'Cg table type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @cg_table_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cg_table_types/1
  # DELETE /cg_table_types/1.json
  def destroy
    @cg_table_type = CgTableType.find(params[:id])
    @cg_table_type.destroy

    respond_to do |format|
      format.html { redirect_to cg_table_types_url }
      format.json { head :no_content }
    end
  end 
  private
    def set_cg_table_type
       @cg_table_type = CgTableType.find(params[:id])
    end
   def cg_table_type_params
          params.require(:cg_table_type).permit(:hide_date_flag,:status_flag,:protocol_id,:table_type,:description,:id,:default_open_flag,:display_order,:display_name,:editable_dashboard_table_type_flag)
   end
end
