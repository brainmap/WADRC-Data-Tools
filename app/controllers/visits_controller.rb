# encoding: utf-8
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
           hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
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

  def change_directory_path
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
    
        # always change # if params[:change_image_dataset_path] == "1"
        sql = "update image_datasets set path = replace(path,'"+v_path_original+"','"+v_path_new+"')
                where path like '"+v_path_original+"%' and image_datasets.visit_id ="+@visit.id.to_s
        connection = ActiveRecord::Base.connection();
        puts sql
        @results = connection.execute(sql)
         
          
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
  def index_by_scope   # probably not being used

    scan_procedure_array =current_user[:view_low_scan_procedure_array]
    @search = Visit.send(params[:scope]).search(params[:search])      # should this be instance_eval 
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
    #redirect_to in_scan_procedure_path( :scan_procedure_id => params[:scan_procedure][:id] )
    redirect_to mri_search_path( :scan_procedure_id => params[:scan_procedure][:id] )
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
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @search = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).search(params[:search])
  end

  # GET /visits/1
  # GET /visits/1.xml
  def show
    scan_procedure_array =current_user[:view_low_scan_procedure_array]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
  
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find_by_id(params[:id])
    # Grab the visits within 1 month +- visit date for "previous" and "back" hack.
    @visits = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).where(:date => @visit.date-1.month..@visit.date+1.month).all
    # might be giving errors if user not have perms on some of visits????
    idx = @visits.index(@visit)
    @older_visit = idx + 1 >= @visits.size ? nil : @visits[idx + 1]
    @newer_visit = idx - 1 < 0 ? nil : @visits[idx - 1]
   
        @image_comments = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets,scan_procedures_visits
         where image_datasets.visit_id = scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?) and image_datasets.visit_id in (?))", scan_procedure_array,@visit.id) 

    @image_datasets = @visit.image_datasets.page(params[:page])
    @participant = @visit.try(:enrollments).first.try(:participant) 
    @enumbers = @visit.enrollments
    @mriscantask = Mriscantask.where("visit_id in (?) and (lookup_set_id not in (8) or lookup_set_id is NULL)",@visit.id)
    @appointment = Appointment.find(@visit.appointment_id)
    @vgroup = Vgroup.find(@appointment.vgroup_id)
              v_app_base_path = Rails.root
                 v_thumbnail_base = v_app_base_path.to_s+"/public/system/thumbnails/"
             if Rails.env=="production" 
                 v_thumbnail_base = v_app_base_path.to_s+"/shared/system/thumbnails/"
              end
              @visit.image_datasets.each do |ids|
                    v_thumbnail_path = v_thumbnail_base+ids.id.to_s
                    puts "aaaaaaaaaaaa v_thumbnail_path=  "+v_thumbnail_path
                    # problem with umask 007 setting all files to 770 , and files created as non-expected (web server?) user
                    # FileUtils.chown_R('panda_user','panda_group', v_thumbnail_path); 
                     # check if file exists,
                     # check permissions 
                   if File.directory?(v_thumbnail_path)
                      FileUtils.chmod_R(0774, v_thumbnail_path)
                   end 
              end

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

def series_desc_cnt(p_start_id="",p_end_id="")  ### ??? duplicate in visit model????
  @v_start_id=""
  @v_end_id = "" 

  if (!params[:series_desc_cnt].blank? and !params[:series_desc_cnt][:start_id].blank? and  !params[:series_desc_cnt][:end_id].blank?) or (!p_start_id.blank? and !p_end_id.blank?)
       if !p_start_id.blank? and !p_end_id.blank?
          @v_start_id  = p_start_id
          @v_end_id = p_end_id
       else
         @v_start_id = params[:series_desc_cnt][:start_id]
         @v_end_id = params[:series_desc_cnt][:end_id]
       end
       v = Visit.find(3) # just getting a visit to call visit model function
       v.series_desc_cnt(@v_start_id,@v_end_id) ## using version in model - same as used by cron
