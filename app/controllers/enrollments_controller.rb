# encoding: utf-8
class EnrollmentsController < ApplicationController
  
  before_filter :set_current_tab
  
  def set_current_tab
    @current_tab = "enroll_parti_sp"
  end
  

    def enrollment_search


        # possible params -- enrollments fields just get added as AND statements
        #   other table fields should be grouped into one lower level IN select 
        # scan_procedures_vgroups.scan_procedures_id
        # vgroups.rmr
        # vgroups.path
        # vgroups.date scan date before = latest_timestamp(1i)(2i)(3i)
        # vgroups.date scan date after  = earliest_timestamp(1i)(2i)(3i)
        #enrollment_vgroup_memberships.enrollment_id enrollments.enumber
        
        # age at ANY of the appointments
      
      @conditions = []
      params[:search] =Hash.new
       if params[:enrollment_search].nil?
            params[:enrollment_search] =Hash.new  
       end
       params["search_criteria"] = ""
        scan_procedure_array =current_user[:view_low_scan_procedure_array]
            scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
                  hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end

        if !params[:enrollment_search][:scan_procedure_id].blank?
              condition =" enrollments.id in (select enrollments.id from enrollments,  enrollment_vgroup_memberships, scan_procedures_vgroups
                              where enrollment_vgroup_memberships.enrollment_id = enrollments.id  
                           and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                           and scan_procedures_vgroups.scan_procedure_id in ("+params[:enrollment_search][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+"))"
              @conditions.push(condition)
              @scan_procedures = ScanProcedure.where("id in (?)",params[:enrollment_search][:scan_procedure_id])
              params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe            
        end

        if !params[:enrollment_search][:enumber].blank?
            
            if params[:enrollment_search][:enumber].include?(',') # string of enumbers
             v_enumber =  params[:enrollment_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
             v_enumber = v_enumber.gsub(/,/,"','")
             condition =" enrollments.id in (select enrollments.id from enrollments
                                        where  lower(enrollments.enumber) in  ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"')) "
          
            else 
            condition ="  enrollments.id in (select enrollments.id from enrollments
                                        where lower(enrollments.enumber) in (lower('"+params[:enrollment_search][:enumber].gsub(/[;:'"()=<>]/, '')+"')) )"
             end
             @conditions.push(condition)
             params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:enrollment_search][:enumber]
          end      

          if !params[:enrollment_search][:rmr].blank? 
              condition ="  enrollments.id in (select enrollments.id from enrollments,  enrollment_vgroup_memberships, scan_procedures_vgroups,vgroups
                                 where enrollment_vgroup_memberships.enrollment_id = enrollments.id  
                              and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                              and vgroups.id = enrollment_vgroup_memberships.vgroup_id
                              and lower(vgroups.rmr) in (lower('"+params[:enrollment_search][:rmr].gsub(/[;:'"()=<>]/, '')+"')   ))"
              @conditions.push(condition)           
              params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:enrollment_search][:rmr]
          end


 

            if !params[:enrollment_search][:wrapnum].blank?
   
              condition ="  enrollments.id in (select enrollments.id from enrollments, participants 
                where  participants.id = enrollments.participant_id 
                       and participants.wrapnum is not NULL and participants.wrapnum in (lower('"+params[:enrollment_search][:wrapnum].gsub(/[;:'"()=<>]/, '')+"')   ) )"
              @conditions.push(condition)           
              params["search_criteria"] = params["search_criteria"] +",  Wrapnum "+params[:enrollment_search][:wrapnum]
            end
            
            if !params[:enrollment_search][:reggieid].blank?
   
             condition ="  enrollments.id in (select enrollments.id from enrollments,   participants
                where  participants.id = enrollments.participant_id 
                       and participants.reggieid is not NULL and participants.reggieid in (lower('"+params[:enrollment_search][:reggieid].gsub(/[;:'"()=<>]/, '')+"')   ))"
              @conditions.push(condition)           
              params["search_criteria"] = params["search_criteria"] +",  reggieid "+params[:enrollment_search][:reggieid]
            end

         # NEED TO CHANGE TO BE FOR ANY APPOITMENT 
               #  build expected date format --- between, >, < 
      v_date_latest =""
      #want all three date parts
      if !params[:enrollment_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:enrollment_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:enrollment_search]["#{'latest_timestamp'}(3i)"].blank?
           v_date_latest = params[:enrollment_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:enrollment_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:enrollment_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
      end
      v_date_earliest =""
      #want all three date parts
      if !params[:enrollment_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:enrollment_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:enrollment_search]["#{'earliest_timestamp'}(3i)"].blank?
            v_date_earliest = params[:enrollment_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:enrollment_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:enrollment_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
       end
      v_date_latest = v_date_latest.gsub(/[;:'"()=<>]/, '')
      v_date_earliest = v_date_earliest.gsub(/[;:'"()=<>]/, '')
      if v_date_latest.length>0 && v_date_earliest.length >0
        condition ="  enrollments.id in  (select enrollment_vgroup_memberships.enrollment_id from vgroups, enrollment_vgroup_memberships where enrollment_vgroup_memberships.vgroup_id = vgroups.id and 
                                                                vgroups.vgroup_date between '"+v_date_earliest+"' and '"+v_date_latest+"' )"
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +",  vvgroup date between "+v_date_earliest+" and "+v_date_latest
      elsif v_date_latest.length>0
        condition ="  enrollments.id  in (select enrollment_vgroup_memberships.enrollment_id from vgroups,enrollment_vgroup_memberships  where enrollment_vgroup_memberships.vgroup_id = vgroups.id and  vgroups.vgroup_date < '"+v_date_latest+"'  )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  vgroup date before "+v_date_latest 
      elsif  v_date_earliest.length >0
        condition ="  enrollments.id  in (SElect enrollment_vgroup_memberships.enrollment_id from vgroups,enrollment_vgroup_memberships  where enrollment_vgroup_memberships.vgroup_id = vgroups.id and vgroups.vgroup_date > '"+v_date_earliest+"' )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  vgroup date after "+v_date_earliest
       end

       if !params[:enrollment_search][:gender].blank?
          condition =" enrollments.id in ( select enrollments.id from enrollments , participants where participants.id = enrollments.participant_id and participants.gender in ("+params[:enrollment_search][:gender].gsub(/[;:'"()=<>]/, '')+") )"
           @conditions.push(condition)
           if params[:enrollment_search][:gender] == 1
              params["search_criteria"] = params["search_criteria"] +",  sex is Male"
           elsif params[:enrollment_search][:gender] == 2
              params["search_criteria"] = params["search_criteria"] +",  sex is Female"
           end
       end   

         if !params[:enrollment_search][:min_age].blank? && params[:enrollment_search][:max_age].blank?
             condition ="  enrollments.id in  (select   enrollments.id from enrollments,  enrollment_vgroup_memberships, scan_procedures_vgroups,vgroups, participants
                                where participants.id = enrollments.participant_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id  
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and vgroups.id = enrollment_vgroup_memberships.vgroup_id
                             and round((DATEDIFF(vgroups.vgroup_date,participants.dob)/365.25),2) >= "+params[:enrollment_search][:min_age].gsub(/[;:'"()=<>]/, '')+"   )"
            @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:enrollment_search][:min_age]
         elsif params[:enrollment_search][:min_age].blank? && !params[:enrollment_search][:max_age].blank?
              condition ="  enrollments.id in  (select  enrollments.id from enrollments,  enrollment_vgroup_memberships, scan_procedures_vgroups,vgroups,participants
                              where participants.id = enrollments.participant_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id  
                          and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                          and vgroups.id = enrollment_vgroup_memberships.vgroup_id
                          and round((DATEDIFF(vgroups.vgroup_date,participants.dob)/365.25),2) <= "+params[:enrollment_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
              @conditions.push(condition)
              params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:enrollment_search][:max_age]
         elsif !params[:enrollment_search][:min_age].blank? && !params[:enrollment_search][:max_age].blank?
            condition =" enrollments.id in  (select   enrollments.id from enrollments,  enrollment_vgroup_memberships, scan_procedures_vgroups,vgroups,participants
                            where participants.id = enrollments.participant_id and enrollment_vgroup_memberships.enrollment_id = enrollments.id  
                        and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                        and vgroups.id = enrollment_vgroup_memberships.vgroup_id
                        and  round((DATEDIFF(vgroups.vgroup_date,participants.dob)/365.25),2) between "+params[:enrollment_search][:min_age].gsub(/[;:'"()=<>]/, '')+" and "+params[:enrollment_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:enrollment_search][:min_age]+" and "+params[:enrollment_search][:max_age]
         end

       # adjust columns and fields for html vs xls
       request_format = request.formats.to_s
       @html_request ="Y"
       case  request_format
         when "[text/html]","text/html" then # ? application/html
           @column_headers = [ 'Enroll Number'] # need to look up values
               # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
           @column_number =   @column_headers.size
           @fields =["enrollments.id"] 
              # need to get enumber in line
            @left_join = [] # left join needs to be in sql right after the parent table!!!!!!!
         else    
           @html_request ="N"          
            @column_headers = [ 'Enroll Number']# need to look up values
                  # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
            @column_number =   @column_headers.size
            @fields =["enrollments.id"] 
              # need to get enumber in line
            @left_join = [] # left join needs to be in sql right after the parent table!!!!!!!   
                        
                 
         end
       @tables =['enrollments'] # trigger joins --- vgroups and appointments by default
       @order_by =["enrollments.id desc"]

      @results = self.run_search_enrollment   # in the application controller
      @results_total = @results  # pageination makes result count wrong
      t = Time.now 
      if params["search_criteria"].blank?
        params["search_criteria"] = ""
      end
      @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")

      ### LOOK WHERE TITLE IS SHOWING UP
      @collection_title = 'All enrollments'
      @current_tab = "enrollments"

         #   export_record.gsub!('%28','(')
         #   export_record.gsub!('%29',')')

      respond_to do |format|
        format.xls # pet_search.xls.erb
        format.xml  { render :xml => @results }    # actually redefined in the xls page    
        format.html {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)} # pet_search.html.erb
      end



    #    render :template => "visits/enrollment_search"    
    
  end
  # GET /enrollments
  # GET /enrollments.xml
  def index
       scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)

             hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    # Hack for Autocomplete Enrollment Number AJAX Search
    #if params[:search].kind_of? String
    #  search_hash = {:enumber_contains => params[:search]}
    #else
    #  search_hash = params[:search]
    #end
#    @search = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).search(search_hash).relation.page(params[:page])
#     @search = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships,scan_procedures_visits
#        where enrollment_visit_memberships.visit_id = scan_procedures_visits.visit_id and  scan_procedures_visits.scan_procedure_id in (?)) ", scan_procedure_array).search(search_hash).relation.page(params[:page]) 
 @results = Enrollment.where(" enrollments.id in (select enrollment_vgroup_memberships.enrollment_id from enrollment_vgroup_memberships, scan_procedures_vgroups
       where enrollment_vgroup_memberships.vgroup_id = scan_procedures_vgroups.vgroup_id and scan_procedures_vgroups.scan_procedure_id in (?) ) 
       OR enrollments.id not in (select enrollment_vgroup_memberships.enrollment_id from enrollment_vgroup_memberships) ", scan_procedure_array)
     
    @enrollments = @results
    
    respond_to do |format|
      format.html {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)} # index.html.erb
      format.xml  { render :xml => @enrollments }
      format.js { render :action => 'index.js.erb'}
    end
  end

  # GET /enrollments/1
  # GET /enrollments/1.xml
  def show
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
#    @enrollment = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])
#     @enrollment = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships, scan_procedures_visits
#                   where enrollment_visit_memberships.visit_id = scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?)) ", scan_procedure_array).find(params[:id])

     if current_user.role == 'Admin_High' # want to get enrollments not linked to any vgroups -- bypass access control for admin, so can unlink from participant
         @enrollment = Enrollment.find(params[:id])
     else
       @enrollment = Enrollment.where(" enrollments.id in (select enrollment_vgroup_memberships.enrollment_id from enrollment_vgroup_memberships, scan_procedures_vgroups
        where enrollment_vgroup_memberships.vgroup_id = scan_procedures_vgroups.vgroup_id and scan_procedures_vgroups.scan_procedure_id in (?)) ", scan_procedure_array).find(params[:id])
     end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @enrollment }
    end
  end

  # GET /enrollments/new
  # GET /enrollments/new.xml
  def new
    @enrollment = Enrollment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @enrollment }
    end
  end

  # GET /enrollments/1/edit
  def edit
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
#    @enrollment = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])
    if current_user.role == 'Admin_High'
        @enrollment = Enrollment.find(params[:id])
     
    else
       @enrollment = Enrollment.where(" enrollments.id in (select enrollment_vgroup_memberships.enrollment_id from enrollment_vgroup_memberships, scan_procedures_vgroups
           where enrollment_vgroup_memberships.vgroup_id = scan_procedures_vgroups.vgroup_id and scan_procedures_vgroups.scan_procedure_id in (?)) ", scan_procedure_array).find(params[:id])
     end
  end

  # POST /enrollments
  # POST /enrollments.xml
  def create
    @enrollment = Enrollment.new(params[:enrollment])
 

    respond_to do |format|
      if @enrollment.save
        flash[:notice] = 'Enrollment was successfully created.'
        format.html { redirect_to(@enrollment) }
        format.xml  { render :xml => @enrollment, :status => :created, :location => @enrollment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @enrollment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /enrollments/1
  # PUT /enrollments/1.xml
  def update
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
#    @enrollment = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])
    if current_user.role == 'Admin_High'
        @enrollment = Enrollment.find(params[:id])
    else
          @enrollment = Enrollment.where(" enrollments.id in (select enrollment_vgroup_memberships.enrollment_id from enrollment_vgroup_memberships, scan_procedures_vgroups
           where enrollment_vgroup_memberships.vgroup_id = scan_procedures_vgroups.vgroup_id and  scan_procedures_vgroups.scan_procedure_id in (?)) ", scan_procedure_array).find(params[:id])
    end 

    respond_to do |format|
      if @enrollment.update_attributes(params[:enrollment])
        if current_user.role == 'Admin_High'
          if !params[:cleanup][:set_participant_id_blank].blank?
             @enrollment.participant_id = nil
             @enrollment.save
          end
          connection = ActiveRecord::Base.connection();
          if @enrollment.do_not_share_scans_flag  == "Y"
              sql = "update vgroups set vgroups.do_not_share_scans ='DO NOT SHARE' 
                        where vgroups.id in ( select enrollment_vgroup_memberships.vgroup_id 
                                               from enrollment_vgroup_memberships 
                                                where enrollment_vgroup_memberships.enrollment_id = "+params[:id]+") "
              @results = connection.execute(sql)
          else
              sql = "update vgroups set vgroups.do_not_share_scans = NULL
                        where vgroups.id in ( select enrollment_vgroup_memberships.vgroup_id 
                                               from enrollment_vgroup_memberships 
                                                where enrollment_vgroup_memberships.enrollment_id = "+params[:id]+") "
               @results = connection.execute(sql)
          end
        end
        flash[:notice] = 'Enrollment was successfully updated.'
        format.html { redirect_to(@enrollment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @enrollment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /enrollments/1
  # DELETE /enrollments/1.xml
  def destroy
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
#    @enrollment = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])
    if current_user.role == 'Admin_High'
        @enrollment = Enrollment.find(params[:id]) 
    else
       @enrollment = Enrollment.where(" enrollments.id in (select enrollment_vgroup_memberships.enrollment_id from enrollment_vgroup_memberships, scan_procedures_vgroups
       where enrollment_vgroup_memberships.vgroup_id = scan_procedures_vgroups.vgroup_id and scan_procedures_vgroups.scan_procedure_id in (?)) ", scan_procedure_array).find(params[:id])
     end
    @enrollment.destroy

    respond_to do |format|
      format.html { redirect_to(enrollments_url) }
      format.xml  { head :ok }
    end
  end
end
