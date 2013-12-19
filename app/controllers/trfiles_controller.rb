class TrfilesController < ApplicationController

  def trfile_home
  # make trfile if no trfile_id, also make tredit, and tredit_actions
  v_comment = ""
   @trfile = nil
   if !params[:trfile_action].nil? and params[:trfile_action] =="create"
     v_subjectid_v = params[:subjectid]

     v_trfile = Trfile.where("subjectid in (?)",v_subjectid_v)

     if !(v_trfile[0]).nil? 
        v_comment = v_comment + " There was already a file for "+v_subjectid_v
     else
       v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload
       v_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid_v)

        if v_sp_id.nil?
            v_comment = v_comment+" The subjectid "+v_subjectid_v+" was not mapped to a scan procedure. "
        end
        v_enrollment_id = v_shared.get_enrollment_id_from_subjectid_v(v_subjectid_v)
        if v_enrollment_id.nil?
            v_comment = v_comment+" The subjectid "+v_subjectid_v+" was not mapped to an enrollment. " 
        end
        if !v_sp_id.nil? and !v_enrollment_id.nil?
           @trfile = Trfile.new
           @trfile.subjectid = v_subjectid_v
           @trfile.enrollment_id = v_enrollment_id
           @trfile.scan_procedure_id = v_sp_id
           @trfile.trtype_id = params[:id]
           @trfile.save
          end 
      end
     # output v_comment
   end # end of create

   if !params[:trfile_action].nil? and ( params[:trfile_action] =="create" or ( params[:trfile_action] == "add_edit" and !params[:frfile_id].nil? ) )
         if params[:trfile_action] =="add_edit" 
             @trfile = Trfile.find(params[:trfile_id])
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
                   v_tredit_action.save
               end
            end
         end
   end
   

  #  get most recent edit, edit_actions 
  if !params[:trfile_action].nil? and    params[:trfile_action] == "get_edit" and !params[:frfile_id].nil?  and !params[:fredit_id].nil?  
        @tredit = Tredit.find(params[:fredit_id])
  elsif !params[:trfile_action].nil? and    params[:trfile_action] == "get_edit" and !params[:frfile_id].nil?  and params[:fredit_id].nil?  
         @tredits = Tredit.where("trfile_id in (?)",params[:frfile_id]).order("created_at")
         @tredits.each do |te|
            @tredit = te # want the last one - newest created_at
         end

  end

  # get specified edit , edit_action in the form

    respond_to do |format|
      format.html # index.html.erb
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
    @trfile = Trfile.new(params[:trfile])

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
      if @trfile.update_attributes(params[:trfile])
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
end
