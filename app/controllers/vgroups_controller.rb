class VgroupsController < ApplicationController
  # GET /vgroups
  # GET /vgroups.xml
  def index
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
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

  # GET /vgroups/1
  # GET /vgroups/1.xml
  def show
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
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
              or vgroups.id in (select id from vgroups where rmr in (?))
                              ))", params[:id],params[:id],@vgroup.rmr)
        
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

    # @vgroup.enrollments << Enrollment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vgroup }
    end
  end

  # GET /vgroups/1/edit
  def edit
    scan_procedure_array =current_user.edit_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    
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
    @vgroup = Vgroup.new(params[:vgroup]) 
    respond_to do |format|
      if @vgroup.save
        if !(@vgroup.participant_id).blank?   # how will this interact with load visit? participant_id is probably blank until the enumber update in mri
          sql = "select enrollments.id from enrollments where participant_id ="+@vgroup.participant_id.to_s 
          # this is going to cause problems if there are multiple enrollments for a participant?

          connection = ActiveRecord::Base.connection();        
          participants_results = connection.execute(sql)
          # is there a better way to get the results?
          participants_results.each do |r|
              sql = "select count(*) cnt from enrollment_vgroup_memberships where vgroup_id = "+@vgroup.id.to_s+" and enrollment_id="+(r[0]).to_s
              results = connection.execute(sql)
              cnt = 0
              results.each do |r_cnt|
                cnt = r_cnt[0]
              end
              if cnt < 1
                sql = "insert into enrollment_vgroup_memberships(vgroup_id,enrollment_id) values("+@vgroup.id.to_s+","+(r[0]).to_s+")"      
                results = connection.execute(sql)
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
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    # update attributes not doing updates
    @vgroup.note =params[:vgroup][:note]
    @vgroup.participant_id =params[:vgroup][:participant_id]
    @vgroup.rmr =params[:vgroup][:rmr]
    @vgroup.vgroup_date = params[:vgroup]["#{'vgroup_date'}(1i)"] +"-"+params[:vgroup]["#{'vgroup_date'}(2i)"].rjust(2,"0")+"-"+params[:vgroup]["#{'vgroup_date'}(3i)"].rjust(2,"0")
    
    
    # getting undefined method `to_sym' error -- somethng is nil 
    # just trying to delete 
    params[:vgroup][:enrollments_attributes].each do|cnt, value|
      #enumberpipr00042id2203_destroy1
      enrollment_id = (value.to_s)[(value.to_s).index("id")+2,(value.to_s).index("_destroy")]
      v_destroy = (value.to_s)[(value.to_s).index("_destroy")+8,(value.to_s).length] 
      if v_destroy.to_s == "1"
        enrollment_id = enrollment_id.sub("_destroy1","")
        sql = "delete from enrollment_vgroup_memberships where enrollment_id="+enrollment_id+" and vgroup_id ="+@vgroup.id.to_s
        connection = ActiveRecord::Base.connection();
        results = connection.execute(sql)
      end
    end
    
    params[:vgroup].delete('enrollments_attributes') 
    
    respond_to do |format|
      if @vgroup.update_attributes(params[:vgroup])
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
        format.html { redirect_to(@vgroup) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vgroup.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # GET /vgroups/:scope
  def index_by_scope

    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    @search = Vgroup.send(params[:scope]).search(params[:search])
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
    redirect_to in_scan_procedure_vgroup_path( :scan_procedure_id => params[:scan_procedure][:id] )
  end

  def index_by_scan_procedure  
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Vgroup.unscoped.search(params[:search]) 
    else
      @search = Vgroup.search(params[:search]) 
    end
    if !params[:scan_procedure_id].blank? 
       @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?) and scan_procedure_id in (?))", 
                              scan_procedure_array,params[:scan_procedure_id]).page(params[:page])
    else
      @vgroups = @search.relation.where(" vgroups.id in (select Vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    end
    @collection_title = "All Visits enrolled in #{ScanProcedure.find_by_id(params[:scan_procedure_id]).codename}"
    render :template => "vgroups/home"

  end
  
  
  def visit_search
     render :template => "vgroups/home"
  end
  
  
  def home
    
    scan_procedure_array =current_user.view_low_scan_procedure_array.split(' ') #[:view_low_scan_procedure_array]
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
    @vgroup = Vgroup.where("vgroups.id in (select vgroup_id from scan_procedures_vgroups where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @vgroup.destroy

    respond_to do |format|
      format.html { redirect_to('/vgroups/home') }
      format.xml  { head :ok }
    end
  end
end
