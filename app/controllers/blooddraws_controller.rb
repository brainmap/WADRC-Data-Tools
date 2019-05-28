# encoding: utf-8
class BlooddrawsController < ApplicationController
  # GET /blooddraws
  # GET /blooddraws.xml
require 'csv'        

before_action :set_blooddraw, only: [:show, :edit, :update, :destroy]   
respond_to :html
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
                             and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) >= ?   )",params[:blooddraw_search][:min_age])
             params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:blooddraw_search][:min_age]
         elsif params[:blooddraw_search][:min_age].blank? && !params[:blooddraw_search][:max_age].blank?
              @search = @search.where("  blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                 where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                              and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                              and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                          and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) <= ?   )",params[:blooddraw_search][:max_age])
             params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:blooddraw_search][:max_age]
         elsif !params[:blooddraw_search][:min_age].blank? && !params[:blooddraw_search][:max_age].blank?
            @search = @search.where("   blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                        and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) between ? and ?   )",params[:blooddraw_search][:min_age],params[:blooddraw_search][:max_age])
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
    if !params[:lh_search].blank?
           @lh_search_params = lh_search_params()
    end
    @conditions = []
     @current_tab = "blooddraws"
     params["search_criteria"] =""
     v_raw_data ="N"
     if !params[:p_raw_data].nil? and !params[:p_raw_data].blank?
         v_raw_data = params[:p_raw_data]
     end 
       # for search dropdown
        @q_forms = Questionform.where("current_tab in (?)",@current_tab).where("status_flag in (?)","Y")
        @q_form_default = @q_forms.where("tab_default_yn='Y'")

     q_form = Questionform.where("current_tab in (?)",@current_tab).where("tab_default_yn in (?)","Y")
     @q_form_id = q_form[0].id.to_s #  12   # use in data_search_q_data
     if !params[:lh_search].nil? and !params[:lh_search][:questionform_id].blank?
           @q_form_id = params[:lh_search][:questionform_id]
     end
   
     #puts "AAAAAAA q_form_id="+q_form_id.to_s

     if params[:lh_search].nil?
          params[:lh_search] =Hash.new  
          # params[:lh_search][:lh_status] = "yes" 
     end

     scan_procedure_array = []
     scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)   

      hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
     # swapping out q_form description if different name linked to scan_procedures 
     @q_forms.each do |f|
            if !params[:lh_search][:scan_procedure_id].blank?
                @spformdisplays = Questionformnamesp.where("questionform_id in (?) and scan_procedure_id in (?) and scan_procedure_id in (?)",f.id,scan_procedure_array,params[:lh_search][:scan_procedure_id])

            else
                @spformdisplays = Questionformnamesp.where("questionform_id in (?) and scan_procedure_id in (?) ",f.id,scan_procedure_array)
            end     
            if !@spformdisplays.nil?
              v_form_name = @spformdisplays.sort_by(&:form_name).collect {|sp| sp.form_name }.join("|")
              v_form_name_array = v_form_name.split("|")
              v_form_name_array = v_form_name_array.uniq
              v_form_name = v_form_name_array.join(", ")
              if !v_form_name.empty?
                  f.description = f.description+","+v_form_name
              end
            end
     end
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
                                                and scan_procedure_id in ("+params[:lh_search][:scan_procedure_id].join(',').gsub(/[;:'"“”()=<>]/, '')+"))"
         @scan_procedures = ScanProcedure.where("id in (?)",params[:lh_search][:scan_procedure_id])
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end

      if !params[:lh_search][:enumber].blank?
        params[:lh_search][:enumber] = params[:lh_search][:enumber].gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
        if params[:lh_search][:enumber].include?(',') # string of enumbers
         v_enumber =  params[:lh_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
         v_enumber = v_enumber.gsub(/,/,"','")
          condition ="   blooddraws.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
           where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
           and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:'"“”()=<>]/, '')+"'))"
          
        else
         condition ="   blooddraws.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
          where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
          and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:lh_search][:enumber].gsub(/[;:'"“”()=<>]/, '')+"')))"
        end
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:lh_search][:enumber]
      end      

      if !params[:lh_search][:rmr].blank? 
          condition ="   blooddraws.appointment_id in (select appointments.id from appointments,vgroups
                    where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower('"+params[:lh_search][:rmr].gsub(/[;:'"“”()=<>]/, '')+"')   ))"
                    @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:lh_search][:rmr]
      end

      if !params[:lh_search][:reggieid].blank? 
          condition ="   blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
           where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
           and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                  and participants.reggieid is not NULL and participants.reggieid in ("+params[:lh_search][:reggieid].gsub(/[;:'"“”()=<>]/, '')+") )"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  Reggie ID ("+params[:lh_search][:reggieid]+")"
      end

      if !params[:lh_search][:lh_status].blank? 
          condition =" blooddraws.appointment_id in (select appointments.id from appointments,vgroups
                              where appointments.vgroup_id = vgroups.id and  lower(vgroups.completedblooddraw) in (lower('"+params[:lh_search][:lh_status].gsub(/[;:'"“”()=<>]/, '')+"')   ))"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  LH status "+params[:lh_search][:lh_status]
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
                   and participants.gender is not NULL and participants.gender in ("+params[:lh_search][:gender].gsub(/[;:'"“”()=<>]/, '')+") )"
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
                            and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) >= "+params[:lh_search][:min_age].gsub(/[;:'"“”()=<>]/, '')+"   )"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:lh_search][:min_age]
        elsif params[:lh_search][:min_age].blank? && !params[:lh_search][:max_age].blank?
             condition ="     blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                         and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) <= "+params[:lh_search][:max_age].gsub(/[;:'"“”()=<>]/, '')+"   )"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:lh_search][:max_age]
        elsif !params[:lh_search][:min_age].blank? && !params[:lh_search][:max_age].blank?
           condition ="      blooddraws.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                           and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                           and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                       and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) between "+params[:lh_search][:min_age].gsub(/[;:'"“”()=<>]/, '')+" and "+params[:lh_search][:max_age].gsub(/[;:'"“”()=<>]/, '')+"   )"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:lh_search][:min_age]+" and "+params[:lh_search][:max_age]
        end
        # trim leading ","
        params["search_criteria"] = params["search_criteria"].sub(", ","")
        # pass to download file?

  
   # adjust columns and fields for html vs xls
   #request_format = request.formats.to_s 
   v_request_format_array = request.formats
    request_format = v_request_format_array[0]
   @html_request ="Y"

   case  request_format
     when "[text/html]","text/html" then  # application/html ?
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
        @left_join_vgroup = []
#puts "ffffffff @left_join="+@left_join.to_s
        @results = self.run_search_q_data(@tables,@fields ,@left_join,@left_join_vgroup,v_raw_data)  # in the application controller
        @column_number =   @column_headers.size
   end
       
       
  @results_total = @results  # pageination makes result count wrong
  t = Time.now 
     v_display_form_name = ""
     if !params[:lh_search][:scan_procedure_id].blank?
        @spformdisplays = Questionformnamesp.where("questionform_id in (?) and scan_procedure_id in (?) and scan_procedure_id in (?)",@q_form_id,scan_procedure_array,params[:lh_search][:scan_procedure_id])
      else
        @spformdisplays = Questionformnamesp.where("questionform_id in (?) and scan_procedure_id in (?) ",@q_form_id,scan_procedure_array)
      end     
      if !@spformdisplays.nil?
         v_form_name = @spformdisplays.sort_by(&:form_name).collect {|sp| sp.form_name }.join(", ")
          if !v_form_name.empty?
             v_display_form_name = v_form_name
          else
              q_form = Questionform.find(@q_form_id)
              v_display_form_name = q_form.description
          end
      end

  @export_file_title =v_display_form_name+" Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
     @csv_array = []
    @results_tmp_csv = []
    @results_tmp_csv.push(@export_file_title)
    @csv_array.push(@results_tmp_csv )
    @csv_array.push( @column_headers)
    @results.each do |result| 
       @results_tmp_csv = []
       for i in 0..@column_number-1  # results is an array of arrays%>
          @results_tmp_csv.push(result[i])
       end 
       @csv_array.push(@results_tmp_csv)
    end 
    if !@csv_array.nil?
        @csv_str = @csv_array.inject([]) { |csv, row|  csv << CSV.generate_line(row) }.join("") 
    end 
  ### LOOK WHERE TITLE IS SHOWING UP
  @collection_title = v_display_form_name+' All Lab Health appts'

  respond_to do |format|
    format.xls # lh_search.xls.erb
    format.csv { send_data @csv_str }
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

    def blooddraw_pdf
      v_q_data_form_id = ""
      v_q_form_id = ""
      if !params[:q_form_id].nil? and !params[:q_data_form_id].blank? and !params[:id].blank?
         v_q_data_form_id = params[:q_data_form_id]
         v_q_form_id = params[:q_form_id]
         # need to evaluate that user has perms on q_data_form_id

           # mimicing show
         scan_procedure_array = []
         scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
         @blooddraw = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                       and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

     @appointment = Appointment.find(@blooddraw.appointment_id)
     @vgroup = Vgroup.find(@appointment.vgroup_id)
     @questionform =Questionform.find(v_q_form_id)

      puts "zzzzz v_q_data_form_id="+v_q_data_form_id.to_s+"  v_q_form_id="+v_q_form_id.to_s

      # HOW much of to do here vs in questionform model
      pdf = @questionform.displayform_pdf(v_q_data_form_id,v_q_form_id,@appointment,@vgroup)
      respond_to do |format|
         format.html # show.html.erb
         format.xml  { render :xml => @participant }
         format.pdf do
           send_data pdf.render,
           filename: "export.pdf",
           type: 'application/pdf',
           disposition: 'inline'
         end
      end

     end # params ok
    end

  # GET /blooddraws/1
  # GET /blooddraws/1.xml
  def show
     @current_tab = "blooddraws"
     scan_procedure_array = []
     scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)

      hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
     @blooddraw = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                       and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

     @appointment = Appointment.find(@blooddraw.appointment_id)
     @vgroup = Vgroup.find(@appointment.vgroup_id)
     sp_list = @vgroup.scan_procedures.collect {|sp| sp.id}.join(",")
     sp_array =[]
     sp_array = sp_list.split(',').map(&:to_i)

     q_form = Questionform.where("current_tab in (?)",@current_tab).where("tab_default_yn in (?)","Y")
     q_form_id = q_form[0].id # 12
     if !params[:appointment].nil? and !params[:appointment][:questionform_id_list].blank?
          q_form_id  = params[:appointment][:questionform_id_list]
          q_form = Questionform.find(q_form_id)
     end
     @q_form_id = q_form_id
     @q_forms = Questionform.where("current_tab in (?)",@current_tab).where("status_flag in (?)","Y").where("questionforms.id not in (select questionform_id from questionform_scan_procedures)
                                                                 or (questionforms.id in 
                                                                         (select questionform_id from questionform_scan_procedures where  include_exclude ='include' and scan_procedure_id in ("+sp_array.join(',')+"))
                                                                      and
                                                                  questionforms.id  not in 
                                              (select questionform_id from questionform_scan_procedures where include_exclude ='exclude' and scan_procedure_id in ("+sp_array.join(',')+")))")
      # swapping out q_form description if different name linked to scan_procedures 
     @q_forms.each do |f|
            @spformdisplays = Questionformnamesp.where("questionform_id in (?) and scan_procedure_id in (?)",f.id,sp_array)
            if !@spformdisplays.nil?
              v_form_name = @spformdisplays.sort_by(&:form_name).collect {|sp| sp.form_name }.join(", ")
              if !v_form_name.empty?
                  f.description = v_form_name
              end
            end
     end
     @q_form_default = @q_forms.where("tab_default_yn='Y'")

     if   !@appointment.questionform_id_list.blank? and (params[:appointment].nil?  or (!params[:appointment].nil? and  params[:appointment][:questionform_id_list].blank?) )
            q_form_id_array = (@appointment.questionform_id_list).split(",")
            q_form_id  = q_form_id_array[0]
     end                             

     @blooddraws = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                 appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                and appointments.appointment_date between ? and ?
                                and scan_procedure_id in (?))", @appointment.appointment_date-2.month,@appointment.appointment_date+2,scan_procedure_array).to_a

     idx = @blooddraws.index(@blooddraw)
     @older_blooddraw = idx + 1 >= @blooddraws.size ? nil : @blooddraws[idx + 1]
     @newer_blooddraw = idx - 1 < 0 ? nil : @blooddraws[idx - 1]

     @participant = @vgroup.try(:participant)
     @enumbers = @vgroup.enrollments

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
 	  @scanprocedures = ScanProcedure.where("id in (?)",sp_array)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @blooddraw }
    end
  end

  # GET /blooddraws/new
  # GET /blooddraws/new.xml
  def new
         hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
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
        sp_list = @vgroup.scan_procedures.collect {|sp| sp.id}.join(",")
        sp_array =[]
        sp_array = sp_list.split(',').map(&:to_i)

        @q_forms = Questionform.where("current_tab in (?)",@current_tab).where("status_flag in (?)","Y").where("questionforms.id not in (select questionform_id from questionform_scan_procedures)
                                                                 or (questionforms.id in 
                                                                         (select questionform_id from questionform_scan_procedures where  include_exclude ='include' and scan_procedure_id in ("+sp_array.join(',')+"))
                                                                      and
                                                                  questionforms.id  not in 
                                              (select questionform_id from questionform_scan_procedures where include_exclude ='exclude' and scan_procedure_id in ("+sp_array.join(',')+")))")
     
        @q_form_default = @q_forms.where("tab_default_yn='Y'")
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @blooddraw }
    end
  end

  # GET /blooddraws/1/edit
  def edit
    @current_tab = "blooddraws"
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
      hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @blooddraw = Blooddraw.where("blooddraws.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @appointment = Appointment.find(@blooddraw.appointment_id) 
    @vgroup = Vgroup.find(@appointment.vgroup_id)
    @enumbers = @vgroup.enrollments

    q_form = Questionform.where("current_tab in (?)",@current_tab).where("tab_default_yn in (?)","Y")
    q_form_id = q_form[0].id # 12
    if !params[:appointment].nil? and !params[:appointment][:questionform_id_list].blank?
          q_form_id  = params[:appointment][:questionform_id_list]
          q_form = Questionform.find(q_form_id)
    elsif   !@appointment.questionform_id_list.blank?
          q_form_id_array = (@appointment.questionform_id_list).split(",")
          q_form_id  = q_form_id_array[0]
          q_form = Questionform.find(q_form_id)
    end
    # NEED TO ADD LIMIT BY SCAN PROCEDURE
    sp_list = @vgroup.scan_procedures.collect {|sp| sp.id}.join(",")
    sp_array =[]
    sp_array = sp_list.split(',').map(&:to_i)

    @q_forms = Questionform.where("current_tab in (?)",@current_tab).where("status_flag in (?)","Y").where("questionforms.id not in (select questionform_id from questionform_scan_procedures)
                                                                 or (questionforms.id in 
                                                                         (select questionform_id from questionform_scan_procedures where  include_exclude ='include' and scan_procedure_id in ("+sp_array.join(',')+"))
                                                                      and
                                                                  questionforms.id  not in 
                                              (select questionform_id from questionform_scan_procedures where include_exclude ='exclude' and scan_procedure_id in ("+sp_array.join(',')+")))")
     
      # swapping out q_form description if different name linked to scan_procedures 
     @q_forms.each do |f|
            @spformdisplays = Questionformnamesp.where("questionform_id in (?) and scan_procedure_id in (?)",f.id,sp_array)
            if !@spformdisplays.nil?
              v_form_name = @spformdisplays.sort_by(&:form_name).collect {|sp| sp.form_name }.join(", ")
              if !v_form_name.empty?
                  f.description = v_form_name
              end
            end
     end
    @q_form_default = @q_forms.where("tab_default_yn='Y'")
    
    @q_data_forms = QDataForm.where("questionform_id="+q_form_id.to_s+" and appointment_id in (?)",@appointment.id)
    @q_data_form = @q_data_forms[0]
    #params[:appointment_id] = @blooddraw.appointment_id
    @questionform =Questionform.find(q_form_id)
     if @q_data_form.nil?
        @q_data_form = QDataForm.new
        @q_data_form.appointment_id = @appointment.id
        @q_data_form.questionform_id = q_form_id
        @q_data_form.save
    end

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
	  @scanprocedures = ScanProcedure.where("id in (?)",sp_array)
  end

  # POST /blooddraws
  # POST /blooddraws.xml
  def create
   @current_tab = "blooddraws"
   q_form = Questionform.where("current_tab in (?)",@current_tab).where("tab_default_yn in (?)","Y")
   q_form_id = q_form[0].id # 12
   if !params[:appointment].nil? and !params[:appointment][:questionform_id_list].blank?
          q_form_id = params[:appointment][:questionform_id_list]
   end
   scan_procedure_array = []
   scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
      hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end

  @blooddraw = Blooddraw.new# (blooddraw_params)#params[:blooddraw])
  
  appointment_date = nil
  if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
       appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
  end
  
  vgroup_id =params[:new_appointment_vgroup_id]
  @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(vgroup_id)
  @appointment = Appointment.new
  if !params[:appointment][:questionform_id_list].blank?
          @appointment.questionform_id_list = params[:appointment][:questionform_id_list]
  end
  @appointment.vgroup_id = vgroup_id
  @appointment.appointment_type ='blood_draw'
  @appointment.appointment_date =appointment_date
  @appointment.comment = params[:appointment][:comment]
  if !params[:appointment].nil? and !params[:appointment][:appointment_coordinator].nil?
            @appointment.appointment_coordinator = params[:appointment][:appointment_coordinator]
  end
  @appointment.user = current_user
  if !@vgroup.participant_id.blank?
    @participant = Participant.find(@vgroup.participant_id)
    if !@participant.dob.blank?
       @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).round(2)
    end
  end
  @appointment.save
  @blooddraw.appointment_id = @appointment.id

   # puts  @blooddraw.appointment_id.to_s
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

      hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end

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
          #if @blooddraw.update(blooddraw_params) #params[:blooddraw]) #, :without_protection => true)
            @appointment = Appointment.find(@blooddraw.appointment_id)
            @vgroup = Vgroup.find(@appointment.vgroup_id)
            @appointment.comment = params[:appointment][:comment]
            if !params[:appointment].nil? and !params[:appointment][:appointment_coordinator].nil?
                @appointment.appointment_coordinator = params[:appointment][:appointment_coordinator]
            end
            @appointment.appointment_date =appointment_date
            if !@vgroup.participant_id.blank?
              @participant = Participant.find(@vgroup.participant_id)
              if !@participant.dob.blank?
                 @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).round(2)
              end
            end

            if !params[:appointment][:questionform_id_list].blank?
              if @appointment.questionform_id_list.nil?
                  @appointment.questionform_id_list =  params[:appointment][:questionform_id_list]
               else
                 v_appointment_questionform_id_array = @appointment.questionform_id_list.split(",")
                 if !v_appointment_questionform_id_array.include?(params[:appointment][:questionform_id_list])
                     v_appointment_questionform_id_array.push(params[:appointment][:questionform_id_list])
                     @appointment.questionform_id_list = v_appointment_questionform_id_array.join(",")
                 end
                end
            end

            @appointment.save
            @vgroup.completedblooddraw = params[:vgroup][:completedblooddraw]
       if   @vgroup.save
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

      hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
     
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
  private
    def set_blooddraw
       @blooddraw = Blooddraw.find(params[:id])
    end   
    # not really used
   def blooddraw_params
          params.require(:blooddraw).permit(:appointment_coordinator,:comment) #(:blooddraw).permit(:weight_kg,:height_inches,:temp_fkvisitid,:temp_fklabhealthid,:blooddrawnote,:enteredbloodwho,:enteredblooddate,:enteredblood,:completedblooddraw_moved_to_vgroups,:appointment_id,:id)
   end  
   def lh_search_params
          params.require(:lh_search).permit!
   end

end