#       @image_datasets = ImageDataset.where( " id between "+@v_start_id+" and "+@v_end_id ).where(" dcm_file_count is null ").where(" glob is not null")
#       @image_datasets.each do |ids|
#       v_path = (ids.path).gsub('team','team*')
#       if !ids.glob.blank?
#         v_glob = (ids.glob).gsub('*.dcm','*.dcm*')
#         v_count = `cd #{v_path};ls -1 #{v_glob}| wc -l`.to_i   # 
#         ids.dcm_file_count = v_count
#         ids.save      
#       end
#     end
   end

  respond_to do |format|
    format.html # new.html.erb
  end
end

  # GET /visits/1/edit
  def edit
    scan_procedure_array =current_user[:edit_low_scan_procedure_array ]
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end   
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @visit.enrollments.build # if @visit.enrollments.blank?
    @mriscantask = Mriscantask.where("visit_id in (?) and (lookup_set_id not in (8) or lookup_set_id is NULL)",@visit.id)
    @appointment = Appointment.find(@visit.appointment_id)
    @vgroup = Vgroup.find(@appointment.vgroup_id)
         @image_comments = ImageComment.where("image_comments.image_dataset_id in ( select image_datasets.id from image_datasets,scan_procedures_visits
         where image_datasets.visit_id = scan_procedures_visits.visit_id and scan_procedures_visits.scan_procedure_id in (?) and image_datasets.visit_id in (?))", scan_procedure_array,@visit.id) 

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
             params[:visit][:mristarttime_hour] = params[:date][:mristartt][3]
             params[:visit][:mristarttime_minute] =params[:date][:mristartt][4]
            end

         params[:date][:mriendt][0]="1899"
         params[:date][:mriendt][1]="12"
         params[:date][:mriendt][2]="30"       
          mriendtime = nil
        if !params[:date][:mriendt][0].blank? && !params[:date][:mriendt][1].blank? && !params[:date][:mriendt][2].blank? && !params[:date][:mriendt][3].blank? && !params[:date][:mriendt][4].blank?
    mriendtime =  params[:date][:mriendt][0]+"-"+params[:date][:mriendt][1]+"-"+params[:date][:mriendt][2]+" "+params[:date][:mriendt][3]+":"+params[:date][:mriendt][4]
         params[:visit][:mriendtime] = mriendtime
         params[:visit][:mriendtime_hour] = params[:date][:mriendt][3]
        params[:visit][:mriendtime_minute] =params[:date][:mriendt][4]
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
        @vgroup.transfer_mri = params[:vgroup][:transfer_mri]
       # @vgroup.dicom_dvd = params[:vgroup][:dicom_dvd]
        #@vgroup.entered_by = params[:vgroup][:entered_by]
       @vgroup.save
       @appointment.vgroup_id = @vgroup.id
       @appointment.user = current_user
       if !@vgroup.participant_id.blank?
         @participant = Participant.find(@vgroup.participant_id)
         if !@participant.dob.blank?
            @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).round(2)
         end
       end
       @appointment.save
       @vital = Vital.new
       @vital.appointment_id = @appointment.id
       @vital.save
       @visit.appointment_id = @appointment.id
    end
    
    
    respond_to do |format|
      if @visit.save
         @vgroup.transfer_mri = params[:vgroup][:transfer_mri]
         # @vgroup.dicom_dvd = params[:vgroup][:dicom_dvd]
         # @vgroup.entered_by = params[:vgroup][:entered_by]
          @vgroup.save
          # not sure if this is useful in the load script
=begin
          sql = "Delete from scan_procedures_vgroups where vgroup_id ="+@vgroup.id.to_s
          connection = ActiveRecord::Base.connection();        
          results = connection.execute(sql)
          sql = "select distinct scan_procedure_id from scan_procedures_visits where visit_id in (select visits.id from visits, appointments where appointments.id = visits.appointment_id and appointments.vgroup_id ="+@vgroup.id.to_s+")"
          connection = ActiveRecord::Base.connection();        
          results = connection.execute(sql)
          results.each do |sp|           
            sql = "Insert into scan_procedures_vgroups(vgroup_id,scan_procedure_id) values("+@vgroup.id.to_s+","+sp[0].to_s+")"
            connection = ActiveRecord::Base.connection();        
            results = connection.execute(sql)        
          end
