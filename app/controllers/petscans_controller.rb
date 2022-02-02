# encoding: utf-8
class PetscansController < ApplicationController
  # GET /petscans
  # GET /petscans.xml
 require 'csv'
  def petscan_search # OLD -- use pet_search
     @current_tab = "petscans"
     params["search_criteria"] =""

     if params[:petscan_search].nil?
          params[:petscan_search] =Hash.new  
     end
     
     scan_procedure_array = []
     scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)   
           hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
     
#    @petscans = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
#                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
#    and scan_procedure_id in (?))", scan_procedure_array).all
#     sql = "select * from petscans inner join  appointments on appointments.id = petscans.appointment_id order by appointment_date desc"
#      @search = Petscan.find_by_sql(sql)
#     @search = Petscan.where("petscans.appointment_id in (select appointments.id from appointments)").all
      @search = Petscan.search(params[:search])    # parms search makes something which works with where?
     # need to find max number of petfiles for this mix of sp's

      if !params[:petscan_search][:scan_procedure_id].blank?
         @search =@search.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                and scan_procedure_id in (?))",params[:petscan_search][:scan_procedure_id])
         @scan_procedures = ScanProcedure.where("id in (?)",params[:petscan_search][:scan_procedure_id])
         params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end
      
      if !params[:petscan_search][:ecatfilename].blank?
         var = "%"+params[:petscan_search][:ecatfilename].downcase+"%"
         @search =@search.where(" petscans.ecatfilename  like ? ", var)
          params["search_criteria"] = params["search_criteria"] +", Ecat file "+params[:petscan_search][:ecatfilename]
      end
      
      if !params[:petscan_search][:enumber].blank?
         @search =@search.where(" petscans.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
          where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
          and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower(?)))",params[:petscan_search][:enumber])
          params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:petscan_search][:enumber]
      end      

      if !params[:petscan_search][:rmr].blank? 
          @search = @search.where(" petscans.appointment_id in (select appointments.id from appointments,vgroups
                    where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower(?)   ))",params[:petscan_search][:rmr])
          params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:petscan_search][:rmr]
      end


       #  build expected date format --- between, >, < 
       v_date_latest =""
       #want all three date parts
      
       if !params[:petscan_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:petscan_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:petscan_search]["#{'latest_timestamp'}(3i)"].blank?
            v_date_latest = params[:petscan_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:petscan_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:petscan_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
       end

       v_date_earliest =""
       #want all three date parts
  
       if !params[:petscan_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:petscan_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:petscan_search]["#{'earliest_timestamp'}(3i)"].blank?
             v_date_earliest = params[:petscan_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:petscan_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:petscan_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
        end

       if v_date_latest.length>0 && v_date_earliest.length >0
         @search = @search.where(" petscans.appointment_id in (select appointments.id from appointments where appointments.appointment_date between ? and ? )",v_date_earliest,v_date_latest)
         params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
       elsif v_date_latest.length>0
         @search = @search.where(" petscans.appointment_id in (select appointments.id from appointments where appointments.appointment_date < ?  )",v_date_latest)
          params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
       elsif  v_date_earliest.length >0
         @search = @search.where(" petscans.appointment_id in (select appointments.id from appointments where appointments.appointment_date > ? )",v_date_earliest)
          params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
        end

        if !params[:petscan_search][:gender].blank?
           @search =@search.where(" petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
            where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
            and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                   and participants.gender is not NULL and participants.gender in (?) )", params[:petscan_search][:gender])
            if params[:petscan_search][:gender] == 1
               params["search_criteria"] = params["search_criteria"] +",  sex is Male"
            elsif params[:petscan_search][:gender] == 2
               params["search_criteria"] = params["search_criteria"] +",  sex is Female"
            end
        end   

        if !params[:petscan_search][:min_age].blank? && params[:petscan_search][:max_age].blank?
            @search = @search.where("  petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                            and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) >= ?   )",params[:petscan_search][:min_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:petscan_search][:min_age]
        elsif params[:petscan_search][:min_age].blank? && !params[:petscan_search][:max_age].blank?
             @search = @search.where("  petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                         and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) <= ?   )",params[:petscan_search][:max_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:petscan_search][:max_age]
        elsif !params[:petscan_search][:min_age].blank? && !params[:petscan_search][:max_age].blank?
           @search = @search.where("   petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                           and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                           and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                       and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) between ? and ?   )",params[:petscan_search][:min_age],params[:petscan_search][:max_age])
          params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:petscan_search][:min_age]+" and "+params[:petscan_search][:max_age]
        end
        # trim leading ","
        params["search_criteria"] = params["search_criteria"].sub(", ","")
        # pass to download file?
        
    @search =  @search.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                               appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                               and scan_procedure_id in (?))", scan_procedure_array)
 
    @petscans =  @search.page(params[:page])

    ### LOOK WHERE TITLE IS SHOWING UP
    @collection_title = 'All Petscan appts'

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @petscans }
    end
  end
  def pet_after_delete
     self.pet_search()
  end
  def pet_search  
    if(!params["pet_search"].blank?)
       @pet_search_params  =pet_search_params()
    end 
     scan_procedure_array = []
     scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)   # applied in application search
           hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
      # make @conditions from search form input, access control in application controller run_search
      @conditions = []
      v_petfile_conditions = [] # need to find max number of petfiles - some have 1, some 2 , etc, for this mix of scan procedures
         # just using sp as an approximation
      @current_tab = "petscans"
      params["search_criteria"] =""

      if params[:pet_search].nil?
           params[:pet_search] =Hash.new  
           params[:pet_search][:pet_status] = "yes"
      end

       v_petfile_condition = " petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                and scan_procedure_id in ("+scan_procedure_array.join(",")+"))"
       v_petfile_conditions.push(v_petfile_condition)

      if !params[:pet_search][:scan_procedure_id].blank?
         condition =" petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                and scan_procedure_id in ("+params[:pet_search][:scan_procedure_id].join(',').gsub(/[;:'"“”()=<>]/, '')+"))"
         @conditions.push(condition)
         v_petfile_conditions.push(condition)
         @scan_procedures = ScanProcedure.where("id in (?)",params[:pet_search][:scan_procedure_id])
         params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end
      # moved file_name to petfiles from petscans
      if !params[:pet_search][:file_name].blank?
          var = "%"+params[:pet_search][:file_name].downcase+"%"
          condition =" petscans.id in ( select petfiles.petscan_id from petfiles where petfiles.file_name  like '"+var.gsub(/[;:'"“”()=<>]/, '')+"' )"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +", File name "+params[:pet_search][:file_name]
      end
      
      if !params[:pet_search][:enumber].blank?
        params[:pet_search][:enumber] = params[:pet_search][:enumber].gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
        if params[:pet_search][:enumber].include?(',') # string of enumbers
         v_enumber =  params[:pet_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
         v_enumber = v_enumber.gsub(/,/,"','")
           condition =" petscans.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
           where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
           and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"“”()=<>]/, '')+"'))"
          
        else
          condition =" petscans.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
          where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
          and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:pet_search][:enumber].gsub(/[;:'"“”()=<>]/, '')+"')))"
        end
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:pet_search][:enumber]
      end      

      if !params[:pet_search][:rmr].blank? 
          condition =" petscans.appointment_id in (select appointments.id from appointments,vgroups
                    where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower('"+params[:pet_search][:rmr].gsub(/[;:'"“”()=<>]/, '')+"')   ))"
          @conditions.push(condition)           
          params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:pet_search][:rmr]
      end   

      if !params[:pet_search][:reggieid].blank? 
          reggieid_param = params[:pet_search][:reggieid]
          if reggieid_param.include?(',')
            #this should solve the trailing comma problem
            reggieid_param = reggieid_param.split(',').select { |x| !x.blank? }.collect { |x| x.strip || x }.join(',')
          end
          condition ="  petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
           where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
           and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                  and participants.reggieid is not NULL and participants.reggieid in ("+reggieid_param.gsub(/[;:'"“”()=<>]/, '')+") )"
           @conditions.push(condition)           
          params["search_criteria"] = params["search_criteria"] +",  Reggie ID in ("+reggieid_param+") "
       end   
      
      if !params[:pet_search][:pet_status].blank? 
          condition =" petscans.appointment_id in (select appointments.id from appointments,vgroups
                              where appointments.vgroup_id = vgroups.id and  lower(vgroups.transfer_pet) in (lower('"+params[:pet_search][:pet_status].gsub(/[;:'"“”()=<>]/, '')+"')   ))"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  Pet status "+params[:pet_search][:pet_status]
      end

      if !params[:pet_search][:lookup_pettracer_id].blank? 
          condition ="  petscans.lookup_pettracer_id in ("+params[:pet_search][:lookup_pettracer_id].gsub(/[;:'"“”()=<>]/, '')+"   )"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  Tracer "+LookupPettracer.find(params[:pet_search][:lookup_pettracer_id]).description
      end

      #  build expected date format --- between, >, < 
      v_date_latest =""
      #want all three date parts
      if !params[:pet_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:pet_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:pet_search]["#{'latest_timestamp'}(3i)"].blank?
           v_date_latest = params[:pet_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:pet_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:pet_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
      end
      v_date_earliest =""
      #want all three date parts
      if !params[:pet_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:pet_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:pet_search]["#{'earliest_timestamp'}(3i)"].blank?
            v_date_earliest = params[:pet_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:pet_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:pet_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
       end
      v_date_latest = v_date_latest.gsub(/[;:'"()=<>]/, '')
      v_date_earliest = v_date_earliest.gsub(/[;:'"()=<>]/, '')
      if v_date_latest.length>0 && v_date_earliest.length >0
        condition ="  petscans.appointment_id in (select appointments.id from appointments where appointments.appointment_date between '"+v_date_earliest+"' and '"+v_date_latest+"' )"
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
      elsif v_date_latest.length>0
        condition ="  petscans.appointment_id in (select appointments.id from appointments where appointments.appointment_date < '"+v_date_latest+"'  )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
      elsif  v_date_earliest.length >0
        condition ="  petscans.appointment_id in (select appointments.id from appointments where appointments.appointment_date > '"+v_date_earliest+"' )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
       end

       if !params[:pet_search][:gender].blank?
          condition ="  petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
           where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
           and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                  and participants.gender is not NULL and participants.gender in ("+params[:pet_search][:gender].gsub(/[;:'"()=<>]/, '')+") )"
           @conditions.push(condition)
           if params[:pet_search][:gender] == 1
              params["search_criteria"] = params["search_criteria"] +",  sex is Male"
           elsif params[:pet_search][:gender] == 2
              params["search_criteria"] = params["search_criteria"] +",  sex is Female"
           end
       end   

       if !params[:pet_search][:min_age].blank? && params[:pet_search][:max_age].blank?
           condition ="   petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                           and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                           and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                           and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) >= "+params[:pet_search][:min_age].gsub(/[;:'"“”()=<>]/, '')+"   )"
            @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:pet_search][:min_age]
       elsif params[:pet_search][:min_age].blank? && !params[:pet_search][:max_age].blank?
            condition ="   petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                        and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) <= "+params[:pet_search][:max_age].gsub(/[;:'"“”()=<>]/, '')+"   )"
           @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:pet_search][:max_age]
       elsif !params[:pet_search][:min_age].blank? && !params[:pet_search][:max_age].blank?
          condition ="    petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                             where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                          and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                          and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                      and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) between "+params[:pet_search][:min_age].gsub(/[;:'"“”()=<>]/, '')+" and "+params[:pet_search][:max_age].gsub(/[;:'"“”()=<>]/, '')+"   )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:pet_search][:min_age]+" and "+params[:pet_search][:max_age]
       end
       # trim leading ","
       params["search_criteria"] = params["search_criteria"].sub(", ","")

      v_petfile_conditions.push("petscans.id = petfiles.petscan_id")
      sql_petfile_cnt = "select max(cnt) from 
     (select    count(petfiles.id) cnt, petscans.id from petfiles, petscans where "+v_petfile_conditions.join(" and ")+ " group by petscans.id) t2"
      connection = ActiveRecord::Base.connection();
      results_petfile_cnt= connection.execute(sql_petfile_cnt) 
       @v_petfile_cnt = 0
       @v_petfile_cnt = results_petfile_cnt.first[0]
       # IS THIS VISIBLE FROM self.run_search?????
       # ADD COLUMNS -- END OF LIST
       # REMOVE file,path fields , insert extra petfile(s) columns if 

       # adjust columns and fields for html vs xls
       #request_format = request.formats.to_s 
       v_request_format_array = request.formats
        request_format = v_request_format_array[0]
       @html_request ="Y"
       case  request_format
         when "[text/html]","text/html" then # ? application/html
           @column_headers = ['Date','Protocol','Enumber','RMR','Tracer','Note','Pet status','Appt Note'] # need to look up values
          if !@v_petfile_cnt.nil?
            i = @v_petfile_cnt
            k = 1
            while i > 0
               @column_headers.push("Pet_file_"+k.to_s)
               @column_headers.push("Pet_path_"+k.to_s)
               @column_headers.push("Pet_note_"+k.to_s)
               k = k + 1
              i = i -1
            end
          end
               # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
           @column_number =   @column_headers.size
           @fields =["lookup_pettracers.name pettracer",
                 "petscans.petscan_note","vgroups.transfer_pet","petscans.id","appointments.comment"] # vgroups.id vgroup_id always first, include table name
            @left_join = ["LEFT JOIN lookup_pettracers on petscans.lookup_pettracer_id = lookup_pettracers.id",
                    "LEFT JOIN employees on petscans.enteredpetscanwho = employees.id"] # left join needs to be in sql right after the parent table!!!!!!!
         else    
           @html_request ="N"          
            @column_headers = ['Date','Protocol','Enumber','RMR','Tracer','Dose','Injection Time','Scan Start','Scanner Location','Scanner Name','Petscan file good to process','Note','Acquisition Duration','Pet status','Pre_BP Systol','Pre_BP Diastol','Pre_Pulse','Blood Glucose','Weight','Height','Post_BP Systol','Post_BP Diastol','Post_Pulse','Age at Appt','Appt Note'] # need to look up values
          if !@v_petfile_cnt.nil?
            i = @v_petfile_cnt
            k = 1
            while i > 0
               @column_headers.push("Pet_file_"+k.to_s)
               @column_headers.push("Pet_path_"+k.to_s)
               @column_headers.push("Pet_note_"+k.to_s)
              k = k + 1
              i = i -1
            end
           end

                  # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
            @column_number =   @column_headers.size
            @fields =["lookup_pettracers.name pettracer","petscans.netinjecteddose",
                    "time_format(timediff( time(petscans.injecttiontime),subtime(utc_time(),time(localtime()))),'%H:%i')",
                    "time_format(timediff( time(scanstarttime),subtime(utc_time(),time(localtime()))),'%H:%i')",
                    "petscans.scanner_location","petscans.scanner_name","petscans.good_to_process_flag",
                    "petscans.petscan_note","petscans.range","vgroups.transfer_pet","vitals.bp_systol","vitals.bp_diastol","vitals.pulse","vitals.bloodglucose","vitals.weight","vitals.height","vitals_post.bp_systol as bp_systol_post","vitals_post.bp_diastol as bp_diastol_post","vitals_post.pulse as pulse_post","appointments.age_at_appointment","petscans.id","appointments.comment"] # vgroups.id vgroup_id always first, include table name 
            @left_join = ["LEFT JOIN lookup_pettracers on petscans.lookup_pettracer_id = lookup_pettracers.id",
                        "LEFT JOIN vitals on petscans.appointment_id = vitals.appointment_id and vitals.pre_post_flag ='pre' ",
                        "LEFT JOIN vitals as vitals_post on petscans.appointment_id = vitals_post.appointment_id and vitals_post.pre_post_flag ='post'  "] # left join needs to be in sql right after the parent table!!!!!!!   
                        # "LEFT JOIN employees on petscans.enteredpetscanwho = employees.id",             
                 
         end
       @tables =['petscans'] # trigger joins --- vgroups and appointments by default
       @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]

       # ALSO USING in shared.run_pet_preprocessed_data
      if  @html_request =="N" 
           @results = self.run_search_pet  # in the application controller - was self.run_search WHY?- messing the petfiles
      else 
           @results = self.run_search_pet   # in the application controller  # need petscan_id in [0]
      end
      @results_total = @results  # pageination makes result count wrong
      t = Time.now 
      @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
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
    @csv_str = @csv_array.inject([]) { |csv, row|  csv << CSV.generate_line(row) }.join("")  
      ### LOOK WHERE TITLE IS SHOWING UP
      @collection_title = 'All Petscan appts'
       if v_request_format_array[0] == "application/json"
        @csv_array_json = @csv_array
        @csv_array_json.shift
        @csv_array_json_header = @csv_array_json[0]
        ###@csv_array_json_header.push("vgroup_id")
        @csv_array_json.shift  # deleted the first row
        @json_hash_of_hash = Hash[]
        @json_array_of_hash = Array[]
        @csv_array_json.each do |item|
          @h = Hash[]
          @h2 = Hash[]
          v_cnt = 0
          @csv_array_json_header.each do |header_col|
            ###@h[v_cnt.to_s+"_"+header_col] = item[v_cnt]
            @h[header_col] = item[v_cnt]
            v_cnt = v_cnt + 1
         end
         #@json_hash_of_hash[item[v_cnt-1]]= @h
         @h2["petscan"]= @h
         @json_array_of_hash.push(@h2)
        end
     end
      respond_to do |format|
        format.xls # pet_search.xls.erb
        format.csv { send_data @csv_str }
        format.xml  { render :xml => @results }    # actually redefined in the xls page    
        format.json { send_data @json_array_of_hash.to_json}
        format.html {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)} # pet_search.html.erb
      end
    end



  # GET /petscans/1
  # GET /petscans/1.xml
  def show
    @current_tab = "petscans"
    scan_procedure_array = []
    scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
     
    @petscan = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @petfiles = Petfile.where("petscan_id in (?)",@petscan.id)

    @appointment = Appointment.find(@petscan.appointment_id)                            

    @petscans = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                               and appointments.appointment_date between ? and ?
                               and scan_procedure_id in (?))", @appointment.appointment_date-2.month,@appointment.appointment_date+2,scan_procedure_array).load.to_a

    idx = @petscans.index(@petscan)
    @older_petscan = idx + 1 >= @petscans.size ? nil : @petscans[idx + 1]
    @newer_petscan = idx - 1 < 0 ? nil : @petscans[idx - 1]
    
    @vgroup = Vgroup.find(@appointment.vgroup_id)
    @participant = @vgroup.try(:participant)
    @enumbers = @vgroup.enrollments

    # get tracer size array for the scan procedures petscan_tracer_file_size   = tracer_id:size|tracer_id:size| etc
    @petscan_tracer_file_size = {}
    @petscan_tracer_file_size_multiple = {}
    v_scan_procedures = ScanProcedure.where("scan_procedures.id in ( select scan_procedure_id from scan_procedures_vgroups where vgroup_id in (?))", @vgroup.id) 
    v_scan_procedures.each do |sp|
        if !sp.petscan_tracer_file_size.nil?
              v_tmp_tracer_size = sp.petscan_tracer_file_size.split("|")
              v_tmp_tracer_size.each do |tr|
                v_tmp_size = tr.split(":")
                @petscan_tracer_file_size[v_tmp_size[0]] = v_tmp_size[1]
                if @petscan_tracer_file_size_multiple[v_tmp_size[0]].nil?
                   @petscan_tracer_file_size_multiple[v_tmp_size[0]] = [v_tmp_size[1]]
                else
                  @petscan_tracer_file_size_multiple[v_tmp_size[0]] = @petscan_tracer_file_size_multiple[v_tmp_size[0]].push(v_tmp_size[1])
                end
              end
        end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @petscan }
    end
  end

  # GET /petscans/new
  # GET /petscans/new.xml
  def new
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @current_tab = "petscans"
    @petscan = Petscan.new
    @petfiles = Petfile.where("petscan_id in (?)",@petscan.id) 
    vgroup_id = params[:id]
    @vgroup = Vgroup.find(vgroup_id)
    @enumbers = @vgroup.enrollments
    params[:new_appointment_vgroup_id] = vgroup_id
    @appointment = Appointment.new
    @appointment.vgroup_id = vgroup_id
    @appointment.appointment_date = (Vgroup.find(vgroup_id)).vgroup_date
    @appointment.appointment_type ='pet_scan'
#    @appointment.save  --- save in create step

    @petscan.appointment_id = @appointment.id
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @petscan }
    end
  end

  # GET /petscans/1/edit
  def edit
    #puts "edit (#{__LINE__}):"+ params.to_s
     @current_tab = "petscans"
     scan_procedure_array = []
     scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
           hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
     @petscan = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                       and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
     @petfiles = Petfile.where("petscan_id in (?)",@petscan.id) 
     @appointment = Appointment.find(@petscan.appointment_id) 
     @vgroup = Vgroup.find(@appointment.vgroup_id)
     @enumbers = @vgroup.enrollments
  end

  # POST /petscans
  # POST /petscans.xml
  def create  
     v_offset = Time.zone_offset('CST') 
     v_offset = (v_offset*(-1))/(60*60) # mess with storing date as local in db - but shifting to utc
     @current_tab = "petscans"
     scan_procedure_array = []
     scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
           hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @petscan = Petscan.new(petscan_params)#params[:petscan])
     v_exclude_path_array = []
    appointment_date = nil
    params[:date][:injectiont][0]="1899"
    params[:date][:injectiont][1]="12"
    params[:date][:injectiont][2]="30"

    params[:date][:scanstartt][0]="1899"
    params[:date][:scanstartt][1]="12"
    params[:date][:scanstartt][2]="30"  


    params[:date][:collection_time][0]="1899"
    params[:date][:collection_time][1]="12"
    params[:date][:collection_time][2]="30" 
    params[:date][:collection_time_post][0]="1899"
    params[:date][:collection_time_post][1]="12"
    params[:date][:collection_time_post][2]="30" 

    if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
         appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
        #params[:date][:injectiont][0]=params[:appointment]["#{'appointment_date'}(1i)"]
        #params[:date][:injectiont][1]=params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")
        #params[:date][:injectiont][2]=params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
        #params[:date][:scanstartt][0]=params[:appointment]["#{'appointment_date'}(1i)"]
        #params[:date][:scanstartt][1]=params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")
        #params[:date][:scanstartt][2]=params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")

    end
    
    injectiontime = nil
    if !params[:date][:injectiont][0].blank? && !params[:date][:injectiont][1].blank? && !params[:date][:injectiont][2].blank? && !params[:date][:injectiont][3].blank? && !params[:date][:injectiont][4].blank?
      params[:date][:injectiont][3]  = ((params[:date][:injectiont][3].to_i)+v_offset).to_s  
      injectiontime =  params[:date][:injectiont][0]+"-"+params[:date][:injectiont][1]+"-"+params[:date][:injectiont][2]+" "+params[:date][:injectiont][3]+":"+params[:date][:injectiont][4]
     @petscan.injecttiontime = DateTime.strptime(injectiontime, "%Y-%m-%d %H:%M") #injectiontime
    end

     
    scanstarttime = nil
    if !params[:date][:scanstartt][0].blank? && !params[:date][:scanstartt][1].blank? && !params[:date][:scanstartt][2].blank? && !params[:date][:scanstartt][3].blank? && !params[:date][:scanstartt][4].blank?
      params[:date][:scanstartt][3]  = ((params[:date][:scanstartt][3].to_i)+v_offset).to_s 
      scanstarttime =  params[:date][:scanstartt][0]+"-"+params[:date][:scanstartt][1]+"-"+params[:date][:scanstartt][2]+" "+params[:date][:scanstartt][3]+":"+params[:date][:scanstartt][4]
      @petscan.scanstarttime = DateTime.strptime(scanstarttime, "%Y-%m-%d %H:%M") #scanstarttime
    end  
    

    
    vgroup_id =params[:new_appointment_vgroup_id]
    puts "#{vgroup_id} id vgroup id"
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(vgroup_id)
    @appointment = Appointment.new
    @appointment.vgroup_id = vgroup_id
    @appointment.appointment_type ='pet_scan'
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
    @petscan.appointment_id = @appointment.id
    # get sp_id's
    connection = ActiveRecord::Base.connection();
    sql_sp = "select distinct scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id ="+@appointment.vgroup_id.to_s
    results_sp = connection.execute(sql_sp)  
    results_sp.each do |r_sp|
      if (@petscan.ecatfilename).blank?
         @petscan.ecatfilename = @petscan.get_pet_file(r_sp[0], @petscan.lookup_pettracer_id,@vgroup.id)
      end
      if (@petscan.path).blank? and !(@petscan.ecatfilename).blank?
        v_path = @petscan.get_pet_path(r_sp[0], @petscan.ecatfilename, @petscan.lookup_pettracer_id,@vgroup.id)
        if !v_path.blank?
              @petscan.path = v_path

        end
      end
    end
    respond_to do |format|
      if @petscan.save
         @vgroup.transfer_pet = params[:vgroup][:transfer_pet]
          @vgroup.save

          sql_sp = "select distinct scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id ="+@appointment.vgroup_id.to_s
          results_sp = connection.execute(sql_sp) 

          if !params[:petfile].blank? and !params[:petfile][:id].blank? and params[:petfile][:petfile_autodetect] == "Off"
             params[:petfile][:id].each do |pf_id|
               if pf_id == "0" 
                   if !params[:petfile][:file_name][0.to_s].blank? # insert new
                      @petfile = Petfile.new
                      @petfile.petscan_id = @petscan.id
                      @petfile.file_name = params[:petfile][:file_name][0.to_s]
                      @petfile.path =  params[:petfile][:path][0.to_s]
                      @petfile.note =  params[:petfile][:note][0.to_s]
                      @petfile.save
                      if (@petfile.path).blank?
                         results_sp.each do |r_sp|
                            v_petfile_check = Petfile.where("file_name in (?) and petscan_id in (?)", @petfile.file_name,@petscan.id)
                            v_path = @petscan.get_pet_path(r_sp[0], @petfile.file_name, @petscan.lookup_pettracer_id,@appointment.vgroup_id)
                            if !v_petfile_check.nil? and v_petfile_check.length > 0
                                 v_petfile_check.each do |pf_check|
                                    if pf_check.path.blank? and !v_path.blank?
                                       pf_check.path = v_path
                                       pf_check.save
                                    end
                                 end
                            end
                        end 
                   end
                end
          end
       end
     end 
          results_sp.each do |r_sp|
               if !params[:petfile].blank? and !params[:petfile][:petfile_autodetect].blank? and params[:petfile][:petfile_autodetect] == "On"
                     v_keep_looking_for_pet_dicoms = 1
                     v_cnt_escape = 0  # incrment and exit if infinite looping
                     while  v_keep_looking_for_pet_dicoms > 0 # keep looking   
                        v_cnt_escape = v_cnt_escape + 1

                        @petfiles_dicoms_found_array = @petscan.get_pet_dicoms(r_sp[0], @petscan.lookup_pettracer_id,@vgroup.id, v_exclude_path_array)
 
                        if @petfiles_dicoms_found_array.nil? or (!@petfiles_dicoms_found_array.nil? and  @petfiles_dicoms_found_array[0].nil? ) or v_cnt_escape > 10
                            v_keep_looking_for_pet_dicoms = 0
                        else
                          petfile_dicom_dir = File.dirname(@petfiles_dicoms_found_array[0])
                           v_exclude_path_array.push(petfile_dicom_dir)
                        end
                        # [0] is path, [1] is dicom header
                        @petfile_header = nil
                        if !@petfiles_dicoms_found_array.nil? and !@petfiles_dicoms_found_array[0].nil? and !@petfiles_dicoms_found_array[1].nil?
                           @petfile_header = @petfiles_dicoms_found_array[1]
                          # GET FROM NEW FILE DIR STRUCTURE v_file_type = #######
                           v_dicom_scanner_name = @petfile_header['0008,1090'][:value].to_s
                           if v_dicom_scanner_name.include?("Discovery MI")
                                params[:petscan][:scanner_name] = v_dicom_scanner_name
                                @petscan.scanner_name = v_dicom_scanner_name
                                @petscan.save
                             v_dicom_tracer = @petfile_header['0008,103E'][:value].to_s
                             #0008,103E Series Description  AV_1451 30 MIN DYN
                             # need some interpretation
                             if v_dicom_tracer.include?("PiB") # MK6240
                                 v_dicom_tracer_id = 1
                             elsif v_dicom_tracer.include?("FDG") # MK6240
                                 v_dicom_tracer_id = 2
                             elsif v_dicom_tracer.include?("WAY") # MK6240
                                 v_dicom_tracer_id = 3
                             elsif v_dicom_tracer.include?("PBR28") # MK6240
                                 v_dicom_tracer_id = 5
                             elsif v_dicom_tracer.include?("AV45") # MK6240
                                 v_dicom_tracer_id = 6
                             elsif v_dicom_tracer.include?("1451") # AV_1451
                                 v_dicom_tracer_id = 9
                             elsif v_dicom_tracer.include?("NeuraCeq") # MK6240
                                 v_dicom_tracer_id = 10
                             elsif v_dicom_tracer.include?("6240") # MK6240
                                 v_dicom_tracer_id = 11
                             elsif v_dicom_tracer.include?("UCB-J") # MK6240
                                 v_dicom_tracer_id = 12 
                             end
                             v_dicom_timezone_offset = @petfile_header['0008,0201'][:value].to_s
                             #0008,0201 Timezone Offset From UTC  -0600
                              # need to move the injection/scan start time to times in database WITH the GMT displacement
                                # running up against UTC displayed /GMT saved in database 
                                # and the petscan injection/scan start dates ignoring the GMT displacement
                                # need to -06 hours , but from hh - and if displayment > hh, need the 12 back wrap
                             v_dicom_scan_start_time = @petfile_header['0008,0031'][:value].to_s
                             #0008,0031 Series Time. HHMMSS
                             v_dicom_scanner_location = @petfile_header['0008,0080'][:value].to_s    # Institution Name
                             if params[:petscan][:scanner_location].nil? or params[:petscan][:scanner_location].blank? or params[:petscan][:scanner_location].include?("elect")
                                params[:petscan][:scanner_location] = v_dicom_scanner_location
                                @petscan.scanner_location = v_dicom_scanner_location
                                @petscan.save
                             end
                             v_dicom_scan_date = @petfile_header['0008,0020'][:value].to_s  # Study Date
                             # raise warnings

                           #elsif  v_dicom_scanner_name.include?("Biograph Horizon")


                           end
                           # what to do with dicom header
                           # GE vs Siemans machine
                           petfile_dicom_dir = File.dirname(@petfiles_dicoms_found_array[0])
                           v_exclude_path_array.push(petfile_dicom_dir.to_s)
                           v_petfile_check = Petfile.where("file_name in (?) and petscan_id in (?)", petfile_dicom_dir.to_s,@petscan.id)
                            if !v_petfile_check.nil? and v_petfile_check.length > 0
                                 v_petfile_check.each do |pf_check|
                                    if pf_check.path.blank? and !v_path.blank?
                                       pf_check.path = v_path
                                       pf_check.dicom_taghash = @petfile_header
                                       pf_check.save
                                    end
                                 end
                            else
                              v_new_petfile = Petfile.new
                              v_new_petfile.petscan_id = @petscan.id
                              v_new_petfile.file_name = ""
                              v_new_petfile.path =  petfile_dicom_dir.to_s
                              v_new_petfile.dicom_taghash = @petfile_header
                              v_new_petfile.save
                            end
                        end
                       end



                        @petfiles_found = @petscan.get_pet_files(r_sp[0], @petscan.lookup_pettracer_id,@vgroup.id)
                        @petfiles_found.each do |pf_name|  # make sure not already in database with this petscan.id
                            v_petfile_check = Petfile.where("file_name in (?) and petscan_id in (?)", pf_name,@petscan.id)
                            v_path = @petscan.get_pet_path(r_sp[0], pf_name, @petscan.lookup_pettracer_id,@appointment.vgroup_id)
                            if !v_petfile_check.nil? and v_petfile_check.length > 0
                                 v_petfile_check.each do |pf_check|
                                    if pf_check.path.blank? and !v_path.blank?
                                       pf_check.path = v_path
                                       pf_check.save
                                    end
                                 end
                            else
                              v_new_petfile = Petfile.new
                              v_new_petfile.petscan_id = @petscan.id
                              v_new_petfile.file_name = pf_name
                              v_new_petfile.path =  v_path
                              v_new_petfile.save
                            end
                        end
               end
        end

        # # @appointment.save
        # if !params[:vital_id].blank?
        #   @vital = Vital.find(params[:vital_id])
        #   @vital.pulse = params[:pulse]
        #   @vital.bp_systol = params[:bp_systol]
        #   @vital.bp_diastol = params[:bp_diastol]
        #   @vital.bloodglucose = params[:bloodglucose]
        #   @vital.weight = params[:weight]
        #   @vital.height = params[:height]
        #   @vital.pre_post_flag  = 'pre'
        #   @vital.save
        # else
        #   @vital = Vital.new
        #   @vital.appointment_id = @petscan.appointment_id
        #   @vital.pulse = params[:pulse]
        #   @vital.bp_systol = params[:bp_systol]
        #   @vital.bp_diastol = params[:bp_diastol]
        #   @vital.bloodglucose = params[:bloodglucose]
        #   @vital.weight = params[:weight]
        #    @vital.height = params[:height]
        #   @vital.pre_post_flag  = 'pre'
        #   @vital.save      
        # end     
        # if !params[:vital_id_post].blank?
        #   @vital = Vital.find(params[:vital_id_post])
        #   @vital.pulse = params[:pulse_post]
        #   @vital.bp_systol = params[:bp_systol_post]
        #   @vital.bp_diastol = params[:bp_diastol_post]
        #   @vital.pre_post_flag  = 'post'
        #   @vital.save
        # else
        #   @vital = Vital.new
        #   @vital.appointment_id = @petscan.appointment_id
        #   @vital.pulse = params[:pulse_post]
        #   @vital.bp_systol = params[:bp_systol_post]
        #   @vital.bp_diastol = params[:bp_diastol_post]
        #   @vital.pre_post_flag  = 'post'
        #   @vital.save      
        # end    

        @vital = nil
        if !params[:vital_id].blank?
          @vital = Vital.find(params[:vital_id])
        else
          @vital = Vital.new
          @vital.appointment_id = @petscan.appointment_id
        end
        @vital.pulse = params[:pulse]
        @vital.bp_systol = params[:bp_systol]
        @vital.bp_diastol = params[:bp_diastol]
        @vital.respiratory_rate = params[:respiratory_rate]
        @vital.bloodglucose = params[:bloodglucose]
        @vital.weight = params[:weight]
        @vital.height = params[:height]
        @vital.weight_units = params[:weight_units]
        @vital.height_units = params[:height_units]
        @vital.pre_post_flag = 'pre'

        collection_time_dt = nil
        if !params[:date][:collection_time][0].blank? && !params[:date][:collection_time][1].blank? && !params[:date][:collection_time][2].blank? && !params[:date][:collection_time][3].blank? && !params[:date][:collection_time][4].blank?
          #params[:date][:collection_time][3]  = ((params[:date][:collection_time][3].to_i)+v_offset).to_s
          collection_time =  params[:date][:collection_time][0]+"-"+params[:date][:collection_time][1]+"-"+params[:date][:collection_time][2]+" "+params[:date][:collection_time][3]+":"+params[:date][:collection_time][4]
          collection_time_dt = Time.strptime(collection_time, "%Y-%m-%d %H:%M")
        end
        @vital.collection_time = collection_time_dt

        @vital.save   

        @vital_post = nil
        if !params[:vital_id_post].blank?
          @vital_post = Vital.find(params[:vital_id_post])
        else
          @vital_post = Vital.new
          @vital_post.appointment_id = @petscan.appointment_id
        end
        @vital_post.pulse = params[:pulse_post]
        @vital_post.bp_systol = params[:bp_systol_post]
        @vital_post.bp_diastol = params[:bp_diastol_post]
        @vital_post.respiratory_rate = params[:respiratory_rate_post]
        @vital_post.pre_post_flag = 'post'

        collection_time_post_dt = nil
        if !params[:date][:collection_time_post][0].blank? && !params[:date][:collection_time_post][1].blank? && !params[:date][:collection_time_post][2].blank? && !params[:date][:collection_time_post][3].blank? && !params[:date][:collection_time_post][4].blank?
          #params[:date][:collection_time_post][3]  = ((params[:date][:collection_time_post][3].to_i)+v_offset).to_s
          collection_time_post =  params[:date][:collection_time_post][0]+"-"+params[:date][:collection_time_post][1]+"-"+params[:date][:collection_time_post][2]+" "+params[:date][:collection_time_post][3]+":"+params[:date][:collection_time_post][4]
          collection_time_post_dt = Time.strptime(collection_time_post, "%Y-%m-%d %H:%M") #scanstarttime
        end
        @vital_post.collection_time = collection_time_post_dt

        @vital_post.save  

        format.html { redirect_to(@petscan, :notice => 'Petscan was successfully created.') }
        format.xml  { render :xml => @petscan, :status => :created, :location => @petscan }
      else
        @appointment.delete
        format.html { render :action => "new" }
        format.xml  { render :xml => @petscan.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /petscans/1
  # PUT /petscans/1.xml
  def update
    #puts "update (#{__LINE__}):"+ params.to_s


    v_offset = Time.zone_offset('CST') 
    v_offset = (v_offset*(-1))/(60*60) # mess with storing date as local in db - but shifting to utc
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end

    v_dicom_tracer = ""
    v_dicom_tracer_id = ""
    v_dicom_scan_start_time = ""
    v_dicom_scanner_location = ""
    v_dicom_scanner_name = ""
    v_dicom_scan_date = ""

    v_exclude_path_array = []

    @petscan = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
                                      
    appointment_date = nil

    #we have to do this weird date init thing for out datetimes, so that strptime doesn't change our times. it's weird.

      params[:date][:injectiont][0]="1899"
      params[:date][:injectiont][1]="12"
      params[:date][:injectiont][2]="30"
      params[:date][:scanstartt][0]="1899"
      params[:date][:scanstartt][1]="12"
      params[:date][:scanstartt][2]="30" 
      params[:date][:collection_time][0]="1899"
      params[:date][:collection_time][1]="12"
      params[:date][:collection_time][2]="30" 
      params[:date][:collection_time_post][0]="1899"
      params[:date][:collection_time_post][1]="12"
      params[:date][:collection_time_post][2]="30" 

    if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
         appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
         # params[:date][:injectiont][0]=params[:appointment]["#{'appointment_date'}(1i)"]
         # params[:date][:injectiont][1]=params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")
         # params[:date][:injectiont][2]=params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
         # params[:date][:scanstartt][0]=params[:appointment]["#{'appointment_date'}(1i)"]
         # params[:date][:scanstartt][1]=params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")
         #  params[:date][:scanstartt][2]=params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
    end

      injectiontime = nil
      if !params[:date][:injectiont][0].blank? && !params[:date][:injectiont][1].blank? && !params[:date][:injectiont][2].blank? && !params[:date][:injectiont][3].blank? && !params[:date][:injectiont][4].blank?
      #params[:date][:injectiont][3]  = ((params[:date][:injectiont][3].to_i)+v_offset).to_s
      injectiontime =  params[:date][:injectiont][0]+"-"+params[:date][:injectiont][1]+"-"+params[:date][:injectiont][2]+" "+params[:date][:injectiont][3]+":"+params[:date][:injectiont][4]
      params[:petscan][:injecttiontime] =  Time.strptime(injectiontime, "%Y-%m-%d %H:%M") #injectiontime
      else
      params[:petscan][:injecttiontime] =  ""
       end
     
        scanstarttime = nil
      if !params[:date][:scanstartt][0].blank? && !params[:date][:scanstartt][1].blank? && !params[:date][:scanstartt][2].blank? && !params[:date][:scanstartt][3].blank? && !params[:date][:scanstartt][4].blank?
       #params[:date][:scanstartt][3]  = ((params[:date][:scanstartt][3].to_i)+v_offset).to_s
       scanstarttime =  params[:date][:scanstartt][0]+"-"+params[:date][:scanstartt][1]+"-"+params[:date][:scanstartt][2]+" "+params[:date][:scanstartt][3]+":"+params[:date][:scanstartt][4]
       params[:petscan][:scanstarttime] = Time.strptime(scanstarttime, "%Y-%m-%d %H:%M") #scanstarttime
     else
        params[:petscan][:scanstarttime] = ""
      end

    # ok to update vitals even if other update fail
    @vital = nil
    if !params[:vital_id].blank?
      @vital = Vital.find(params[:vital_id])
    else
      @vital = Vital.new
      @vital.appointment_id = @petscan.appointment_id
    end
    @vital.pulse = params[:pulse]
    @vital.bp_systol = params[:bp_systol]
    @vital.bp_diastol = params[:bp_diastol]
    @vital.respiratory_rate = params[:respiratory_rate]
    @vital.bloodglucose = params[:bloodglucose]
    @vital.weight = params[:weight]
    @vital.height = params[:height]
    @vital.weight_units = params[:weight_units]
    @vital.height_units = params[:height_units]
    @vital.pre_post_flag = 'pre'

    collection_time_dt = nil
    if !params[:date][:collection_time][0].blank? && !params[:date][:collection_time][1].blank? && !params[:date][:collection_time][2].blank? && !params[:date][:collection_time][3].blank? && !params[:date][:collection_time][4].blank?
      #params[:date][:collection_time][3]  = ((params[:date][:collection_time][3].to_i)+v_offset).to_s
      collection_time =  params[:date][:collection_time][0]+"-"+params[:date][:collection_time][1]+"-"+params[:date][:collection_time][2]+" "+params[:date][:collection_time][3]+":"+params[:date][:collection_time][4]
      collection_time_dt = Time.strptime(collection_time, "%Y-%m-%d %H:%M")
    end
    @vital.collection_time = collection_time_dt

    @vital.save   

    @vital_post = nil
    if !params[:vital_id_post].blank?
      @vital_post = Vital.find(params[:vital_id_post])
    else
      @vital_post = Vital.new
      @vital_post.appointment_id = @petscan.appointment_id
    end
    @vital_post.pulse = params[:pulse_post]
    @vital_post.bp_systol = params[:bp_systol_post]
    @vital_post.bp_diastol = params[:bp_diastol_post]
    @vital_post.respiratory_rate = params[:respiratory_rate_post]
    @vital_post.pre_post_flag = 'post'

    collection_time_post_dt = nil
    if !params[:date][:collection_time_post][0].blank? && !params[:date][:collection_time_post][1].blank? && !params[:date][:collection_time_post][2].blank? && !params[:date][:collection_time_post][3].blank? && !params[:date][:collection_time_post][4].blank?
      #params[:date][:collection_time_post][3]  = ((params[:date][:collection_time_post][3].to_i)+v_offset).to_s
      collection_time_post =  params[:date][:collection_time_post][0]+"-"+params[:date][:collection_time_post][1]+"-"+params[:date][:collection_time_post][2]+" "+params[:date][:collection_time_post][3]+":"+params[:date][:collection_time_post][4]
      collection_time_post_dt = Time.strptime(collection_time_post, "%Y-%m-%d %H:%M") #scanstarttime
    end
    @vital_post.collection_time = collection_time_post_dt

    @vital_post.save      
    
     if !params[:petfile].blank? and !params[:petfile][:id].blank?
      params[:petfile][:id].each do |pf_id|
         if pf_id == "0" 
             if !params[:petfile][:file_name][0.to_s].blank? # insert new
                @petfile = Petfile.new
                @petfile.petscan_id = @petscan.id
                @petfile.file_name = params[:petfile][:file_name][0.to_s]
                @petfile.path =  params[:petfile][:path][0.to_s]
                @petfile.note =  params[:petfile][:note][0.to_s]
                @petfile.save
             end
          else # update old
              @petfile = Petfile.find(pf_id)
              if !params[:petfile][:delete_petfile_id].blank? 
                if !params[:petfile][:delete_petfile_id][pf_id].blank? 
                end
              end
              if !params[:petfile][:delete_petfile_id].blank?   and !params[:petfile][:delete_petfile_id][pf_id].blank? and params[:petfile][:delete_petfile_id][pf_id] == "1"
                @petfile.delete
              else
                @petfile.petscan_id = @petscan.id
                @petfile.file_name = params[:petfile][:file_name][pf_id]
                @petfile.path =  params[:petfile][:path][pf_id]
                @petfile.note =  params[:petfile][:note][pf_id]
                @petfile.save
              end
          end
       end
     end

    respond_to do |format|
      if @petscan.update(petscan_params)#params[:petscan], :without_protection => true)

        @appointment = Appointment.find(@petscan.appointment_id)
        @vgroup = Vgroup.find(@appointment.vgroup_id)
        # get sp_id's
        connection = ActiveRecord::Base.connection();
        sql_sp = "select distinct scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id ="+@appointment.vgroup_id.to_s
        results_sp = connection.execute(sql_sp)  
        results_sp.each do |r_sp|
               if !params[:petfile].blank? and !params[:petfile][:petfile_autodetect].blank? and params[:petfile][:petfile_autodetect] == "On"  
                     v_keep_looking_for_pet_dicoms = 1
                     v_cnt_escape = 0  # incrment and exit if infinite looping
                     while  v_keep_looking_for_pet_dicoms > 0 # keep looking   
                        v_cnt_escape = v_cnt_escape + 1 
                        @petfiles_dicoms_found_array = @petscan.get_pet_dicoms(r_sp[0], @petscan.lookup_pettracer_id,@vgroup.id, v_exclude_path_array)

                        puts "petflies_dicoms_found: #{@petfiles_dicoms_found_array}"
 
                        if @petfiles_dicoms_found_array.nil? or (!@petfiles_dicoms_found_array.nil? and  @petfiles_dicoms_found_array[0].nil? ) or v_cnt_escape > 10
                            v_keep_looking_for_pet_dicoms = 0
                        else
                          petfile_dicom_dir = File.dirname(@petfiles_dicoms_found_array[0])
                           v_exclude_path_array.push(petfile_dicom_dir)
                        end
                        @petfile_header = nil
                        if !@petfiles_dicoms_found_array.nil? and !@petfiles_dicoms_found_array[0].nil? and !@petfiles_dicoms_found_array[1].nil?

                          @petfile_header = @petfiles_dicoms_found_array[1]
                          # GET FROM NEW FILE DIR STRUCTURE v_file_type = #######

                          #especially on AV45 dicoms from WIMR(?), files named 9xx are summary files, and aren't appropriate 
                          # for this copyforward we're doing onto the Petscan obj (they break stuff, and aren't what we want anyway).
                          if !@petfiles_dicoms_found_array[0].to_s.start_with?('9')
                             v_dicom_scanner_name = @petfile_header['0008,1090'][:value].to_s
                             if v_dicom_scanner_name.include?("Discovery MI")
                                  params[:petscan][:scanner_name] = v_dicom_scanner_name
                                  @petscan.scanner_name = v_dicom_scanner_name
                                  @petscan.save
                               v_dicom_tracer = @petfile_header['0008,103E'][:value].to_s
                               #0008,103E Series Description  AV_1451 30 MIN DYN
                               # need some interpretation
                               if v_dicom_tracer.include?("PiB") # MK6240
                                   v_dicom_tracer_id = 1
                               elsif v_dicom_tracer.include?("FDG") # MK6240
                                   v_dicom_tracer_id = 2
                               elsif v_dicom_tracer.include?("WAY") # MK6240
                                   v_dicom_tracer_id = 3
                               elsif v_dicom_tracer.include?("PBR28") # MK6240
                                   v_dicom_tracer_id = 5
                               elsif v_dicom_tracer.include?("AV45") # MK6240
                                   v_dicom_tracer_id = 6
                               elsif v_dicom_tracer.include?("1451") # AV_1451
                                   v_dicom_tracer_id = 9
                               elsif v_dicom_tracer.include?("NeuraCeq") # MK6240
                                   v_dicom_tracer_id = 10
                               elsif v_dicom_tracer.include?("6240") # MK6240
                                   v_dicom_tracer_id = 11
                               elsif v_dicom_tracer.include?("UCB-J") # MK6240
                                   v_dicom_tracer_id = 12 
                               end

                               if @petfile_header.has_key?('0008,0201') and !@petfile_header['0008,0201'].nil? and !@petfile_header['0008,0201'].blank?
                                 v_dicom_timezone_offset = @petfile_header['0008,0201'][:value].to_s
                               else
                                 v_dicom_timezone_offset = ""
                               end
                               #0008,0201 Timezone Offset From UTC  -0600
                                # need to move the injection/scan start time to times in database WITH the GMT displacement
                                  # running up against UTC displayed /GMT saved in database 
                                  # and the petscan injection/scan start dates ignoring the GMT displacement
                                  # need to -06 hours , but from hh - and if displayment > hh, need the 12 back wrap
                               
                               if @petfile_header.has_key?('0008,0031') and !@petfile_header['0008,0031'].nil? and !@petfile_header['0008,0031'].blank?
                                 v_dicom_scan_start_time = @petfile_header['0008,0031'][:value].to_s
                               end

                               #0008,0031 Series Time. HHMMSS
                               v_dicom_scanner_location = @petfile_header['0008,0080'][:value].to_s    # Institution Name
                               if params[:petscan][:scanner_location].nil? or params[:petscan][:scanner_location].blank? or params[:petscan][:scanner_location].include?("elect")
                                  params[:petscan][:scanner_location] = v_dicom_scanner_location
                                  @petscan.scanner_location = v_dicom_scanner_location
                                  @petscan.save
                               end

                               if @petfile_header.has_key?('0008,0020') and !@petfile_header['0008,0020'].nil? and !@petfile_header['0008,0020'].blank?
                                 v_dicom_scan_date = @petfile_header['0008,0020'][:value].to_s
                               end
                               # raise warnings

                             elsif  v_dicom_scanner_name.include?("Biograph Horizon")


                             end
                           end
                          
                           # what to do with dicom header
                           # GE vs Siemans machine
                           petfile_dicom_dir = File.dirname(@petfiles_dicoms_found_array[0])
                           v_exclude_path_array.push(petfile_dicom_dir.to_s)
                           v_petfile_check = Petfile.where("file_name in (?) and petscan_id in (?)", petfile_dicom_dir.to_s,@petscan.id)
                          
                            if !v_petfile_check.nil? and v_petfile_check.length > 0
                                 v_petfile_check.each do |pf_check|
                                    if pf_check.path.blank? and !v_path.blank?
                                       pf_check.path = v_path
                                       pf_check.dicom_taghash = @petfile_header
                                       pf_check.save
                                    end
                                 end
                            else
                              v_new_petfile = Petfile.new
                              v_new_petfile.petscan_id = @petscan.id
                              v_new_petfile.file_name = ""
                              v_new_petfile.path =  petfile_dicom_dir.to_s
                              v_new_petfile.dicom_taghash = @petfile_header
                              v_new_petfile.save
                            end
                        end
                      end # end of dicom while
                        @petfiles_found = @petscan.get_pet_files(r_sp[0], @petscan.lookup_pettracer_id,@vgroup.id)
                        @petfiles_found.each do |pf_name|  # make sure not already in database with this petscan.id
                            v_petfile_check = Petfile.where("file_name in (?) and petscan_id in (?)", pf_name,@petscan.id)
                            v_path = @petscan.get_pet_path(r_sp[0], pf_name, @petscan.lookup_pettracer_id,@appointment.vgroup_id)
                            if !v_petfile_check.nil? and v_petfile_check.length > 0
                                 v_petfile_check.each do |pf_check|
                                    if pf_check.path.blank? and !v_path.blank?
                                       pf_check.path = v_path
                                       pf_check.file_type = "ecat"
                                       pf_check.save
                                    end
                                 end
                            else
                              v_new_petfile = Petfile.new
                              v_new_petfile.petscan_id = @petscan.id
                              v_new_petfile.file_name = pf_name
                              v_new_petfile.path =  v_path
                              v_new_petfile.file_type = "ecat"
                              v_new_petfile.save
                            end
                        end
               end
            if @petscan.ecatfilename.blank?
              puts "aaaaa blank ecatfilename"
              @petscan.ecatfilename = @petscan.get_pet_file(r_sp[0], @petscan.lookup_pettracer_id,@vgroup.id)
            end
            v_path = ""
            if !@petscan.ecatfilename.blank?
               v_path = @petscan.get_pet_path(r_sp[0], @petscan.ecatfilename, @petscan.lookup_pettracer_id,@vgroup.id)
               if !v_path.blank?
                 @petscan.path = v_path
                 @petscan.save 
               end
            end
        end
        @appointment.comment = params[:appointment][:comment]
        @appointment.appointment_date =appointment_date
        if !params[:appointment].nil? and !params[:appointment][:appointment_coordinator].nil?
            @appointment.appointment_coordinator = params[:appointment][:appointment_coordinator]
        end
        if !@vgroup.participant_id.blank?
          @participant = Participant.find(@vgroup.participant_id)
          if !@participant.dob.blank?
             @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).round(2)
          end
        end
        @appointment.save
        @vgroup.transfer_pet = params[:vgroup][:transfer_pet]
        @vgroup.save
        format.html { redirect_to(@petscan, :notice => 'Petscan was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @petscan.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /petscans/1
  # DELETE /petscans/1.xml
  def destroy   
   
   puts "aaaaaaa"
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
   puts "bbbbbbb"  
    @petscan = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])  
    puts "ccccc"
    if @petscan.appointment_id > 3156 # sure appointment_id not used by any other
       @appointment = Appointment.find(@petscan.appointment_id)
       @appointments = Appointment.where("vgroup_id in (?)",@appointment.vgroup_id)
       if @appointments.length < 2 # sure appointment_id not used by any other    
         puts "ddddd"
         @petscan.destroy
         @appointment.destroy 
          @vgroup = Vgroup.find(@appointment.vgroup_id)
          @vgroup.destroy 
       else  
         puts "eeee"
         @petscan.destroy 
         puts "ffff"
         @appointment.destroy  
         puts "gggg" 
         
       end
    else   
      puts "hhhhh"
      @petscan.destroy
    end
    puts "iiiiiii"
    respond_to do |format|
      format.html { redirect_to  :controller => "petscans", :action =>"pet_search", "_method" =>:get, status: 303 } 

      format.xml  { head :ok }
    end
  end   
  private
    def set_petscan
       @petscan = Petscan.find(params[:id])
    end
   def petscan_params
          params.require(:petscan).permit(:temp_fkpetscanid,:petscan_note,:completedpetscan_moved_to_vgroups,:enteredpetscan,:enteredpetscandate,:enteredpetscanwho,:path,:scanstarttime,:injecttiontime,:range,:units,:netinjecteddose,:ecatfilename,:lookup_pettracer_id,:appointment_id,:id,:scanner_location,:scanner_name,:good_to_process_flag)
   end  
   def pet_search_params
          params.require(:pet_search).permit! #(:enumber,:rmr,:file_name,:latest_timestamp,:earliest_timestamp, :gender,:min_age, :max_age, :pet_status,:lookup_pettracer_id,scan_procedure_id: []) 
  end
end
