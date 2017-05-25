class TrfilesController < ApplicationController
 	before_action :set_trfile, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  def trfile_edit_action
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    v_shared = Shared.new
    # get params -- tredit_id ==> trfile_id, trype_id 
    if !params[:tredit_id].nil?
         v_datetime = DateTime.now
        @tredit = Tredit.find(params[:tredit_id])
        if !params[:tredit].nil? and !params[:tredit][:status_flag].nil?
            @tredit.status_flag = params[:tredit][:status_flag]
        end
        if !params[:tredit].nil? and !params[:tredit][:user_id].nil?
            @tredit.user_id = params[:tredit][:user_id]
        end
        @tredit.updated_at = v_datetime.strftime('%Y-%m-%d %H:%M:%S')
        @tredit.save
        @trfiles = Trfile.where("trfiles.scan_procedure_id in (?)",scan_procedure_array).where("trfiles.id in (?)",@tredit.trfile_id)
       @trfile = @trfiles[0]
        @trfile.image_dataset_id  = params[:trfile_edit_action][:image_dataset_id]
        @trfile.file_completed_flag  = params[:trfile_edit_action][:file_completed_flag]
        @trfile.qc_value  = params[:trfile_edit_action][:qc_value]
        @trfile.qc_notes  = params[:trfile_edit_action][:qc_notes]
        @trfile.status_flag  = params[:trfile_edit_action][:status_flag]
        @trfile.updated_at = v_datetime.strftime('%Y-%m-%d %H:%M:%S')
        @trfile.save
        @tredit.user_id = params[:tredit][:user_id]
        @trtype = Trtype.find(@trfile.trtype_id)
        if !params[:value].nil?
             @tractiontypes = Tractiontype.where("trtype_id in (?)",@trfile.trtype_id).where("tractiontypes.form_display_order is not null")
             @tractiontypes.each do |ta|
               @tredit_actions = TreditAction.where("tredit_id in (?)",@tredit.id).where("tractiontype_id in (?)",ta.id)
               @tredit_action = @tredit_actions[0]
               v_value = nil
               v_previous_value = nil
               if !@tredit_action.nil?
                    v_previous_value = @tredit_action.value
               end
               if !params["value"][(ta.id).to_s].nil?
                v_value = params["value"][(ta.id).to_s].join(',')

               else
                  puts "bbbbbb nil = "+(ta.id).to_s
               end
               @tredit_action.value = v_value
               v_datetime = DateTime.now
               @tredit.updated_at = v_datetime.strftime('%Y-%m-%d %H:%M:%S')
               @tredit_action.save

              if !(ta.triggers_1).blank?
                  # triggers are a work in progress
                  v_trigger_array = (ta.triggers_1).split("|")

                  if v_trigger_array[0] == "update_field" # _send_email
                      v_trtype_array = v_trigger_array[1].split("=")
                      v_trtype_id_array = (v_trtype_array[1].gsub(/\[/,"").gsub(/\]/,"")).split(",")
                      v_target = v_trigger_array[2]
                      v_target_field = v_trigger_array[3]
                      # set the v_target . v_target_field for this subject_id in v_trtype_id_array
                      if v_target == "trfile"
                        if !@trfile.secondary_key.blank?
                           @target_trfiles = Trfile.where("subjectid in (?) and ( secondary_key in (?) )", @trfile.subjectid,@trfile.secondary_key).where("trfiles.trtype_id in (?)",v_trtype_id_array)
                         else
                           @target_trfiles = Trfile.where("subjectid in (?) and ( secondary_key in  (?) or secondary_key is NULL)", @trfile.subjectid,@trfile.secondary_key).where("trfiles.trtype_id in (?)",v_trtype_id_array)
                         end  
                        @target_trfiles.each do |tar|
                          puts "CCCCCCC tar.id ="+tar.id.to_s+"   v_target_field="+v_target_field
                               if v_target_field == "qc_value"
                                   # need to translate tp Pass, Partial,
                                   v_description = v_shared.get_lookup_refs_description(ta.ref_table_b_1, v_value)

                                  tar.qc_value = v_description
                                  tar.save
                                elsif v_target_field == "qc_notes"
                                  # need to make a composite of all the qc fields into notes
                                  tar.qc_notes = v_value
                                  tar.save
                               end
                        end
                      end
                      if v_trigger_array[4] == "email_params"
                          v_user_array = v_trigger_array[5].split("=")
                          v_email = ""
                          v_user = User.find(74 ) # panda_user
                          v_email_array = [v_user.email]
                          if v_user_array[0] == "user_id_to"
                              v_user = User.find(v_user_array[1])
                              v_user_email = v_user.email
                              v_email_array.push(v_user_email)
                          end
                          v_subject = "msg from tracker"
                          v_subject_array = v_trigger_array[6].split("=")
                          if v_subject_array[0] == "subject"
                              v_subject = v_subject_array[1]
                          end
                          v_body = "tracker email"
                          v_body_array = v_trigger_array[7].split("=")
                          if v_body_array[0] == "body"
                                 v_secondary_key = ""
                                 if !@trfile.secondary_key.nil?
                                      v_secondary_key = @trfile.secondary_key
                                 end
                                 v_edit_user = User.find(@tredit.user_id)
                                 v_body = v_body_array[1].gsub(/\[user\]/,v_edit_user.username).gsub(/\[subjectid\]/,@trfile.subjectid+" "+v_secondary_key )
                          end
                          v_trigger_value = "-1"
                          v_trigger_value_array = v_trigger_array[8].split("=")
                          if v_trigger_value_array[0] == "trigger_value"
                             v_trigger_value = v_trigger_value_array[1]
                          end
                          if v_trigger_value == v_value and v_previous_value != v_value # send the email only if changed 
                            v_subject= v_subject+"!!!!! --------"
                            v_email_array.each do |address|
                              PandaMailer.send_email(v_subject,{:send_to => address},v_body).deliver
                            end
                          end
                      end
                  end
              end
             end
             #update_field|tractiontypes_id=[23,22,24,25,26,27,28,29,30]|trtype_id=[4,1]|trfile|qc_notes
             if !(@trtype.triggers_1).blank?
                 v_trigger_array = (@trtype.triggers_1).split("|")
                 if v_trigger_array[0] == "update_field_send_email"
                    v_tractiontype_array = v_trigger_array[1].split("=")
                    # get label - value from this tredit and these tractiontype
                    v_tractiontype_id_array = (v_tractiontype_array[1].gsub(/\[/,"").gsub(/\]/,"")).split(",")
                    v_composite_value = ""
                    v_tractiontype_id_array.each do |act_id|
                        v_tractiontype = Tractiontype.find(act_id)
                        v_tredit_action = TreditAction.where("tractiontype_id in (?) and tredit_id in (?)",act_id, @tredit.id)
                        v_tmp_value = v_tredit_action[0].value
                        if v_tractiontype.ref_table_a_1 == "lookup_refs"
                               v_tmp_value =  v_shared.get_lookup_refs_description(v_tractiontype.ref_table_b_1, v_tmp_value)
                        end
