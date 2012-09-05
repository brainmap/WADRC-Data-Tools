require "base64"
class VisitsController <  AuthorizedController #  ApplicationController

    load_resource
    load_and_authorize_resource  :only => [ :show, :edit, :update]  #-- causes problems with the searches, but seems to be needed for the edit, show

    
    # to get the ussr scan_procedure array in
    # added in below by find
  
    before_filter :set_current_tab
    

  # GET /visits
  # GET /visits.xml  
  def index

     scan_procedure_array =current_user[:view_low_scan_procedure_array]
     # Remove default scope if sorting has been requested.
     if !params[:search].blank? && !params[:search][:meta_sort].blank?
       @search = Visit.unscoped.search(params[:search]) 
     else
       @search = Visit.search(params[:search]) 
     end
     @visits = @search.relation.where(" visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
     @collection_title = 'All MRI appts'
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @visits }
    end

  def change_direcory_path
       # normal visits way of getting sp array didn't work -- using vgroups version to get sp array
       scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:edit_low_scan_procedure_array] 
      @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
      v_path_original = @visit.path
      v_path_new = params[:path]
      cnt = 0
      if File.directory? v_path_new
        puts "folder exisits"
        cnt = 1
        @visit.path = v_path_new
        @visit.save
    
        if params[:change_image_dataset_path] == "1"
           sql = "update image_datasets set path = replace(path,'"+v_path_original+"','"+v_path_new+"')
                where path like '"+v_path_original+"%'"
           connection = ActiveRecord::Base.connection();
           @results = connection.execute(sql)
         end
          
        end
          if cnt > 0
             respond_to do |format|
                format.html { redirect_to( '/visits/'+params[:id], :notice => 'Directory path has been updated to '+params[:path]+'.' )}
                format.xml  { render :xml => @vgroup }
              end
          else
            respond_to do |format|
               format.html { redirect_to( '/visits/'+params[:id], :notice => 'The directory path was not valid.' )}
               format.xml  { render :xml => @vgroup }
             end
          end
  end

  # GET /visits/:scope
  def index_by_scope

    scan_procedure_array =current_user[:view_low_scan_procedure_array]
    @search = Visit.send(params[:scope]).search(params[:search])
    @visits = @search.relation.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    @collection_title = "All #{params[:scope].to_s.gsub('_',' ')} MRI appts"
    render :template => "visits/index"
  end
  
  def assigned_to_who
    redirect_to assigned_to_path( :user_login => params[:user][:username] )
  end
  
  # GET /visits/assigned_to/:user_login
  def index_by_user_id

    scan_procedure_array =current_user[:view_low_scan_procedure_array]
    
    @user = User.find(params[:user_login])
    @search = Visit.assigned_to(@user.id).search
    @visits = @search.relation.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    
    @collection_title = "All MRI appts assigned " # to #{params[:user_login]}"
    @visits = nil
    render :template => "visits/index"
  end
  
  def in_scan_procedure
    redirect_to in_scan_procedure_path( :scan_procedure_id => params[:scan_procedure][:id] )
  end

  def index_by_scan_procedure  


    scan_procedure_array =current_user[:view_low_scan_procedure_array]
    # sp = ScanProcedure.find_by_id(params[:scan_procedure_id])
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Visit.unscoped.includes(:scan_procedures).where(:scan_procedures => {:id => params[:scan_procedure_id]}).search(params[:search])
    else
      @search = Visit.includes(:scan_procedures).where(:scan_procedures => {:id => params[:scan_procedure_id]}).search
    end
    @visits =  @search.relation.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])   
    
    @collection_title = "All MRI appts enrolled in #{ScanProcedure.find_by_id(params[:scan_procedure_id]).codename}"
    
    
    render :template => "visits/index"

  end
  
  # GET /visits/by_month
  def by_month

    scan_procedure_array =current_user[:view_low_scan_procedure_array]
    @visits = Visit.relation.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).all
    @title = "Visits by month"
    @collection_title = "MRI appts by month"
    @total_count = @visits.size
    
    render :template => "visits/index_by_month"
  end
  
  # GET /visits/found
  def found

    scan_procedure_array =current_user[:view_low_scan_procedure_array]   
    @visits = Visit.find_by_search_params(params['visit_search']).where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    @collection_title = "Found MRI appts"
    @visit_search = params['visit_search']
    
    if @visits.size == 1
      @visit = @visits.first
      flash[:notice] = "Found 1 MRI appt matching that search."
      respond_to do |format|
        format.xml  { render :xml => @visit }
        format.html { redirect_to @visit }
      end
      
    else
      render :template => "visits/found"
    end
  end


   
  
  # GET /visits/find
  def find
    scan_procedure_array =current_user[:view_low_scan_procedure_array]
    @search = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).search(params[:search])
  end

  # GET /visits/1
  # GET /visits/1.xml
  def show
    scan_procedure_array =current_user[:view_low_scan_procedure_array]
  
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find_by_id(params[:id])
    # Grab the visits within 1 month +- visit date for "previous" and "back" hack.
    @visits = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).where(:date => @visit.date-1.month..@visit.date+1.month).all
    idx = @visits.index(@visit)
    @older_visit = idx + 1 >= @visits.size ? nil : @visits[idx + 1]
    @newer_visit = idx - 1 < 0 ? nil : @visits[idx - 1]
   
    @image_datasets = @visit.image_datasets.page(params[:page])
    @participant = @visit.try(:enrollments).first.try(:participant) 
    @enumbers = @visit.enrollments
    @mriscantask = Mriscantask.where("visit_id in (?) and (lookup_set_id not in (8) or lookup_set_id is NULL)",@visit.id)
    @appointment = Appointment.find(@visit.appointment_id)
    @vgroup = Vgroup.find(@appointment.vgroup_id)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @visit }
    end
  end

  # GET /visits/new
  # GET /visits/new.xml
  def new
    vgroup_id = params[:id]
    @vgroup = Vgroup.find(vgroup_id)
    @enumbers = @vgroup.enrollments
    params[:new_appointment_vgroup_id] = vgroup_id
    @visit = Visit.new
    @visit.enrollments << Enrollment.new
    @visit.user = current_user
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @visit }
    end
  end

  # GET /visits/1/edit
  def edit
    scan_procedure_array =current_user[:edit_low_scan_procedure_array ]   
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @visit.enrollments.build # if @visit.enrollments.blank?
    @mriscantask = Mriscantask.where("visit_id in (?) and (lookup_set_id not in (8) or lookup_set_id is NULL)",@visit.id)
    @appointment = Appointment.find(@visit.appointment_id)
  end

  # POST /visits
  # POST /visits.xml
  def create
            params[:date][:mristartt][0]="1899"
             params[:date][:mristartt][1]="12"
             params[:date][:mristartt][2]="30"       
             mristarttime = nil
            if !params[:date][:mristartt][0].blank? && !params[:date][:mristartt][1].blank? && !params[:date][:mristartt][2].blank? && !params[:date][:mristartt][3].blank? && !params[:date][:mristartt][4].blank?
        mristarttime =  params[:date][:mristartt][0]+"-"+params[:date][:mristartt][1]+"-"+params[:date][:mristartt][2]+" "+params[:date][:mristartt][3]+":"+params[:date][:mristartt][4]
             params[:visit][:mristarttime] = mristarttime
            end

         params[:date][:mriendt][0]="1899"
         params[:date][:mriendt][1]="12"
         params[:date][:mriendt][2]="30"       
          mriendtime = nil
        if !params[:date][:mriendt][0].blank? && !params[:date][:mriendt][1].blank? && !params[:date][:mriendt][2].blank? && !params[:date][:mriendt][3].blank? && !params[:date][:mriendt][4].blank?
    mriendtime =  params[:date][:mriendt][0]+"-"+params[:date][:mriendt][1]+"-"+params[:date][:mriendt][2]+" "+params[:date][:mriendt][3]+":"+params[:date][:mriendt][4]
         params[:visit][:mriendtime] = mriendtime
        end
    @visit = Visit.new(params[:visit])
    @visit.user = current_user
    if @visit.appointment_id.blank?
       @appointment = Appointment.create
       @appointment.appointment_type ='mri'
       @appointment.appointment_date = @visit.date
       if !params[:new_appointment_vgroup_id].blank?
         @vgroup = Vgroup.find(params[:new_appointment_vgroup_id])
       else
         @vgroup = Vgroup.create
         @vgroup.vgroup_date = @visit.date
       end
        @vgroup.rmr = @visit.rmr
       @vgroup.save
       @appointment.vgroup_id = @vgroup.id
       @appointment.user = current_user
       @appointment.save
       @vital = Vital.new
       @vital.appointment_id = @appointment.id
       @vital.save
       @visit.appointment_id = @appointment.id
    end
    
    
    respond_to do |format|
      if @visit.save
         @vgroup.transfer_mri = params[:vgroup][:transfer_mri]
          @vgroup.save
        flash[:notice] = 'MRI appt was successfully created.'
        format.html { redirect_to(@visit) }
        format.xml  { render :xml => @visit, :status => :created, :location => @visit }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @visit.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /visits/1
  # PUT /visits/1.xml
  def update
     scan_procedure_array =current_user[:edit_low_scan_procedure_array] 
     delete_scantask_array = []
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

             params[:date][:mristartt][0]="1899"
             params[:date][:mristartt][1]="12"
             params[:date][:mristartt][2]="30"       
             mristarttime = nil
            if !params[:date][:mristartt][0].blank? && !params[:date][:mristartt][1].blank? && !params[:date][:mristartt][2].blank? && !params[:date][:mristartt][3].blank? && !params[:date][:mristartt][4].blank?
        mristarttime =  params[:date][:mristartt][0]+"-"+params[:date][:mristartt][1]+"-"+params[:date][:mristartt][2]+" "+params[:date][:mristartt][3]+":"+params[:date][:mristartt][4]
             params[:visit][:mristarttime] = mristarttime
            end

         params[:date][:mriendt][0]="1899"
         params[:date][:mriendt][1]="12"
         params[:date][:mriendt][2]="30"       
          mriendtime = nil
        if !params[:date][:mriendt][0].blank? && !params[:date][:mriendt][1].blank? && !params[:date][:mriendt][2].blank? && !params[:date][:mriendt][3].blank? && !params[:date][:mriendt][4].blank?
    mriendtime =  params[:date][:mriendt][0]+"-"+params[:date][:mriendt][1]+"-"+params[:date][:mriendt][2]+" "+params[:date][:mriendt][3]+":"+params[:date][:mriendt][4]
         params[:visit][:mriendtime] = mriendtime
        end

    # hiding the protocols in checkbox which user not have access to, if any add in to attributes before update
    @scan_procedures = ScanProcedure.where(" scan_procedures.id in (select scan_procedure_id from scan_procedures_visits where visit_id = "+params[:id]+" and scan_procedure_id not in (?))",  scan_procedure_array ).all
    if @scan_procedures.count > 0
       scan_procedure_array = []
       @scan_procedures.each do |p2|
         scan_procedure_array << p2.id
       end    
       params[:visit][:scan_procedure_ids] = params[:visit][:scan_procedure_ids] | scan_procedure_array   
    end
     # HTML Checkbox Hack to remove all if none were checked.
    attributes = {'scan_procedure_ids' => []}.merge(params[:visit] || {} )
    
    @enumbers = @visit.enrollments
    # also want to set participant in vgroup
    set_participant_in_enrollment(@visit.rmr, @enumbers)
   if params[:pulse].blank?  
     params[:pulse]=991 
   end
   if params[:bp_systol].blank?  
     params[:bp_systol]=991 
   end
   if params[:bp_diastol].blank?  
     params[:bp_diastol]=991 
   end
   if params[:bloodglucose].blank?  
     params[:bloodglucose]=991 
   end
      
    if !params[:vital_id].blank?
      @vital = Vital.find(params[:vital_id])
      @vital.pulse = params[:pulse]
      @vital.bp_systol = params[:bp_systol]
      @vital.bp_diastol = params[:bp_diastol]
      @vital.bloodglucose = params[:bloodglucose]
      @vital.save
    else
      @vital = Vital.new
      @vital.appointment_id = @visit.appointment_id
      @vital.pulse = params[:pulse]
      @vital.bp_systol = params[:bp_systol]
      @vital.bp_diastol = params[:bp_diastol]
      @vital.bloodglucose = params[:bloodglucose]
      @vital.save      
    end
       
    # THIS SHOULD ALL BE CONDENSED ===> do it the ruby way
    # get all mriscantask[mriscantask_id][]
    #  if < 0 => insert if some field not null
    #  mriperformance[mriperformance_id][]  get all ---> if < 0 ==> insert if some field not null
                #e.g. name="mriperformance[mriperformance_id][]" value="-3" 
    						#name="mriperformance[mriscantask_id][-3]"  value="-22"  
    						
    						
    mriscantask_id_array = params[:mriscantask][:mriscantask_id]  
    mriscantask_id_array.each do |mri_id|
      if !params[:mriscantask][:destroy].blank?
       if !params[:mriscantask][:destroy][mri_id].blank?
        if !delete_scantask_array.blank?
          delete_scantask_array.push(mri_id)
        else
          delete_scantask_array=[mri_id]
        end
       end
      end
      mri_id_int = mri_id.to_i
      if mri_id_int < 0 
        if !params[:mriscantask][:lookup_set_id][mri_id].blank? or 
           !params[:mriscantask][:lookup_scantask_id][mri_id].blank? or 
              #!params[:mriscantask][:preday][mri_id].blank? or 
                 #!params[:mriscantask][:task_order][mri_id].blank? or 
                    #!params[:mriscantask][:moved][mri_id].blank? or 
                       #!params[:mriscantask][:eyecontact][mri_id].blank? or 
                          !params[:mriscantask][:logfilerecorded][mri_id].blank? or 
                              #!params[:mriscantask][:p_file][mri_id].blank? or 
                                  !params[:mriscantask][:tasknote][mri_id].blank? or 
                                      #!params[:mriscantask][:reps][mri_id].blank? or 
                                          #!params[:mriscantask][:has_concerns][mri_id].blank? or 
                                              #!params[:mriscantask][:concerns][mri_id].blank? or 
                                                  !params[:mriscantask][:image_dataset_id][mri_id].blank? 
            @mriscantask = Mriscantask.new
            @mriscantask.lookup_set_id = params[:mriscantask][:lookup_set_id][mri_id]
            if !params[:mriscantask][:lookup_scantask_id][mri_id].blank?
              @mriscantask.lookup_scantask_id = params[:mriscantask][:lookup_scantask_id][mri_id]
            end
            #@mriscantask.preday = params[:mriscantask][:preday][mri_id]
            @mriscantask.task_order = params[:mriscantask][:task_order][mri_id]
            #@mriscantask.moved = params[:mriscantask][:moved][mri_id]
            #@mriscantask.eyecontact = params[:mriscantask][:eyecontact][mri_id]
            @mriscantask.logfilerecorded = params[:mriscantask][:logfilerecorded][mri_id]
            #@mriscantask.p_file = params[:mriscantask][:p_file][mri_id]
            @mriscantask.tasknote = params[:mriscantask][:tasknote][mri_id]
            #@mriscantask.reps = params[:mriscantask][:reps][mri_id]
            #@mriscantask.has_concerns = params[:mriscantask][:has_concerns][mri_id]
            #@mriscantask.concerns = params[:mriscantask][:concerns][mri_id]
            @mriscantask.image_dataset_id = params[:mriscantask][:image_dataset_id][mri_id]
            @mriscantask.visit_id = @visit.id
            @mriscantask.save
            # get the acc and hit
            if !params[:mriscantask][:mriperformance_id][mri_id].blank?
              mp_id =  params[:mriscantask][:mriperformance_id][mri_id]
              mp_id_int = mp_id.to_i

              if mp_id_int < 0
                if !params[:mriperformance][:hitpercentage][mp_id].blank? or
                    !params[:mriperformance][:accuracypercentage][mp_id].blank?
                    @mriperformance = Mriperformance.new
                    @mriperformance.hitpercentage =params[:mriperformance][:hitpercentage][mp_id]
                    @mriperformance.accuracypercentage =params[:mriperformance][:accuracypercentage][mp_id]
                    @mriperformance.mriscantask_id =@mriscantask.id
                    @mriperformance.save          
                end 
              else
                @mriperformance = Mriperformance.find(mp_id)
                @mriperformance.hitpercentage =params[:mriperformance][:hitpercentage][mp_id]
                @mriperformance.accuracypercentage =params[:mriperformance][:accuracypercentage][mp_id]
                @mriperformance.save
              end
             end
          end
      else

        @mriscantask = Mriscantask.find(mri_id_int)
        @mriscantask.lookup_set_id = params[:mriscantask][:lookup_set_id][mri_id]
        if !params[:mriscantask][:lookup_scantask_id][mri_id].blank?
             @mriscantask.lookup_scantask_id = params[:mriscantask][:lookup_scantask_id][mri_id]
        end
        #@mriscantask.preday = params[:mriscantask][:preday][mri_id] 
        #@mriscantask.task_order = params[:mriscantask][:task_order][mri_id]
        #@mriscantask.moved = params[:mriscantask][:moved][mri_id]
        #@mriscantask.eyecontact = params[:mriscantask][:eyecontact][mri_id]
        @mriscantask.logfilerecorded = params[:mriscantask][:logfilerecorded][mri_id]
        #@mriscantask.p_file = params[:mriscantask][:p_file][mri_id]
        @mriscantask.tasknote = params[:mriscantask][:tasknote][mri_id]
        #@mriscantask.reps = params[:mriscantask][:reps][mri_id]
        #@mriscantask.has_concerns = params[:mriscantask][:has_concerns][mri_id]
        #@mriscantask.concerns = params[:mriscantask][:concerns][mri_id]
        @mriscantask.image_dataset_id = params[:mriscantask][:image_dataset_id][mri_id]
        @mriscantask.save
        # get the acc and hit
        
        if !params[:mriscantask][:mriperformance_id][mri_id].blank?
          mp_id =  params[:mriscantask][:mriperformance_id][mri_id]
          mp_id_int = mp_id.to_i

          if mp_id_int < 0
            if !params[:mriperformance][:hitpercentage][mp_id].blank? or
                !params[:mriperformance][:accuracypercentage][mp_id].blank?
                @mriperformance = Mriperformance.new
                @mriperformance.hitpercentage =params[:mriperformance][:hitpercentage][mp_id]
                @mriperformance.accuracypercentage =params[:mriperformance][:accuracypercentage][mp_id]
                @mriperformance.mriscantask_id =@mriscantask.id
                @mriperformance.save          
            end 
          else
            @mriperformance = Mriperformance.find(mp_id)
            @mriperformance.hitpercentage =params[:mriperformance][:hitpercentage][mp_id]
            @mriperformance.accuracypercentage =params[:mriperformance][:accuracypercentage][mp_id]
            @mriperformance.save
          end
         end
      end
    end         
    respond_to do |format|
      if @visit.update_attributes(attributes)
        if !delete_scantask_array.blank?
          delete_scantask_array.each do |mri_id|
             @mriscantask = Mriscantask.find(mri_id.to_i)
             @mriscantask.destroy
         end
        end
        @appointment = Appointment.find(@visit.appointment_id)
        @appointment.appointment_date = @visit.date
        @appointment.save
        @vgroup = Vgroup.find(@appointment.vgroup_id)
        @vgroup.transfer_mri = params[:vgroup][:transfer_mri]
        @vgroup.rmr = @visit.rmr
 #       @vgroup.enrollments = @visit.enrollments
        if !@visit.enrollments.blank?
          sql = "Delete from enrollment_vgroup_memberships where vgroup_id ="+@vgroup.id.to_s
          connection = ActiveRecord::Base.connection();        
          results = connection.execute(sql)
          @visit.enrollments.each do |e|
            sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+e.id.to_s+")"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)
          end 
          
        else
          sql = "Delete from enrollment_vgroup_memberships where vgroup_id ="+@vgroup.id.to_s
          connection = ActiveRecord::Base.connection();        
          results = connection.execute(sql)
        end
         if !@visit.scan_procedures.blank?
           sql = "Delete from scan_procedures_vgroups where vgroup_id ="+@vgroup.id.to_s
           connection = ActiveRecord::Base.connection();        
           results = connection.execute(sql)
           @visit.scan_procedures.each do |sp|  
             sql = "Insert into scan_procedures_vgroups(vgroup_id,scan_procedure_id) values("+@vgroup.id.to_s+","+sp.id.to_s+")"
             connection = ActiveRecord::Base.connection();        
             results = connection.execute(sql)        
           end   
         else
           sql = "Delete from scan_procedures_vgroups where vgroup_id ="+@vgroup.id.to_s
           connection = ActiveRecord::Base.connection();        
           results = connection.execute(sql)
         end
        @vgroup.save
   #     4
        flash[:notice] = 'visit was successfully updated.'
        format.html { redirect_to(@visit) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @visit.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def set_participant_in_enrollment( rmr, enroll)
    # loop thru each enrollment, check for participant_id
    # if not populated, look for other participant_id based on
    # last 6 digits of rmr = RMRaic
    # other participant_id for the enumber
    
    participant_id =""
    enumber_array = []
    # make hash of enums
     blank_participant_id ="N"
    enroll.each do |e|
       enumber_array << e.enumber
       if !e.participant_id.blank?
           participant_id = e.participant_id
       else
           blank_participant_id ="Y"
       end
    end
    # what if there are two participant_id's -- multiple enrollments

    if participant_id.blank?
      # if rmr starts with RMRaic and last 6 chars are digits
      # look for a participant with this reggieID
      if rmr[0..5] == "RMRaic" && is_a_number?(rmr[6..11]) && rmr.length == 12
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
      if participant_id.blank? && rmr[0..5] == "RMRaic" && is_a_number?(rmr[6..11]) && rmr.length == 12
          # do insert , get participant_id
           
           @participant = Participant.new
           @participant.reggieid = rmr[6..11]
           @participant.save
          participant_id = @participant.id
      end
          # participant_id was blank, now, if not blank, update enrollments where participant_id is null
      if !participant_id.blank?
         sql = "UPDATE enrollments set enrollments.participant_id = "+participant_id.to_s+" WHERE enrollments.participant_id is NULL AND
                          enrollments.id 
                            IN (select  enrollment_visit_memberships.enrollment_id  FROM enrollment_visit_memberships
                                WHERE enrollment_visit_memberships.visit_id = "+params[:id]+ " )"

                           
          connection = ActiveRecord::Base.connection();
          results = connection.execute(sql)          
      end      
    end
    if  blank_participant_id == "Y"
      if !participant_id.blank?
         sql = "UPDATE enrollments set enrollments.participant_id = 2606 WHERE enrollments.participant_id is NULL AND
                          enrollments.id 
                            IN (select  enrollment_visit_memberships.enrollment_id  FROM enrollment_visit_memberships
                                WHERE enrollment_visit_memberships.visit_id = 832 )"

         # problems with multiple participants - even the same one for a visit                  
           connection = ActiveRecord::Base.connection();
           results = connection.execute(sql)          
      end      
    end 
    
    # check if vgroup.participant_id is blank 
    if !participant_id.blank?
      # HOW TO DO THE CHAINED FIND?
       @vgroup = Vgroup.find(Appointment.find(Visit.find(params[:id]).appointment_id).vgroup_id)
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
  

  # DELETE /visits/1
  # DELETE /visits/1.xml
  def destroy
     @user = current_user
  # not sure why :edit_low_scan_procedure_array is getting lost, could because permissions on user and ability
  # can also get edit_low_scan_procedure_array from user, but its got spaces 
   #  scan_procedure_array =@user[:edit_low_scan_procedure_array]
    scan_procedure_array =(@user.edit_low_scan_procedure_array).split(' ').map(&:to_i) 
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    
    
    if @visit.appointment_id > 3156 # sure appointment_id not used by any other
       @appointment = Appointment.find(@visit.appointment_id)
       @appointments = Appointment.where("vgroup_id in (?)",@appointment.vgroup_id)
       if @appointments.length < 2 # sure appointment_id not used by any other
          @vgroup = Vgroup.find(@appointment.vgroup_id)
          @vgroup.destroy
       end
       @appointment.destroy
    end
    @visit.destroy

    respond_to do |format|
      format.html { redirect_to(visit_search_path) }
      format.xml  { head :ok }
    end
  end
  
  # Send an Email About the Visit
  def send_confirmation
    @visit=Visit.find(params[:id])
    begin
      PandaMailer.visit_confirmation(@visit, params[:email]).deliver
      flash[:notice] = "Email was succesfully sent."
    rescue StandardError => error
      logger.info error
      flash[:error] = "Sorry, your email was not delivered: " + error.to_s
    end
    redirect_to @visit
  end
  
  
  
  def visit_search
    # possible params -- visits fields just get added as AND statements
    #   other table fields should be grouped into one lower level IN select 
    # scan_procedures_visits.scan_procedures_id
    # visits.rmr
    # visits.path
    # visits.date scan date before = latest_timestamp(1i)(2i)(3i)
    # visits.date scan date after  = earliest_timestamp(1i)(2i)(3i)
    
   
    #enrollment_visit_memberships.enrollment_id enrollments.enumber
   params["search_criteria"] =""
    
   if params[:visit_search].nil?
        params[:visit_search] =Hash.new  
   end
    #scan_procedure_array =current_user[:view_low_scan_procedure_array]
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
    # Remove default scope if sorting has been requested.
    @search = Visit.search(params[:search]) 
      if !params[:visit_search][:scan_procedure_id].blank?
         @search =@search.where(" visits.id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedures_visits.scan_procedure_id in (?))",params[:visit_search][:scan_procedure_id])
         @scan_procedures = ScanProcedure.where("id in (?)",params[:visit_search][:scan_procedure_id])
         params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end
      
      if !params[:visit_search][:series_description].blank?
         var = "%"+params[:visit_search][:series_description].downcase+"%"
         @search =@search.where(" visits.id in (select image_datasets.visit_id from image_datasets
          where lower(image_datasets.series_description) like ? )", var)
          params["search_criteria"] = params["search_criteria"] +", Series description "+params[:visit_search][:series_description]
      end
      
      if !params[:visit_search][:enumber].blank?
         @search =@search.where(" visits.id in (select enrollment_visit_memberships.visit_id from enrollment_visit_memberships,enrollments
          where enrollment_visit_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower(?)))",params[:visit_search][:enumber])
          params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:visit_search][:enumber]
      end      

      if !params[:visit_search][:rmr].blank? && params[:visit_search][:path].blank? && params[:visit_search][:latest_timestamp].blank? && params[:visit_search][:earliest_timestamp].blank?
          @search = @search.where(" lower(visits.rmr) in (lower(?))",params[:visit_search][:rmr])
          params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:visit_search][:rmr]
      elsif params[:visit_search][:rmr].blank? && !params[:visit_search][:path].blank? && params[:visit_search][:latest_timestamp].blank? && params[:visit_search][:earliest_timestamp].blank?
              var ="%"+params[:visit_search][:path]+"%"
             @search = @search.where(" visits.path LIKE ? ",var)
             params["search_criteria"] = params["search_criteria"] +", Path "+params[:visit_search][:path]
      elsif !params[:visit_search][:rmr].blank? && !params[:visit_search][:path].blank? && params[:visit_search][:latest_timestamp].blank? && params[:visit_search][:earliest_timestamp].blank?
            var ="%"+params[:visit_search][:path]+"%"
            @search = @search.where(" visits.path LIKE ? and visits.rmr in (?) ",var,params[:visit_search][:rmr])
            params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:visit_search][:rmr]+", Path "+params[:visit_search][:path]
      end

       #  build expected date format --- between, >, < 
       v_date_latest =""
       #want all three date parts
      
       if !params[:visit_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:visit_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:visit_search]["#{'latest_timestamp'}(3i)"].blank?
            v_date_latest = params[:visit_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:visit_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:visit_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
       end

       v_date_earliest =""
       #want all three date parts
  
       if !params[:visit_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:visit_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:visit_search]["#{'earliest_timestamp'}(3i)"].blank?
             v_date_earliest = params[:visit_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:visit_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:visit_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
        end

       if v_date_latest.length>0 && v_date_earliest.length >0
         @search = @search.where(" visits.date between ? and ? ",v_date_earliest,v_date_latest)
         params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
       elsif v_date_latest.length>0
         @search = @search.where(" visits.date < ?  ",v_date_latest)
          params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest
       elsif  v_date_earliest.length >0
         @search = @search.where(" visits.date > ? ",v_date_earliest)
          params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
        end

        if !params[:visit_search][:gender].blank?
           @search =@search.where(" visits.id in (select enrollment_visit_memberships.visit_id from participants,  enrollment_visit_memberships, enrollments
            where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
                   and participants.gender is not NULL and participants.gender in (?) )", params[:visit_search][:gender])
            if params[:visit_search][:gender] == 1
               params["search_criteria"] = params["search_criteria"] +",  sex is Male"
            elsif params[:visit_search][:gender] == 2
               params["search_criteria"] = params["search_criteria"] +",  sex is Female"
            end
        end   


        if !params[:visit_search][:min_age].blank? && params[:visit_search][:max_age].blank?
            @search = @search.where("  visits.id in (select enrollment_visit_memberships.visit_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits,visits
                               where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id 
                            and visits.id = enrollment_visit_memberships.visit_id
                            and floor(DATEDIFF(visits.date,participants.dob)/365.25) >= ?   )",params[:visit_search][:min_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:visit_search][:min_age]
        elsif params[:visit_search][:min_age].blank? && !params[:visit_search][:max_age].blank?
             @search = @search.where("  visits.id in (select enrollment_visit_memberships.visit_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits,visits
                             where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                         and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id 
                         and visits.id = enrollment_visit_memberships.visit_id
                         and floor(DATEDIFF(visits.date,participants.dob)/365.25) <= ?   )",params[:visit_search][:max_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:visit_search][:max_age]
        elsif !params[:visit_search][:min_age].blank? && !params[:visit_search][:max_age].blank?
           @search = @search.where("  visits.id in (select enrollment_visit_memberships.visit_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits,visits
                           where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                       and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id 
                       and visits.id = enrollment_visit_memberships.visit_id
                       and floor(DATEDIFF(visits.date,participants.dob)/365.25) between ? and ?   )",params[:visit_search][:min_age],params[:visit_search][:max_age])
          params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:visit_search][:min_age]+" and "+params[:visit_search][:max_age]
        end
        # trim leading ","
        params["search_criteria"] = params["search_criteria"].sub(", ","")
        # pass to download file?
        
    @search =  @search.where(" visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array)
    @visits =  @search.page(params[:page])
    ### LOOK WHERE TITLE IS SHOWING UP
    @collection_title = 'All MRI appts'
 
   
#    light_include_options = :image_dataset_quality_checks
#    heavy_include_options = {
#      :image_dataset_quality_checks => {:except => [:id]},
#      :visit => {:methods => :age_at_visit, :only => [:scanner_source, :date], :include => {
#        :enrollments => {:only => [:enumber], :include => { 
#          :participant => { :methods => :genetic_status, :only => [:gender, :wrapnum, :ed_years] }
#        }}
#      }}
#    }
=begin
light_include_options = :image_dataset_quality_checks
merged_comment_html
label_not_null_comments
scan_procedure_name

radiology_comments_options = {
  :visit => {:methods => :age_at_visit, :only => [:id,:scanner_source, :rmr, :date,:note], :include => {
    :radiology_comment =>{:only => [:comment_html_1, :comment_html_2]},
    :image_dataset_quality_checks =>{ :only => [:id]},
    :image_dataset =>{:image_dataset_comment => { :only =>[:comment]}}
    :enrollments => {:only => [:enumber], :include => { 
      :participant => { :methods => :genetic_status, :only => [:gender, :wrapnum, :ed_years] }
    }}
  }}
}
=end
# use methods for radiology_comments, image_dataset comment and image dataset quailty check comments
radiology_comments_options = {
      :radiology_comments => { :methods => :combined_radiology_comments ,:only =>[:q1_flag ]    }
}
#      :image_datasets => { :only => [:series_description] }
# }

limit_visits =  [:user_id ,:initials,:transfer_mri,:transfer_pet,:conference,:dicom_dvd,:compile_folder,:id,
                  :created_at, :updated_at, :research_diagnosis, :consent_form_type, :created_by_id, :dicom_study_uid,:compiled_at]



### if Radiology - pass in params -- do same seach, but call differ respond_to
### add radiology_comments, image_dataset comment, and image_dataset_quality_check columns to visit?
### define what field go out
#     light_include_options = :visit
        export_record = visit_search_path(:visit_search => params[:visit_search], :format => :csv)
        export_record.gsub!('%28','(')
        export_record.gsub!('%29',')')

        
        #current_user.id.to_s 
        # add export_log
  @current_tab = "visit_search"
    respond_to do |format|
      format.html {render :template => "visits/visit_search"}
      if !params[:visit_search][:include_radiology_comment].try(:length).nil?
         if params[:visit_search][:include_radiology_comment] == "1"
           
            format.csv  {   render :csv => @visits.csv_download_limit(@search,radiology_comments_options,limit_visits) }
         else
            format.csv  { render :csv => @visits.csv_download(@search) }
         end
      else
        format.csv  { render :csv => @visits.csv_download(@search) }
      end  
    end
#    render :template => "visits/visit_search"
    
  end
  
  private
  
  def set_current_tab
    @current_tab = "visits"
  end
  
end
