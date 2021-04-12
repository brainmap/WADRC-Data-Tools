# encoding: utf-8
class LumbarpuncturesController < ApplicationController
  # GET /lumbarpunctures
  # GET /lumbarpunctures.xml
  require 'csv'   
  require 'json/ext'
  before_action :set_lumbarpuncture, only: [:show, :edit, :update, :destroy]   
	respond_to :html
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
    scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
     
    @lumbarpuncture = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

    @appointment = Appointment.find(@lumbarpuncture.appointment_id)                            

    @lumbarpunctures = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                               and appointments.appointment_date between ? and ?
                               and scan_procedure_id in (?))", @appointment.appointment_date-2.month,@appointment.appointment_date+2,scan_procedure_array).to_a

  

    idx = @lumbarpunctures.index(@lumbarpuncture)
    @older_lumbarpuncture = idx + 1 >= @lumbarpunctures.size ? nil : @lumbarpunctures[idx + 1]
    @newer_lumbarpuncture = idx - 1 < 0 ? nil : @lumbarpunctures[idx - 1]
    
    @vgroup = Vgroup.find(@appointment.vgroup_id)
    @participant = @vgroup.try(:participant)
    @enumbers = @vgroup.enrollments
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lumbarpuncture }
      format.json { render :json => @lumbarpuncture.to_json }
    end
  end

  def json_lp

    scan_procedure_array = []
    scan_procedure_array =  (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
    hide_date_flag_array = []
    hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
    @hide_page_flag = 'N'
    if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
    end
     
    @lumbarpuncture = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

    @appointment = Appointment.find(@lumbarpuncture.appointment_id)                            
    @lumbarpuncture_json = @lumbarpuncture.to_json
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lumbarpuncture }
      format.json { render :json => @lumbarpuncture_json }
    end
  end

  # GET /lumbarpunctures/new
  # GET /lumbarpunctures/new.xml
  def new
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
       @current_tab = "lumbarpunctures"
       @lumbarpuncture = Lumbarpuncture.new
       @lumbarpuncture.lp_data_entered_by = current_user.id
       @lumbarpuncture.lp_data_entered_date = Date.today

        vgroup_id = params[:id]
        @vgroup = Vgroup.find(vgroup_id)
        @enumbers = @vgroup.enrollments
        params[:new_appointment_vgroup_id] = vgroup_id
        @appointment = Appointment.new
        @appointment.vgroup_id = vgroup_id
        @appointment.appointment_date = (Vgroup.find(vgroup_id)).vgroup_date
        @appointment.appointment_type ='lumbar_puncture'
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
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @lumbarpuncture = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @appointment = Appointment.find(@lumbarpuncture.appointment_id)
    @vgroup = Vgroup.find(@appointment.vgroup_id)
    @enumbers = @vgroup.enrollments   
  end

  # POST /lumbarpunctures
  # POST /lumbarpunctures.xml
  def create     
    
     @current_tab = "lumbarpunctures"
     scan_procedure_array = []
     scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
           hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
         #@lumbarpuncture = Lumbarpuncture.new( lumbarpuncture_params)#params[:lumbarpuncture])  
    appointment_date = nil
    if !lumbarpuncture_params[:appointment]["#{'appointment_date'}(1i)"].blank? && !lumbarpuncture_params[:appointment]["#{'appointment_date'}(2i)"].blank? && !lumbarpuncture_params[:appointment]["#{'appointment_date'}(3i)"].blank?
         appointment_date = lumbarpuncture_params[:appointment]["#{'appointment_date'}(1i)"] +"-"+lumbarpuncture_params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+lumbarpuncture_params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
    end
    
    vgroup_id =params[:new_appointment_vgroup_id]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(vgroup_id)
    @appointment = Appointment.new
    @appointment.vgroup_id = vgroup_id
    @appointment.appointment_type ='lumbar_puncture'
    @appointment.appointment_date =appointment_date
    @appointment.comment = lumbarpuncture_params[:appointment][:comment]
    if !lumbarpuncture_params[:appointment].nil? and !lumbarpuncture_params[:appointment][:appointment_coordinator].nil?
                @appointment.appointment_coordinator = lumbarpuncture_params[:appointment][:appointment_coordinator]
    end
    @appointment.user = current_user
    if !@vgroup.participant_id.blank?
      @participant = Participant.find(@vgroup.participant_id)
      if !@participant.dob.blank?
         @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).round(2)
      end
    end
    @appointment.save 
  #   params[:lumbarpuncture][:appointment_id]  = @appointment.id 

    lp_params = lumbarpuncture_params[:lumbarpuncture]

    lp_params[:lpstarttime_time]= "#{lumbarpuncture_params[:time_fields][:lpstarttime_time][:hour].to_s.rjust(2,'0')}:#{lumbarpuncture_params[:time_fields][:lpstarttime_time][:minute].to_s.rjust(2,'0')}"
    lp_params[:lpfluidstarttime_time]= "#{lumbarpuncture_params[:time_fields][:lpfluidstarttime_time][:hour].to_s.rjust(2,'0')}:#{lumbarpuncture_params[:time_fields][:lpfluidstarttime_time][:minute].to_s.rjust(2,'0')}"
    lp_params[:lpendtime_time]= "#{lumbarpuncture_params[:time_fields][:lpendtime_time][:hour].to_s.rjust(2,'0')}:#{lumbarpuncture_params[:time_fields][:lpendtime_time][:minute].to_s.rjust(2,'0')}"

    @lumbarpuncture = Lumbarpuncture.new( lp_params )
    @lumbarpuncture.appointment_id = @appointment.id
    if @lumbarpuncture.lp_data_entered_by.blank?
       @lumbarpuncture.lp_data_entered_by = current_user.id
    end
    if @lumbarpuncture.lp_data_entered_date.blank?
        @lumbarpuncture.lp_data_entered_date = Date.today
    end

    respond_to do |format|

      if @lumbarpuncture.save
         @vgroup.completedlumbarpuncture = lumbarpuncture_params[:lumbarpuncture][:lpsuccess] == '1' ? "yes" : "no"
          @vgroup.save

        # @appointment.save
        if !vitals_params[:vital_id].blank?
          @vital = Vital.find(vitals_params[:vital_id])
          @vital.pulse = vitals_params[:pulse]
          @vital.bp_systol = vitals_params[:bp_systol]
          @vital.bp_diastol = vitals_params[:bp_diastol]
          @vital.bloodglucose = vitals_params[:bloodglucose]
          @vital.save
        else
          @vital = Vital.new
          @vital.appointment_id = @lumbarpuncture.appointment_id
          @vital.pulse = vitals_params[:pulse]
          @vital.bp_systol = vitals_params[:bp_systol]
          @vital.bp_diastol = vitals_params[:bp_diastol]
          @vital.bloodglucose = vitals_params[:bloodglucose]
          @vital.save      
        end    
        
        if !params[:lookup_lumbarpuncture_id].blank?
          LookupLumbarpuncture.all.each do |lookup_lp|
              val = nil
              val = params[:lookup_lumbarpuncture_id][lookup_lp.id.to_s].to_s
              if val.blank?
                   val = "0"
              end
              sql = "INSERT INTO lumbarpuncture_results (lumbarpuncture_id,lookup_lumbarpuncture_id,value) VALUES ("+@lumbarpuncture.id.to_s+","+lookup_lp.id.to_s+",'"+val+"')
                    ON DUPLICATE KEY UPDATE value='"+val+"' "
              ActiveRecord::Base.connection.insert_sql sql
              # insert or update?
          end
        else
           # update to null or delete?
        end   

        format.html { redirect_to(@lumbarpuncture, :notice => 'Lumbarpuncture was successfully created.') }
        format.xml  { render :xml => @lumbarpuncture, :status => :created, :location => @lumbarpuncture }
      else
        @appointment.delete
        format.html { render :action => "new" }
        format.xml  { render :xml => @lumbarpuncture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lumbarpunctures/1
  # PUT /lumbarpunctures/1.xml
  def update
    puts "hey, we're updating."

        scan_procedure_array = []
        scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
              hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end

        @lumbarpuncture = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                          appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                          and scan_procedure_id in (?))", scan_procedure_array).find(lumbarpuncture_params[:lumbarpuncture][:id])



        # puts "lp date params: #{lumbarpuncture_params[:date]}"
        appointment_date = nil
        if !lumbarpuncture_params[:appointment]["#{'appointment_date'}(1i)"].blank? && !lumbarpuncture_params[:appointment]["#{'appointment_date'}(2i)"].blank? && !lumbarpuncture_params[:appointment]["#{'appointment_date'}(3i)"].blank?
             appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+lumbarpuncture_params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+lumbarpuncture_params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
        end
       
        # ok to update vitals even if other update fail
        if !vitals_params[:vital_id].blank?
          @vital = Vital.find(vitals_params[:vital_id])
          @vital.pulse = vitals_params[:pulse]
          @vital.bp_systol = vitals_params[:bp_systol]
          @vital.bp_diastol = vitals_params[:bp_diastol]
          @vital.bloodglucose = vitals_params[:bloodglucose]
          @vital.save
        else
          @vital = Vital.new
          @vital.appointment_id = @lumbarpuncture.appointment_id
          @vital.pulse = vitals_params[:pulse]
          @vital.bp_systol = vitals_params[:bp_systol]
          @vital.bp_diastol = vitals_params[:bp_diastol]
          @vital.bloodglucose = vitals_params[:bloodglucose]
          @vital.save      
        end
        
        if !lumbarpuncture_params[:lookup_lumbarpuncture_id].blank?
          LookupLumbarpuncture.all.each do |lookup_lp|
              val = nil
              val = lumbarpuncture_params[:lookup_lumbarpuncture_id][lookup_lp.id.to_s].to_s
              if val.blank?
                 val = "0"   # not sure why "" not going to 0
              end
              sql = "INSERT INTO lumbarpuncture_results (lumbarpuncture_id,lookup_lumbarpuncture_id,value) VALUES ("+@lumbarpuncture.id.to_s+","+lookup_lp.id.to_s+",'"+val+"')
                    ON DUPLICATE KEY UPDATE value='"+val+"' "
               ActiveRecord::Base.connection.insert sql
             
              # insert or update?
          end
        else
           # update to null or delete?
        end

        lp_params = lumbarpuncture_params[:lumbarpuncture]

        lp_params[:lpstarttime_time]= "#{lumbarpuncture_params[:time_fields][:lpstarttime_time][:hour].to_s.rjust(2,'0')}:#{lumbarpuncture_params[:time_fields][:lpstarttime_time][:minute].to_s.rjust(2,'0')}"
        lp_params[:lpfluidstarttime_time]= "#{lumbarpuncture_params[:time_fields][:lpfluidstarttime_time][:hour].to_s.rjust(2,'0')}:#{lumbarpuncture_params[:time_fields][:lpfluidstarttime_time][:minute].to_s.rjust(2,'0')}"
        lp_params[:lpendtime_time]= "#{lumbarpuncture_params[:time_fields][:lpendtime_time][:hour].to_s.rjust(2,'0')}:#{lumbarpuncture_params[:time_fields][:lpendtime_time][:minute].to_s.rjust(2,'0')}"

        # puts "final params: #{lp_params}"

        respond_to do |format|

          if @lumbarpuncture.update(lp_params)#params[:lumbarpuncture], :without_protection => true)
           
            @appointment = Appointment.find(@lumbarpuncture.appointment_id)
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
            @appointment.save
            @vgroup.completedlumbarpuncture = 'yes'
            @vgroup.save
            
           

        format.html { redirect_to(@lumbarpuncture, :notice => 'Lumbarpuncture was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lumbarpuncture.errors, :status => :unprocessable_entity }
      end
    end
  end
  
    
 def lp_search 
   if !params[:lp_search].blank?
      @lp_search_params = lp_search_params()
   end
     # make @conditions from search form input, access control in application controller run_search
     @conditions = []
     @current_tab = "lumbarpunctures"
     params["search_criteria"] =""
      hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end

     if params[:lp_search].nil?
          params[:lp_search] =Hash.new  
          params[:lp_search][:lp_status] = "yes"
     end
     
     if !params[:lp_search][:scan_procedure_id].blank?
        condition =" lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                               appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                               and scan_procedure_id in ("+params[:lp_search][:scan_procedure_id].join(',').gsub(/[;:'"“”()=<>]/, '')+"))"
        @conditions.push(condition)
        @scan_procedures = ScanProcedure.where("id in (?)",params[:lp_search][:scan_procedure_id])
        params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
     end
 
     if !params[:lp_search][:enumber].blank?
       params[:lp_search][:enumber] = params[:lp_search][:enumber].gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
       if params[:lp_search][:enumber].include?(',') # string of enumbers
        v_enumber =  params[:lp_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
        v_enumber = v_enumber.gsub(/,/,"','")
          condition =" lumbarpunctures.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
             where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
             and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"“”()=<>]/, '')+"'))"         
       else
        condition =" lumbarpunctures.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
         where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
         and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:lp_search][:enumber].gsub(/[;:'"“”()=<>]/, '')+"')))"
       end
       @conditions.push(condition)
       params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:lp_search][:enumber]
     end      

     if !params[:lp_search][:rmr].blank? 
         condition =" lumbarpunctures.appointment_id in (select appointments.id from appointments,vgroups
                   where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower('"+params[:lp_search][:rmr].gsub(/[;:'"“”()=<>]/, '')+"')   ))"
         @conditions.push(condition)           
         params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:lp_search][:rmr]
     end  

     if !params[:lp_search][:reggieid].blank? 
         reggieid_param = params[:lp_search][:reggieid]
         if reggieid_param.include?(',')
          #this should solve the trailing comma problem
          reggieid_param = reggieid_param.split(',').select { |x| !x.blank? }.collect { |x| x.strip || x }.join(',')
         end
         condition =" lumbarpunctures.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
           where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
           and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                  and participants.reggieid is not NULL and participants.reggieid in ("+reggieid_param.gsub(/[;:'"“”()=<>]/, '')+") )"
         @conditions.push(condition)           
         params["search_criteria"] = params["search_criteria"] +",  Reggie ID ("+reggieid_param+")"
     end  
     
      if !params[:lp_search][:lp_status].blank? 
          condition =" lumbarpunctures.appointment_id in (select appointments.id from appointments,vgroups
                              where appointments.vgroup_id = vgroups.id and  lower(vgroups.completedlumbarpuncture) in (lower('"+params[:lp_search][:lp_status].gsub(/[;:'"“”()=<>]/, '')+"')   ))"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  LP status "+params[:lp_search][:lp_status]
      end 

     #  build expected date format --- between, >, < 
     v_date_latest =""
     #want all three date parts
     if !params[:lp_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:lp_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:lp_search]["#{'latest_timestamp'}(3i)"].blank?
          v_date_latest = params[:lp_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:lp_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:lp_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
     end
     v_date_earliest =""
     #want all three date parts
     if !params[:lp_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:lp_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:lp_search]["#{'earliest_timestamp'}(3i)"].blank?
           v_date_earliest = params[:lp_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:lp_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:lp_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
      end
     v_date_latest = v_date_latest.gsub(/[;:'"()=<>]/, '')
     v_date_earliest = v_date_earliest.gsub(/[;:'"()=<>]/, '')
     if v_date_latest.length>0 && v_date_earliest.length >0
       condition ="  lumbarpunctures.appointment_id in (select appointments.id from appointments where appointments.appointment_date between '"+v_date_earliest+"' and '"+v_date_latest+"' )"
       @conditions.push(condition)
       params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
     elsif v_date_latest.length>0
       condition ="  lumbarpunctures.appointment_id in (select appointments.id from appointments where appointments.appointment_date < '"+v_date_latest+"'  )"
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
     elsif  v_date_earliest.length >0
       condition ="  lumbarpunctures.appointment_id in (select appointments.id from appointments where appointments.appointment_date > '"+v_date_earliest+"' )"
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
      end

      if !params[:lp_search][:gender].blank?
         condition ="  lumbarpunctures.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
          where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
          and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                 and participants.gender is not NULL and participants.gender in ("+params[:lp_search][:gender].gsub(/[;:'"“”()=<>]/, '')+") )"
          @conditions.push(condition)
          if params[:lp_search][:gender] == 1
             params["search_criteria"] = params["search_criteria"] +",  sex is Male"
          elsif params[:lp_search][:gender] == 2
             params["search_criteria"] = params["search_criteria"] +",  sex is Female"
          end
      end   

      if !params[:lp_search][:min_age].blank? && params[:lp_search][:max_age].blank?
          condition ="   lumbarpunctures.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                             where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                          and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                          and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                          and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) >= "+params[:lp_search][:min_age].gsub(/[;:'"“”()=<>]/, '')+"   )"
           @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:lp_search][:min_age]
      elsif params[:lp_search][:min_age].blank? && !params[:lp_search][:max_age].blank?
           condition ="   lumbarpunctures.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                           and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                           and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                       and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) <= "+params[:lp_search][:max_age].gsub(/[;:'"“”()=<>]/, '')+"   )"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:lp_search][:max_age]
      elsif !params[:lp_search][:min_age].blank? && !params[:lp_search][:max_age].blank?
         condition ="    lumbarpunctures.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                            where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                         and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                         and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                     and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) between "+params[:lp_search][:min_age].gsub(/[;:'"“”()=<>]/, '')+" and "+params[:lp_search][:max_age].gsub(/[;:'"“”()=<>]/, '')+"   )"
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:lp_search][:min_age]+" and "+params[:lp_search][:max_age]
      end
      # trim leading ","
      params["search_criteria"] = params["search_criteria"].sub(", ","")

      # adjust columns and fields for html vs xls
     #request_format = request.formats.to_s   
     v_request_format_array = request.formats
      request_format = v_request_format_array[0]
      @html_request ="Y"
      case  request_format
        when "[text/html]","text/html" then  # application/html ?
          @column_headers = ['Date','Protocol','Enumber','RMR','LP status','LP abnormality','LP success','LP followup','Completed Fast','Post-Lp Headache','Needle Size','LP Note', 'Appt Note'] # need to look up values
          # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
          @column_number =   @column_headers.size
          @fields =["vgroups.completedlumbarpuncture", "CASE lumbarpunctures.lpabnormality WHEN 1 THEN 'yes' ELSE 'no' end" ,"CASE lumbarpunctures.lpsuccess WHEN 1 THEN 'yes' WHEN 2 THEN 'unk' ELSE 'no' end ","lumbarpunctures.lpfollownote",
            "CASE lumbarpunctures.completedlpfast WHEN 1 THEN 'yes' ELSE 'no' end","lumbarpunctures.followupheadache","CONCAT(lumbarpunctures.lpneedle_gauge, ' x ',lumbarpunctures.lpneedle_length)",
            "lumbarpunctures.lumbarpuncture_note","lumbarpunctures.id"] # vgroups.id vgroup_id always first, include table name
          @left_join = ["LEFT JOIN employees on lumbarpunctures.lp_exam_md_id = employees.id"] # left join needs to be in sql right after the parent table!!!!!!!
        else
              @html_request ="N"
              @column_headers = ['Date','Protocol','Enumber','RMR','LP success','LP abnormality','LP followup','LP MD','Completed Fast','Fast hrs','Fast min','Fast Completed Unknown','Fast Time as Range','Last Intake hrs','Last Intake min','Last Intake Unknown',
              'LP status',
              'Post-LP Headache','Post-LP Headache-Date Resolved','Post-LP Headache-Severity','Post-LP Headache-Note',
              'Post-LP Low Back Pain','Post-LP Low Back Pain-Date Resolved','Post-LP Low Back Pain-Severity','Post-LP Low Back Pain-Note',
              'Post-LP Other Side Effects','Post-LP Other Side Effects-Date Resolved','Post-LP Other Side Effects-Severity','Post-LP Other Side Effects-Note',
              'Needle Length','Needle Gauge','Needle Type','Needle Type -Other','LP Position','LP Method',
              'Initial Needle Insertion','Fluid Collection Start','Final Needle Removal',
                'CSF Amount Collected (ml)','CSF Initial Amount Stored (ml)','CSF Nucleated Cell Count','CSF Red Cell Count','Cell Count Remarks',
                'If LP unsuccessful-Unable to access CSF','If LP unsuccessful-Participant pain/discomfort','If LP unsuccessful-Participant vasovagal','If LP unsuccessful-Other',
                "Complications - headache",
                  "Complications - other",
                  "Complications - pain",
                  "Complications - radiculopathy",
                  "Complications - vasovagal",
                  "Complications - other specify",
                  "Amount of lidocaine administered",
                  "Position - sitting",
                  "Position - decubitus",
                  "Method - gravity",
                  "Method - aspiration",
                  "Amount collected - gravity",
                  "Amount collected - aspiration",
                'LP Data entered by','LP Data entry date','LP Data QCed by','LP Data QCed date',
               'LP Note', 'Preanalytic protocol', 'Form version', 'BP Systol','BP Diastol','Pulse','Blood Glucose','Age at Appt', 'Appt Note'] # need to look up values
              # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
              @column_number =   @column_headers.size
              @fields =["CASE lumbarpunctures.lpsuccess WHEN 1 THEN 'Yes' WHEN 2 THEN 'unk' ELSE 'No' end ","CASE lumbarpunctures.lpabnormality WHEN 1 THEN 'Yes' ELSE 'No' end" ,"lumbarpunctures.lpfollownote",
                 "concat(employees.first_name,' ',employees.last_name)",
                "CASE lumbarpunctures.completedlpfast WHEN 1 THEN 'Yes' ELSE 'No' end",
                "lumbarpunctures.lpfasttotaltime","lumbarpunctures.lpfasttotaltime_min",  "CASE lumbarpunctures.lpfasttotaltime_unk WHEN 2 THEN 'Unk' ELSE '' end",
                "lumbarpunctures.lpfasttotaltime_range",
                "lumbarpunctures.lptimelastintake","lumbarpunctures.lptimelastintake_min",  "CASE lumbarpunctures.lptimelastintake_unk WHEN 2 THEN 'Unk' ELSE '' end",
                "vgroups.completedlumbarpuncture",
                "lumbarpunctures.followupheadache","DATE_FORMAT(lumbarpunctures.lpheadache_dateresolved,'%Y-%m-%d')","lumbarpunctures.lpheadache_severity","lumbarpunctures.lpheadache_note",
                "lumbarpunctures.lplowbackpain","DATE_FORMAT(lumbarpunctures.lplowbackpain_dateresolved,'%Y-%m-%d')","lumbarpunctures.lplowbackpain_severity","lumbarpunctures.lplowbackpain_note",
                "lumbarpunctures.lpothersideeffects","DATE_FORMAT(lumbarpunctures.lpothersideeffects_dateresolved,'%Y-%m-%d')","lumbarpunctures.lpothersideeffects_severity","lumbarpunctures.lpothersideeffects_note",
                "lumbarpunctures.lpneedle_gauge","lumbarpunctures.lpneedle_length",
                "lumbarpunctures.lpneedletype","lumbarpunctures.lpneedletype_other","lumbarpunctures.lpposition","lumbarpunctures.lpmethod",
                "lumbarpunctures.lpstarttime_time","lumbarpunctures.lpfluidstarttime_time",
                "lumbarpunctures.lpendtime_time",
                 "lumbarpunctures.lpamountcollected","lumbarpunctures.lpinitialamountstored","lumbarpunctures.lpcsfnucleatedcellcount","lumbarpunctures.lpcsfredcellcount","lumbarpunctures.lpcsfcellcount_note",
                 "CASE lumbarpunctures.lpcsfunsuccessful_noaccess WHEN 1 THEN 'yes' ELSE '' end",
                 "CASE lumbarpunctures.lpcsfunsuccessful_pain WHEN 1 THEN 'yes' ELSE '' end",
                 "CASE lumbarpunctures.lpcsfunsuccessful_vasovagal WHEN 1 THEN 'yes' ELSE '' end","lumbarpunctures.lpcsfunsuccessful_other_specify",
                 "lumbarpunctures.lpcomplications_headache",
                  "lumbarpunctures.lpcomplications_other",
                  "lumbarpunctures.lpcomplications_pain",
                  "lumbarpunctures.lpcomplications_radiculopathy",
                  "lumbarpunctures.lpcomplications_vasovagal",
                  "lumbarpunctures.lpcomplications_other_specify",
                  "lumbarpunctures.lpamountoflidocaine",
                  "lumbarpunctures.lpposition_sitting",
                  "lumbarpunctures.lpposition_decubitus",
                  "lumbarpunctures.lpmethod_gravity",
                  "lumbarpunctures.lpmethod_aspiration",
                  "lumbarpunctures.lpmethod_gravity_collected",
                  "lumbarpunctures.lpmethod_aspiration_collected",
                 "concat(u2.first_name,' ',u2.last_name)", "DATE_FORMAT(lumbarpunctures.lp_data_entered_date,'%Y-%m-%d')",
                 "concat(u3.first_name,' ',u3.last_name)", "DATE_FORMAT(lumbarpunctures.lp_data_qced_date,'%Y-%m-%d')",
                "lumbarpunctures.lumbarpuncture_note", "lumbarpunctures.preanalytic_protocol", "lumbarpunctures.form_version","vitals.bp_systol","vitals.bp_diastol","vitals.pulse","vitals.bloodglucose","appointments.age_at_appointment","appointments.comment"] # vgroups.id vgroup_id always first, include table name

              @left_join = ["LEFT JOIN employees on lumbarpunctures.lp_exam_md_id = employees.id",
                "LEFT JOIN users u2 on lumbarpunctures.lp_data_entered_by = u2.id  ",
                "LEFT JOIN users u3 on lumbarpunctures.lp_data_qced_by = u3.id  ",
                            "LEFT JOIN vitals on lumbarpunctures.appointment_id = vitals.appointment_id"] # left join needs to be in sql right after the parent table!!!!!!!
        end


      @tables =['lumbarpunctures'] # trigger joins --- vgroups and appointments by default

      #@conditions =[] # ["scan_procedures.codename='johnson.pipr.visit1'"] # need look up for like, lt, gt, between  
      @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]
            
     @results = self.run_search   # in the application controller
     @results_total = @results  # pageination makes result count wrong
     t = Time.now 
     @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
    @csv_array = []
    @results_tmp_csv = []
    @results_tmp_csv.push(@export_file_title)
    @csv_array.push(@results_tmp_csv )
    @csv_array.push( @column_headers)
    if v_request_format_array[0] == "application/json"
      # want a unique id for lumbarpuncture - not dropping last column
      @results.each do |result| 
         @results_tmp_csv = []
         for i in 0..@column_number  # results is an array of arrays%>
            @results_tmp_csv.push(result[i])
         end 
         @csv_array.push(@results_tmp_csv)
      end

    else
      @results.each do |result| 
         @results_tmp_csv = []
         for i in 0..@column_number-1  # results is an array of arrays%>
            @results_tmp_csv.push(result[i])
         end 
         @csv_array.push(@results_tmp_csv)
      end 
    end
    @csv_str = @csv_array.inject([]) { |csv, row|  csv << CSV.generate_line(row) }.join("")  
     ### LOOK WHERE TITLE IS SHOWING UP
     @collection_title = 'All Lumbarpuncture appts'

     # for json
     # delete 1st row
     # use 2nd row as key for all rest of rows
     # make a hash of items in each row, 
     # make a hash of the hash
     # push this hash into an array
     # makes the same json format as the @lumbarpunctures object
     if v_request_format_array[0] == "application/json"
        @csv_array_json = @csv_array
        @csv_array_json.shift
        @csv_array_json_header = @csv_array_json[0]
        @csv_array_json_header.push("lumbarpuncture_id")
        @csv_array_json.shift  # deleted the first row
        @json_hash_of_hash = Hash[]
        @json_array_of_hash = Array[]
        @csv_array_json.each do |item|
          @h = Hash[]
          @h2 = Hash[]
          v_cnt = 0
          @csv_array_json_header.each do |header_col|
            @h[header_col] = item[v_cnt]
            v_cnt = v_cnt + 1
          end
         #@json_hash_of_hash[item[v_cnt-1]]= @h
         @h2["lumbarpuncture"]= @h
         @json_array_of_hash.push(@h2)
        end

    end

     respond_to do |format|
       format.xls # lp_search.xls.erb
       format.csv { send_data @csv_str }
       format.xml  { render :xml => @lumbarpunctures }       
       format.html {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)} # lp_search.html.erb
       format.json { send_data @json_array_of_hash.to_json } #render :json =>  @json_array_of_hash.to_json} # @test_to_json_lumbarpunctures}
     end
   end
  
  

  # DELETE /lumbarpunctures/1
  # DELETE /lumbarpunctures/1.xml
  def destroy
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
     
    @lumbarpuncture = Lumbarpuncture.where("lumbarpunctures.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                      appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                      and scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    
    if @lumbarpuncture.appointment_id > 3156 # sure appointment_id not used by any other
       @appointment = Appointment.find(@lumbarpuncture.appointment_id)
       @appointment.destroy
    end
    @lumbarpuncture.destroy

    respond_to do |format|
      format.html { redirect_to(lp_search_path) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_lumbarpuncture
       @lumbarpuncture = Lumbarpuncture.find(params[:id])
    end

    def vitals_params
      params.permit(:pulse,:bp_systol,:bp_diastol,:bloodglucose,:vital_id)
    end
   def lumbarpuncture_params
          # params.permit!
          params.permit(vgroup:[],:lumbarpuncture =>[:id, :lpfasttotaltime_min,:lpfasttotaltime,:lumbarpuncture_note,:enteredlumbarpuncturewho,:enteredlumbarpuncturedate,:needlesize,
          :followupheadache,:lpstarttime,:lpendtime,:lpstarttime_hour,:lpstarttime_minute,:lpendtime_hour,:lpendtime_minute,:enteredlumbarpuncture,:completedlumbarpuncture_moved_to_vgroups,
          :lpfollownote,:id,:completedlpfast,:lp_exam_md_id,:lpsuccess,:lpabnormality,:appointment_id, :lptimelastintake, :lptimelastintake_min, :lptimelastintake_unk, 
          :lpfasttotaltime_unk, :lpamountcollected, :lpinitialamountstored, :lpneedletype, :lpneedletype_other, :lpposition, :lpmethod, :lpfluidstarttime, :lpfluidstarttime_hour, 
          :lpfluidstarttime_minute, :lpheadache_dateresolved, :lpheadache_severity, :lpheadache_note, :lplowbackpain, :lplowbackpain_dateresolved, :lplowbackpain_severity, 
          :lplowbackpain_note, :lpothersideeffects, :lpothersideeffects_dateresolved, :lpothersideeffects_severity, :lpothersideeffects_note, :lpcsfnucleatedcellcount, 
          :lpcsfredcellcount, :lpcsfcellcount_note, :lpcsfunsuccessful_noaccess, :lpcsfunsuccessful_pain, :lpcsfunsuccessful_vasovagal, :lpcsfunsuccessful_other, 
          :lpcsfunsuccessful_other_specify,:lp_data_entered_by,:lp_data_entered_date,:lp_data_qced_by,:lp_data_qced_date,:lpfasttotaltime_range, 
          :lpcomplications_headache,:lpcomplications_other,:lpcomplications_pain, :lpcomplications_radiculopathy, :lpcomplications_vasovagal, :lpcomplications_other_specify,
          :lpamountoflidocaine, :lpneedle_gauge, :lpneedle_length, :lpposition_sitting, :lpposition_decubitus, :lpmethod_gravity, :lpmethod_aspiration, :lpmethod_gravity_collected,
          :lpmethod_aspiration_collected, :lpheadache, :preanalytic_protocol, :form_version, :lpstarttime_time => [:hour, :minute], :lpfluidstarttime_time => [:hour, :minute], :lpendtime_time => [:hour, :minute]],
          :time_fields => [:lpstarttime_time => [:hour, :minute], :lpfluidstarttime_time => [:hour, :minute], :lpendtime_time => [:hour, :minute]], 
          appointment:[:appointment_date, :appointment_coordinator, :comment]
          ) #,:temp_fklumbarpunctureid)

   end 
   def appointment_params
      params.require(:appointment).permit!
    end
   def lp_search_params
          params.require(:lp_search).permit!
   end
end
