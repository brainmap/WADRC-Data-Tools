class TrfilesController < ApplicationController
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
        v_subjectid_chop = (@trfile.subjectid).gsub('_v2','').gsub('_v3','').gsub('_v4','').gsub('_v5','')
        v_enrollment = Enrollment.where("enumber in (?)",v_subjectid_chop)
        if !v_enrollment[0].nil? 
            @trfile.enrollment_id = v_enrollment[0].id
        end
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
        v_subjectid_chop = params[:trfile][:subjectid].gsub('_v2','').gsub('_v3','').gsub('_v4','').gsub('_v5','')
        v_enrollment = Enrollment.where("enumber in (?)",v_subjectid_chop)
        if !v_enrollment[0].nil? 
            params[:trfile][:enrollment_id] = v_enrollment[0].id
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
