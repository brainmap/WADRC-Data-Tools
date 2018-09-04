class ProcessedimagesController < ApplicationController
  before_action :set_processedimage, only: [:show, :edit, :update, :destroy]

  # GET /processedimages
  # GET /processedimages.json
  def index
    @processedimages = Processedimage.all
    respond_to do |format|
   format.html {@processedimages = Kaminari.paginate_array(@processedimages).page(params[:page]).per(50)} 
    end
  end

# LOTS NOT WORKING
 def processedimage_search
      if !params[:processedimage_search].blank?
      ### causing error   @processedimage_search_params = processedimage_params()
      end
      @conditions = []
       @current_tab = "admin"
       params["search_criteria"] =""
       if params[:processedimage_search].nil?
            params[:processedimage_search] =Hash.new 
       end

       if !params[:processedimage_search][:scan_procedure_id].blank?
           condition ="  processedimages.scan_procedure_id in ("+params[:processedimage_search][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+")"
           @scan_procedures = ScanProcedure.where("id in (?)",params[:processedimage_search][:scan_procedure_id])
           @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
        end

        if !params[:processedimage_search][:enumber].blank?
          params[:processedimage_search][:enumber] = params[:processedimage_search][:enumber].gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
          if params[:processedimage_search][:enumber].include?(',') # string of enumbers
           v_enumber =  params[:processedimage_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
           v_enumber = v_enumber.gsub(/,/,"','")
             condition ="    processedimages.enrollment_id in (select enrollments.id from enrollments where lower(enrollments.enumber) in  ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"'))"
          else
           condition ="    processedimages.enrollment_id in (select enrollments.id from enrollments
            where  lower(enrollments.enumber) in  (lower('"+params[:processedimage_search][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"

          end
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:processedimage_search][:enumber]
        end   

         #  build expected date format --- between, >, < 
         v_date_latest =""
         #want all three date parts

         if !params[:processedimage_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:processedimage_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:processedimage_search]["#{'latest_timestamp'}(3i)"].blank?
              v_date_latest = params[:processedimage_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:processedimage_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:processedimage_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
         end
         v_date_earliest =""
         #want all three date parts

         if !params[:processedimage_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:processedimage_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:processedimage_search]["#{'earliest_timestamp'}(3i)"].blank?
               v_date_earliest = params[:processedimage_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:processedimage_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:processedimage_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
          end
          #
         if v_date_latest.length>0 && v_date_earliest.length >0
           condition ="processedimages.scan_procedure_id  in (select scan_procedures_vgroups.scan_procedure_id from appointments,scan_procedures_vgroups  where appointments.vgroup_id =scan_procedures_vgroups.vgroup_id and appointments.appointment_date between '"+v_date_earliest+"' and '"+v_date_latest+"' ) and
                         processedimages.enrollment_id  in (select enrollment_vgroup_memberships.enrollment_id from appointments,enrollment_vgroup_memberships  where appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id and appointments.appointment_date between '"+v_date_earliest+"' and '"+v_date_latest+"' )" #,v_date_earliest,v_date_latest)


           condition ="processedimages.id  in (select pi2.id from processedimages pi2, appointments,scan_procedures_vgroups,enrollment_vgroup_memberships  
                                            where appointments.vgroup_id =scan_procedures_vgroups.vgroup_id 
                                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                                            and pi2.scan_procedure_id = scan_procedures_vgroups.scan_procedure_id 
                                            and pi2.enrollment_id = enrollment_vgroup_memberships.enrollment_id
                                            and appointments.appointment_date  between '"+v_date_earliest+"' and '"+v_date_latest+"') "       
           params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
           @conditions.push(condition)
         elsif v_date_latest.length>0
           condition ="processedimages.scan_procedure_id  in (select scan_procedures_vgroups.scan_procedure_id from appointments,scan_procedures_vgroups  where appointments.vgroup_id =scan_procedures_vgroups.vgroup_id and appointments.appointment_date < '"+v_date_latest+"' ) and
                         processedimages.enrollment_id  in (select enrollment_vgroup_memberships.enrollment_id from appointments,enrollment_vgroup_memberships  where appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id and appointments.appointment_date < '"+v_date_latest+"' )"
            condition ="processedimages.id  in (select pi2.id from processedimages pi2, appointments,scan_procedures_vgroups,enrollment_vgroup_memberships  
                                            where appointments.vgroup_id =scan_procedures_vgroups.vgroup_id 
                                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                                            and pi2.scan_procedure_id = scan_procedures_vgroups.scan_procedure_id 
                                            and pi2.enrollment_id = enrollment_vgroup_memberships.enrollment_id
                                            and appointments.appointment_date '"+v_date_latest+"' ) "

            params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
            @conditions.push(condition)
         elsif  v_date_earliest.length >0
           condition ="processedimages.id  in (select pi2.id from processedimages pi2, appointments,scan_procedures_vgroups,enrollment_vgroup_memberships  
                                            where appointments.vgroup_id =scan_procedures_vgroups.vgroup_id 
                                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                                            and pi2.scan_procedure_id = scan_procedures_vgroups.scan_procedure_id 
                                            and pi2.enrollment_id = enrollment_vgroup_memberships.enrollment_id
                                            and appointments.appointment_date  > '"+v_date_earliest+"' ) "
            params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
            @conditions.push(condition)
          end   

        
        if !params[:processedimage_search][:status_flag].blank? 
            condition =" processedimages.status_flag in ('"+params[:processedimage_search][:status_flag].gsub(/[;:'"()=<>]/, '')+"')   "
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  status_flag "+params[:processedimage_search][:status_flag]
        end
        
        if !params[:processedimage_search][:exists_flag].blank? 
            condition =" processedimages.exists_flag in ('"+params[:processedimage_search][:exists_flag].gsub(/[;:'"()=<>]/, '')+"')   "
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  exists_flag "+params[:processedimage_search][:exists_flag]
        end     

        if !params[:processedimage_search][:file_type].blank? 
            condition ="   processedimages.file_name like '%"+params[:processedimage_search][:file_type].gsub(/[;:'"()=<>]/, '')+"%'"
                     @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  file_type "+params[:processedimage_search][:file_type]
        end     

        if !params[:processedimage_search][:file_name].blank? 
            condition ="    processedimages.file_name like '%"+params[:processedimage_search][:file_name].gsub(/[;:'"()=<>]/, '')+"%'"
                     @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  file_name "+params[:processedimage_search][:file_name]
        end     

        if !params[:processedimage_search][:file_path].blank? 
            condition ="   processedimages.file_name like '%"+params[:processedimage_search][:file_path].gsub(/[;:'"()=<>]/, '')+"%'"
                    @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  file_path "+params[:processedimage_search][:file_path]
        end

         #  build expected date format --- between, >, < 
         v_date_latest =""
         #want all three date parts

         if !params[:processedimage_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:processedimage_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:processedimage_search]["#{'latest_timestamp'}(3i)"].blank?
              v_date_latest = params[:processedimage_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:processedimage_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:processedimage_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
         end

         v_date_earliest =""
         #want all three date parts

         if !params[:processedimage_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:processedimage_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:processedimage_search]["#{'earliest_timestamp'}(3i)"].blank?
               v_date_earliest = params[:processedimage_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:processedimage_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:processedimage_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
          end

         if v_date_latest.length>0 && v_date_earliest.length >0
           condition ="    questionnaires.appointment_id in (select appointments.id from appointments where appointments.appointment_date between '"+v_date_earliest+"' and '"+v_date_latest+"' )"
        ##   @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
         elsif v_date_latest.length>0
           condition ="    questionnaires.appointment_id in (select appointments.id from appointments where appointments.appointment_date <  '"+v_date_latest+"'  )"
         ##   @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
         elsif  v_date_earliest.length >0
           condition ="    questionnaires.appointment_id in (select appointments.id from appointments where appointments.appointment_date >  '"+v_date_earliest+"' )"
         ##   @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
          end

       params["search_criteria"] = params["search_criteria"].sub(", ","")
    puts @conditions.join(" and ")
    @processedimages = Processedimage.where(@conditions.join(" and "))
    respond_to do |format|
   format.html {@processedimages = Kaminari.paginate_array(@processedimages).page(params[:page]).per(50)} 
    end
  end

  # GET /processedimages/1
  # GET /processedimages/1.json
  def show
  end

  # GET /processedimages/new
  def new
    @processedimage = Processedimage.new
  end

  # GET /processedimages/1/edit
  def edit
  end

  # POST /processedimages
  # POST /processedimages.json
  def create
    @processedimage = Processedimage.new(processedimage_params)

    respond_to do |format|
      if @processedimage.save
        format.html { redirect_to @processedimage, notice: 'Processedimage was successfully created.' }
        format.json { render :show, status: :created, location: @processedimage }
      else
        format.html { render :new }
        format.json { render json: @processedimage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /processedimages/1
  # PATCH/PUT /processedimages/1.json
  def update
    respond_to do |format|
      if @processedimage.update(processedimage_params)
        format.html { redirect_to @processedimage, notice: 'Processedimage was successfully updated.' }
        format.json { render :show, status: :ok, location: @processedimage }
      else
        format.html { render :edit }
        format.json { render json: @processedimage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /processedimages/1
  # DELETE /processedimages/1.json
  def destroy
    @processedimage.destroy
    respond_to do |format|
      format.html { redirect_to processedimages_url, notice: 'Processedimage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_processedimage
      @processedimage = Processedimage.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def processedimage_params
      params.require(:processedimage).permit(:file_name, :file_path, :comment, :file_type, :status_flag, :exists_flag,:scan_procedure_id, :enrollment_id)
    end

end
