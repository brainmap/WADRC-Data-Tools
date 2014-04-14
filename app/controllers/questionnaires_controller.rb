# encoding: utf-8
class QuestionnairesController < ApplicationController

  
  
    def questionnaire_search
       @current_tab = "questionnaires"
       params["search_criteria"] =""

       if params[:questionnaire_search].nil?
            params[:questionnaire_search] =Hash.new  
       end

       scan_procedure_array = []
       scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)   

  #    @questionnaires = Blooddraw.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
  #                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
  #    and scan_procedure_id in (?))", scan_procedure_array).all
  #     sql = "select * from questionnaires inner join  appointments on appointments.id = questionnaires.appointment_id order by appointment_date desc"
  #      @search = Blooddraw.find_by_sql(sql)
  #     @search = Blooddraw.where("questionnaires.appointment_id in (select appointments.id from appointments)").all
        @search = Questionnaire.search(params[:search])    # parms search makes something which works with where?
        @search =@search.where("questionnaires.appointment_id in (select appointment_id from q_data_forms)")
        if !params[:questionnaire_search][:scan_procedure_id].blank?
           @search =@search.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                  appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                  and scan_procedure_id in (?))",params[:questionnaire_search][:scan_procedure_id])
           @scan_procedures = ScanProcedure.where("id in (?)",params[:questionnaire_search][:scan_procedure_id])
           params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
        end

        if !params[:questionnaire_search][:enumber].blank?
           @search =@search.where(" questionnaires.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
            where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
            and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower(?)))",params[:questionnaire_search][:enumber])
            params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:questionnaire_search][:enumber]
        end      

        if !params[:questionnaire_search][:rmr].blank? 
            @search = @search.where(" questionnaires.appointment_id in (select appointments.id from appointments,vgroups
                      where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower(?)   ))",params[:questionnaire_search][:rmr])
            params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:questionnaire_search][:rmr]
        end

         #  build expected date format --- between, >, < 
         v_date_latest =""
         #want all three date parts

         if !params[:questionnaire_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:questionnaire_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:questionnaire_search]["#{'latest_timestamp'}(3i)"].blank?
              v_date_latest = params[:questionnaire_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:questionnaire_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:questionnaire_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
         end

         v_date_earliest =""
         #want all three date parts

         if !params[:questionnaire_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:questionnaire_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:questionnaire_search]["#{'earliest_timestamp'}(3i)"].blank?
               v_date_earliest = params[:questionnaire_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:questionnaire_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:questionnaire_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
          end

         if v_date_latest.length>0 && v_date_earliest.length >0
           @search = @search.where(" questionnaires.appointment_id in (select appointments.id from appointments where appointments.appointment_date between ? and ? )",v_date_earliest,v_date_latest)
           params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
         elsif v_date_latest.length>0
           @search = @search.where(" questionnaires.appointment_id in (select appointments.id from appointments where appointments.appointment_date < ?  )",v_date_latest)
            params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
         elsif  v_date_earliest.length >0
           @search = @search.where(" questionnaires.appointment_id in (select appointments.id from appointments where appointments.appointment_date > ? )",v_date_earliest)
            params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
          end

          if !params[:questionnaire_search][:gender].blank?
             @search =@search.where(" questionnaires.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
              and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                     and participants.gender is not NULL and participants.gender in (?) )", params[:questionnaire_search][:gender])
              if params[:questionnaire_search][:gender] == 1
                 params["search_criteria"] = params["search_criteria"] +",  sex is Male"
              elsif params[:questionnaire_search][:gender] == 2
                 params["search_criteria"] = params["search_criteria"] +",  sex is Female"
              end
          end   

          if !params[:questionnaire_search][:min_age].blank? && params[:questionnaire_search][:max_age].blank?
              @search = @search.where("  questionnaires.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                 where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                              and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                              and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                              and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) >= ?   )",params[:questionnaire_search][:min_age])
              params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:questionnaire_search][:min_age]
          elsif params[:questionnaire_search][:min_age].blank? && !params[:questionnaire_search][:max_age].blank?
               @search = @search.where("  questionnaires.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                  where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                               and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                               and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                           and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) <= ?   )",params[:questionnaire_search][:max_age])
              params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:questionnaire_search][:max_age]
          elsif !params[:questionnaire_search][:min_age].blank? && !params[:questionnaire_search][:max_age].blank?
             @search = @search.where("   questionnaires.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                         and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) between ? and ?   )",params[:questionnaire_search][:min_age],params[:questionnaire_search][:max_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:questionnaire_search][:min_age]+" and "+params[:questionnaire_search][:max_age]
          end
          # trim leading ","
          params["search_criteria"] = params["search_criteria"].sub(", ","")
          # pass to download file?

      @search =  @search.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                 appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                 and scan_procedure_id in (?))", scan_procedure_array)


      @questionnaires =  @search.page(params[:page])

      ### LOOK WHERE TITLE IS SHOWING UP
      @collection_title = 'All Questionnaire appts'

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @questionnaires }
      end
    end
    
  
    def q_search
      @conditions = []
       @current_tab = "questionnaires"
       params["search_criteria"] =""
       # for search dropdown
        @q_forms = Questionform.where("current_tab in (?)",@current_tab).where("status_flag in (?)","Y")
        @q_form_default = @q_forms.where("tab_default_yn='Y'")

       q_form = Questionform.where("current_tab in (?)",@current_tab).where("tab_default_yn in (?)","Y")
       @q_form_id = q_form[0].id # 14   # use in data_search_q_data
       if !params[:q_search].nil? and !params[:q_search][:questionform_id].blank?
           @q_form_id = params[:q_search][:questionform_id]
       end

       if params[:q_search].nil?
            params[:q_search] =Hash.new 
           #  params[:q_search][:q_status] = "yes" 
       end

       scan_procedure_array = []
       scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)   

  #    @questionnaires = Blooddraw.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
  #                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
  #    and scan_procedure_id in (?))", scan_procedure_array).all
  #     sql = "select * from questionnaires inner join  appointments on appointments.id = questionnaires.appointment_id order by appointment_date desc"
  #      @search = Blooddraw.find_by_sql(sql)
  #     @search = Blooddraw.where("questionnaires.appointment_id in (select appointments.id from appointments)").all
   #     @search = Questionnaire.search(params[:search])    # parms search makes something which works with where?
        condition ="   questionnaires.appointment_id in (select appointment_id from q_data_forms)"
        if !params[:q_search][:scan_procedure_id].blank?
           condition ="   questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                  appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                  and scan_procedure_id in ("+params[:q_search][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+"))"
           @scan_procedures = ScanProcedure.where("id in (?)",params[:q_search][:scan_procedure_id])
           @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
        end

        if !params[:q_search][:enumber].blank?
          if params[:q_search][:enumber].include?(',') # string of enumbers
           v_enumber =  params[:q_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
           v_enumber = v_enumber.gsub(/,/,"','")
             condition ="    questionnaires.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
              where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in  ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"'))"
          else
           condition ="    questionnaires.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
            where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
            and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in  (lower('"+params[:q_search][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"
          end
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:q_search][:enumber]
        end      

        if !params[:q_search][:rmr].blank? 
            condition ="    questionnaires.appointment_id in (select appointments.id from appointments,vgroups
                      where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower('"+params[:q_search][:rmr].gsub(/[;:'"()=<>]/, '')+"')   ))"
                      @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:q_search][:rmr]
        end
        
        if !params[:q_search][:q_status].blank? 
            condition =" questionnaires.appointment_id in (select appointments.id from appointments,vgroups
                                where appointments.vgroup_id = vgroups.id and  lower(vgroups.completedquestionnaire) in (lower('"+params[:q_search][:q_status].gsub(/[;:'"()=<>]/, '')+"')   ))"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  Q status "+params[:q_search][:q_status]
        end

         #  build expected date format --- between, >, < 
         v_date_latest =""
         #want all three date parts

         if !params[:q_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:q_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:q_search]["#{'latest_timestamp'}(3i)"].blank?
              v_date_latest = params[:q_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:q_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:q_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
         end

         v_date_earliest =""
         #want all three date parts

         if !params[:q_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:q_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:q_search]["#{'earliest_timestamp'}(3i)"].blank?
               v_date_earliest = params[:q_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:q_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:q_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
          end

         if v_date_latest.length>0 && v_date_earliest.length >0
           condition ="    questionnaires.appointment_id in (select appointments.id from appointments where appointments.appointment_date between '"+v_date_earliest+"' and '"+v_date_latest+"' )"
           @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
         elsif v_date_latest.length>0
           condition ="    questionnaires.appointment_id in (select appointments.id from appointments where appointments.appointment_date <  '"+v_date_latest+"'  )"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
         elsif  v_date_earliest.length >0
           condition ="    questionnaires.appointment_id in (select appointments.id from appointments where appointments.appointment_date >  '"+v_date_earliest+"' )"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
          end

          if !params[:q_search][:gender].blank?
             condition ="    questionnaires.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
              and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                     and participants.gender is not NULL and participants.gender in ("+params[:q_search][:gender].gsub(/[;:'"()=<>]/, '')+") )"
              @conditions.push(condition)
              if params[:q_search][:gender] == 1
                 params["search_criteria"] = params["search_criteria"] +",  sex is Male"
              elsif params[:q_search][:gender] == 2
                 params["search_criteria"] = params["search_criteria"] +",  sex is Female"
              end
          end   

          if !params[:q_search][:min_age].blank? && params[:q_search][:max_age].blank?
              condition ="     questionnaires.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                 where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                              and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                              and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                              and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) >= "+params[:q_search][:min_age].gsub(/[;:'"()=<>]/, '')+"   )"
               @conditions.push(condition)
              params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:q_search][:min_age]
          elsif params[:q_search][:min_age].blank? && !params[:q_search][:max_age].blank?
               condition ="     questionnaires.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                  where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                               and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                               and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                           and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) <= "+params[:q_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
              @conditions.push(condition)
              params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:q_search][:max_age]
          elsif !params[:q_search][:min_age].blank? && !params[:q_search][:max_age].blank?
             condition ="      questionnaires.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                         and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) between "+params[:q_search][:min_age].gsub(/[;:'"()=<>]/, '')+" and "+params[:q_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:q_search][:min_age]+" and "+params[:q_search][:max_age]
          end
          # trim leading ","
          params["search_criteria"] = params["search_criteria"].sub(", ","")
          # pass to download file?

     # @search =  @search.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
    #                                             appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
     #                                            and scan_procedure_id in (?))", scan_procedure_array)


      #@questionnaires =  @search.page(params[:page])

      # adjust columns and fields for html vs xls
      request_format = request.formats.to_s
      @html_request ="Y"
      case  request_format
        when "[text/html]","text/html" then  # application/html ?
          @column_headers = ['Date','Protocol','Enumber','RMR','Q status','Appt Note'] # need to look up values
          # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
          @column_number =   @column_headers.size
          @fields =["vgroups.completedquestionnaire", "questionnaires.id"] # vgroups.id vgroup_id always first, include table name
          @left_join = [] # left join needs to be in sql right after the parent table!!!!!!!
        else
              @html_request ="N"
              @column_headers = ['Date','Protocol','Enumber','RMR','Q status', 'Age at Appt','Appt Note'] # need to look up values
              # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
              #@column_number =   @column_headers.size
              @fields =["vgroups.completedquestionnaire","appointments.age_at_appointment", "questionnaires.id"] # vgroups.id vgroup_id always first, include table name
              @left_join = [] # left join needs to be in sql right after the parent table!!!!!!!
              @column_headers_q_data =[]
              @fields_q_data = []
              @left_join_q_data = []
        end
      @tables =['questionnaires'] # trigger joins --- vgroups and appointments by default

      #@conditions =[] # ["scan_procedures.codename='johnson.pipr.visit1'"] # need look up for like, lt, gt, between  
      @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]
            
   
   if @html_request == "Y"     
       @results = self.run_search   # in the application controller
   elsif @html_request == "N"
        @results = self.run_search_q_data(@tables,@fields ,@left_join,@left_join_vgroup)   # in the application controller
        @column_number =   @column_headers.size
   end
     @results_total = @results  # pageination makes result count wrong
     t = Time.now 
     @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
    
     ### LOOK WHERE TITLE IS SHOWING UP
     @collection_title = 'All Questionnaire appts'

     respond_to do |format|
       format.xls # lp_search.xls.erb
       format.xml  { render :xml => @questionnaires }       
       format.html {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)} # lp_search.html.erb
     end

    end


  # GET /questionnaires
  # GET /questionnaires.xml
  def index
    @questionnaires = Questionnaire.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questionnaires }
    end
  end

  # GET /questionnaires/1
  # GET /questionnaires/1.xml
  def show
    @current_tab = "questionnaires"
    q_form = Questionform.where("current_tab in (?)",@current_tab).where("tab_default_yn in (?)","Y")
    q_form_id = q_form[0].id # 14
     scan_procedure_array = []
     scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)

     @questionnaire = Questionnaire.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                       and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

     @appointment = Appointment.find(@questionnaire.appointment_id)
     if   !@appointment.questionform_id_list.blank?
            q_form_id_array = (@appointment.questionform_id_list).split(",")
            q_form_id  = q_form_id_array[0]
     end                             

     @questionnaires = Questionnaire.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                 appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                and appointments.appointment_date between ? and ?
                                and scan_procedure_id in (?))", @appointment.appointment_date-2.month,@appointment.appointment_date+2,scan_procedure_array).all

     idx = @questionnaires.index(@questionnaire)
     @older_questionnaire = idx + 1 >= @questionnaires.size ? nil : @questionnaires[idx + 1]
     @newer_questionnaire = idx - 1 < 0 ? nil : @questionnaires[idx - 1]

     @vgroup = Vgroup.find(@appointment.vgroup_id)
     @participant = @vgroup.try(:participant)
     @enumbers = @vgroup.enrollments
     
     @appointment = Appointment.find(@questionnaire.appointment_id)
     @q_data_form = QDataForm.where("questionform_id="+q_form_id.to_s+" and appointment_id in (?)",@appointment.id)
     @q_data_form = @q_data_form[0]
     #params[:appointment_id] = @questionnaire.appointment_id
     @questionform =Questionform.find(q_form_id)

     # NEED SCAN PROC ARRAY FOR VGROUP  --- change to vgroup!!

      @a =  Appointment.where("vgroup_id in (?)",@appointment.vgroup_id)
      # swicthing to vgroup sp
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
      format.xml  { render :xml => @questionnaire }
    end
  end

  # GET /questionnaires/new
  # GET /questionnaires/new.xml
  def new
        @current_tab = "questionnaires"
        @questionnaire = Questionnaire.new
        vgroup_id = params[:id]
        @vgroup = Vgroup.find(vgroup_id)
        @enumbers = @vgroup.enrollments
        params[:new_appointment_vgroup_id] = vgroup_id
        @appointment = Appointment.new
        @appointment.vgroup_id = vgroup_id
        @appointment.appointment_date = (Vgroup.find(vgroup_id)).vgroup_date
        @appointment.appointment_type ='blood_draw'
    #    @appointment.save  --- save in create step

        @questionnaire.appointment_id = @appointment.id
        @q_forms = Questionform.where("current_tab in (?)",@current_tab).where("status_flag in (?)","Y")
        @q_form_default = @q_forms.where("tab_default_yn='Y'")

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @questionnaire }
    end
  end

  # GET /questionnaires/1/edit
  def edit
    @current_tab = "questionnaires"
    q_form = Questionform.where("current_tab in (?)",@current_tab).where("tab_default_yn in (?)","Y")
    q_form_id = q_form[0].id # 14
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @questionnaire = Questionnaire.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @appointment = Appointment.find(@questionnaire.appointment_id)
    if   !@appointment.questionform_id_list.blank?
            q_form_id_array = (@appointment.questionform_id_list).split(",")
            q_form_id  = q_form_id_array[0]
    end 
    @vgroup = Vgroup.find(@appointment.vgroup_id)
    @enumbers = @vgroup.enrollments
    
    @q_data_form = QDataForm.where("questionform_id="+q_form_id.to_s+" and appointment_id in (?)",@appointment.id)
    @q_data_form = @q_data_form[0]
    #params[:appointment_id] = @questionnaire.appointment_id
    @questionform =Questionform.find(q_form_id)

    # NEED SCAN PROC ARRAY FOR VGROUP  --- change to vgroup!!
  
     @a =  Appointment.where("vgroup_id in (?)",@appointment.vgroup_id)
      # switching to vgroup sp
#        a_array =@a.to_a
#       @visits = Visit.where("appointment_id in (?) ",a_array)
#         visit = nil
#         @visits.each do |v| 
#	       visit = v
#	     end  
#	  sp_list = visit.scan_procedures.collect {|sp| sp.id}.join(",")
    vgroup = Vgroup.find(@appointment.vgroup_id)
    sp_list = vgroup.scan_procedures.collect {|sp| sp.id}.join(",")
	  sp_array =[]
	  sp_array = sp_list.split(',').map(&:to_i)
	  @scanprocedures = ScanProcedure.where("id in (?)",sp_array)
  end

  # POST /questionnaires
  # POST /questionnaires.xml
  def create
     @current_tab = "questionnaires"
     q_form = Questionform.where("current_tab in (?)",@current_tab).where("tab_default_yn in (?)","Y")
     q_form_id = q_form[0].id # 14
     if !params[:appointment][:questionform_id].blank?
          q_form_id = params[:appointment][:questionform_id]
     end
     scan_procedure_array = []
     scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @questionnaire = Questionnaire.new(params[:questionnaire])


    appointment_date = nil
    if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
         appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
    end

    vgroup_id =params[:new_appointment_vgroup_id]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(vgroup_id)
    @appointment = Appointment.new
    if !params[:appointment][:questionform_id].blank?
          @appointment.questionform_id_list = params[:appointment][:questionform_id]
    end
    @appointment.vgroup_id = vgroup_id
    @appointment.appointment_type ='questionnaire'
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
    @questionnaire.appointment_id = @appointment.id
    @q_data_form = QDataForm.new
    @q_data_form.appointment_id = @appointment.id
    @q_data_form.questionform_id = q_form_id
    @q_data_form.save
    respond_to do |format|
      if @questionnaire.save
        @vgroup.completedquestionnaire = params[:vgroup][:completedquestionnaire]
        @vgroup.save
=begin    
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
          @vital.appointment_id = @questionnaire.appointment_id
          @vital.pulse = params[:pulse]
          @vital.bp_systol = params[:bp_systol]
          @vital.bp_diastol = params[:bp_diastol]
          @vital.bloodglucose = params[:bloodglucose]
          @vital.save      
        end
=end
        
        format.html { redirect_to(@questionnaire, :notice => 'Questionnaire was successfully created.') }
        format.xml  { render :xml => @questionnaire, :status => :created, :location => @questionnaire }
      else
        @q_data_form.delete
        @appointment.delete
        format.html { render :action => "new" }
        format.xml  { render :xml => @questionnaire.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /questionnaires/1
  # PUT /questionnaires/1.xml
  def update
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)

    @questionnaire = Questionnaire.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

    appointment_date = nil
    if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
         appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
    end

=begin
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
      @vital.appointment_id = @questionnaire.appointment_id
      @vital.pulse = params[:pulse]
      @vital.bp_systol = params[:bp_systol]
      @vital.bp_diastol = params[:bp_diastol]
      @vital.bloodglucose = params[:bloodglucose]
      @vital.save      
    end
=end
    respond_to do |format|
      if @questionnaire.update_attributes(params[:questionnaire])
        @appointment = Appointment.find(@questionnaire.appointment_id)
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
        @vgroup.completedquestionnaire = params[:vgroup][:completedquestionnaire]
        @vgroup.save
        format.html { redirect_to(@questionnaire, :notice => 'Questionnaire was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @questionnaire.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /questionnaires/1
  # DELETE /questionnaires/1.xml
  def destroy
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
     
    @questionnaire = Questionnaire.where("questionnaires.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    
    if @questionnaire.appointment_id > 3156 # sure appointment_id not used by any other
       @appointment = Appointment.find(@questionnaire.appointment_id)
       @appointment.destroy
    end
    @questionnaire.destroy

    respond_to do |format|
      format.html { redirect_to(q_search_path) }
      format.xml  { head :ok }
    end
  end
end
