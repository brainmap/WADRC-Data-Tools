class BlooddrawsController < ApplicationController
  # GET /blooddraws
  # GET /blooddraws.xml

   def blooddraw_search
      @current_tab = "blooddraws"
      params["search_criteria"] =""

      if params[:blooddraw_search].nil?
           params[:blooddraw_search] =Hash.new  
      end

      scan_procedure_array = []
      scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)   

 #    @blooddraws = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
 #                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
 #    and scan_procedure_id in (?))", scan_procedure_array).all
 #     sql = "select * from blooddraws inner join  appointments on appointments.id = blooddraws.appointment_id order by appointment_date desc"
 #      @search = Blooddraw.find_by_sql(sql)
 #     @search = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments)").all
       @search = Blooddraw.search(params[:search])    # parms search makes something which works with where?

       if !params[:blooddraw_search][:scan_procedure_id].blank?
          @search =@search.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                 appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                 and scan_procedure_id in (?))",params[:blooddraw_search][:scan_procedure_id])
          @scan_procedures = ScanProcedure.where("id in (?)",params[:blooddraw_search][:scan_procedure_id])
          params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
       end

       if !params[:blooddraw_search][:enumber].blank?
          @search =@search.where(" blooddraws.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
           where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
           and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower(?)))",params[:blooddraw_search][:enumber])
           params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:blooddraw_search][:enumber]
       end      

       if !params[:blooddraw_search][:rmr].blank? 
           @search = @search.where(" blooddraws.appointment_id in (select appointments.id from appointments,vgroups
                     where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower(?)   ))",params[:blooddraw_search][:rmr])
           params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:blooddraw_search][:rmr]
       end

        #  build expected date format --- between, >, < 
        v_date_latest =""
        #want all three date parts

        if !params[:blooddraw_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:blooddraw_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:blooddraw_search]["#{'latest_timestamp'}(3i)"].blank?
             v_date_latest = params[:blooddraw_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:blooddraw_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:blooddraw_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
        end

        v_date_earliest =""
        #want all three date parts

        if !params[:blooddraw_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:blooddraw_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:blooddraw_search]["#{'earliest_timestamp'}(3i)"].blank?
              v_date_earliest = params[:blooddraw_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:blooddraw_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:blooddraw_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
         end

        if v_date_latest.length>0 && v_date_earliest.length >0
          @search = @search.where(" blooddraws.appointment_id in (select appointments.id from appointments where appointments.appointment_date between ? and ? )",v_date_earliest,v_date_latest)
          params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
        elsif v_date_latest.length>0
          @search = @search.where(" blooddraws.appointment_id in (select appointments.id from appointments where appointments.appointment_date < ?  )",v_date_latest)
           params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
        elsif  v_date_earliest.length >0
          @search = @search.where(" blooddraws.appointment_id in (select appointments.id from appointments where appointments.appointment_date > ? )",v_date_earliest)
           params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
         end

         if !params[:blooddraw_search][:gender].blank?
            @search =@search.where(" blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
             where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
             and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                    and participants.gender is not NULL and participants.gender in (?) )", params[:blooddraw_search][:gender])
             if params[:blooddraw_search][:gender] == 1
                params["search_criteria"] = params["search_criteria"] +",  sex is Male"
             elsif params[:blooddraw_search][:gender] == 2
                params["search_criteria"] = params["search_criteria"] +",  sex is Female"
             end
         end   

         if !params[:blooddraw_search][:min_age].blank? && params[:blooddraw_search][:max_age].blank?
             @search = @search.where("  blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                             and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) >= ?   )",params[:blooddraw_search][:min_age])
             params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:blooddraw_search][:min_age]
         elsif params[:blooddraw_search][:min_age].blank? && !params[:blooddraw_search][:max_age].blank?
              @search = @search.where("  blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                 where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                              and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                              and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                          and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) <= ?   )",params[:blooddraw_search][:max_age])
             params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:blooddraw_search][:max_age]
         elsif !params[:blooddraw_search][:min_age].blank? && !params[:blooddraw_search][:max_age].blank?
            @search = @search.where("   blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                        and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) between ? and ?   )",params[:blooddraw_search][:min_age],params[:blooddraw_search][:max_age])
           params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:blooddraw_search][:min_age]+" and "+params[:blooddraw_search][:max_age]
         end
         # trim leading ","
         params["search_criteria"] = params["search_criteria"].sub(", ","")
         # pass to download file?

     @search =  @search.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                and scan_procedure_id in (?))", scan_procedure_array)


     @blooddraws =  @search.page(params[:page])

     ### LOOK WHERE TITLE IS SHOWING UP
     @collection_title = 'All Blooddraw appts'

     respond_to do |format|
       format.html # index.html.erb
       format.xml  { render :xml => @blooddraws }
     end
   end

  def lh_search
    @conditions = []
     @current_tab = "blooddraws"
     params["search_criteria"] =""
      @q_form_id = 12   # use in data_search_q_data

     if params[:lh_search].nil?
          params[:lh_search] =Hash.new  
     end

     scan_procedure_array = []
     scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)   

