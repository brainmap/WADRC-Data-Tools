class TreditActionsController < ApplicationController   
  before_action :set_tredit_action, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /tredit_actions
  # GET /tredit_actions.json
  def index
    @tredit_actions = TreditAction.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tredit_actions }
    end
  end

  # GET /tredit_actions/1
  # GET /tredit_actions/1.json
  def show
    @tredit_action = TreditAction.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tredit_action }
    end
  end

  # GET /tredit_actions/new
  # GET /tredit_actions/new.json
  def new
    @tredit_action = TreditAction.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tredit_action }
    end
  end

  # GET /tredit_actions/1/edit
  def edit
    @tredit_action = TreditAction.find(params[:id])
  end

  # POST /tredit_actions
  # POST /tredit_actions.json
  def create
    @tredit_action = TreditAction.new(tredit_action_params)#)#params[:tredit_action])

    respond_to do |format|
      if @tredit_action.save
        format.html { redirect_to @tredit_action, notice: 'Tredit action was successfully created.' }
        format.json { render json: @tredit_action, status: :created, location: @tredit_action }
      else
        format.html { render action: "new" }
        format.json { render json: @tredit_action.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tredit_actions/1
  # PUT /tredit_actions/1.json
  def update
    @tredit_action = TreditAction.find(params[:id])

    respond_to do |format|
      if @tredit_action.update(tredit_action_params)#)#params[:tredit_action], :without_protection => true)
        format.html { redirect_to @tredit_action, notice: 'Tredit action was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tredit_action.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tredit_actions/1
  # DELETE /tredit_actions/1.json
  def destroy
    @tredit_action = TreditAction.find(params[:id])
    @tredit_action.destroy

    respond_to do |format|
      format.html { redirect_to tredit_actions_url }
      format.json { head :no_content }
    end
  end 
  private
    def set_tredit_action
       @tredit_action = TreditAction.find(params[:id])
    end
   def tredit_action_params
          params.require(:tredit_action).permit(:updated_at,:id,:tredit_id,:tractiontype_id,:value,:status_flag,:created_at)
   end
end
