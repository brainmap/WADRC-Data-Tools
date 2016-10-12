# encoding: utf-8
class VgroupsController < ApplicationController
  # GET /vgroups
  # GET /vgroups.xml
  require 'csv'
  def index
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @vgroups = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vgroups }
    end
  end

  def change_appointment_vgroup
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    
      # check that a valid vgroup_id
      sql = "select count(*) cnt from vgroups where id ="+params[:target_vgroup_id] 
      connection = ActiveRecord::Base.connection();
      @results = connection.execute(sql)
      cnt =10
      @results.each do |r|
        cnt=r[0]
      end
      if cnt.to_i > 0

         # update appointments.vgroup_id to new vgroup_id
         # delete old vgroup is last appointment???
         sql = "update appointments set appointments.vgroup_id = "+params[:target_vgroup_id]+" where appointments.id ="+params[:move_appointemnt_id][0]
         @results = connection.execute(sql)
         respond_to do |format|
            format.html { redirect_to( '/vgroups/'+params[:id], :notice => 'Appointment was moved to vgroup '+params[:target_vgroup_id]+'.' )}
            format.xml  { render :xml => @vgroup }
          end
      else
        respond_to do |format|
           format.html { redirect_to( '/vgroups/'+params[:id], :notice => 'The vgroup_id was not valid.' )}
           format.xml  { render :xml => @vgroup }
         end
      end
  end
  def change_qc_vgroup
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @vgroup.entered_by =params[:vgroup][:entered_by]
    @vgroup.qc_by =params[:vgroup][:qc_by]
    @vgroup.qc_completed =params[:vgroup][:qc_completed]
    @vgroup.dicom_dvd =params[:vgroup][:dicom_dvd]
    @vgroup.compile_folder = params[:vgroup][:compile_folder]
    @vgroup.save
    respond_to do |format|
       format.html { redirect_to( '/vgroups/'+params[:id], :notice => ' ' )}
       format.xml  { render :xml => @vgroup }
     end  
  end
  
  def change_completedquestionnaire_vgroup
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @vgroup.completedquestionnaire =params[:vgroup][:completedquestionnaire]
    @vgroup.save
    respond_to do |format|
       format.html { redirect_to( '/vgroups/'+params[:id], :notice => ' ' )}
       format.xml  { render :xml => @vgroup }
     end  
  end
    
  def change_completedneuropsych_vgroup
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @vgroup.completedneuropsych =params[:vgroup][:completedneuropsych]
    @vgroup.save
    respond_to do |format|
       format.html { redirect_to( '/vgroups/'+params[:id], :notice => ' ' )}
       format.xml  { render :xml => @vgroup }
     end  
  end  
  
  
  
  def change_completedblooddraw_vgroup
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @vgroup.completedblooddraw =params[:vgroup][:completedblooddraw]
    @vgroup.save
    respond_to do |format|
       format.html { redirect_to( '/vgroups/'+params[:id], :notice => ' ' )}
       format.xml  { render :xml => @vgroup }
     end  
  end  
  
  
  def change_completedlumbarpuncture_vgroup
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @vgroup.completedlumbarpuncture =params[:vgroup][:completedlumbarpuncture]
    @vgroup.save
    respond_to do |format|
       format.html { redirect_to( '/vgroups/'+params[:id], :notice => ' ' )}
       format.xml  { render :xml => @vgroup }
     end  
  end
  
  
  def change_transfer_pet_vgroup
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @vgroup.transfer_pet =params[:vgroup][:transfer_pet]
    @vgroup.save
    respond_to do |format|
       format.html { redirect_to( '/vgroups/'+params[:id], :notice => ' ' )}
       format.xml  { render :xml => @vgroup }
     end  
  end

  def change_transfer_mri_vgroup
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @vgroup.transfer_mri =params[:vgroup][:transfer_mri]
    @vgroup.save
    respond_to do |format|
       format.html { redirect_to( '/vgroups/'+params[:id], :notice => ' ' )}
       format.xml  { render :xml => @vgroup }
     end  
  end

  def change_consent_form_vgroup
    new_consent_form_id = params[:consent_form][:id]
    new_consent_form_date = params["consent_form"]["date(1i)"].to_s+"-"+params["consent_form"]["date(2i)"].rjust(2,"0").to_s+"-"+params["consent_form"]["date(3i)"].rjust(2,"0").to_s
    consent_forms = params[:consent_form]["delete"]
    if !consent_forms.nil?
       consent_forms.each do |v_index,v_val|
             if v_val == "1"
                existing_consent_form_vgroup = ConsentFormVgroup.find(v_index)
                existing_consent_form_vgroup.destroy
             end
       end
    end
    if  !new_consent_form_id.empty? 
       consent_form_vgroup = ConsentFormVgroup.new
       consent_form_vgroup.vgroup_id = params[:id]
       consent_form_vgroup.consent_form_id = new_consent_form_id
       consent_form_vgroup.consent_date = new_consent_form_date
       consent_form_vgroup.user_id = current_user.id
       consent_form_vgroup.save
    end                 
    respond_to do |format|
       format.html { redirect_to( '/vgroups/'+params[:id], :notice => ' ' )}
       format.xml  { render :xml => @vgroup }
     end
  end

  # GET /vgroups/1
  # GET /vgroups/1.xml
  def show
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find_by_id(params[:id])
    # if the vgroup is not linked to a scan protocol, the access control breaks down
    # to get at vgroups without sp's need to be admin - also check that not linked to any sp
    @scan_procedures_vgroups = ScanProcedure.where("scan_procedures.id in (select scan_procedure_id from scan_procedures_vgroups where  vgroup_id in (?))",params[:id]) 
    @consent_forms = ConsentForm.where("consent_forms.id in (select consent_form_id from consent_form_scan_procedures where scan_procedure_id in (?)) OR consent_forms.id not in (select consent_form_id from consent_form_scan_procedures) ",@scan_procedures_vgroups)
    @consent_form_vgroups = ConsentFormVgroup.where("consent_form_vgroups.vgroup_id in  (?) and status_flag ='Y' ",params[:id]) 


    if(@vgroup.nil? and  current_user.role == 'Admin_High' and @scan_procedures_vgroups.size <1)
         @vgroup = Vgroup.find(params[:id])
     end 

    @trfiles = Trfile.where("trfiles.scan_procedure_id in (select scan_procedure_id from scan_procedures_vgroups where vgroup_id in (?))",@vgroup.id).where("trfiles.enrollment_id in (select enrollment_id from enrollment_vgroup_memberships where vgroup_id in (?))",@vgroup.id)

    if current_user.role == 'Admin_High'
        # for changing appointment vgroup_id    
        @appointments = Appointment.order("appointments.appointment_type ASC").where("appointments.vgroup_id in (?)", params[:id])
        v_appointment_array = Array.new 
        i = 0
        @appointments.each do |appointment|
            v_temp_array = [[appointment.appointment_type+"-"+(appointment.appointment_date).to_s, appointment.id]]
            if i > 0 
               @v_appointment_array.concat(v_temp_array)
            else
               @v_appointment_array = v_temp_array
            end
            i = 1
        end 
        
        @possible_vgroups = Vgroup.where("vgroups.id != (?) and 
                (vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships 
                                        where enrollment_vgroup_memberships.enrollment_id in
                                                  (select enrollment_id from enrollment_vgroup_memberships where vgroup_id in (?))
              or vgroups.id in (select id from vgroups where rmr in (?) and rmr is not NULL and rmr != '')
              or vgroups.id in (select id from vgroups where participant_id in (?) and participant_id is not NULL and participant_id != '')
                              ))", params[:id],params[:id],@vgroup.rmr,@vgroup.participant_id)
        
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vgroup }
    end
  end

  # GET /vgroups/new
  # GET /vgroups/new.xml
  def new
    @vgroup = Vgroup.new

    @vgroup.enrollments << Enrollment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vgroup }
    end
  end

  # GET /vgroups/1/edit
  def edit
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find_by_id(params[:id])
   # if the vgroup is not linked to a scan protocol, the access control breaks down
    # to get at vgroups without sp's need to be admin - also check that not linked to any sp
    @scan_procedures_vgroups = ScanProcedure.where("scan_procedures.id in (select scan_procedure_id from scan_procedures_vgroups where  vgroup_id in (?))",params[:id]) 

    if(@vgroup.nil? and  current_user.role == 'Admin_High' and @scan_procedures_vgroups.size <1)
         @vgroup = Vgroup.find(params[:id])
     end 

    if !@vgroup.participant_id.nil?
        @participant = Participant.find(@vgroup.participant_id)
    end
    if current_user.role == 'Admin_High'
        # for changing appointment vgroup_id    
        @appointments = Appointment.order("appointments.appointment_type ASC").where("appointments.vgroup_id in (?)", params[:id])
        v_appointment_array = Array.new 
        i = 0
        @appointments.each do |appointment|
            v_temp_array = [[appointment.appointment_type+"-"+(appointment.appointment_date).to_s, appointment.id]]
            if i > 0 
               @v_appointment_array.concat(v_temp_array)
            else
               @v_appointment_array = v_temp_array
            end
            i = 1
        end
     end
  end

  # POST /vgroups
  # POST /vgroups.xml
  def create
    # PROBLEM WITH SAVE vgroup IF ENUMBER ALREADY EXISTS !!!!
    @vgroup = Vgroup.new(params[:vgroup]) 
    connection = ActiveRecord::Base.connection();
    v_param_vgroup_participant_id = ''
    if !params[:vgroup][:participant_id].blank?
       v_param_vgroup_participant_id =  params[:vgroup][:participant_id]
    end
    # want to check for participant_id mis-match - reggieid rmraic, enumber and vgroup
    v_reggieid_participant_id = ''
    if !params[:participant].nil? and !params[:participant][:reggieid].blank?
       v_reggieid_participants = Participant.where("reggieid in (?)",params[:participant][:reggieid].rjust(6,"0"))
       if !v_reggieid_participants.nil? and !v_reggieid_participants[0].nil?
          v_reggieid_participant_id = v_reggieid_participants[0].id
       end
    end
    v_rmraic_participant_id = ''
    if !params[:vgroup][:rmr].blank?  && params[:vgroup][:rmr] [0..5] == "RMRaic" && ((params[:vgroup][:rmr] )[6..11] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ ) && params[:vgroup][:rmr] .length == 12
         v_reggieid = params[:vgroup][:rmr][6..11]
         v_rmraic_participants = Participant.where(" reggieid in (?)",v_reggieid)
         v_rmraic_participant_id = v_rmraic_participants[0].try(:id).to_s
    end   
    v_enumber_participant_ids = [] 
    # removed attr_accessible in model and now ok --not sure why vgroup params not getting saved -- same in update  -- something with the mess of enrollments?
    #  @vgroup.compile_folder = params[:vgroup][:compile_folder]
    #  @vgroup.note =params[:vgroup][:note]
    #  @vgroup.participant_id =params[:vgroup][:participant_id]
    #  @vgroup.rmr =params[:vgroup][:rmr]
    #  @vgroup.vgroup_date = params[:vgroup]["#{'vgroup_date'}(1i)"] +"-"+params[:vgroup]["#{'vgroup_date'}(2i)"].rjust(2,"0")+"-"+params[:vgroup]["#{'vgroup_date'}(3i)"].rjust(2,"0")
    # this gets messy - probably multiple inserts
    if  !params[:participant].nil? and !params[:participant][:reggieid].blank?
         v_participant = Participant.where("reggieid in (?)",params[:participant][:reggieid].rjust(6,"0"))
         if !v_participant[0].nil? and params[:vgroup][:participant_id].blank?
            if !params[:vgroup][:rmr].blank?
              if (params[:vgroup][:rmr])[0..5] == "RMRaic" && (params[:vgroup][:rmr][6..11] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ ) && (params[:vgroup][:rmr]).length == 12
                    reggieid_rmr = (params[:vgroup][:rmr])[6..11]
                    v_participant_rmr = Participant.where(" reggieid in (?)",reggieid_rmr)
                    if !v_participant_rmr[0].nil? and v_participant_rmr[0].id != v_participant[0].id
                       # flash[:warning] = "The participants from the reggieid and RMRaic######  do not match !!!!!!  SOMETHING IS AMISS! "
                    else
                       params[:vgroup][:participant_id] = v_participant[0].id.to_s
                    end
              end
            else
              params[:vgroup][:participant_id] = v_participant[0].id.to_s
              # not sure why setting params not carrying thru
              @vgroup.participant_id = v_participant[0].id
            end
         elsif !params[:vgroup][:participant_id].blank? 
              if (params[:vgroup][:rmr])[0..5] == "RMRaic" && (params[:vgroup][:rmr][6..11] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ ) && (params[:vgroup][:rmr]).length == 12
                    reggieid_rmr = (params[:vgroup][:rmr])[6..11]
                    v_participant_rmr = Participant.where(" reggieid in (?)",reggieid_rmr)
              end
          elsif (params[:vgroup][:rmr])[0..5] == "RMRaic" && (params[:vgroup][:rmr][6..11] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ ) && (params[:vgroup][:rmr]).length == 12
               # pick up later - let RMRaic take precident
          elsif v_participant[0].nil? and (params[:participant][:reggieid]=~ /\A[-+]?[0-9]*\.?[0-9]+\Z/)  # make a new participant
            v_new_participant = Participant.new
            v_new_participant.reggieid = params[:participant][:reggieid].rjust(6,"0")
            v_new_participant.save
            params[:vgroup][:participant_id] = v_new_participant.id.to_s
              # not sure why setting params not carrying thru
            @vgroup.participant_id = v_new_participant.id
         end
    end
    respond_to do |format|
      v_enrollment_id_array = []
      v_enrollment_array = []
      enumber_array = []
      @vgroup.do_not_share_scans = ""
      if @vgroup.save  # save being blocked if enumber already exists
        params[:id] = @vgroup.id.to_s
        #problems with new enumber
        if !params[:vgroup][:enrollments_attributes]["0"][:enumber].blank?
          enumber_array << params[:vgroup][:enrollments_attributes]["0"][:enumber]
          # getting enrollments if enumber already in enrollments
          connection = ActiveRecord::Base.connection();
          enrollment = Enrollment.where("enumber = ?",params[:vgroup][:enrollments_attributes]["0"][:enumber] )
        v_do_not_share_scans_flag ="N"
        if !enrollment.blank?
            v_do_not_share_scans_flag ="Y"
        end
          enrollment.each do |e|
             if e.do_not_share_scans_flag.blank? or e.do_not_share_scans_flag != "Y"
                v_do_not_share_scans_flag ="N" 
             end
             v_enrollment_array.push(e)
             v_enrollment_id_array.push(e.id)
             v_evg_check = EnrollmentVgroupMembership.where("vgroup_id in (?) and enrollment_id in (?)",@vgroup.id,e.id)
             if v_evg_check.nil?
               sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+(e.id).to_s+")"      
               results = connection.execute(sql)
             end
          end
          if !enrollment.blank?
            if v_do_not_share_scans_flag == "Y"
                 @vgroup.do_not_share_scans = "DO NOT SHARE"
                 @vgroup.save
            end
            if !(enrollment[0].participant_id).nil? and (@vgroup.participant_id).blank? 
                @vgroup.participant_id = enrollment[0].participant_id
                @vgroup.save
            elsif  (@vgroup.participant_id).blank? and !(@vgroup.rmr).blank?
                if (@vgroup.rmr)[0..5] == "RMRaic" &&    ((@vgroup.rmr)[6..11] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ ) && (@vgroup.rmr).length == 12
                    reggieid = (@vgroup.rmr)[6..11]
                    v_participant = Participant.where(" reggieid in (?)",reggieid)
                    v_participant_id = v_participant[0].try(:id).to_s
                    if !v_participant_id.blank?
                       @vgroup.participant_id = v_participant_id
                       @vgroup.save
                    else # make a participant
                      set_participant_in_enrollment(@vgroup.rmr, enumber_array)
                    end
                end
            end
            if (enrollment[0].participant_id).nil? and !(@vgroup.participant_id).blank? 
                 enrollment[0].participant_id = @vgroup.participant_id
                 enrollment[0].save
             end
          else  # make a new enrollment with this participant-- only works for participant selected
            if  (@vgroup.participant_id).blank? and !(@vgroup.rmr).blank?
                if (@vgroup.rmr)[0..5] == "RMRaic" && ((@vgroup.rmr)[6..11] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ )&& (@vgroup.rmr).length == 12
                    reggieid = (@vgroup.rmr)[6..11]
                    v_participant = Participant.where(" reggieid in (?)",reggieid)
                    v_participant_id = v_participant[0].try(:id).to_s
                    if !v_participant_id.blank?
                       @vgroup.participant_id = v_participant_id
                       @vgroup.save
                     else # make new participant
                      set_participant_in_enrollment(@vgroup.rmr, enumber_array)
                    end
                end
            end
            if !(@vgroup.participant_id).blank? 
                @enrollment = Enrollment.where("enumber = ?",params[:vgroup][:enrollments_attributes]["0"][:enumber] )
                if @enrollment[0].nil?
                   sql = " insert into enrollments(enumber,participant_id)values('"+params[:vgroup][:enrollments_attributes]["0"][:enumber].gsub(/[;:'"()=<>]/, '')+"',"+@vgroup.participant_id.to_s+")"
                   results = connection.execute(sql) 
                   @enrollment = Enrollment.where("enumber = ?",params[:vgroup][:enrollments_attributes]["0"][:enumber] )
                end
                v_enrollment_array.push(@enrollment[0])
                v_evg_check = EnrollmentVgroupMembership.where("vgroup_id in (?) and enrollment_id in (?)",@vgroup.id,@enrollment[0].id)
                if v_evg_check.nil?
                  sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+(@enrollment[0].id).to_s+")"      
                  results = connection.execute(sql)
                end
            else
                # need to add
                @enrollment = Enrollment.where("enumber = ?",params[:vgroup][:enrollments_attributes]["0"][:enumber] )
                if @enrollment[0].nil?
                  sql = " insert into enrollments(enumber)values('"+params[:vgroup][:enrollments_attributes]["0"][:enumber].gsub(/[;:'"()=<>]/, '')+"' )"
                  results = connection.execute(sql)
                  @enrollment = Enrollment.where("enumber = ?",params[:vgroup][:enrollments_attributes]["0"][:enumber] )
                end
                v_enrollment_id_array.push(@enrollment[0].id)
                v_enrollment_array.push(@enrollment[0])
                v_evg_check = EnrollmentVgroupMembership.where("vgroup_id in (?) and enrollment_id in (?)",@vgroup.id,@enrollment[0].id)
                if v_evg_check.nil?
                  sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+(@enrollment[0].id).to_s+")"      
                  results = connection.execute(sql)
                end
                enumber_array = []
                enumber_array << params[:vgroup][:enrollments_attributes]["0"][:enumber]
                   # also want to set participant in vgroup
                
                set_participant_in_enrollment(@vgroup.rmr, enumber_array)

            end                    
           end    
        end  
        if !(@vgroup.participant_id).blank?   # how will this interact with load visit? participant_id is probably blank until the enumber update in mri
          sql = "select enrollments.id from enrollments where participant_id ="+@vgroup.participant_id.to_s 
          # this is going to cause problems if there are multiple enrollments for a participant?        
          participants_results = connection.execute(sql)
          # is there a better way to get the results?
          participants_results.each do |r|
              v_enrollment_array.each do |e|
                if (e.participant_id).nil?
                    if !@vgroup.participant_id.blank? and @vgroup.participant_id != e.participant_id
                       #  flash[:warning] = "The participants from the PARTICIPANT and subjectid  do not match !!!!!!  SOMETHING IS AMISS! "
                    else 
                         e.participant_id = @vgroup.participant_id
                         e.save
                    end
                end
              end
              sql = "select count(*) cnt from enrollment_vgroup_memberships where vgroup_id = "+@vgroup.id.to_s+" and enrollment_id="+(r[0]).to_s
              results = connection.execute(sql)
              cnt = 0
              results.each do |r_cnt|
                cnt = r_cnt[0]
              end
              if cnt < 1
                if v_enrollment_id_array.include?(r[0])
                  v_evg_check = EnrollmentVgroupMembership.where("vgroup_id in (?) and enrollment_id in (?)",@vgroup.id,r[0])
                  if v_evg_check.nil?
                    sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+(r[0]).to_s+")"  
                    results = connection.execute(sql)
                  end
                end
              end
          end
        end

      # removed attr_accessible in model and now ok  
      #  if !params[:vgroup][:scan_procedure_ids].blank?
      #     connection = ActiveRecord::Base.connection();
      #    params[:vgroup][:scan_procedure_ids].each do |sp|           
      #      sql = "Insert into scan_procedures_vgroups(vgroup_id,scan_procedure_id) values("+@vgroup.id.to_s+","+sp+")"        
      #      results = connection.execute(sql)        
      #    end
      #  end
                        # check for other vgroups with same sp and enumber within 1 month
          v_near_vgroups = Vgroup.where("vgroups.id != "+@vgroup.id.to_s+" 
            and STR_TO_DATE('"+@vgroup.vgroup_date.strftime('%m/%d/%Y')+"','%m/%d/%Y')  between (vgroups.vgroup_date - interval 1 month ) and (vgroups.vgroup_date + interval 1 month ) 
                  and vgroups.id in ( select evgm.vgroup_id from enrollment_vgroup_memberships evgm where evgm.enrollment_id in
                                                (select evgm2.enrollment_id from enrollment_vgroup_memberships evgm2 where 
                                                          evgm2.vgroup_id = "+@vgroup.id.to_s+"))")
          v_near_vgroup_msg = ""
          if !v_near_vgroups.nil?
              v_near_vgroups.each do |nvg|
                 v_near_vgroup_msg = v_near_vgroup_msg + " There is a EXISTING vgroup with the same enumber on "+nvg.vgroup_date.to_s+".    "
              end
              if !v_near_vgroup_msg.blank?
                  if !flash[:warning].blank?
                     flash[:warning] = flash[:warning] + v_near_vgroup_msg
                  else
                     flash[:warning] =  v_near_vgroup_msg
                  end
              end
          end
           
          v_tmp_cnt = 0
           v_tmp_enumber_array = []
           params[:vgroup][:enrollments_attributes].each do|cnt, value|
              v_tmp_cnt = v_tmp_cnt + 1
              if !params[:vgroup][:enrollments_attributes][cnt.to_s][:id].blank?
                 v_enrollments = Enrollment.where("enumber in (?) and participant_id is not NULL",params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber] )
                 if !v_enrollments.nil? and !v_enrollments[0].nil? and !(v_enrollments[0].participant_id).blank?
                     v_enumber_participant_ids.push(v_enrollments[0].participant_id)
                 end
              end
           end 

                    # check for participant vgroup, rmraic, reggieid, enumber mismatch
          v_mismatch_participant_msg = ""
          if v_rmraic_participant_id != '' and  v_reggieid_participant_id != '' and v_rmraic_participant_id.to_s !=  v_reggieid_participant_id.to_s 
              v_mismatch_participant_msg = v_mismatch_participant_msg +"  MISMATCH - reggieid participant and RMRaicxxxxxx participant. "
          end
          if v_param_vgroup_participant_id != '' and  v_reggieid_participant_id != '' and v_param_vgroup_participant_id.to_s !=  v_reggieid_participant_id.to_s 
              v_mismatch_participant_msg = v_mismatch_participant_msg +"  MISMATCH - reggieid participant and selected participant. "
          end
          if v_param_vgroup_participant_id != '' and  v_rmraic_participant_id != '' and v_param_vgroup_participant_id.to_s !=  v_rmraic_participant_id.to_s 
              v_mismatch_participant_msg = v_mismatch_participant_msg +"  MISMATCH - RMRaicxxxxxxparticipant and selected participant. "
          end

          if !v_enumber_participant_ids.nil? and !v_enumber_participant_ids[0].nil?
             v_enumber_participant_ids.each do |ee|
                if v_reggieid_participant_id != '' and v_reggieid_participant_id.to_s !=  ee.to_s 
                    v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - enumber participant and reggieid participant. "
                end
                if v_rmraic_participant_id != '' and v_rmraic_participant_id.to_s !=  ee.to_s 
                    v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - enumber participant and RMRaicxxxxxx participant. "
                end
                if v_param_vgroup_participant_id != '' and v_param_vgroup_participant_id.to_s !=  ee.to_s 
                    v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - enumber participant and selected participant. "
                end
             end
          end
          if !v_mismatch_participant_msg.blank?
              # send email
              PandaMailer.send_email(v_mismatch_participant_msg,{:send_to => "noreply_johnson_lab@medicine.wisc.edu"},v_mismatch_participant_msg).deliver
     
               if !flash[:warning].blank?
                  flash[:warning] = flash[:warning] + v_mismatch_participant_msg
               else
                  flash[:warning] =  v_mismatch_participant_msg
               end
          end
          # works in create - not during import - makes participant if blank and   sp.make_participant_flag == 'Y'
        if (@vgroup.participant_id).blank?
            # check if sp.make_participant_flag == 'Y'
            @scan_procedures = ScanProcedure.where("scan_procedures.id in ( select scan_procedure_id from scan_procedures_vgroups where vgroup_id in (?))",@vgroup.id )
            @scan_procedures.each do |sp|
              if sp.make_participant_flag == "Y"  and (@vgroup.participant_id).blank?
                 v_new_participant = Participant.new
                 v_new_participant.save
                 @vgroup.participant_id = v_new_participant.id
                 @vgroup.save
                 @enrollment = Enrollment.where("enumber = ?",params[:vgroup][:enrollments_attributes]["0"][:enumber] )
                 @enrollment.each do |ee|
                   if (ee.participant_id).blank?
                      ee.participant_id = v_new_participant.id
                      ee.save
                   end
                 end
              end
            end
        end
        # check if placeholder appt exisits on another vg 
        if !(@vgroup.participant_id).blank?
                    appointments_placeholder = Appointment.where("appointments.appointment_type = 'placeholder' and appointments.vgroup_id in (select vgroups.id from vgroups where vgroups.participant_id in (?)) 
              and  appointments.vgroup_id in (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups where scan_procedures_vgroups.scan_procedure_id in 
                   (select scan_procedures_vgroups.scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id in (?)))
                   and appointments.vgroup_id  NOT IN (?) ",@vgroup.participant_id,@vgroup.id,@vgroup.id)
            appointments_placeholder.each do |apl|
              appointments_other = Appointment.where("appointments.appointment_type IS NOT NULL and appointments.appointment_type != 'placeholder' and appointments.vgroup_id in (?)",apl.vgroup_id)
              if !appointments_other.blank?
                    apl.destroy
              else
                  @apl_vgroup = Vgroup.find(apl.vgroup_id)
                  apl.destroy
                  if !@apl_vgroup.blank?
                           @apl_vgroup.destroy
                  end
              end
          end
        end
        format.html { redirect_to(@vgroup, :notice => 'Vgroup was successfully created.') }
        format.xml  { render :xml => @vgroup, :status => :created, :location => @vgroup }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vgroup.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vgroups/1
  # PUT /vgroups/1.xml
  def update
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find_by_id(params[:id])
   # if the vgroup is not linked to a scan protocol, the access control breaks down
    # to get at vgroups without sp's need to be admin - also check that not linked to any sp
    @scan_procedures_vgroups = ScanProcedure.where("scan_procedures.id in (select scan_procedure_id from scan_procedures_vgroups where  vgroup_id in (?))",params[:id]) 

    if(@vgroup.nil? and  current_user.role == 'Admin_High' and @scan_procedures_vgroups.size <1)
         @vgroup = Vgroup.find(params[:id])
     end 
    # removed attr_accessible  in model and ok now - update attributes not doing updates
    #   @vgroup.compile_folder = params[:vgroup][:compile_folder]
    #   @vgroup.note =params[:vgroup][:note]
    #   @vgroup.participant_id =params[:vgroup][:participant_id]
    #   @vgroup.rmr =params[:vgroup][:rmr]
    #   @vgroup.vgroup_date = params[:vgroup]["#{'vgroup_date'}(1i)"] +"-"+params[:vgroup]["#{'vgroup_date'}(2i)"].rjust(2,"0")+"-"+params[:vgroup]["#{'vgroup_date'}(3i)"].rjust(2,"0")
   
    v_param_vgroup_participant_id = ''
    if params[:vgroup][:participant_id].blank?
         @vgroup.participant_id = nil
         @vgroup.save
    else
       v_param_vgroup_participant_id =  params[:vgroup][:participant_id]
    end
    # want to check for participant_id mis-match - reggieid rmraic, enumber and vgroup
    v_vgroup_participant_id = ''
    if !@vgroup.participant_id.nil?
       v_vgroup_participant_id = @vgroup.participant_id
    end
    v_reggieid_participant_id = ''
    if !params[:participant].nil? and !params[:participant][:reggieid].blank?
       v_reggieid_participants = Participant.where("reggieid in (?)",params[:participant][:reggieid].rjust(6,"0"))
       if !v_reggieid_participants.nil? and !v_reggieid_participants[0].nil?
          v_reggieid_participant_id = v_reggieid_participants[0].id
       end
    end
    v_rmraic_participant_id = ''
    if !params[:vgroup][:rmr].blank?  && params[:vgroup][:rmr] [0..5] == "RMRaic" && ((params[:vgroup][:rmr] )[6..11] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ ) && params[:vgroup][:rmr] .length == 12
         v_reggieid = params[:vgroup][:rmr][6..11]
         v_rmraic_participants = Participant.where(" reggieid in (?)",v_reggieid)
         v_rmraic_participant_id = v_rmraic_participants[0].try(:id).to_s
    end   
    v_enumber_participant_ids = [] # could be multiples -- get below 

        # shoe horning in the reggieid 
    if @vgroup.participant_id.nil? and !params[:participant].nil? and !params[:participant][:reggieid].blank?
         v_participant = Participant.where("reggieid in (?)",params[:participant][:reggieid].rjust(6,"0"))
         if !v_participant[0].nil? and params[:vgroup][:participant_id].blank?
          @vgroup.participant_id = v_participant[0].id
          params[:vgroup][:participant_id] = v_participant[0].id.to_s
         end
    end
    
    # getting undefined method `to_sym' error -- somethng is nil 
    # just trying to delete 
    v_cnt = 0
    enumber_array = []
    params[:vgroup][:enrollments_attributes].each do|cnt, value|
      v_cnt = v_cnt + 1
      if !params[:vgroup][:enrollments_attributes][cnt.to_s][:id].blank?
         #enumberpipr00042id2203_destroy1
         enrollment_id = params[:vgroup][:enrollments_attributes][cnt.to_s][:id] #  (value.to_s)[(value.to_s).index("id")+2,(value.to_s).index("_destroy")]
         v_destroy = params[:vgroup][:enrollments_attributes][cnt.to_s][:_destroy] #(value.to_s)[(value.to_s).index("_destroy")+8,(value.to_s).length] 
         if v_destroy.to_s == "1"
             enrollment_id = enrollment_id.sub("_destroy1","")
             sql = "Delete from enrollment_vgroup_memberships where vgroup_id ="+@vgroup.id.to_s+" and enrollment_id ="+enrollment_id
             connection = ActiveRecord::Base.connection();
             results = connection.execute(sql)
             params[:vgroup][:enrollments_attributes][cnt.to_s] = nil
             #v_destroy = 0
         else
           enumber_array << params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber]
           v_enrollments = Enrollment.where("enumber in (?) and participant_id is not NULL",params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber] )
           if !v_enrollments.nil? and !v_enrollments[0].nil? and !(v_enrollments[0].participant_id).blank?
              v_enumber_participant_ids.push(v_enrollments[0].participant_id)
           end 
         end
       else
         if !params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber].blank?
           connection = ActiveRecord::Base.connection();
           @enrollment = Enrollment.where("enumber = ?",params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber] )
           enumber_array << params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber] 
           if !@enrollment.blank?
             @enrollment_vgroup_membership = EnrollmentVgroupMembership.where("enrollment_id in (?) and vgroup_id in (?)",@enrollment[0].id, @vgroup.id)
              if @enrollment_vgroup_membership.blank?
                  sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+(@enrollment[0].id).to_s+")"      
                  results = connection.execute(sql)
                  if !(@vgroup.participant_id).blank? # tryiong to get link to participant for enumber
                    sql = "update enrollments set participant_id = "+@vgroup.participant_id.to_s+" where participant_id is null and enrollments.id ="+@enrollment[0].id.to_s+" "
                    results = connection.execute(sql)
                  end
              end
           else  # make a new enrollment with this participant-- only works for participant selected
            @enrollment = Enrollment.where("enumber = ?",params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber] )
             if !(@vgroup.participant_id).blank? and @enrollment[0].nil?
                 sql = " insert into enrollments(enumber,participant_id)values('"+params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber].gsub(/[;:'"()=<>]/, '')+"',"+@vgroup.participant_id.to_s+")"
                 results = connection.execute(sql) 
             elsif v_enrollments[0].nil?
                 sql = " insert into enrollments(enumber)values('"+params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber].gsub(/[;:'"()=<>]/, '')+"' )"  
                 results = connection.execute(sql)
              end
                 # need to add
                 @enrollment = Enrollment.where("enumber = ?",params[:vgroup][:enrollments_attributes][cnt.to_s][:enumber] )
                 if !@enrollment.nil? and !@enrollment[0].blank?
                    @enrollment_vgroup_membership = EnrollmentVgroupMembership.where("enrollment_id in (?)",@enrollment[0].id)
                    if @enrollment_vgroup_membership.blank?
                        sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+(@enrollment[0].id).to_s+")"      
                        results = connection.execute(sql)
                    end 
                  end                  
            end    
         end
       end
    end
    if v_cnt > 0
       # also want to set participant in vgroup
       @vgroup.rmr = params[:vgroup][:rmr]
       v_current_vgroup_participant_id = @vgroup.participant_id
       set_participant_in_enrollment(@vgroup.rmr, enumber_array)
       # picking up participant_id in set_participant_in_enrollment, but being wiped out by blank params[:vgroup][:participant_id]
       if params[:vgroup][:participant_id].blank?
             params[:vgroup][:participant_id] = @vgroup.participant_id.to_s
       end
    end
    
    params[:vgroup].delete('enrollments_attributes') 
    
    respond_to do |format|
      if @vgroup.update_attributes(params[:vgroup])  #@vgroup.save #update_attributes(params[:vgroup])
        connection = ActiveRecord::Base.connection();
        # problem with not deleting enum vgr
        sql = "delete from scan_procedures_vgroups where vgroup_id ="+@vgroup.id.to_s
        results = connection.execute(sql)
        if !params[:vgroup][:scan_procedure_ids].blank?
          params[:vgroup][:scan_procedure_ids].each do |sp|           
            sql = "Insert into scan_procedures_vgroups(vgroup_id,scan_procedure_id) values("+@vgroup.id.to_s+","+sp+")"        
            results = connection.execute(sql)        
          end
        end
#        connection = ActiveRecord::Base.connection(); 
#        sql = "delete from enrollment_vgroup_memberships where vgroup_id = "+@vgroup.id.to_s
#        results = connection.execute(sql)
#        if !(@vgroup.participant_id).blank?   # how will this interact with load visit? participant_id is probably blank until the enumber update in mri
#          sql = "select enrollments.id from enrollments where participant_id ="+@vgroup.participant_id.to_s 
#          # this is going to cause problems if there are multiple enrollments for a participant?
       
#          participants_results = connection.execute(sql)
          # is there a better way to get the results?
#          participants_results.each do |r|
#              sql = "select count(*) cnt from enrollment_vgroup_memberships where vgroup_id = "+@vgroup.id.to_s+" and enrollment_id="+(r[0]).to_s
#              results = connection.execute(sql)
#              cnt = 0
#              results.each do |r_cnt|
#                cnt = r_cnt[0]
#              end
#              if cnt < 1
#                sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+(r[0]).to_s+")"      
#                results = connection.execute(sql)
#              end
#          end
#        end
        if @vgroup.participant_id.blank? and !params[:make_participant_flag].blank? and params[:make_participant_flag] == "Y"
          # make new participant-- no data
          @participant = Participant.new
          if !params[:participant].nil? and !params[:participant][:reggieid].blank? and (params[:participant][:reggieid]=~ /\A[-+]?[0-9]*\.?[0-9]+\Z/)
              @participant.reggieid = params[:participant][:reggieid].rjust(6,"0")
          end
          @participant.save
          @vgroup.participant_id = @participant.id
          @vgroup.save

          @enrollments = Enrollment.where("enrollments.id in (select enrollment_vgroup_memberships.enrollment_id from enrollment_vgroup_memberships 
                                                  where vgroup_id in ("+@vgroup.id.to_s+" ))")
           @enrollments.each do |e|
              if e.participant_id.blank?       
                 e.participant_id = @participant.id
                 e.save
              end             
            end
          
          # link participant_id to enrollments
          # link participant_id to vgroup
        end
        @vgroup.do_not_share_scans = ""
        if  !params[:vgroup][:pilot_flag].blank? and params[:vgroup][:pilot_flag] == 'Y'
             @vgroup.do_not_share_scans ='DO NOT SHARE'
        end 
        @vgroup.save
        v_do_not_share_scans_flag ="N"
        @enrollments = Enrollment.where("enrollments.id in (select enrollment_vgroup_memberships.enrollment_id from enrollment_vgroup_memberships 
                                                  where vgroup_id in ("+@vgroup.id.to_s+" ))")
        if !@enrollments.blank?
            v_do_not_share_scans_flag ="Y"
        end
        @enrollments.each do |e|
             if e.do_not_share_scans_flag.blank? or e.do_not_share_scans_flag != "Y"
                v_do_not_share_scans_flag ="N" 
             end
         end
       if !@enrollments.blank?
            if v_do_not_share_scans_flag == "Y"
                 @vgroup.do_not_share_scans = "DO NOT SHARE"
                 @vgroup.save
            end
        end


                  # check for other vgroups with same sp and enumber within 1 month
          v_near_vgroups = Vgroup.where("vgroups.id != "+@vgroup.id.to_s+" 
            and STR_TO_DATE('"+@vgroup.vgroup_date.strftime('%m/%d/%Y')+"','%m/%d/%Y')  between (vgroups.vgroup_date - interval 1 month ) and (vgroups.vgroup_date + interval 1 month ) 
                  and vgroups.id in ( select evgm.vgroup_id from enrollment_vgroup_memberships evgm where evgm.enrollment_id in
                                                (select evgm2.enrollment_id from enrollment_vgroup_memberships evgm2 where 
                                                          evgm2.vgroup_id = "+@vgroup.id.to_s+"))")
          v_near_vgroup_msg = ""
          if !v_near_vgroups.nil?
              v_near_vgroups.each do |nvg|
                 v_near_vgroup_msg = v_near_vgroup_msg + " There is a EXISTING vgroup with the same enumber on "+nvg.vgroup_date.to_s+".    "
              end
              if !v_near_vgroup_msg.blank?
                  if !flash[:warning].blank?
                     flash[:warning] = flash[:warning] + v_near_vgroup_msg
                  else
                     flash[:warning] =  v_near_vgroup_msg
                  end
              end
          end

                    # check for participant vgroup, rmraic, reggieid, enumber mismatch
          v_mismatch_participant_msg = ""
          if v_vgroup_participant_id != '' and  v_reggieid_participant_id != '' and v_vgroup_participant_id.to_s !=  v_reggieid_participant_id.to_s 
              v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - reggieid participant and selected participant. "
          end
          if v_vgroup_participant_id != '' and  v_rmraic_participant_id != '' and v_vgroup_participant_id.to_s !=  v_rmraic_participant_id.to_s 
              v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - RMRaicxxxxxx participant and selected participant. "
          end
          if v_rmraic_participant_id != '' and  v_reggieid_participant_id != '' and v_rmraic_participant_id.to_s !=  v_reggieid_participant_id.to_s 
              v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - reggieid participant and RMRaicxxxxxx participant. "
          end
          if v_param_vgroup_participant_id != '' and  v_vgroup_participant_id != '' and v_param_vgroup_participant_id.to_s !=  v_vgroup_participant_id.to_s 
              v_mismatch_participant_msg = v_mismatch_participant_msg +" minor MISMATCH - previous selected participant and selected participant."
          end
          if v_param_vgroup_participant_id != '' and  v_reggieid_participant_id != '' and v_param_vgroup_participant_id.to_s !=  v_reggieid_participant_id.to_s 
              v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - reggieid participant and selected participant. "
          end
          if v_param_vgroup_participant_id != '' and  v_rmraic_participant_id != '' and v_param_vgroup_participant_id.to_s !=  v_rmraic_participant_id.to_s 
              v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - RMRaicxxxxxxparticipant and selected participant. "
          end

          if !v_enumber_participant_ids.nil? and !v_enumber_participant_ids[0].nil?
             v_enumber_participant_ids.each do |ee|
                if v_vgroup_participant_id != '' and v_vgroup_participant_id.to_s !=  ee.to_s 
                    v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - enumber participant and selected participant. "
                end
                if v_reggieid_participant_id != '' and v_reggieid_participant_id.to_s !=  ee.to_s 
                    v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - enumber participant and reggieid participant. "
                end
                if v_rmraic_participant_id != '' and v_rmraic_participant_id.to_s !=  ee.to_s 
                    v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - enumber participant and RMRaicxxxxxx participant. "
                end
                if v_param_vgroup_participant_id != '' and v_param_vgroup_participant_id.to_s !=  ee.to_s 
                    v_mismatch_participant_msg = v_mismatch_participant_msg +" MISMATCH - enumber participant and selected participant. "
                end
             end
          end
          if !v_mismatch_participant_msg.blank?
               PandaMailer.send_email(v_mismatch_participant_msg,{:send_to => "noreply_johnson_lab@medicine.wisc.edu"},v_mismatch_participant_msg).deliver
     
               if !flash[:warning].blank?
                  flash[:warning] = flash[:warning] + v_mismatch_participant_msg
               else
                  flash[:warning] =  v_mismatch_participant_msg
               end
          end

        # works in update - makes participant if blank and   sp.make_participant_flag == 'Y'
        if (@vgroup.participant_id).blank?
            # check if sp.make_participant_flag == 'Y'
            @scan_procedures = ScanProcedure.where("scan_procedures.id in ( select scan_procedure_id from scan_procedures_vgroups where vgroup_id in (?))",@vgroup.id )
            @scan_procedures.each do |sp|
              if sp.make_participant_flag == "Y"  and (@vgroup.participant_id).blank?
                 v_new_participant = Participant.new
                 v_new_participant.save
                 @vgroup.participant_id = v_new_participant.id
                 @vgroup.save
                 @enrollment = Enrollment.where("enrollments.id in ( select enrollment_id from enrollment_vgroup_memberships where vgroup_id in (?) )",@vgroup.id )
                 @enrollment.each do |ee|
                   if (ee.participant_id).blank?
                      ee.participant_id = v_new_participant.id
                      ee.save
                   end
                 end
              end
            end
        end
        # updating adrcnum in participant - this will update the participant is adrcnum null/blank and participant linked to an adrc visit
        # even when this visit is not with adrc
        if (!@vgroup.participant_id).blank?
              sql ="UPDATE participants p
SET p.adrcnum = (SELECT DISTINCT e2.enumber FROM enrollments e2, enrollment_vgroup_memberships evgm,scan_procedures_vgroups spvg, vgroups vg
WHERE e2.participant_id = p.id   
AND e2.id = evgm.enrollment_id 
             AND evgm.vgroup_id = spvg.vgroup_id
AND vg.id = spvg.vgroup_id   AND vg.participant_id = p.id
                         AND spvg.scan_procedure_id IN ( SELECT sp.id FROM scan_procedures sp WHERE sp.codename LIKE 'asthana.adrc-clinical-core.visit%'  )
                         AND e2.enumber LIKE 'adrc%') 
WHERE (p.adrcnum IS NULL or p.adrcnum = '')
AND p.id IN (SELECT vg2.participant_id FROM vgroups vg2, scan_procedures_vgroups spvg2 WHERE vg2.id = spvg2.vgroup_id 
                     AND spvg2.scan_procedure_id in (SELECT sp2.id FROM scan_procedures sp2 WHERE sp2.codename LIKE 'asthana.adrc-clinical-core.visit%'))
AND p.id in ("+@vgroup.participant_id.to_s+")"
        connection = ActiveRecord::Base.connection();
        results = connection.execute(sql) 
        # look for other vg - appt placeholder 
          #appointments_placeholder = Appointment.where("appointments.appointment_type = 'placeholder' and appointments.vgroup_id in (select vgroups.id from vgroups where vgroups.participant_id in (?))",@vgroup.participant_id)
          appointments_placeholder = Appointment.where("appointments.appointment_type = 'placeholder' and appointments.vgroup_id in (select vgroups.id from vgroups where vgroups.participant_id in (?)) 
              and  appointments.vgroup_id in (select scan_procedures_vgroups.vgroup_id from scan_procedures_vgroups where scan_procedures_vgroups.scan_procedure_id in 
                   (select scan_procedures_vgroups.scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id in (?)))
                   and appointments.vgroup_id  NOT IN (?) ",@vgroup.participant_id,@vgroup.id,@vgroup.id)
          appointments_placeholder.each do |apl|
              appointments_other = Appointment.where("appointments.appointment_type IS NOT NULL and appointments.appointment_type != 'placeholder' and appointments.vgroup_id in (?)",apl.vgroup_id)
              if !appointments_other.blank?
                    apl.destroy
              else
                  @apl_vgroup = Vgroup.find(apl.vgroup_id)
                  apl.destroy
                  if !@apl_vgroup.blank?
                           @apl_vgroup.destroy
                  end
              end
          end
        end  

        format.html { redirect_to(@vgroup) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vgroup.errors, :status => :unprocessable_entity }
      end
    end
  end

# similar to function in visits controller
def set_participant_in_enrollment( rmr, enumber_array)
  # loop thru each enrollment, check for participant_id
  # if not populated, look for other participant_id based on
  # last 6 digits of rmr = RMRaic
  # other participant_id for the enumber
  @vgroup = Vgroup.find(params[:id])
  participant_id =""
  # make hash of enums
   blank_participant_id ="N"
  enumber_array.each do |enum|
    @e = Enrollment.where("enumber ='"+enum+"'")
     if !@e[0].participant_id.blank?
         participant_id = @e[0].participant_id
     else
         blank_participant_id ="Y"
     end
  end
  # what if there are two participant_id's -- multiple enrollments
  if participant_id.blank?
    # if rmr starts with RMRaic and last 6 chars are digits
    # look for a participant with this reggieID
    if rmr[0..5] == "RMRaic" && ((rmr)[6..11] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ ) && rmr.length == 12
         reggieid = rmr[6..11]
         @participant = Participant.where(" reggieid in (?)",reggieid)
         participant_id = @participant[0].try(:id).to_s
    end
    if participant_id.blank?
          # look for participant_id associated with enumber
          @participant = Participant.where(" participants.id in (select enrollments.participant_id  from  enrollments where enumber  in (?))",enumber_array)
          participant_id = @participant[0].try(:id).to_s           
    end
    # if still blank, and good rmr format, insert new partipant
    if participant_id.blank? && rmr[0..5] == "RMRaic" && ((rmr)[6..11] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ ) && rmr.length == 12
        # do insert , get participant_id
         
         @participant = Participant.new
         @participant.reggieid = rmr[6..11]
         @participant.save
        participant_id = @participant.id
    end
  end
        # participant_id was blank, now, if not blank, update enrollments where participant_id is null
    if !participant_id.blank? 
       sql = "UPDATE enrollments set enrollments.participant_id = "+participant_id.to_s+" WHERE enrollments.participant_id is NULL AND
                        enrollments.id 
                          IN (select  enrollment_vgroup_memberships.enrollment_id  FROM enrollment_vgroup_memberships
                              WHERE enrollment_vgroup_memberships.vgroup_id = "+params[:id]+ " )"

                         
        connection = ActiveRecord::Base.connection();
        results = connection.execute(sql) 
        sql = "UPDATE vgroups set vgroups.participant_id = "+participant_id.to_s+" WHERE vgroups.id = "+params[:id]
         connection = ActiveRecord::Base.connection();
         results = connection.execute(sql)
        if blank_participant_id == "Y"
          enumber_array.each do |enum|
              @e = Enrollment.where("enumber ='"+enum+"'")
             if !@e[0].participant_id.blank?
                 var = var # not do anything
             else
                    sql = "UPDATE enrollments set enrollments.participant_id = "+participant_id.to_s+" WHERE enrollments.participant_id is NULL AND
                                     enrollments.id = "+@e[0].id.to_s
                     connection = ActiveRecord::Base.connection();
                     results = connection.execute(sql)
             end
          end
        end         
         
  end 

  # check if vgroup.participant_id is blank 
  if !participant_id.blank?
    # HOW TO DO THE CHAINED FIND?
     #@vgroup = Vgroup.find(Appointment.find(Visit.find(params[:id]).appointment_id).vgroup_id)
     if @vgroup.participant_id.blank?
       @vgroup.participant_id = participant_id
       @vgroup.save
     end
     
  end
  
end
    def is_a_number?(s)

      s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  1
    end
  
  # GET /vgroups/:scope
  def index_by_scope  # probably not being used

    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @search = Vgroup.send(params[:scope]).search(params[:search])  # should this be instance_eval
    @visits = @search.relation.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    @collection_title = "All #{params[:scope].to_s.gsub('_',' ')} Visits"
    render :template => "vgroups/home"
  end
  
  def assigned_to_who
    redirect_to assigned_to_vgroup_path( :user_login => params[:user][:username] )
  end
  
  # GET /vgroups/assigned_to/:user_login
  def index_by_user_id

    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    
    @user = User.find(params[:user_login])
    @search = Vgroup.assigned_to(@user.id).search
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Vgroup.unscoped.search(params[:search]) 
    else
      @search = Vgroup.search(params[:search]) 
    end

    @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))
                          and vgroups.user_id in (?)", 
                              scan_procedure_array,@user.id).page(params[:page])

    
    @collection_title = "All Visits assigned " # to #{params[:user_login]}"
    render :template => "vgroups/home"
  end
  
  def in_scan_procedure
   # redirect_to in_scan_procedure_vgroup_path( :scan_procedure_id => params[:scan_procedure][:id] )
   redirect_to '/vgroups_search?vgroups_search[scan_procedure_id][]='+ params[:scan_procedure][:id]
   
  end
  
  def in_enumber
   redirect_to in_enumber_vgroup_path( :enumber => params[:enumber] )
  end

  def index_by_scan_procedure  
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Vgroup.unscoped.search(params[:search]) 
    else
      @search = Vgroup.search(params[:search]) 
    end
    # if !params[:enumber].blank? 
    #   @vgroups = @search.where(" vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships,enrollments
    #                                                      where enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower(?)))",params[:enumber])
    #  @collection_title = "All Visits for params[:enumber]"
    if !params[:scan_procedure_id].blank? 
       @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?) and scan_procedure_id in (?))", 
                              scan_procedure_array,params[:scan_procedure_id]).page(params[:page])
       @collection_title = "All Visits enrolled in #{ScanProcedure.find_by_id(params[:scan_procedure_id]).codename}"
    else
      @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
      @collection_title = "All Visits"
    end
    
    render :template => "vgroups/home"

  end
  
  def index_by_enumber  
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Vgroup.unscoped.search(params[:search]) 
    else
      @search = Vgroup.search(params[:search]) 
    end
    # if !params[:enumber].blank? 
    #   @vgroups = @search.where(" vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships,enrollments
    #                                                      where enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower(?)))",params[:enumber])
    #  @collection_title = "All Visits for params[:enumber]"
    if !params[:enumber].blank? 
       @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?) ) and 
                                         vgroups.id in ( select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships, enrollments 
                                                            where enrollments.id = enrollment_vgroup_memberships.enrollment_id and enrollments.enumber in (?)) ", 
                              scan_procedure_array,params[:enumber]).page(params[:page])
       @collection_title = "All Visits with enumber in "+params[:enumber]
    else
      @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
      @collection_title = "All Visits"
    end
    
    render :template => "vgroups/home"

  end
  
  
  def visit_search
     render :template => "vgroups/home"
  end
  
  def vgroups_search
      # slightly different -- no joins in appointment, so can't use common search
      scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
      scan_procedure_list = scan_procedure_array.map(&:to_i).join(',')
            hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
      # make @conditions from search form input, access control in application controller run_search
      @conditions = []
      @current_tab = "vgroups"
      @schedules = Schedule.all
      @schedules_users = []
      @schedules_users.push(-1)
      @schedules.each do |s|
        s.users.each do |u|
          @schedules_users.push(u.id)
        end 
      end
      params["search_criteria"] =""
      if params[:vgroups_search].nil?
           params[:vgroups_search] =Hash.new  
      end

      if !params[:vgroups_search][:scan_procedure_id].blank? and !params[:vgroups_search][:scan_procedure_id][:id].blank?
         condition =" vgroups.id in (select vgroup_id from scan_procedures_vgroups where 
                                                 scan_procedure_id in ("+params[:vgroups_search][:scan_procedure_id][:id].gsub(/[;:'"()=<>]/, '')+"))"
         @conditions.push(condition)
         @scan_procedures = ScanProcedure.where("id in (?)",params[:vgroups_search][:scan_procedure_id][:id])
         params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end

      if !params[:vgroups_search][:enumber].blank?
        if params[:vgroups_search][:enumber].include?(',') # string of enumbers
         v_enumber =  params[:vgroups_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
         v_enumber = v_enumber.gsub(/,/,"','")
           condition =" vgroups.id in (select vgroup_id from enrollment_vgroup_memberships,enrollments
           where enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"'))"         
        else
          condition =" vgroups.id in (select vgroup_id from enrollment_vgroup_memberships,enrollments
          where enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:vgroups_search][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"
        end
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:vgroups_search][:enumber]
      end 
      
      if !params[:vgroups_search][:qc_completed].blank?
          condition =" vgroups.qc_completed in ('"+params[:vgroups_search][:qc_completed].gsub(/[;:'"()=<>]/, '')+"')"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  QC completed "+params[:vgroups_search][:qc_completed]
      end 
      
      if !params[:vgroups_search][:entered_by].blank?
          condition =" vgroups.entered_by in ('"+params[:vgroups_search][:entered_by].gsub(/[;:'"()=<>]/, '')+"')"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  Entered by "+User.find(params[:vgroups_search][:entered_by]).username_name
      end          
       # trim leading ","
       params["search_criteria"] = params["search_criteria"].sub(", ","")


         
       # adjust columns and fields for html vs xls
       request_format = request.formats.to_s
       @html_request ="Y"
       case  request_format
         when "[text/html]", "text/html" then # ? application/html
           @column_headers = ['Date','Protocol','Enumber','RMR','MRI status','PET status','LP status','LH status','NP status','Questionnaire status'] # need to look up values
               # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
           @fields =["vgroups.transfer_mri", "vgroups.transfer_pet", "vgroups.completedlumbarpuncture", "vgroups.completedblooddraw", "vgroups.completedneuropsych", "vgroups.completedquestionnaire"]      
           @left_join = []
               
           @column_number =   @column_headers.size
    
         else    
           @html_request ="N"          
            @column_headers = ['Date','Protocol','Enumber','RMR','MRI status','PET status','LP status','LH status','NP status','Questionnaire status','Entered by','QCed by','QC completed','Compile folder','FS Y/N','Vgroup Note'] # need to look up values
            @fields =["vgroups.transfer_mri", "vgroups.transfer_pet", "vgroups.completedlumbarpuncture", "vgroups.completedblooddraw", "vgroups.completedneuropsych", "vgroups.completedquestionnaire", "concat(u1.first_name,' ',u1.last_name)", "concat(u2.first_name,' ',u2.last_name)", "vgroups.qc_completed", "vgroups.compile_folder","vgroups.fs_flag", "vgroups.note"]
            @left_join = ["LEFT JOIN users u1 on vgroups.entered_by = u1.id",
                              "LEFT JOIN users u2 on vgroups.qc_by = u2.id  "]
                  # Protocol,Enumber,RMR,vgroup_Date get prepended to the fields   
           @column_number =   @column_headers.size         
         end
          
          @tables =['vgroups'] # trigger joins --- vgroups and appointments by default
          @order_by =["vgroups.vgroup_date DESC", "vgroups.rmr"]
          
          # do what self.run_search is doing

          sql ="SELECT distinct vgroups.id vgroup_id,vgroups.vgroup_date,  vgroups.rmr , "+@fields.join(',')+" 
           FROM  scan_procedures_vgroups, "+@tables.join(',')+" "+@left_join.join(' ')+"
           WHERE  scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "

           sql = sql +" AND scan_procedures_vgroups.vgroup_id = vgroups.id "

           if @conditions.size > 0
               sql = sql +" AND "+@conditions.join(' and ')
           end
          #conditions - feed thru ActiveRecord? stop sql injection -- replace : ; " ' ( ) = < > - others?
           if @order_by.size > 0
             sql = sql +" ORDER BY "+@order_by.join(',')
           end          

           connection = ActiveRecord::Base.connection();
           @results2 = connection.execute(sql)
           @temp_results = @results2


           @results = []   
           i =0
           @temp_results.each do |var|
             @temp = []
             @temp_vgroup_id =[]
             # TRY TUNING BY GETTING ALL RELEVANT sp , enum , put in hash, with vgroup_id as key
             # take each var --- get vgroup_id => find vgroup
             # get scan procedure(s) -- make string, put in @results[0]
             # vgroup.rmr --- put in @results[1]
             # get enumber(s) -- make string, put in @results[2]
             # put the rest of var - minus vgroup_id, into @results
             # SLOWER THAN sql  -- 9915 msec vs 3193 msec
             #vgroup = Vgroup.find(var[0])
             #@temp[0]=vgroup.scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ")
             #@temp[1]=vgroup.enrollments.collect {|e| e.enumber }.join(", ")
             # change to scan_procedures.id and enrollments.id  or vgroup_id to make links-- maybe keep vgroup_id for display
             @temp[0] = var[1] # want appt date first
             if @html_request =="N"
                 sql_sp = "SELECT distinct scan_procedures.codename 
                       FROM scan_procedures, scan_procedures_vgroups
                       WHERE scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
                       AND scan_procedures_vgroups.vgroup_id = "+var[0].to_s
                 @results_sp = connection.execute(sql_sp)
                 @temp[1] =@results_sp.to_a.join(", ")

                 sql_enum = "SELECT distinct enrollments.enumber 
                       FROM enrollments, enrollment_vgroup_memberships
                       WHERE enrollments.id = enrollment_vgroup_memberships.enrollment_id
                       AND enrollment_vgroup_memberships.vgroup_id = "+var[0].to_s
                 @results_enum = connection.execute(sql_enum)
                 @temp[2] =@results_enum.to_a.join(", ")
                 var.delete_at(0) # get rid of vgroup_id- only in xls -- using vgroup_id to get vgroup --- so not chnage the index page code
                 var.delete_at(0) # get rid of vgroup_id- only in xls -- using vgroup_id to get vgroup --- so not chnage the index page code
             else  # need to only get the sp and enums which are displayed - and need object to make link
               @temp[1] = var[0].to_s
               @temp[2] = var[0].to_s
               var.delete_at(0) # get rid of vgroup_id- only in xls -- using vgroup_id to get vgroup --- so not chnage the index page code
             end 

             #

             @temp_row = @temp+ var
             @results[i] = @temp_row
             i = i+1
           end   
         
         @results_total = @results  # pageination makes result count wrong
        # return @vgroups instead? for html -- xls -- go to results -- no pageation
      t = Time.now 
      @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.count.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
      
      ### LOOK WHERE TITLE IS SHOWING UP
      @collection_title = 'All Vgroups'

      respond_to do |format|
        if @hide_page_flag == 'Y'
           format.html { redirect_to '/cg_search' }
        else
           format.xls # vgroups_search.xls.erb
           format.xml  { render :xml => @results }       
           format.html   {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)}# vgroups_search.html.erb
         end
      end
    end

    def nii_file_cnt(p_start_id="",p_end_id="") # duplicated somewhat in vgroup model
      @v_start_id=""
      @v_end_id = "" 

      if (!params[:nii_file_cnt].blank? and !params[:nii_file_cnt][:start_id].blank? and  !params[:nii_file_cnt][:end_id].blank?) or (!p_start_id.blank? and !p_end_id.blank?)
           if !p_start_id.blank? and !p_end_id.blank?
              @v_start_id  = p_start_id
              @v_end_id = p_end_id
           else
             @v_start_id = params[:nii_file_cnt][:start_id]
             @v_end_id = params[:nii_file_cnt][:end_id]
           end
           vg = Vgroup.find( @v_start_id)
           vg.nii_file_cnt( @v_start_id, @v_end_id) # use version in model - same as used by cron_interface
           
#           @vgroups = Vgroup.where( " id between "+@v_start_id+" and "+@v_end_id ).where("( nii_file_count is null or nii_file_count = 0 )")
#           v_base_path = @vgroups[0].get_base_path
#           v_glob = '*.nii'
#           @vgroups.each do |vg|
#             # could be multiple sp
#             vg.scan_procedures.each do |sp| 
#               v_sp = sp.codename
#               # could be multiple subject_id
#               vg.enrollments.each do |s|
#                 v_subject_id = s.enumber
#                 v_path = v_base_path+"/preprocessed/visits/"+v_sp+"/"+v_subject_id+"/unknown/"
#                 v_count = `cd #{v_path};ls -1 #{v_glob}| wc -l`.to_i   #
#                 if v_count > 0 
#                   @vgroup = Vgroup.find(vg.id)
#                   @vgroup.nii_file_count = v_count
#                   @vgroup.save
#                 end
#               end
#             end      
#           end
       end

      respond_to do |format|
           format.html # new.html.erb
      
      end
    end


  
  def home
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    # Remove default scope if sorting has been requested.
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Vgroup.unscoped.search(params[:search]) 
    else
      @search = Vgroup.search(params[:search]) 
    end
    @vgroups = @search.relation.where(" vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    @collection_title = 'All Visits'
    
    respond_to do |format|
      format.html # home.html.erb
      format.xml  { render :xml => @visits }
    end
    #  render :template => "vgroups/home"
  end

  # DELETE /vgroups/1
  # DELETE /vgroups/1.xml
  def destroy
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find_by_id(params[:id])
    # if the vgroup is not linked to a scan protocol, the access control breaks down
    # to get at vgroups without sp's need to be admin - also check that not linked to any sp
    @scan_procedures_vgroups = ScanProcedure.where("scan_procedures.id in (select scan_procedure_id from scan_procedures_vgroups where  vgroup_id in (?))",params[:id]) 
    if(@vgroup.nil? and  current_user.role == 'Admin_High' and @scan_procedures_vgroups.size <1)
         @vgroup = Vgroup.find(params[:id])
     end 
    @vgroup.destroy

    respond_to do |format|
      format.html { redirect_to('/vgroups/home') }
      format.xml  { head :ok }
    end
  end
end
