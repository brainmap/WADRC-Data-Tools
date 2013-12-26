class TreditsController < ApplicationController


  def tredit_home
   @trfiles = Trfile.where("trtype_id ="+params[:trtype_id])
    # get search conditions

    @tredits_search = Tredit.all # apply limits



    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @trfiles }
    end

  end
  
  # GET /tredits
  # GET /tredits.json
  def index
    @tredits = Tredit.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tredits }
    end
  end

  # GET /tredits/1
  # GET /tredits/1.json
  def show
    @tredit = Tredit.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tredit }
    end
  end

  # GET /tredits/new
  # GET /tredits/new.json
  def new
    @tredit = Tredit.new
        sql = "select concat( trtypes.description,' -- ',trfiles.subjectid ), trfiles.id from trfiles , trtypes
              where trfiles.trtype_id = trtypes.id order by concat( trtypes.description,' -- ',trfiles.subjectid) "
              connection = ActiveRecord::Base.connection();
    @tr_type_subject =  connection.execute(sql)
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tredit }
    end
  end

  # GET /tredits/1/edit
  def edit
    @tredit = Tredit.find(params[:id])
            sql = "select concat( trtypes.description,' -- ',trfiles.subjectid ), trfiles.id   from trfiles , trtypes
              where trfiles.trtype_id = trtypes.id and trfiles.id = "+(@tredit.trfile_id).to_s+" order by concat( trtypes.description,' -- ',trfiles.subjectid )"
              connection = ActiveRecord::Base.connection();
    @tr_type_subject =  connection.execute(sql)
  end

  # POST /tredits
  # POST /tredits.json
  def create
    @tredit = Tredit.new(params[:tredit])

    respond_to do |format|
      if @tredit.save
        format.html { redirect_to @tredit, notice: 'Tredit was successfully created.' }
        format.json { render json: @tredit, status: :created, location: @tredit }
      else
        format.html { render action: "new" }
        format.json { render json: @tredit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tredits/1
  # PUT /tredits/1.json
  def update
    @tredit = Tredit.find(params[:id])

    respond_to do |format|
      if @tredit.update_attributes(params[:tredit])
        format.html { redirect_to @tredit, notice: 'Tredit was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tredit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tredits/1
  # DELETE /tredits/1.json
  def destroy
    @tredit = Tredit.find(params[:id])
    @tredit.destroy

    respond_to do |format|
      format.html { redirect_to tredits_url }
      format.json { head :no_content }
    end
  end
end
