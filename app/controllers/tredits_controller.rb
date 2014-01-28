class TreditsController < ApplicationController


  def tredit_home
    scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
   @v_action_name = Trtype.find(params[:trtype_id]).action_name 
   @tractiontypes = Tractiontype.where("trtype_id in (?)",params[:trtype_id]).where("tractiontypes.display_order is not null").order(:display_order) 
   @tractiontypes_search = Tractiontype.where("trtype_id in (?)",params[:trtype_id]).where("tractiontypes.display_search_flag = 'Y' ").order(:display_order)
    # base columns
    @export_file_title =Trtype.find(params[:trtype_id]).description+" file edits"
    @column_headers_display = ['Edit','File Completed','Last Update','Subjectid','Scan Procedure','User','Active']
    @column_headers = ['Edit_id','File Completed','Last Update','Subjectid','Scan Procedure','User','Active']

    @tractiontypes.each do |act|
      @column_headers_display.push(act.display_column_header_1)
      @column_headers.push(act.export_column_header_1)
    end
    @column_number = @column_headers.size
    
   @trfiles = Trfile.where("trtype_id ="+params[:trtype_id]).where("trfiles.scan_procedure_id in (?)",scan_procedure_array)
   @conditions = ["scan_procedures.id = trfiles.scan_procedure_id ","trfiles.scan_procedure_id in ("+scan_procedure_array.join(',')+")"]
  if !params[:tr_search].nil?
       @trfiles_search = Trfile.where("trtype_id ="+params[:trtype_id]).where("trfiles.scan_procedure_id in (?)",scan_procedure_array).where("trfiles.scan_procedure_id in (?)",scan_procedure_array).order("updated_at desc")

       if !@tractiontypes_search.nil? and !params[:tr_search][:tractiontype_id].nil?
          @tractiontypes_search.each do |act|
             if !params[:tr_search][:tractiontype_id][(act.id).to_s].nil? and params[:tr_search][:tractiontype_id][(act.id).to_s] > ""
                @trfiles_search = @trfiles_search.where("trfiles.id in (select tredits.trfile_id from tredits, tredit_actions where
                                                                      tredits.id = tredit_actions.tredit_id and tredit_actions.tractiontype_id in (?)
                                                                       and tredit_actions.value in (?) )",act.id, params[:tr_search][:tractiontype_id][(act.id).to_s])
                @conditions.push(" trfiles.id in (select tredits.trfile_id from tredits, tredit_actions where
                                                                      tredits.id = tredit_actions.tredit_id and tredit_actions.tractiontype_id in ("+(act.id).to_s+")
                                                                       and tredit_actions.value in ("+params[:tr_search][:tractiontype_id][(act.id).to_s]+"))")
                   
             end
          end
        end

        if !params[:tr_search][:trfile_id].nil? and params[:tr_search][:trfile_id] > ''
          @trfiles_search = @trfiles_search.where("id in (?)",params[:tr_search][:trfile_id])
          @conditions.push(" trfiles.id in ("+params[:tr_search][:trfile_id]+") ")
        end
        if !params[:tr_search][:scan_procedure_id].nil? and params[:tr_search][:scan_procedure_id] > ''
          @trfiles_search = @trfiles_search.where("scan_procedure_id in
                        (select scan_procedure_id from scan_procedures_vgroups where 
                                              vgroup_id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?)))",
                                             params[:tr_search][:scan_procedure_id])
          # this retrieves a few extra -- e.g. mets and pdt 
          

          @conditions.push("trfiles.scan_procedure_id in
                    (select scan_procedure_id from scan_procedures_vgroups where 
                                              vgroup_id in 
                                              (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in 
                                                ("+params[:tr_search][:scan_procedure_id]+")))")
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
      # @trfiles_search = Trfile.where("trtype_id ="+params[:trtype_id]).where("updated_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) ").where("trfiles.scan_procedure_id in (?)",scan_procedure_array).order("updated_at desc")
      @trfiles_search = Trfile.where("trtype_id ="+params[:trtype_id]).where("trfiles.scan_procedure_id in (?)",scan_procedure_array).order("updated_at desc")
      @conditions.push(" trfiles.trtype_id ="+params[:trtype_id]+" ")
      #@conditions.push(" trfiles.updated_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) ")  # change to pageination
          
    end
        @html_request ="Y"
         request_format = request.formats.to_s
         case  request_format
          when "[text/html]","text/html" then
            @html_request ="Y"
          else
              @html_request ="N"
          end
              # get the tredit_action values
              @db_columns   =["trfiles.id","trfiles.file_completed_flag","trfiles.updated_at","trfiles.subjectid","scan_procedures.codename"]
              sql = "select "+@db_columns.join(",")+" from scan_procedures, trfiles where "+@conditions.join(' and ') 
              connection = ActiveRecord::Base.connection();
              @trfiles_search  =  connection.execute(sql)
              @tredits_search = []
              @trfiles_search.each do |trfile|
                      @tredits = Tredit.where("trfile_id in (?)",trfile[0]).order(:updated_at).reverse_order
                      if !@tractiontypes_search.nil? and !params[:tr_search].nil? and !params[:tr_search][:tractiontype_id].nil?
                        @tractiontypes_search.each do |act|
                            if !params[:tr_search][:tractiontype_id][(act.id).to_s].nil? and params[:tr_search][:tractiontype_id][(act.id).to_s] > ""
                               @tredits = @tredits.where("tredits.id in (select tredit_actions.tredit_id from  tredit_actions where
                                                                       tredit_actions.tractiontype_id in (?)
                                                                       and tredit_actions.value in (?) )",act.id, params[:tr_search][:tractiontype_id][(act.id).to_s])
                   
                            end
                        end
                      end

                      @tredits.each do |tredit|
                        @tredit_row  = []
                        @tredit_row.push(tredit.id)
                        @tredit_row.push(trfile[1]) # file_completed_flag
                        @tredit_row.push((tredit.updated_at).strftime('%Y-%m-%d %H:%M')  ) #update_at
                        @tredit_row.push(trfile[3]) #subjectid
                        @tredit_row.push(trfile[4]) #codenme
                        @tredit_row.push((User.find(tredit.user_id)).username_name)
                        @tredit_row.push(tredit.status_flag)
                        @tractiontypes.each do |act|
                          @tredit_actions = TreditAction.where("tredit_id in (?)",tredit.id).where("tractiontype_id in (?)",act.id)
                          # translate stored value to display value -- q_data does this by one big join
                          if  !act.ref_table_a_1.nil? and act.ref_table_a_1 == "lookup_refs" and !(act.ref_table_b_1).nil? and !@tredit_actions[0].nil? and !(@tredit_actions[0].value).nil?
                             sql_val = "select lookup_refs.description from lookup_refs where label='"+ act.ref_table_b_1+"' and ref_value in ("+@tredit_actions[0].value+")"
                              vals =  connection.execute(sql_val)
                               val=[]
                               vals.each do |v|
                                 val.push(v[0])
                               end
                              @tredit_row.push(val.join(', '))
                          elsif  !act.ref_table_a_1.blank?  and !@tredit_actions[0].nil? and !(@tredit_actions[0].value).nil?
                               vals =((act.ref_table_a_1).constantize).where("id in (?)",@tredit_actions[0].value)
                               @tredit_row.push((vals.first).description)
                          elsif !@tredit_actions[0].nil?
                            @tredit_row.push(@tredit_actions[0].value)
                          end
                        end
                        @tredits_search.push(@tredit_row)
                      end
                       
              end


    respond_to do |format|
      @v_tredits_search_size = @tredits_search.size
      format.html {@tredits_search = Kaminari.paginate_array(@tredits_search).page(params[:page]).per(100)} # index.html.erb
      format.xls 
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