v_composite_value = v_composite_value + "
     "+v_tractiontype.display_summary_column_header_1+": "+v_tmp_value
                    end

                    v_trtype_array = v_trigger_array[2].split("=")
                    # update  matching this trfile.subjectid and these trtype_id
                    v_trtype_id_array = (v_trtype_array[1].gsub(/\[/,"").gsub(/\]/,"")).split(",")

                    v_target = v_trigger_array[3]
                    v_target_field = v_trigger_array[4]
                    if v_target == "trfile"
                        if !@trfile.secondary_key.blank?
                           @target_trfiles = Trfile.where("subjectid in (?) and ( secondary_key in (?) )", @trfile.subjectid,@trfile.secondary_key).where("trfiles.trtype_id in (?)",v_trtype_id_array)
                        else
                           @target_trfiles = Trfile.where("subjectid in (?) and ( secondary_key in (?) or secondary_key is NULL)", @trfile.subjectid,@trfile.secondary_key).where("trfiles.trtype_id in (?)",v_trtype_id_array)

                        end

                        @target_trfiles.each do |tar|
                          puts "CCCCCCC tar.id ="+tar.id.to_s+"   v_target_field="+v_target_field
                               if  v_target_field == "qc_notes"
                                  # need to make a composite of all the qc fields into notes
                                  tar.qc_notes = v_composite_value
                                  tar.save
                               end
                        end
                     end
                 end
            end
        end
    end
    # update trfile
    # update tredit
    # loop thru traction_edit
    # redirect back to trtype_home
    # if fs qc = trtype_id = 4 , make composite from all fs qc fields 

    respond_to do |format|
          format.html { redirect_to( '/trtype_home/'+(@trfile.trtype_id).to_s, :notice => ' ' )}
    end

  end

  def trfile_home
    scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
    scan_procedure_edit_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
  # make trfile if no trfile_id, also make tredit, and tredit_actions
  v_comment = ""
   @trfile = nil
   
      v_display_form = "Y"
   if !params[:trfile_action].nil? and params[:trfile_action] =="create" 
     v_subjectid_v = params[:subjectid]
     v_secondary_key = ""
     if !params[:secondary_key].blank?
       v_secondary_key = params[:secondary_key]
        v_trfile = Trfile.where("subjectid in (?)",v_subjectid_v).where("secondary_key in (?)",v_secondary_key).where("trtype_id in (?)",params[:id]).where("trfiles.scan_procedure_id in (?)",scan_procedure_edit_array)    
     else
        v_trfile = Trfile.where("subjectid in (?)",v_subjectid_v).where("trtype_id in (?)",params[:id]).where("trfiles.scan_procedure_id in (?)",scan_procedure_edit_array)
     end
     if !(v_trfile[0]).nil? 
        v_comment = v_comment + " There was already a file for "+v_subjectid_v+" "+v_secondary_key+". This is the most recent edit."
        if !v_subjectid_v.include? "_v"
            v_comment = v_comment + " Did you mean to include _v2 or _v3 or _v# in the subjectid?"
        end
        @trfile = v_trfile[0]
        params[:trfile_action] = "get_edit"
        params[:trfile_id] = (@trfile.id).to_s
     else
       v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload
       v_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid_v)
        if v_sp_id.nil?
            v_comment = v_comment+" The subjectid "+v_subjectid_v+" was not mapped to a scan procedure. "
            v_display_form = "N" 
        end
        v_enrollment_id = v_shared.get_enrollment_id_from_subjectid_v(v_subjectid_v)
        if v_enrollment_id.nil?
            v_comment = v_comment+" The subjectid "+v_subjectid_v+" was not mapped to an enrollment. " 
            v_display_form = "N" 
        end  
        # problem with sp but enumber not in all the visits 
        if !v_sp_id.nil? and !v_enrollment_id.nil?
             v_check_vgroup_id = Vgroup.where("vgroups.id in (select spvg.vgroup_id from scan_procedures_vgroups spvg where spvg.scan_procedure_id in (?)) and vgroups.id in (select evgm.vgroup_id from enrollment_vgroup_memberships evgm where evgm.enrollment_id in (?))",v_sp_id,v_enrollment_id).to_a 
             if v_check_vgroup_id.nil? or v_check_vgroup_id[0].nil? 
                  v_display_form = "N" 
                  v_comment = v_comment+" The subjectid "+v_subjectid_v+" does not have a visit in the scan procedure. " 
             end
        end
        if !v_sp_id.nil? and !v_enrollment_id.nil? and !v_check_vgroup_id[0].nil? 
          puts "AAAAA making a trfile?"
           @trfile = Trfile.new
           @trfile.subjectid = v_subjectid_v
           @trfile.secondary_key = v_secondary_key
           @trfile.enrollment_id = v_enrollment_id
           @trfile.scan_procedure_id = v_sp_id
           @trfile.trtype_id = params[:id]
           v_trtype = Trtype.find(params[:id])
           if !(v_trtype.triggers_1).blank?
              # create_field|tractiontypes_id=[23,24,25,26,27,28,29,30]|trtype_id=[4]|trfile|qc_notes
                v_trigger_array = (v_trtype.triggers_1).split("|")
                 if v_trigger_array[0] == "create_field"
                    v_tractiontype_array = v_trigger_array[1].split("=")
                    v_trtype_array = v_trigger_array[2].split("=")
                    # update  matching this trfile.subjectid and these trtype_id
                    v_trtype_id_array = (v_trtype_array[1].gsub(/\[/,"").gsub(/\]/,"")).split(",")
                    # get label - value from this tredit and these tractiontype
                    v_tractiontype_id_array = (v_tractiontype_array[1].gsub(/\[/,"").gsub(/\]/,"")).split(",")
                    v_composite_value = ""
                    # need source trfile, expect 1 trfile
                    if !@trfile.secondary_key.blank?
                       v_source_trfiles = Trfile.where("subjectid in (?) and ( secondary_key in (?) )", @trfile.subjectid,@trfile.secondary_key).where("trfiles.trtype_id in (?)",v_trtype_id_array)
                    else
                       v_source_trfiles = Trfile.where("subjectid in (?) and ( secondary_key in (?) or secondary_key is NULL)", @trfile.subjectid,@trfile.secondary_key).where("trfiles.trtype_id in (?)",v_trtype_id_array)
                    end

                     # get last edit
                     if !v_source_trfiles.nil? and !v_source_trfiles[0].nil?
                        v_src_tredits = Tredit.where("trfile_id in (?) and status_flag ='Y' ",v_source_trfiles[0].id).order("created_at")
                        v_src_tredit = nil
                        v_src_tredits.each do |te|
                            v_src_tredit = te # want the last one - newest created_at
                        end    
                      v_tractiontype_id_array.each do |act_id|
                        v_tractiontype = Tractiontype.find(act_id)

                        v_tredit_action = TreditAction.where("tractiontype_id in (?) and tredit_id in (?)",act_id, v_src_tredit.id)
                        v_tmp_value = v_tredit_action[0].value
                        if v_tractiontype.ref_table_a_1 == "lookup_refs"
                               v_tmp_value =  v_shared.get_lookup_refs_description(v_tractiontype.ref_table_b_1, v_tmp_value)
                        end
