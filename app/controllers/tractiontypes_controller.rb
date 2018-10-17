class TractiontypesController < ApplicationController  
  before_action :set_tractiontype, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /tractiontypes
  # GET /tractiontypes.json
  def index
    @tractiontypes = Tractiontype.all.order("trtype_id, form_display_order" )

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
    @tractiontype = Tractiontype.new(tractiontype_params)#params[:tractiontype])

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
      if @tractiontype.update(tractiontype_params)#params[:tractiontype], :without_protection => true)
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
  private
    def set_tractiontype
       @tractiontype = Tractiontype.find(params[:id])
    end
   def tractiontype_params
          params.require(:tractiontype).permit(:form_default_value,:form_required_y_n_1,:form_js,:values_1,:ref_table_a_1,:ref_table_b_1,:triggers_1,:created_at,:updated_at,:display_search_flag,:prompt,:form_col_span,:form_display_field_type,:form_display_label,:id,:trtype_id,:description,:status_flag,:display_order,:display_in_summary,:display_column_header_1,:display_summary_column_header_1,:summary_peek_flag,:export_column_header_1,:form_display_order)
   end
end