#    @blooddraws = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
#                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
#    and scan_procedure_id in (?))", scan_procedure_array).all
#     sql = "select * from blooddraws inner join  appointments on appointments.id = blooddraws.appointment_id order by appointment_date desc"
#      @search = Blooddraw.find_by_sql(sql)
#     @search = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments)").all
    ####  @search = Blooddraw.search(params[:search])    # parms search makes something which works with where?

      if !params[:lh_search][:scan_procedure_id].blank?
         condition ="   blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                and scan_procedure_id in ("+params[:lh_search][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+"))"
         @scan_procedures = ScanProcedure.where("id in (?)",params[:lh_search][:scan_procedure_id])
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end

      if !params[:lh_search][:enumber].blank?
         condition ="   blooddraws.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
          where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
          and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:lh_search][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:lh_search][:enumber]
      end      

      if !params[:lh_search][:rmr].blank? 
          condition ="   blooddraws.appointment_id in (select appointments.id from appointments,vgroups
                    where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower('"+params[:lh_search][:rmr].gsub(/[;:'"()=<>]/, '')+"')   ))"
                    @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:lh_search][:rmr]
      end

       #  build expected date format --- between, >, < 
       v_date_latest =""
       #want all three date parts

       if !params[:lh_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:lh_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:lh_search]["#{'latest_timestamp'}(3i)"].blank?
            v_date_latest = params[:lh_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:lh_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:lh_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
       end

       v_date_earliest =""
       #want all three date parts

       if !params[:lh_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:lh_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:lh_search]["#{'earliest_timestamp'}(3i)"].blank?
             v_date_earliest = params[:lh_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:lh_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:lh_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
        end

       if v_date_latest.length>0 && v_date_earliest.length >0
         condition ="    blooddraws.appointment_id in (select appointments.id from appointments where appointments.appointment_date between '"+v_date_earliest+"' and '"+v_date_latest+"' )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
       elsif v_date_latest.length>0
         condition ="    blooddraws.appointment_id in (select appointments.id from appointments where appointments.appointment_date < '"+v_date_latest+"'  )"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
       elsif  v_date_earliest.length >0
         condition ="    blooddraws.appointment_id in (select appointments.id from appointments where appointments.appointment_date >  '"+v_date_earliest+"' )"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
        end

        if !params[:lh_search][:gender].blank?
           condition ="    blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
            where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
            and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                   and participants.gender is not NULL and participants.gender in ("+params[:lh_search][:gender].gsub(/[;:'"()=<>]/, '')+") )"
            @conditions.push(condition)
            if params[:lh_search][:gender] == 1
               params["search_criteria"] = params["search_criteria"] +",  sex is Male"
            elsif params[:lh_search][:gender] == 2
               params["search_criteria"] = params["search_criteria"] +",  sex is Female"
            end
        end   

        if !params[:lh_search][:min_age].blank? && params[:lh_search][:max_age].blank?
            condition ="     blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                            and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) >= "+params[:lh_search][:min_age].gsub(/[;:'"()=<>]/, '')+"   )"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:lh_search][:min_age]
        elsif params[:lh_search][:min_age].blank? && !params[:lh_search][:max_age].blank?
             condition ="     blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                         and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) <= "+params[:lh_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:lh_search][:max_age]
        elsif !params[:lh_search][:min_age].blank? && !params[:lh_search][:max_age].blank?
           condition ="      blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                           and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                           and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                       and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) between "+params[:lh_search][:min_age].gsub(/[;:'"()=<>]/, '')+" and "+params[:lh_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:lh_search][:min_age]+" and "+params[:lh_search][:max_age]
        end
        # trim leading ","
        params["search_criteria"] = params["search_criteria"].sub(", ","")
        # pass to download file?

  
   # adjust columns and fields for html vs xls
   request_format = request.formats.to_s
   @html_request ="Y"
   case  request_format
     when "text/html" then  # application/html ?
       @column_headers = ['Date','Protocol','Enumber','RMR','LH status','LH Note', 'Appt Note'] # need to look up values
       # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
       @column_number =   @column_headers.size
       @fields =["vgroups.completedblooddraw","blooddraws.blooddrawnote","blooddraws.id"] # vgroups.id vgroup_id always first, include table name
       @left_join = [""] # left join needs to be in sql right after the parent table!!!!!!!
     else
           @html_request ="N"
           @column_headers = ['Date','Protocol','Enumber','RMR','LH status','LH Note','BP Systol','BP Diastol','Pulse','Blood Glucose','Height(inches)','Weight(kg)','Age at Appt', 'Appt Note'] # need to look up values
           # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
           #@column_number =   @column_headers.size
           @fields =["vgroups.completedblooddraw","blooddraws.blooddrawnote","vitals.bp_systol","vitals.bp_diastol","vitals.pulse","vitals.bloodglucose","blooddraws.height_inches","blooddraws.weight_kg","appointments.age_at_appointment","blooddraws.id"] # vgroups.id vgroup_id always first, include table name
           @left_join = ["LEFT JOIN vitals on blooddraws.appointment_id = vitals.appointment_id"] # left join needs to be in sql right after the parent table!!!!!!!
           # need to split off q_data into sql with less than 61 tables 
           @column_headers_q_data =[]
           @fields_q_data = []
           @left_join_q_data = []
     end
   @tables =['blooddraws'] # trigger joins --- vgroups and appointments by default

   #@conditions =[] # ["scan_procedures.codename='johnson.pipr.visit1'"] # need look up for like, lt, gt, between  
   @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]
   
   if @html_request == "Y"     
       @results = self.run_search   # in the application controller
   elsif @html_request == "N"
        @results = self.run_search_q_data   # in the application controller
        @column_number =   @column_headers.size
   end
       
       
  @results_total = @results  # pageination makes result count wrong
  t = Time.now 
  @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
 
  ### LOOK WHERE TITLE IS SHOWING UP
  @collection_title = 'All Lab Health appts'

  respond_to do |format|
    format.xls # lh_search.xls.erb
    format.xml  { render :xml => @blooddraws }       
    format.html {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)} # lp_search.html.erb
  end

  end


  def index
    @blooddraws = Blooddraw.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @blooddraws }
    end
  end

  # GET /blooddraws/1
  # GET /blooddraws/1.xml
  def show

    @current_tab = "blooddraws"
     q_form_id = 12
     scan_procedure_array = []
     scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)

     @blooddraw = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                       and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

     @appointment = Appointment.find(@blooddraw.appointment_id)                            

     @blooddraws = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                 appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                and appointments.appointment_date between ? and ?
                                and scan_procedure_id in (?))", @appointment.appointment_date-2.month,@appointment.appointment_date+2,scan_procedure_array).all

     idx = @blooddraws.index(@blooddraw)
     @older_blooddraw = idx + 1 >= @blooddraws.size ? nil : @blooddraws[idx + 1]
     @newer_blooddraw = idx - 1 < 0 ? nil : @blooddraws[idx - 1]

     @vgroup = Vgroup.find(@appointment.vgroup_id)
     @participant = @vgroup.try(:participant)
     @enumbers = @vgroup.enrollments
     
     @appointment = Appointment.find(@blooddraw.appointment_id)
     @q_data_form = QDataForm.where("questionform_id="+ q_form_id.to_s+" and appointment_id in (?)",@appointment.id)
     @q_data_form = @q_data_form[0]
     #params[:appointment_id] = @blooddraw.appointment_id
     @questionform =Questionform.find(q_form_id)

     # NEED SCAN PROC ARRAY FOR VGROUP  --- change to vgroup!!

      @a =  Appointment.where("vgroup_id in (?)",@appointment.vgroup_id)
