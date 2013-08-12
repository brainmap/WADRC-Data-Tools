# encoding: utf-8
class PetscansController < ApplicationController
  # GET /petscans
  # GET /petscans.xml
 
  def petscan_search
     @current_tab = "petscans"
     params["search_criteria"] =""

     if params[:petscan_search].nil?
          params[:petscan_search] =Hash.new  
     end
     
     scan_procedure_array = []
     scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)   
     
#    @petscans = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
#                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
#    and scan_procedure_id in (?))", scan_procedure_array).all
#     sql = "select * from petscans inner join  appointments on appointments.id = petscans.appointment_id order by appointment_date desc"
#      @search = Petscan.find_by_sql(sql)
#     @search = Petscan.where("petscans.appointment_id in (select appointments.id from appointments)").all
      @search = Petscan.search(params[:search])    # parms search makes something which works with where?

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
                            and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) >= ?   )",params[:petscan_search][:min_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:petscan_search][:min_age]
        elsif params[:petscan_search][:min_age].blank? && !params[:petscan_search][:max_age].blank?
             @search = @search.where("  petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                         and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) <= ?   )",params[:petscan_search][:max_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:petscan_search][:max_age]
        elsif !params[:petscan_search][:min_age].blank? && !params[:petscan_search][:max_age].blank?
           @search = @search.where("   petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                           and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                           and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                       and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) between ? and ?   )",params[:petscan_search][:min_age],params[:petscan_search][:max_age])
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

  def pet_search
      # make @conditions from search form input, access control in application controller run_search
      @conditions = []
      @current_tab = "petscans"
      params["search_criteria"] =""

      if params[:pet_search].nil?
           params[:pet_search] =Hash.new  
           params[:pet_search][:pet_status] = "yes"
      end

      if !params[:pet_search][:scan_procedure_id].blank?
         condition =" petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                and scan_procedure_id in ("+params[:pet_search][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+"))"
         @conditions.push(condition)
         @scan_procedures = ScanProcedure.where("id in (?)",params[:pet_search][:scan_procedure_id])
         params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end

      if !params[:pet_search][:ecatfilename].blank?
          var = "%"+params[:pet_search][:ecatfilename].downcase+"%"
          condition =" petscans.ecatfilename  like '"+var.gsub(/[;:'"()=<>]/, '')+"' "
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +", Ecat file "+params[:pet_search][:ecatfilename]
      end
      
      if !params[:pet_search][:enumber].blank?
        if params[:pet_search][:enumber].include?(',') # string of enumbers
         v_enumber =  params[:pet_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
         v_enumber = v_enumber.gsub(/,/,"','")
           condition =" petscans.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
           where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
           and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"'))"
          
        else
          condition =" petscans.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
          where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
          and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:pet_search][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"
        end
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:pet_search][:enumber]
      end      

      if !params[:pet_search][:rmr].blank? 
          condition =" petscans.appointment_id in (select appointments.id from appointments,vgroups
                    where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower('"+params[:pet_search][:rmr].gsub(/[;:'"()=<>]/, '')+"')   ))"
          @conditions.push(condition)           
          params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:pet_search][:rmr]
      end   
      
      if !params[:pet_search][:pet_status].blank? 
          condition =" petscans.appointment_id in (select appointments.id from appointments,vgroups
                              where appointments.vgroup_id = vgroups.id and  lower(vgroups.transfer_pet) in (lower('"+params[:pet_search][:pet_status].gsub(/[;:'"()=<>]/, '')+"')   ))"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  Pet status "+params[:pet_search][:pet_status]
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
                           and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) >= "+params[:pet_search][:min_age].gsub(/[;:'"()=<>]/, '')+"   )"
            @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:pet_search][:min_age]
       elsif params[:pet_search][:min_age].blank? && !params[:pet_search][:max_age].blank?
            condition ="   petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                        and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) <= "+params[:pet_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
           @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:pet_search][:max_age]
       elsif !params[:pet_search][:min_age].blank? && !params[:pet_search][:max_age].blank?
          condition ="    petscans.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                             where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                          and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                          and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                      and floor(DATEDIFF(appointments.appointment_date,participants.dob)/365.25) between "+params[:pet_search][:min_age].gsub(/[;:'"()=<>]/, '')+" and "+params[:pet_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:pet_search][:min_age]+" and "+params[:pet_search][:max_age]
       end
       # trim leading ","
       params["search_criteria"] = params["search_criteria"].sub(", ","")

       # adjust columns and fields for html vs xls
       request_format = request.formats.to_s
       @html_request ="Y"
       case  request_format
         when "text/html" then # ? application/html
           @column_headers = ['Date','Protocol','Enumber','RMR','Tracer','Ecatfile','Path','Note','Pet status','Appt Note'] # need to look up values
               # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
           @column_number =   @column_headers.size
           @fields =["lookup_pettracers.name pettracer","petscans.ecatfilename","petscans.path",
                 "petscans.petscan_note","vgroups.transfer_pet","petscans.id"] # vgroups.id vgroup_id always first, include table name
            @left_join = ["LEFT JOIN lookup_pettracers on petscans.lookup_pettracer_id = lookup_pettracers.id",
                    "LEFT JOIN employees on petscans.enteredpetscanwho = employees.id"] # left join needs to be in sql right after the parent table!!!!!!!
         else    
           @html_request ="N"          
            @column_headers = ['Date','Protocol','Enumber','RMR','Tracer','Ecatfile','Path','Dose','Injection Time','Scan Start','Note','Range','Pet status','BP Systol','BP Diastol','Pulse','Blood Glucose','Age at Appt','Appt Note'] # need to look up values
                  # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
            @column_number =   @column_headers.size
            @fields =["lookup_pettracers.name pettracer","petscans.ecatfilename","petscans.path","petscans.netinjecteddose",
                    "time_format(timediff( time(petscans.injecttiontime),subtime(utc_time(),time(localtime()))),'%H:%i')",
                    "time_format(timediff( time(scanstarttime),subtime(utc_time(),time(localtime()))),'%H:%i')",
                    "petscans.petscan_note","petscans.range","vgroups.transfer_pet","vitals.bp_systol","vitals.bp_diastol","vitals.pulse","vitals.bloodglucose","appointments.age_at_appointment","petscans.id"] # vgroups.id vgroup_id always first, include table name 
            @left_join = ["LEFT JOIN lookup_pettracers on petscans.lookup_pettracer_id = lookup_pettracers.id",
                        "LEFT JOIN vitals on petscans.appointment_id = vitals.appointment_id  "] # left join needs to be in sql right after the parent table!!!!!!!   
                        # "LEFT JOIN employees on petscans.enteredpetscanwho = employees.id",             
                 
         end
       @tables =['petscans'] # trigger joins --- vgroups and appointments by default
       @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]

      @results = self.run_search   # in the application controller
      @results_total = @results  # pageination makes result count wrong
      t = Time.now 
      @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")

      ### LOOK WHERE TITLE IS SHOWING UP
      @collection_title = 'All Petscan appts'

      respond_to do |format|
        format.xls # pet_search.xls.erb
        format.xml  { render :xml => @results }    # actually redefined in the xls page    
        format.html {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)} # pet_search.html.erb
      end
    end



  # GET /petscans/1
  # GET /petscans/1.xml
  def show
    @current_tab = "petscans"
    scan_procedure_array = []
    scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
     
    @petscan = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

    @appointment = Appointment.find(@petscan.appointment_id)                            

    @petscans = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                               and appointments.appointment_date between ? and ?
                               and scan_procedure_id in (?))", @appointment.appointment_date-2.month,@appointment.appointment_date+2,scan_procedure_array).all

    idx = @petscans.index(@petscan)
    @older_petscan = idx + 1 >= @petscans.size ? nil : @petscans[idx + 1]
    @newer_petscan = idx - 1 < 0 ? nil : @petscans[idx - 1]
    
    @vgroup = Vgroup.find(@appointment.vgroup_id)
    @participant = @vgroup.try(:participant)
    @enumbers = @vgroup.enrollments

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @petscan }
    end
  end

  # GET /petscans/new
  # GET /petscans/new.xml
  def new
    @current_tab = "petscans"
    @petscan = Petscan.new
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
     @current_tab = "petscans"
     scan_procedure_array = []
     scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
     @petscan = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                       and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
     @appointment = Appointment.find(@petscan.appointment_id) 
     @vgroup = Vgroup.find(@appointment.vgroup_id)
     @enumbers = @vgroup.enrollments
  end

  # POST /petscans
  # POST /petscans.xml
  def create
     @current_tab = "petscans"
     scan_procedure_array = []
     scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @petscan = Petscan.new(params[:petscan])
    
    params[:date][:injectiont][0]="1899"
    params[:date][:injectiont][1]="12"
    params[:date][:injectiont][2]="30"
    injectiontime = nil
    if !params[:date][:injectiont][0].blank? && !params[:date][:injectiont][1].blank? && !params[:date][:injectiont][2].blank? && !params[:date][:injectiont][3].blank? && !params[:date][:injectiont][4].blank?
      injectiontime =  params[:date][:injectiont][0]+"-"+params[:date][:injectiont][1]+"-"+params[:date][:injectiont][2]+" "+params[:date][:injectiont][3]+":"+params[:date][:injectiont][4]
     @petscan.injecttiontime = injectiontime
    end

    params[:date][:scanstartt][0]="1899"
    params[:date][:scanstartt][1]="12"
    params[:date][:scanstartt][2]="30"       
    scanstarttime = nil
    if !params[:date][:scanstartt][0].blank? && !params[:date][:scanstartt][1].blank? && !params[:date][:scanstartt][2].blank? && !params[:date][:scanstartt][3].blank? && !params[:date][:scanstartt][4].blank?
      scanstarttime =  params[:date][:scanstartt][0]+"-"+params[:date][:scanstartt][1]+"-"+params[:date][:scanstartt][2]+" "+params[:date][:scanstartt][3]+":"+params[:date][:scanstartt][4]
      @petscan.scanstarttime = scanstarttime
    end  
    
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
    @appointment.user = current_user
    if !@vgroup.participant_id.blank?
      @participant = Participant.find(@vgroup.participant_id)
      if !@participant.dob.blank?
         @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).floor
      end
    end
    @appointment.save
    @petscan.appointment_id = @appointment.id

    respond_to do |format|
      if @petscan.save
         @vgroup.transfer_pet = params[:vgroup][:transfer_pet]
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
          @vital.appointment_id = @petscan.appointment_id
          @vital.pulse = params[:pulse]
          @vital.bp_systol = params[:bp_systol]
          @vital.bp_diastol = params[:bp_diastol]
          @vital.bloodglucose = params[:bloodglucose]
          @vital.save      
        end        
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
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
     
    @petscan = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
                                      
    appointment_date = nil
    if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
         appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
    end
      params[:date][:injectiont][0]="1899"
      params[:date][:injectiont][1]="12"
      params[:date][:injectiont][2]="30"
      injectiontime = nil
      if !params[:date][:injectiont][0].blank? && !params[:date][:injectiont][1].blank? && !params[:date][:injectiont][2].blank? && !params[:date][:injectiont][3].blank? && !params[:date][:injectiont][4].blank?