v_composite_value = v_composite_value + "
     "+v_tractiontype.display_summary_column_header_1+": "+v_tmp_value
                      end
                      v_target = v_trigger_array[3]
                      v_target_field = v_trigger_array[4]
                      if v_target == "trfile"
                        if v_target_field == "qc_notes"
                           @trfile.qc_notes = v_composite_value
                           # want to grab gc_value also
                           #v_description = v_shared.get_lookup_refs_description(ta.ref_table_b_1, v_value)
                           @trfile.qc_value = v_source_trfiles[0].qc_value
                        end
                      end 
                    end
                 end

           end 
           @trfile.save 
        else
          v_display_form = "N"
        end 
      end
     # output v_comment
   end # end of create

   if !params[:trfile_action].nil? and ( params[:trfile_action] =="create"  or ( params[:trfile_action] == "add_edit" and !params[:trfile_id].nil? ) )

         if params[:trfile_action] =="add_edit" 
             @trfiles = Trfile.where("trfiles.id in (?)",params[:trfile_id]).where("trfiles.scan_procedure_id in (?)",scan_procedure_edit_array)
             @trfile = @trfiles[0]
         end
         if !@trfile.nil?
            @tredit = Tredit.new
            @tredit.trfile_id = @trfile.id
            @tredit.user_id = current_user.id
            @tredit.save
            # make all the edit_actions for the tredit
            v_tractiontypes = Tractiontype.where("trtype_id in (?)",params[:id])
            if !v_tractiontypes.nil?
               v_tractiontypes.each do |tat|
                   v_tredit_action = TreditAction.new
                   v_tredit_action.tredit_id = @tredit.id
                   v_tredit_action.tractiontype_id = tat.id
                   if !(tat.form_default_value).blank?
                         v_tredit_action.value = tat.form_default_value
                   end
                   v_tredit_action.save
               end
            end
         end
   end
   

  #  get most recent edit, edit_actions 
  if !params[:trfile_action].nil? and    params[:trfile_action] == "get_edit" and !params[:trfile_id].nil?  and !params[:tredit_id].nil?  

        @tredit = Tredit.find(params[:tredit_id])
        @trfile = Trfile.find(@tredit.trfile_id)
        if (@tredit.user_id).nil?
            @tredit.user_id = current_user.id
        end
  elsif !params[:trfile_action].nil? and    params[:trfile_action] == "get_edit" and !params[:trfile_id].nil?  and params[:tredit_id].nil?  

         @tredits = Tredit.where("trfile_id in (?) and status_flag ='Y' ",params[:trfile_id]).order("created_at")
         @tredits.each do |te|
            @tredit = te # want the last one - newest created_at
         end
         @trfile = Trfile.find(@tredit.trfile_id)
        if (@tredit.user_id).nil?
            @tredit.user_id = current_user.id
        end

  end
  if v_display_form  == "N"
   # not get anything
  else
    @tredit_prev = nil
    @tredit_next = nil
    tredits = Tredit.where("tredits.trfile_id in (?) and tredits.status_flag ='Y'", @tredit.trfile_id).order(:id)
    @v_edit_cnt =1
    @v_last_edit = "N"
    v_cnt =0
    tredits.each do |tr|
      v_cnt = v_cnt + 1
      if tr.id < @tredit.id
         @tredit_prev = tr
      end
      if tr.id == @tredit.id
          @v_edit_cnt = v_cnt
      end
      if tr.id > @tredit.id and @tredit_next.nil?
         @tredit_next = tr
      end
    end
    if v_cnt == @v_edit_cnt 
         @v_last_edit = "Y"
    end
  

    # get all the scan procedures linked to vgroup

    @trfiles = Trfile.where("trfiles.scan_procedure_id in (?)",scan_procedure_array).where("trfiles.id in (?)",@trfile.id)
    @trfile = @trfiles[0]
    @trtype = Trtype.find(@trfile.trtype_id)
    @v_action_name = @trtype.action_name
    @vgroups = Vgroup.where("vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships where enrollment_id in (?) )",@trfile.enrollment_id).where("vgroups.id in (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))",@trfile.scan_procedure_id)
       if !(@trfile.scan_procedure_id).nil? and !(@trfile.enrollment_id).nil? 
          @ids = ImageDataset.where(" image_datasets.visit_id in (select v1.id from visits v1, appointments a1, scan_procedures_vgroups spvg1, enrollment_vgroup_memberships evg1
                                                      where v1.appointment_id = a1.id and a1.vgroup_id =spvg1.vgroup_id and a1.vgroup_id = evg1.vgroup_id 
                                                      and spvg1.scan_procedure_id in (?) 
                                                      and evg1.enrollment_id in (?)) 
                                      and image_datasets.series_description in 
                                       ( select sdm1.series_description from series_description_maps sdm1 where series_description_type_id in (?))",
                    @trfile.scan_procedure_id ,@trfile.enrollment_id, @trtype.series_description_type_id)

      end
    end
  # get specified edit , edit_action in the form
    if !v_comment.blank?
     flash[:error] = v_comment
    end
    respond_to do |format|
      if v_display_form  == "N"
         format.html { redirect_to( '/trtype_home/'+params[:id], :notice => ' ' )}
      else
        format.html # index.html.erb
      end
      #format.json { render json: @trfiles }
    end
  end

  # GET /trfiles
  # GET /trfiles.json
  def index
    @trfiles = Trfile.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trfiles }
    end
  end

  # GET /trfiles/1
  # GET /trfiles/1.json
  def show
    @trfile = Trfile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trfile }
    end
  end

  # GET /trfiles/new
  # GET /trfiles/new.json
  def new
    @trfile = Trfile.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trfile }
    end
  end

  # GET /trfiles/1/edit
  def edit
    @trfile = Trfile.find(params[:id])
    if !(@trfile.trtype_id).nil?
      @trtype = Trtype.find(@trfile.trtype_id)
      if !(@trfile.scan_procedure_id).nil? and !(@trfile.enrollment_id).nil? 
          @ids = ImageDataset.where(" image_datasets.visit_id in (select v1.id from visits v1, appointments a1, scan_procedures_vgroups spvg1, enrollment_vgroup_memberships evg1
                                                      where v1.appointment_id = a1.id and a1.vgroup_id =spvg1.vgroup_id and a1.vgroup_id = evg1.vgroup_id 
                                                      and spvg1.scan_procedure_id in (?) 
                                                      and evg1.enrollment_id in (?)) 
                                      and image_datasets.series_description in 
                                       ( select sdm1.series_description from series_description_maps sdm1 where series_description_type_id in (?))",
                    @trfile.scan_procedure_id ,@trfile.enrollment_id, @trtype.series_description_type_id)

      end
    end
  end

  # POST /trfiles
  # POST /trfiles.json
  def create
    @trfile = Trfile.new(trfile_params)# params[:trfile])

    respond_to do |format|
      if @trfile.save
    if !(@trfile.subjectid).nil?
        v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload
        v_sp_id = v_shared.get_sp_id_from_subjectid_v(@trfile.subjectid)
        if !v_sp_id.nil?
            @trfile.scan_procedure_id = v_sp_id
        end
        v_enrollment_id = v_shared.get_enrollment_id_from_subjectid_v(@trfile.subjectid)
        @trfile.enrollment_id = v_enrollment_id

        @trfile.save
     end

        format.html { redirect_to @trfile, notice: 'Trfile was successfully created.' }
        format.json { render json: @trfile, status: :created, location: @trfile }
      else
        format.html { render action: "new" }
        format.json { render json: @trfile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trfiles/1
  # PUT /trfiles/1.json
  def update
    @trfile = Trfile.find(params[:id])
    if !params[:trfile][:subjectid].nil?
        v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload
        v_sp_id = v_shared.get_sp_id_from_subjectid_v(params[:trfile][:subjectid])
        if !v_sp_id.nil?
            params[:trfile][:scan_procedure_id] = v_sp_id
        end
        v_enrollment_id = v_shared.get_enrollment_id_from_subjectid_v(params[:trfile][:subjectid])
        if !v_enrollment_id.nil?
            params[:trfile][:enrollment_id] = v_enrollment_id
        end
     end

    respond_to do |format|
      if @trfile.update(trfile_params)# params[:trfile], :without_protection => true)
        format.html { redirect_to @trfile, notice: 'Trfile was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trfile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trfiles/1
  # DELETE /trfiles/1.json
  def destroy
    @trfile = Trfile.find(params[:id])
    @trfile.destroy

    respond_to do |format|
      format.html { redirect_to trfiles_url }
      format.json { head :no_content }
    end
  end   
  private
    def set_trfile
       @trfile = Trfile.find(params[:id])
    end
   def trfile_params
          params.require(:trfile).permit(:updated_at,:status_flag,:qc_value,:file_completed_flag,:qc_notes,:secondary_key,:created_at,:scan_procedure_id,:id,:trtype_id,:image_dataset_id,:subjectid,:enrollment_id)
   end
end