# switching to vgroup sp
#         a_array =@a.to_a
#        @visits = Visit.where("appointment_id in (?) ",a_array)
#          visit = nil
#          @visits.each do |v| 
# 	       visit = v
# 	     end  
# 	  sp_list = visit.scan_procedures.collect {|sp| sp.id}.join(",")
 	  
 	  vgroup = Vgroup.find(@appointment.vgroup_id)
 	  sp_list = vgroup.scan_procedures.collect {|sp| sp.id}.join(",")

 	  sp_array =[]
 	  sp_array = sp_list.split(',').map(&:to_i)
 	  @scanprocedures = ScanProcedure.where("id in (?)",sp_array)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @blooddraw }
    end
  end

  # GET /blooddraws/new
  # GET /blooddraws/new.xml
  def new
        @current_tab = "blooddraws"
        @blooddraw = Blooddraw.new
        vgroup_id = params[:id]
        @vgroup = Vgroup.find(vgroup_id)
        @enumbers = @vgroup.enrollments
        params[:new_appointment_vgroup_id] = vgroup_id
        @appointment = Appointment.new
        @appointment.vgroup_id = vgroup_id
        @appointment.appointment_date = (Vgroup.find(vgroup_id)).vgroup_date
        @appointment.appointment_type ='blood_draw'
    #    @appointment.save  --- save in create step

        @blooddraw.appointment_id = @appointment.id
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @blooddraw }
    end
  end

  # GET /blooddraws/1/edit
  def edit
    q_form_id = 12
    @current_tab = "blooddraws"
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @blooddraw = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @appointment = Appointment.find(@blooddraw.appointment_id)
    @vgroup = Vgroup.find(@appointment.vgroup_id)
    @enumbers = @vgroup.enrollments
    @q_data_form = QDataForm.where("questionform_id="+q_form_id.to_s+" and appointment_id in (?)",@appointment.id)
    @q_data_form = @q_data_form[0]
    #params[:appointment_id] = @blooddraw.appointment_id
    @questionform =Questionform.find(q_form_id)

    # NEED SCAN PROC ARRAY FOR VGROUP  --- change to vgroup!!
  
     @a =  Appointment.where("vgroup_id in (?)",@appointment.vgroup_id)
    # switching to vgroup sp
    #    a_array =@a.to_a
    #   @visits = Visit.where("appointment_id in (?) ",a_array)
    #     visit = nil
    #     @visits.each do |v| 
	  #     visit = v
	   #  end  
	  #sp_list = visit.scan_procedures.collect {|sp| sp.id}.join(",")
	  vgroup = Vgroup.find(@appointment.vgroup_id)
 	  sp_list = vgroup.scan_procedures.collect {|sp| sp.id}.join(",")
	  sp_array =[]
	  sp_array = sp_list.split(',').map(&:to_i)
	  @scanprocedures = ScanProcedure.where("id in (?)",sp_array)

  end

  # POST /blooddraws
  # POST /blooddraws.xml
  def create
   @current_tab = "blooddraws"
   q_form_id = 12
   scan_procedure_array = []
   scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
  @blooddraw = Blooddraw.new(params[:blooddraw])
  
  appointment_date = nil
  if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
       appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
  end
  
  vgroup_id =params[:new_appointment_vgroup_id]
  @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(vgroup_id)
  @appointment = Appointment.new
  @appointment.vgroup_id = vgroup_id
  @appointment.appointment_type ='blood_draw'
  @appointment.appointment_date =appointment_date
  @appointment.comment = params[:appointment][:comment]
  @appointment.user = current_user
  if !@vgroup.participant_id.blank?
    @participant = Participant.find(@vgroup.participant_id)
    if !@participant.dob.blank?
       @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).floor
    end
  end
  @appointment.save
  @blooddraw.appointment_id = @appointment.id