=end          
        flash[:notice] = 'MRI appt was successfully created.'
        format.html { redirect_to(@visit) }
        format.xml  { render :xml => @visit, :status => :created, :location => @visit }
      else
        @vital.delete
        @appointment.delete
        format.html { render :action => "new" }
        format.xml  { render :xml => @visit.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /visits/1
  # PUT /visits/1.xml
  def update
     scan_procedure_array =current_user[:edit_low_scan_procedure_array] 
           hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
     delete_scantask_array = []
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

             params[:date][:mristartt][0]="1899"
             params[:date][:mristartt][1]="12"
             params[:date][:mristartt][2]="30"       
             mristarttime = nil
            if !params[:date][:mristartt][0].blank? && !params[:date][:mristartt][1].blank? && !params[:date][:mristartt][2].blank? && !params[:date][:mristartt][3].blank? && !params[:date][:mristartt][4].blank?
        mristarttime =  params[:date][:mristartt][0]+"-"+params[:date][:mristartt][1]+"-"+params[:date][:mristartt][2]+" "+params[:date][:mristartt][3]+":"+params[:date][:mristartt][4]
             params[:visit][:mristarttime] = mristarttime
             params[:visit][:mristarttime_hour] = params[:date][:mristartt][3]
             params[:visit][:mristarttime_minute] =params[:date][:mristartt][4]
            end

         params[:date][:mriendt][0]="1899"
         params[:date][:mriendt][1]="12"
         params[:date][:mriendt][2]="30"       
          mriendtime = nil
        if !params[:date][:mriendt][0].blank? && !params[:date][:mriendt][1].blank? && !params[:date][:mriendt][2].blank? && !params[:date][:mriendt][3].blank? && !params[:date][:mriendt][4].blank?
    mriendtime =  params[:date][:mriendt][0]+"-"+params[:date][:mriendt][1]+"-"+params[:date][:mriendt][2]+" "+params[:date][:mriendt][3]+":"+params[:date][:mriendt][4]
         params[:visit][:mriendtime] = mriendtime
         params[:visit][:mriendtime_hour] = params[:date][:mriendt][3]
        params[:visit][:mriendtime_minute] =params[:date][:mriendt][4]
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
      # delete the ids comment
      if !params[:mriscantask][:image_dataset_id].blank? and !params[:mriscantask][:image_dataset_id][mri_id].blank? and
             !params[:mriscantask][:imagedataset].blank? and !params[:mriscantask][:imagedataset][:destroy].blank? and 
                 !params[:mriscantask][:imagedataset][:destroy][params[:mriscantask][:image_dataset_id][mri_id]].blank?
           params[:mriscantask][:imagedataset][:destroy][params[:mriscantask][:image_dataset_id][mri_id]].each do |ids_comment|
puts "DELETE COMMENT "+ids_comment.to_s
              @image_comment = ImageComment.where("image_comments.image_dataset_id in (?) ",params[:mriscantask][:image_dataset_id][mri_id]).find(ids_comment[0])
              @image_comment.destroy
           end
      end 

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
                    !params[:mriscantask][:task_order][mri_id].blank? or
                          !params[:mriscantask][:logfilerecorded][mri_id].blank? or 
                                  !params[:mriscantask][:tasknote][mri_id].blank? or 
                                                  !params[:mriscantask][:image_dataset_id][mri_id].blank? 

            if !params[:mriscantask][:tasknote][mri_id].blank? and !params[:mriscantask][:image_dataset_id][mri_id].blank? and    
       params[:mriscantask][:lookup_set_id][mri_id].blank? and  params[:mriscantask][:lookup_scantask_id][mri_id].blank? and 
                    params[:mriscantask][:task_order][mri_id].blank? and  params[:mriscantask][:logfilerecorded][mri_id].blank? 
              @image_comment = ImageComment.new
              @image_comment.image_dataset_id = params[:mriscantask][:image_dataset_id][mri_id]
              @image_comment.comment = params[:mriscantask][:tasknote][mri_id]
              @image_comment.user = current_user
              @image_comment.save
              params[:mriscantask][:tasknote][mri_id] = ""
            end   # still need to make the scantask linked to ids            
            @mriscantask = Mriscantask.new
            @mriscantask.lookup_set_id = params[:mriscantask][:lookup_set_id][mri_id]
            
            if !params[:mriscantask][:lookup_scantask_id][mri_id].blank?
              @mriscantask.lookup_scantask_id = params[:mriscantask][:lookup_scantask_id][mri_id]
            end
            @mriscantask.task_order = params[:mriscantask][:task_order][mri_id]
            @mriscantask.logfilerecorded = params[:mriscantask][:logfilerecorded][mri_id]
            @mriscantask.tasknote = params[:mriscantask][:tasknote][mri_id]
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

       if !params[:mriscantask][:tasknote][mri_id].blank? and !params[:mriscantask][:image_dataset_id][mri_id].blank? and    
       params[:mriscantask][:lookup_set_id][mri_id].blank? and  params[:mriscantask][:lookup_scantask_id][mri_id].blank? and 
                    params[:mriscantask][:task_order][mri_id].blank? and  params[:mriscantask][:logfilerecorded][mri_id].blank? 
           @image_comment = ImageComment.new
           @image_comment.image_dataset_id = params[:mriscantask][:image_dataset_id][mri_id]
           @image_comment.comment = params[:mriscantask][:tasknote][mri_id]
           @image_comment.user = current_user
           @image_comment.save
           # this isn't doing the Redcloth markup language?
            # got stringify error when used image_comments_controller create 
            # @image_comment = @image_dataset.image_comments.build(params[:image_comment])
       else   
        @mriscantask = Mriscantask.find(mri_id_int)
        @mriscantask.lookup_set_id = params[:mriscantask][:lookup_set_id][mri_id]
        if !params[:mriscantask][:lookup_scantask_id][mri_id].nil?
             @mriscantask.lookup_scantask_id = params[:mriscantask][:lookup_scantask_id][mri_id]
        end
        @mriscantask.logfilerecorded = params[:mriscantask][:logfilerecorded][mri_id]
        @mriscantask.task_order = params[:mriscantask][:task_order][mri_id]
        @mriscantask.tasknote = params[:mriscantask][:tasknote][mri_id]
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
       end # comment only
      end
    end 
    
    # image_datasets.dicom_hashtag is weird -hard to pull out the field value
    # using ruby -- IF visit_id = 762

    # getting error when trying to add enumber ??? try changing thye enum format chars[xxxx(x)]digits[xxxx]
    if (@visit.mri_coil_name).blank?
        # was doing a batch image_dataset update triggers by an update in visit 762
      ##  if @visit.id == 762
      ##      @temp_imagedatasets = ImageDataset.where("images_datasets.mri_coil_name is null and image_datasets.scanned_file like '%dcm%'")
      ##      @temp_imagedatasets.each do |dataset|
      ##        if  dataset.dicom_taghash and dataset.mri_coil_name.blank?  
      ##          tags = dataset.dicom_taghash      
      ##          if !tags['0018,1250'].blank? and tags['0018,1250'] != '0018,1250' and tags['0018,1250'][:value] != ''
      ##            dataset.mri_coil_name  = tags['0018,1250'][:value].blank? ? nil : tags['0018,1250'][:value].to_s  
      ##            dataset.save
      ##          end
      ##        end 
      ##      end
      ##  end

       @mri_coil_name = @visit.mri_coil_name_from_dicom_info 
       # excluding 
       #'HDNV Array','Perfusion ROIs','BODY','FMT (color)','MTT(CVP) (color)','flow:SVDbc (color)', 'rCBV (color)','rCBV','flow:SVD (bc)','FMT','MTT(CVP)'
       # getting 2 mri_coil_name in scan

       @visit.mri_coil_name = @mri_coil_name[:name]  unless @mri_coil_name[:name].blank?
       # doing update if ids mri_coil_name instead of changing metamri

       @visit.image_datasets.each do |dataset|
        if  dataset.dicom_taghash  
          tags = dataset.dicom_taghash      
          if !tags['0018,1250'].blank? and tags['0018,1250'] != '0018,1250' and tags['0018,1250'][:value] != ''
              dataset.mri_coil_name  = tags['0018,1250'][:value].blank? ? nil : tags['0018,1250'][:value].to_s  
              dataset.save
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
        @vgroup = Vgroup.find(@appointment.vgroup_id)
        @appointment.appointment_date = @visit.date
        if !@vgroup.participant_id.blank?
          @participant = Participant.find(@vgroup.participant_id)
          if !@participant.dob.blank?
             @appointment.age_at_appointment = ((@appointment.appointment_date - @participant.dob)/365.25).round(2)
          end
        end
        if !params[:appointment].nil? and !params[:appointment][:appointment_coordinator].nil?
            @appointment.appointment_coordinator = params[:appointment][:appointment_coordinator]
        end
        if !params[:appointment].nil? and !params[:appointment][:secondary_key].nil?
            @appointment.secondary_key = params[:appointment][:secondary_key]
        end
        @appointment.save

        @vgroup.transfer_mri = params[:vgroup][:transfer_mri]
       # @vgroup.dicom_dvd = params[:vgroup][:dicom_dvd]
        #@vgroup.entered_by = params[:vgroup][:entered_by]
        @vgroup.rmr = @visit.rmr
 #       @vgroup.enrollments = @visit.enrollments
        sql = "Delete from enrollment_vgroup_memberships where vgroup_id ="+@vgroup.id.to_s
        connection = ActiveRecord::Base.connection();        
        results_del = connection.execute(sql)
        sql = "select distinct enrollment_id from enrollment_visit_memberships where visit_id in (select visits.id from visits, appointments where appointments.id = visits.appointment_id and appointments.vgroup_id ="+@vgroup.id.to_s+")"
        connection = ActiveRecord::Base.connection();        
        results = connection.execute(sql)
        v_do_not_share_scans_flag ="N"
        if results.count > 0
            v_do_not_share_scans_flag ="Y"
        end
        results.each do |e|
          enrollment = Enrollment.find(e[0])
          if enrollment.do_not_share_scans_flag.empty? or enrollment.do_not_share_scans_flag != "Y"
            v_do_not_share_scans_flag ="N" 
          end
          sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+e[0].to_s+")"
          connection = ActiveRecord::Base.connection();        
          results = connection.execute(sql)
          # trying to get link to participant to show up in one update of enumber
          if !@vgroup.participant_id.blank?
            sql = "update enrollments set participant_id = "+@vgroup.participant_id.to_s+" where participant_id is null and enrollments.id ="+e[0].to_s
            results = connection.execute(sql)                    
          end
        end 
        if v_do_not_share_scans_flag == "Y"
             @vgroup.do_not_share_scans = "DO NOT SHARE"
        else
             @vgroup.do_not_share_scans = ""
        end
        #### REPEAT FOR SP  

        sql = "Delete from scan_procedures_vgroups where vgroup_id ="+@vgroup.id.to_s
        connection = ActiveRecord::Base.connection();        
        results = connection.execute(sql)
        sql = "select distinct scan_procedure_id from scan_procedures_visits where visit_id in (select visits.id from visits, appointments where appointments.id = visits.appointment_id and appointments.vgroup_id ="+@vgroup.id.to_s+")"
        connection = ActiveRecord::Base.connection();        
        results = connection.execute(sql)
        results.each do |sp|           
          sql = "Insert into scan_procedures_vgroups(vgroup_id,scan_procedure_id) values("+@vgroup.id.to_s+","+sp[0].to_s+")"
          connection = ActiveRecord::Base.connection();        
          results = connection.execute(sql)        
        end   

        @vgroup.save
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
        end  
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
  #similar to function in vgroups controller
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
    end
          # participant_id was blank, now, if not blank, update enrollments where participant_id is null
      if !participant_id.blank? 
         sql = "UPDATE enrollments set enrollments.participant_id = "+participant_id.to_s+" WHERE enrollments.participant_id is NULL AND
                          enrollments.id 
                            IN (select  enrollment_visit_memberships.enrollment_id  FROM enrollment_visit_memberships
                                WHERE enrollment_visit_memberships.visit_id = "+params[:id]+ " )"

                           
          connection = ActiveRecord::Base.connection();
          results = connection.execute(sql) 
          if blank_participant_id == "Y"
            enroll.each do |e|
               if !e.participant_id.blank?
                   var = var # not do anything
               else
                      sql = "UPDATE enrollments set enrollments.participant_id = "+participant_id.to_s+" WHERE enrollments.participant_id is NULL AND
                                       enrollments.id = "+e.id.to_s
                       connection = ActiveRecord::Base.connection();
                       results = connection.execute(sql)
               end
            end
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
#1
  end  
  

  # DELETE /visits/1
  # DELETE /visits/1.xml
  def destroy
     @user = current_user
  # not sure why :edit_low_scan_procedure_array is getting lost, could because permissions on user and ability
  # can also get edit_low_scan_procedure_array from user, but its got spaces 
   #  scan_procedure_array =@user[:edit_low_scan_procedure_array]
    scan_procedure_array =(@user.edit_low_scan_procedure_array).split(' ').map(&:to_i) 
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
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
      format.html { redirect_to(mri_search_path) }
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

          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
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
                            and round((DATEDIFF(visits.date,participants.dob)/365.25),2) >= ?   )",params[:visit_search][:min_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:visit_search][:min_age]
        elsif params[:visit_search][:min_age].blank? && !params[:visit_search][:max_age].blank?
             @search = @search.where("  visits.id in (select enrollment_visit_memberships.visit_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits,visits
                             where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                         and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id 
                         and visits.id = enrollment_visit_memberships.visit_id
                         and round((DATEDIFF(visits.date,participants.dob)/365.25),2) <= ?   )",params[:visit_search][:max_age])
            params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:visit_search][:max_age]
        elsif !params[:visit_search][:min_age].blank? && !params[:visit_search][:max_age].blank?
           @search = @search.where("  visits.id in (select enrollment_visit_memberships.visit_id from participants,  enrollment_visit_memberships, enrollments, scan_procedures_visits,visits
                           where enrollment_visit_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                       and  scan_procedures_visits.visit_id = enrollment_visit_memberships.visit_id 
                       and visits.id = enrollment_visit_memberships.visit_id
                       and round((DATEDIFF(visits.date,participants.dob)/365.25),2) between ? and ?   )",params[:visit_search][:min_age],params[:visit_search][:max_age])
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