injectiontime =  params[:date][:injectiont][0]+"-"+params[:date][:injectiont][1]+"-"+params[:date][:injectiont][2]+" "+params[:date][:injectiont][3]+":"+params[:date][:injectiont][4]
      params[:petscan][:injecttiontime] = injectiontime
       end

       params[:date][:scanstartt][0]="1899"
       params[:date][:scanstartt][1]="12"
       params[:date][:scanstartt][2]="30"       
        scanstarttime = nil
      if !params[:date][:scanstartt][0].blank? && !params[:date][:scanstartt][1].blank? && !params[:date][:scanstartt][2].blank? && !params[:date][:scanstartt][3].blank? && !params[:date][:scanstartt][4].blank?
  scanstarttime =  params[:date][:scanstartt][0]+"-"+params[:date][:scanstartt][1]+"-"+params[:date][:scanstartt][2]+" "+params[:date][:scanstartt][3]+":"+params[:date][:scanstartt][4]
       params[:petscan][:scanstarttime] = scanstarttime
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
      @vital.appointment_id = @petscan.appointment_id
      @vital.pulse = params[:pulse]
      @vital.bp_systol = params[:bp_systol]
      @vital.bp_diastol = params[:bp_diastol]
      @vital.bloodglucose = params[:bloodglucose]
      @vital.save      
    end
    

    respond_to do |format|
      if @petscan.update_attributes(params[:petscan])
        @appointment = Appointment.find(@petscan.appointment_id)
        @vgroup = Vgroup.find(@appointment.vgroup_id)
        # get sp_id's
        connection = ActiveRecord::Base.connection();
        sql_sp = "select distinct scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id ="+@appointment.vgroup_id.to_s
        results_sp = connection.execute(sql_sp) 
        v_shared = Shared.new  
        results_sp.each do |r_sp|
            v_path = ""
            v_path = v_shared.get_pet_path(r_sp[0], @petscan.ecatfilename, @petscan.lookup_pettracer_id)
            if v_path > ""
              @petscan.path = v_path
              @petscan.save 
            end
        end
        @appointment.comment = params[:appointment][:comment]
        @appointment.appointment_date =appointment_date
        if !@vgroup.participant_id.blank?
          @participant = Participant.find(@vgroup.participant_id)
          if !@participant.dob.blank?
             @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).floor
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
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
     
    @petscan = Petscan.where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    if @petscan.appointment_id > 3156 # sure appointment_id not used by any other
       @appointment = Appointment.find(@petscan.appointment_id)
       @appointments = Appointment.where("vgroup_id in (?)",@appointment.vgroup_id)
       if @appointments.length < 2 # sure appointment_id not used by any other
          @vgroup = Vgroup.find(@appointment.vgroup_id)
          @vgroup.destroy
       end
       @appointment.destroy
    end
    @petscan.destroy

    respond_to do |format|
      format.html { redirect_to(pet_search_path) }
      format.xml  { head :ok }
    end
  end
end
