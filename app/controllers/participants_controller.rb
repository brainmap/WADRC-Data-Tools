class ParticipantsController < ApplicationController
  
  PER_PAGE = 50
  
  before_filter :set_current_tab
  
  def set_current_tab
    @current_tab = "participants"
  end
  
  # GET /participants
  # GET /participants.xml
  def index
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
#    @search = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?)))) ", scan_procedure_array).search(params[:search])
     
#     @search = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in (select enrollment_visit_memberships.enrollment_id
#      from enrollment_visit_memberships, scan_procedures_visits
#      where enrollment_visit_memberships.visit_id = scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?))) ", scan_procedure_array).search(params[:search])
 
 @search = Participant.where(" participants.id in ( select participant_id from enrollments,enrollment_visit_memberships, scan_procedures_visits
      where enrollments.id = enrollment_visit_memberships.enrollment_id
     and  enrollment_visit_memberships.visit_id = scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?)) ", scan_procedure_array).search(params[:search])
           
    @participants = @search.relation.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @participants }
    end
  end

  # GET /participants/1
  # GET /participants/1.xml
  def show
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
#    @participant = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?)))) ", scan_procedure_array).find(params[:id])
     
     @participant = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships, scan_procedures_visits
           where enrollment_visit_memberships.visit_id = scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @participant }
    end
  end

  # GET /participants/new
  # GET /participants/new.xml
  def new
    @participant = Participant.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @participant }
    end
  end

  # GET /participants/1/edit
  def edit
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
#    @participant = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?)))) ", scan_procedure_array).find(params[:id])
     @participant = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in 
     (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships,scan_procedures_visits
      where enrollment_visit_memberships.visit_id = scan_procedures_visits.visit_id and  scan_procedures_visits.scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])
  end

  # POST /participants
  # POST /participants.xml
  def create
    @participant = Participant.new(params[:participant])

    respond_to do |format|
      if @participant.save
        flash[:notice] = 'Participant was successfully created.'
        format.html { redirect_to(@participant) }
        format.xml  { render :xml => @participant, :status => :created, :location => @participant }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @participant.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /participants/1
  # PUT /participants/1.xml
  def update
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
#    @participant = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?)))) ", scan_procedure_array).find(params[:id])
     @participant = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships, scan_procedures_visits
                 where enrollment_visit_memberships.visit_id  =  scan_procedures_visits.visit_id and  scan_procedures_visits.scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])

    respond_to do |format|
      if @participant.update_attributes(params[:participant])
        flash[:notice] = 'Participant was successfully updated.'
        format.html { redirect_to(@participant) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @participant.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def participant_search


        # possible params -- participants fields just get added as AND statements
        #   other table fields should be grouped into one lower level IN select 
        # scan_procedures_visits.scan_procedures_id
        # visits.rmr
        # visits.path
        # visits.date scan date before = latest_timestamp(1i)(2i)(3i)
        # visits.date scan date after  = earliest_timestamp(1i)(2i)(3i)
        #enrollment_visit_memberships.enrollment_id enrollments.enumber
        
        # age at ANY of the appointments


       if params[:participant_search].nil?
            params[:participant_search] =Hash.new  
       end
        scan_procedure_array =current_user[:view_low_scan_procedure_array]
            scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
        # Remove default scope if sorting has been requested.
        @search = Participant.search(params[:search]) 
          if !params[:participant_search][:scan_procedure_id].blank?
             @search =@search.where(" participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits
                               where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id
                            and scan_procedures_visits.scan_procedure_id in (?))",params[:participant_search][:scan_procedure_id])
          end

          if !params[:participant_search][:enumber].blank?
             @search =@search.where("  participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments
                                        where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                                          and lower(enrollments.enumber) in (lower(?)))",params[:participant_search][:enumber])
          end      

          if !params[:participant_search][:rmr].blank? 
              @search = @search.where("  participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits,visits
                                 where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                              and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id 
                              and visits.id = enrollment_visit_memberships.visit_id
                              and lower(visits.rmr) in (lower(?)  ) )",params[:participant_search][:rmr])
          end

           #  build expected date format --- between, >, < 
           v_date_latest =""
           #want all three date parts

           if !params[:participant_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:participant_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:participant_search]["#{'latest_timestamp'}(3i)"].blank?
                v_date_latest = params[:participant_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:participant_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:participant_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
           end

           v_date_earliest =""
           #want all three date parts

           if !params[:participant_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:participant_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:participant_search]["#{'earliest_timestamp'}(3i)"].blank?
                 v_date_earliest = params[:participant_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:participant_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:participant_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
            end

           if v_date_latest.length>0 && v_date_earliest.length >0
             @search = @search.where("  participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments,visits
               where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                      and visits.id = enrollment_visit_memberships.visit_id
                      and   visits.date between ? and ? )",v_date_earliest,v_date_latest)
           elsif v_date_latest.length>0
             @search = @search.where(" participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments,visits
                where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                       and visits.id = enrollment_visit_memberships.visit_id
                       and visits.date < ?  )",v_date_latest)
           elsif  v_date_earliest.length >0
             @search = @search.where(" participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments,visits
                where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                       and visits.id = enrollment_visit_memberships.visit_id
                       and visits.date > ? )",v_date_earliest)
            end

            if !params[:participant_search][:gender].blank?
   
              @search =@search.where(" participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments
                where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
                       and participants.gender is not NULL and participants.gender in (?) )", params[:participant_search][:gender])
            end   

            if !params[:participant_search][:wrapnum].blank?
   
              @search =@search.where(" participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments
                where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
                       and participants.wrapnum is not NULL and participants.wrapnum in (?) )", params[:participant_search][:wrapnum])
            end
            
            if !params[:participant_search][:reggieid].blank?
   
              @search =@search.where(" participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments
                where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
                       and participants.reggieid is not NULL and participants.reggieid in (?) )", params[:participant_search][:reggieid])
            end

         # NEED TO CHANGE TO BE FOR ANY APPOITMENT 

         if !params[:participant_search][:min_age].blank? && params[:participant_search][:max_age].blank?
             @search = @search.where("  participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits,visits
                                where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id 
                             and visits.id = enrollment_visit_memberships.visit_id
                             and floor(DATEDIFF(visits.date,participants.dob)/365.25) >= ?   )",params[:participant_search][:min_age])
         elsif params[:participant_search][:min_age].blank? && !params[:participant_search][:max_age].blank?
              @search = @search.where("  participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits,visits
                              where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                          and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id 
                          and visits.id = enrollment_visit_memberships.visit_id
                          and floor(DATEDIFF(visits.date,participants.dob)/365.25) <= ?   )",params[:participant_search][:max_age])
         elsif !params[:participant_search][:min_age].blank? && !params[:participant_search][:max_age].blank?
            @search = @search.where("  participants.id in (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits,visits
                            where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                        and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id 
                        and visits.id = enrollment_visit_memberships.visit_id
                        and floor(DATEDIFF(visits.date,participants.dob)/365.25) between ? and ?   )",params[:participant_search][:min_age],params[:participant_search][:max_age])
         end

        @search  =  @search.where(" participants.id in     (select enrollments.participant_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits
                               where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id
                            and Scan_procedures_visits.scan_procedure_id in (?))", scan_procedure_array)
       @participants  =  @search.page(params[:page]) 

        ### LOOK WHERE TITLE IS SHOWING UP
        @collection_title = 'All participants'


    limit_visits =  [:user_id ,:initials,:transfer_mri,:transfer_pet,:conference,:dicom_dvd,:compile_folder,:id,
                      :created_at, :updated_at, :research_diagnosis, :consent_form_type, :created_by_id, :dicom_study_uid,:compiled_at]



    ### if Radiology - pass in params -- do same seach, but call differ respond_to
    ### add radiology_comments, image_dataset comment, and image_dataset_quality_check columns to visit?
    ### define what field go out
    #     light_include_options = :visit
            export_record = participant_search_path(:participant_search => params[:participant_search], :format => :csv)
            export_record.gsub!('%28','(')
            export_record.gsub!('%29',')')


            #current_user.id.to_s 
            # add export_log
      @current_tab = "participants"
        respond_to do |format|
          format.html {render :template => "participants/participant_search"}
          format.csv  { render :csv => @participants.csv_download(@search) }
        end
    #    render :template => "visits/participant_search"    
    
  end

  # DELETE /participants/1
  # DELETE /participants/1.xml
  def destroy
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
#    @participant = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
#     (select visit_id from scan_procedures_visits where scan_procedure_id in (?)))) ", scan_procedure_array).find(params[:id])
     
     @participant = Participant.where(" participants.id in ( select participant_id from enrollments where enrollments.id in 
     (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships, scan_procedures_visits
      where enrollment_visit_memberships.visit_id = scan_procedures_visits.visit_id and  scan_procedures_visits.scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id]) 
    @participant.destroy

    respond_to do |format|
      format.html { redirect_to(participants_url) }
      format.xml  { head :ok }
    end
  end
end
