class LumbarpuncturesController < ApplicationController
  # GET /lumbarpunctures
  # GET /lumbarpunctures.xml
  def index
    @lumbarpunctures = Lumbarpuncture.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lumbarpunctures }
    end
  end

  # GET /lumbarpunctures/1
  # GET /lumbarpunctures/1.xml
  def show

    @current_tab = "lumbarpunctures"
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
     
    @lumbarpuncture = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

    @appointment = Appointment.find(@lumbarpuncture.appointment_id)                            

    @lumbarpunctures = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                               and appointments.appointment_date between ? and ?
                               and scan_procedure_id in (?))", @appointment.appointment_date-2.month,@appointment.appointment_date+2,scan_procedure_array).all

    idx = @lumbarpunctures.index(@lumbarpuncture)
    @older_lumbarpuncture = idx + 1 >= @lumbarpunctures.size ? nil : @lumbarpunctures[idx + 1]
    @newer_lumbarpuncture = idx - 1 < 0 ? nil : @lumbarpunctures[idx - 1]
    
    @vgroup = Vgroup.find(@appointment.vgroup_id)
    @participant = @vgroup.try(:participant)
    @enumbers = @vgroup.enrollments
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lumbarpuncture }
    end
  end

  # GET /lumbarpunctures/new
  # GET /lumbarpunctures/new.xml
  def new
       @current_tab = "lumbarpunctures"
    @lumbarpuncture = Lumbarpuncture.new
        vgroup_id = params[:id]
        params[:new_appointment_vgroup_id] = vgroup_id
        @appointment = Appointment.new
        @appointment.vgroup_id = vgroup_id
        @appointment.appointment_date = (Vgroup.find(vgroup_id)).vgroup_date
        @appointment.appointment_type ='pet_scan'
    #    @appointment.save  --- save in create step

        @lumbarpuncture.appointment_id = @appointment.id

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lumbarpuncture }
    end
  end

  # GET /lumbarpunctures/1/edit
  def edit
    @current_tab = "lumbarpunctures"
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @lumbarpuncture = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @appointment = Appointment.find(@lumbarpuncture.appointment_id)
    
  end

  # POST /lumbarpunctures
  # POST /lumbarpunctures.xml
  def create
     @current_tab = "lumbarpunctures"
     scan_procedure_array = []
     scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @lumbarpuncture = Lumbarpuncture.new(params[:lumbarpuncture])
        
    appointment_date = nil
    if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
         appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
    end
    
    vgroup_id =params[:new_appointment_vgroup_id]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(vgroup_id)
    @appointment = Appointment.new
    @appointment.vgroup_id = vgroup_id
    @appointment.appointment_type ='pet_scan'
    @appointment.appointment_date =appointment_date
    @appointment.comment = params[:appointment][:comment]
    @appointment.save
    @lumbarpuncture.appointment_id = @appointment.id

    respond_to do |format|
      if @lumbarpuncture.save
        # @appointment.save
        if !params[:vital_id].blank?
          @vital = Vital.find(params[:vital_id])
          @vital.pulse = params[:pulse]
          @vital.bp_systol = params[:bp_systol]
          @vital.bp_diastol = params[:bp_diastol]
          @vital.bloodglucose = params[:bloodglucose]
          @vital.save
        else
          @vital = Vital.new
          @vital.appointment_id = @lumbarpuncture.appointment_id
          @vital.pulse = params[:pulse]
          @vital.bp_systol = params[:bp_systol]
          @vital.bp_diastol = params[:bp_diastol]
          @vital.bloodglucose = params[:bloodglucose]
          @vital.save      
        end        

        format.html { redirect_to(@lumbarpuncture, :notice => 'Lumbarpuncture was successfully created.') }
        format.xml  { render :xml => @lumbarpuncture, :status => :created, :location => @lumbarpuncture }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lumbarpuncture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lumbarpunctures/1
  # PUT /lumbarpunctures/1.xml
  def update

        scan_procedure_array = []
        scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)

        @lumbarpuncture = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                          appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                          and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

        appointment_date = nil
        if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
             appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
        end

        # ok to update vitals even if other update fail
        if !params[:vital_id].blank?
          @vital = Vital.find(params[:vital_id])
          @vital.pulse = params[:pulse]
          @vital.bp_systol = params[:bp_systol]
          @vital.bp_diastol = params[:bp_diastol]
          @vital.bloodglucose = params[:bloodglucose]
          @vital.save
        else
          @vital = Vital.new
          @vital.appointment_id = @lumbarpuncture.appointment_id
          @vital.pulse = params[:pulse]
          @vital.bp_systol = params[:bp_systol]
          @vital.bp_diastol = params[:bp_diastol]
          @vital.bloodglucose = params[:bloodglucose]
          @vital.save      
        end

        respond_to do |format|
          if @lumbarpuncture.update_attributes(params[:lumbarpuncture])
            @appointment = Appointment.find(@lumbarpuncture.appointment_id)
            @appointment.comment = params[:appointment][:comment]
            @appointment.appointment_date =appointment_date
            @appointment.save

        format.html { redirect_to(@lumbarpuncture, :notice => 'Lumbarpuncture was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lumbarpuncture.errors, :status => :unprocessable_entity }
      end
    end
  end
  

    def lumbarpuncture_search
       @current_tab = "lumbarpunctures"
       params["search_criteria"] =""

       if params[:lumbarpuncture_search].nil?
            params[:lumbarpuncture_search] =Hash.new  
       end

       scan_procedure_array = []
       scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)   

  #    @lumbarpunctures = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
  #                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
  #    and scan_procedure_id in (?))", scan_procedure_array).all
  #     sql = "select * from lumbarpunctures inner join  appointments on appointments.id = lumbarpunctures.appointment_id order by appointment_date desc"
  #      @search = Lumbarpuncture.find_by_sql(sql)
  #     @search = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments)").all
        @search = Lumbarpuncture.search(params[:search])    # parms search makes something which works with where?

        if !params[:lumbarpuncture_search][:scan_procedure_id].blank?
           @search =@search.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                  appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                  and scan_procedure_id in (?))",params[:lumbarpuncture_search][:scan_procedure_id])
           @scan_procedures = ScanProcedure.where("id in (?)",params[:lumbarpuncture_search][:scan_procedure_id])
           params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
        end

        if !params[:lumbarpuncture_search][:enumber].blank?
           @search =@search.where(" lumbarpunctures.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
            where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
            and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower(?)))",params[:lumbarpuncture_search][:enumber])
            params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:lumbarpuncture_search][:enumber]
        end      

        if !params[:lumbarpuncture_search][:rmr].blank? 
            @search = @search.where(" lumbarpunctures.appointment_id in (select appointments.id from appointments,vgroups
                      where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower(?)   ))",params[:lumbarpuncture_search][:rmr])
            params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:lumbarpuncture_search][:rmr]
        end

         #  build expected date format --- between, >, < 
         v_date_latest =""
         #want all three date parts

         if !params[:lumbarpuncture_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:lumbarpuncture_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:lumbarpuncture_search]["#{'latest_timestamp'}(3i)"].blank?
              v_date_latest = params[:lumbarpuncture_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:lumbarpuncture_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:lumbarpuncture_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
         end

         v_date_earliest =""
         #want all three date parts

         if !params[:lumbarpuncture_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:lumbarpuncture_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:lumbarpuncture_search]["#{'earliest_timestamp'}(3i)"].blank?
               v_date_earliest = params[:lumbarpuncture_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:lumbarpuncture_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:lumbarpuncture_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
          end

         if v_date_latest.length>0 && v_date_earliest.length >0
           @search = @search.where(" lumbarpunctures.appointment_id in (select appointments.id from appointments where appointments.appointment_date between ? and ? )",v_date_earliest,v_date_latest)
           params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
         elsif v_date_latest.length>0
           @search = @search.where(" lumbarpunctures.appointment_id in (select appointments.id from appointments where appointments.appointment_date < ?  )",v_date_latest)
            params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
         elsif  v_date_earliest.length >0
           @search = @search.where(" lumbarpunctures.appointment_id in (select appointments.id from appointments where appointments.appointment_date > ? )",v_date_earliest)
            params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
          end

          if !params[:lumbarpuncture_search][:gender].blank?
             @search =@search.where(" lumbarpunctures.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
              and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                     and participants.gender is not NULL and participants.gender in (?) )", params[:lumbarpuncture_search][:gender])
              if params[:lumbarpuncture_search][:gender] == 1
                 params["search_criteria"] = params["search_criteria"] +",  sex is Male"
              elsif params[:lumbarpuncture_search][:gender] == 2
                 params["search_criteria"] = params["search_criteria"] +",  sex is Female"
              end
          end   

          if !params[:lumbarpuncture_search][:min_age].blank? && params[:lumbarpuncture_search][:max_age].blank?
              @search = @search.where("  lumbarpunctures.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                 where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                              and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                              and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                              and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) >= ?   )",params[:lumbarpuncture_search][:min_age])
              params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:lumbarpuncture_search][:min_age]
          elsif params[:lumbarpuncture_search][:min_age].blank? && !params[:lumbarpuncture_search][:max_age].blank?
               @search = @search.where("  lumbarpunctures.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                  where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                               and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                               and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                           and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) <= ?   )",params[:lumbarpuncture_search][:max_age])
              params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:lumbarpuncture_search][:max_age]
          elsif !params[:lumbarpuncture_search][:min_age].blank? && !params[:lumbarpuncture_search][:max_age].blank?
             @search = @search.where("   lumbarpunctures.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                         and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) between ? and ?   )",params[:lumbarpuncture_search][:min_age],params[:lumbarpuncture_search][:max_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:lumbarpuncture_search][:min_age]+" and "+params[:lumbarpuncture_search][:max_age]
          end
          # trim leading ","
          params["search_criteria"] = params["search_criteria"].sub(", ","")
          # pass to download file?

      @search =  @search.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                 appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                 and scan_procedure_id in (?))", scan_procedure_array)


      @lumbarpunctures =  @search.page(params[:page])

      ### LOOK WHERE TITLE IS SHOWING UP
      @collection_title = 'All Lumbarpuncture appts'

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @lumbarpunctures }
      end
    end
  

  # DELETE /lumbarpunctures/1
  # DELETE /lumbarpunctures/1.xml
  def destroy
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
     
    @lumbarpuncture = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @lumbarpuncture.destroy

    respond_to do |format|
      format.html { redirect_to(lumbarpunctures_url) }
      format.xml  { head :ok }
    end
  end
end