puts  @blooddraw.appointment_id.to_s
  @q_data_form = QDataForm.new
  @q_data_form.appointment_id = @appointment.id
  @q_data_form.questionform_id = q_form_id
  @q_data_form.save

  respond_to do |format|
    if @blooddraw.save
     # puts params[:vgroup][:completedblooddraw]
      @vgroup.completedblooddraw = params[:vgroup][:completedblooddraw]
      @vgroup.save
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
        @vital.appointment_id = @blooddraw.appointment_id
        @vital.pulse = params[:pulse]
        @vital.bp_systol = params[:bp_systol]
        @vital.bp_diastol = params[:bp_diastol]
        @vital.bloodglucose = params[:bloodglucose]
        @vital.save  
      end        
 
        format.html { redirect_to(@blooddraw, :notice => 'Lab Health was successfully created.') }
        format.xml  { render :xml => @blooddraw, :status => :created, :location => @blooddraw }
      else
        @q_data_form.delete
        @appointment.delete
        format.html { render :action => "new" }
        format.xml  { render :xml => @blooddraw.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /blooddraws/1
  # PUT /blooddraws/1.xml
  def update
        scan_procedure_array = []
        scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)

        @blooddraw = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
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
          @vital.appointment_id = @blooddraw.appointment_id
          @vital.pulse = params[:pulse]
          @vital.bp_systol = params[:bp_systol]
          @vital.bp_diastol = params[:bp_diastol]
          @vital.bloodglucose = params[:bloodglucose]
          @vital.save      
        end

        respond_to do |format|
          if @blooddraw.update_attributes(params[:blooddraw])
            @appointment = Appointment.find(@blooddraw.appointment_id)
            @vgroup = Vgroup.find(@appointment.vgroup_id)
            @appointment.comment = params[:appointment][:comment]
            @appointment.appointment_date =appointment_date
            if !@vgroup.participant_id.blank?
              @participant = Participant.find(@vgroup.participant_id)
              if !@participant.dob.blank?
                 @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).floor
              end
            end
            @appointment.save
            @vgroup.completedblooddraw = params[:vgroup][:completedblooddraw]
            @vgroup.save
        format.html { redirect_to(@blooddraw, :notice => 'Lab Health was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @blooddraw.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /blooddraws/1
  # DELETE /blooddraws/1.xml
  def destroy
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
     
    @blooddraw = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])


    if @blooddraw.appointment_id > 3156 # sure appointment_id not used by any other
       @appointment = Appointment.find(@blooddraw.appointment_id)
       @appointment.destroy
    end
                                       
    @blooddraw.destroy

    respond_to do |format|
      format.html { redirect_to(lh_search_path) }
      format.xml  { head :ok }
    end
  end

end


