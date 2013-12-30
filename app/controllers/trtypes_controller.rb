class TrtypesController < ApplicationController



  def trtype_home
    @trtypes = Trtype.all
    if !params[:id].nil?
         @trfiles = Trfile.where("trtype_id ="+params[:id])
         @conditions = ["scan_procedures.id = trfiles.scan_procedure_id "]
         if !params[:tr_search].nil?
           
            @trfiles_search = Trfile.where("trtype_id ="+params[:id]).order("updated_at desc")
            if !params[:tr_search][:trfile_id].nil? and params[:tr_search][:trfile_id] > ''
               @trfiles_search = @trfiles_search.where("id in (?)",params[:tr_search][:trfile_id])
               @conditions.push(" trfiles.id in ("+params[:tr_search][:trfile_id]+") ")
            end
            if !params[:tr_search][:scan_procedure_id].nil? and params[:tr_search][:scan_procedure_id] > ''
               @trfiles_search = @trfiles_search.where("scan_procedure_id in (?)",params[:tr_search][:scan_procedure_id])
               @conditions.push(" trfiles.scan_procedure_id in("+params[:tr_search][:scan_procedure_id]+") ")
            end
            if !params[:tr_search][:user_id].nil? and params[:tr_search][:user_id] > ''
               @trfiles_search = @trfiles_search.where("id in (select trfile_id from tredits where user_id in (?))",params[:tr_search][:user_id])
               @conditions.push(" trfiles.id in (select trfile_id from tredits where user_id in ("+params[:tr_search][:user_id]+")) ")
            end
            if !params[:tr_search][:file_completed_flag].nil? and params[:tr_search][:file_completed_flag] > ''
              @trfiles_search = @trfiles_search.where("file_completed_flag in (?)",params[:tr_search][:file_completed_flag])
               @conditions.push(" trfiles.file_completed_flag in('"+params[:tr_search][:file_completed_flag]+"') ")
            end
         else
          @trfiles_search = Trfile.where("trtype_id ="+params[:id]).where("updated_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) ").order("updated_at desc")
          @conditions.push(" trfiles.trtype_id ="+params[:id]+" ")
          @conditions.push(" trfiles.updated_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)")  # change to pageination
          
         end
         @export_file_title =Trtype.find(params[:id]).description+" file edits"
         @column_headers_display = ['Completed','Last Update','Subjectid','Add edit','Last edit','Scan Procedure']
         @column_headers = ['Completed','Last Update','Subjectid','Scan Procedure']

         # add in trtype specific summary columns
         # if export -- do select 
         @html_request ="Y"
         request_format = request.formats.to_s
         case  request_format
          when "[text/html]","text/html" then
              @column_headers_display = ['Completed','Last Update','Subjectid','Add edit','Last edit','Scan Procedure']
            else
              @html_request ="N"
              @column_headers = ['Completed','Last Update','Subjectid','Scan Procedure']
              @db_columns   =["trfiles.file_completed_flag","trfiles.updated_at","trfiles.subjectid","scan_procedures.codename"]
              sql = "select "+@db_columns.join(",")+" from scan_procedures, trfiles where "+@conditions.join(' and ') 
              connection = ActiveRecord::Base.connection();
              @trfiles_search  =  connection.execute(sql)
            end

         @column_number = @column_headers.size
    end

    
    respond_to do |format|
      format.xls 
      format.html # index.html.erb
      #format.json { render json: @trtypes }
    end
  end
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