limit_visits =  [:user_id ,:initials,:transfer_mri,:transfer_pet,:conference,:id,
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

  def mri_search
      # make @conditions from search form input, access control in application controller run_search

          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
      @conditions = []
      @current_tab = "visit_search"
      params["search_criteria"] =""

      if params[:mri_search].nil?
           params[:mri_search] =Hash.new
           params[:mri_search][:mri_status] = "yes"  
      end

      if !params[:mri_search][:scan_procedure_id].blank?
         condition =" visits.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                and scan_procedure_id in ("+params[:mri_search][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+"))"
         @conditions.push(condition)
         @scan_procedures = ScanProcedure.where("id in (?)",params[:mri_search][:scan_procedure_id])
         params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end
      
      if !params[:mri_search][:series_description].blank?
         var = "%"+params[:mri_search][:series_description].downcase+"%"
         condition ="  visits.id in (select image_datasets.visit_id from image_datasets
          where lower(image_datasets.series_description) like '"+var.gsub(/[;:'"()=<>]/, '')+"' )"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +", Series description "+params[:mri_search][:series_description]
      end      

      if !params[:mri_search][:enumber].blank?
        if params[:mri_search][:enumber].include?(',') # string of enumbers
         v_enumber =  params[:mri_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
         v_enumber = v_enumber.gsub(/,/,"','")
          condition =" visits.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
             where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
             and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"'))"         
        else
         condition =" visits.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
          where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
          and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:mri_search][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"
        end
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:mri_search][:enumber]
      end      

      if !params[:mri_search][:rmr].blank? 
          condition =" visits.appointment_id in (select appointments.id from appointments,vgroups
                    where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower('"+params[:mri_search][:rmr].gsub(/[;:'"()=<>]/, '')+"')   ))"
          @conditions.push(condition)           
          params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:mri_search][:rmr]
      end   

      if !params[:mri_search][:mri_status].blank? 
          condition =" visits.appointment_id in (select appointments.id from appointments,vgroups
                              where appointments.vgroup_id = vgroups.id and  lower(vgroups.transfer_mri) in (lower('"+params[:mri_search][:mri_status].gsub(/[;:'"()=<>]/, '')+"')   ))"
          @conditions.push(condition)
          params["search_criteria"] = params["search_criteria"] +",  Mri status "+params[:mri_search][:mri_status]
      end
      #  build expected date format --- between, >, < 
      v_date_latest =""
      #want all three date parts
      if !params[:mri_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:mri_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:mri_search]["#{'latest_timestamp'}(3i)"].blank?
           v_date_latest = params[:mri_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:mri_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:mri_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
      end
      v_date_earliest =""
      #want all three date parts
      if !params[:mri_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:mri_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:mri_search]["#{'earliest_timestamp'}(3i)"].blank?
            v_date_earliest = params[:mri_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:mri_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:mri_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
       end
      v_date_latest = v_date_latest.gsub(/[;:'"()=<>]/, '')
      v_date_earliest = v_date_earliest.gsub(/[;:'"()=<>]/, '')
      if v_date_latest.length>0 && v_date_earliest.length >0
        condition ="  visits.appointment_id in (select appointments.id from appointments where appointments.appointment_date between '"+v_date_earliest+"' and '"+v_date_latest+"' )"
        @conditions.push(condition)
        params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
      elsif v_date_latest.length>0
        condition ="  visits.appointment_id in (select appointments.id from appointments where appointments.appointment_date < '"+v_date_latest+"'  )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
      elsif  v_date_earliest.length >0
        condition ="  visits.appointment_id in (select appointments.id from appointments where appointments.appointment_date > '"+v_date_earliest+"' )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
       end

       if !params[:mri_search][:gender].blank?
          condition ="  visits.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
           where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
           and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                  and participants.gender is not NULL and participants.gender in ("+params[:mri_search][:gender].gsub(/[;:'"()=<>]/, '')+") )"
           @conditions.push(condition)
           if params[:mri_search][:gender] == 1
              params["search_criteria"] = params["search_criteria"] +",  sex is Male"
           elsif params[:mri_search][:gender] == 2
              params["search_criteria"] = params["search_criteria"] +",  sex is Female"
           end
       end   

       if !params[:mri_search][:min_age].blank? && params[:mri_search][:max_age].blank?
           condition ="   visits.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                              where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                           and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                           and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                           and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) >= "+params[:mri_search][:min_age].gsub(/[;:'"()=<>]/, '')+"   )"
            @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:mri_search][:min_age]
       elsif params[:mri_search][:min_age].blank? && !params[:mri_search][:max_age].blank?
            condition ="   visits.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                            and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                        and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) <= "+params[:mri_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
           @conditions.push(condition)
           params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:mri_search][:max_age]
       elsif !params[:mri_search][:min_age].blank? && !params[:mri_search][:max_age].blank?
          condition ="    visits.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                             where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                          and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                          and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                      and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) between "+params[:mri_search][:min_age].gsub(/[;:'"()=<>]/, '')+" and "+params[:mri_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
         @conditions.push(condition)
         params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:mri_search][:min_age]+" and "+params[:mri_search][:max_age]
       end
       # trim leading ","
       params["search_criteria"] = params["search_criteria"].sub(", ","")
       v_include_radiology_comments = "0"
       if !params[:mri_search][:include_radiology_comment].try(:length).nil?   
         v_include_radiology_comments = params[:mri_search][:include_radiology_comment]
       end
       @html_request ="Y"
       # adjust columns and fields for html vs xls, adjust for radiology comments
      request_format = request.formats.to_s
      if v_include_radiology_comments == "1"
          case  request_format
            when "[text/html]","text/html" then
              @column_headers = ['Date','Protocol','Enumber','RMR','Scan','Path',  'Radiology Comments','Rad Site','Appt Note'] # need to look up values
              # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
              @column_number =   @column_headers.size
              @fields =["visits.scan_number","visits.path","concat(radiology_comments.comment_html_1,radiology_comments.comment_html_2,radiology_comments.comment_html_3,radiology_comments.comment_html_4,radiology_comments.comment_html_5)",
                                   "radiology_comments.rad_path","visits.id"] # vgroups.id vgroup_id always first, include table name
            else
              @html_request ="N"
              @column_headers = ['Date','Protocol','Enumber','RMR','Scan','Path',  'Radiology Comments','Rad Site','Appt Note'] # need to look up values
              # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
              @column_number =   @column_headers.size
              @fields =["visits.scan_number","visits.path","concat(radiology_comments.comment_text_1,radiology_comments.comment_text_2,radiology_comments.comment_text_3,radiology_comments.comment_text_4,radiology_comments.comment_text_5)",
                       "radiology_comments.rad_path","visits.id"] # vgroups.id vgroup_id always first, include table name
            end
         @tables =['visits'] # trigger joins --- vgroups and appointments by default
         @left_join = ["LEFT JOIN radiology_comments on visits.id = radiology_comments.visit_id" ] # left join needs to be in sql right after the parent table!!!!!!!
         @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]     
      else
         # adjust columns and fields for html vs xls, adjust for radiology comments
         case  request_format
           when "[text/html]","text/html" then
             @column_headers = ['Date','Protocol','Enumber','RMR','Scan','Path','Mri status','Radiology Outcome','Notes','Appt Note'] # need to look up values
             # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
             @column_number =   @column_headers.size
             @fields =["visits.scan_number","visits.path","vgroups.transfer_mri","visits.radiology_outcome","visits.notes","visits.id"] # vgroups.id vgroup_id always first, include table name
             @left_join = [ ] # left join needs to be in sql right after the parent table!!!!!!!
           else
             @html_request ="N"
             @column_headers = ['Date','Protocol','Enumber','RMR','Scan','Path',  'Completed Fast','Fast hrs','Fast min','MRI start Hour', 'MRI start Minute','MRI end Hour', 'MRI end Minute','Mri status','Radiology Outcome','Notes','BP Systol','BP Diastol','Pulse','Blood Glucose','Age at Appt','Appt Note'] # need to look up values
             # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
             @column_number =   @column_headers.size
             @fields =["visits.scan_number","visits.path","CASE visits.completedmrifast WHEN 1 THEN 'Yes' ELSE 'No' end",
               "visits.mrifasttotaltime","visits.mrifasttotaltime_min","visits.mristarttime_hour","visits.mristarttime_minute","visits.mriendtime_hour","visits.mriendtime_minute","vgroups.transfer_mri","radiology_outcome","visits.notes","vitals.bp_systol","vitals.bp_diastol","vitals.pulse","vitals.bloodglucose","appointments.age_at_appointment","visits.id"] # vgroups.id vgroup_id always first, include table name
             @left_join = ["LEFT JOIN vitals on visits.appointment_id = vitals.appointment_id" ] # left join needs to be in sql right after the parent table!!!!!!!
           end
        @tables =['visits'] # trigger joins --- vgroups and appointments by default  
        @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]
      end

      @results = self.run_search   # in the application controller
      @results_total = @results  # pageination makes result count wrong
      t = Time.now 
      @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")

      ### LOOK WHERE TITLE IS SHOWING UP
      @collection_title = 'All Mri appts'

      respond_to do |format|
        format.xls # mri_search.xls.erb
        format.xml  { render :xml => @visits }       
        format.html {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)} # mri_search.html.erb
      end
    end


  
  private
  
  def set_current_tab
    @current_tab = "visits"
  end
  
end
