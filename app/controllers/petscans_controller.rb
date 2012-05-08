class PetscansController < ApplicationController
  # GET /petscans
  # GET /petscans.xml
 
  def index
     @current_tab = "petscans"
     scan_procedure_array = []
     scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @petscans = Petscan. where("petscans.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                       appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                       and scan_procedure_id in (?))", scan_procedure_array).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @petscans }
    end
  end

  # GET /petscans/1
  # GET /petscans/1.xml
  def show
    @current_tab = "petscans"
    scan_procedure_array = []
    scan_procedure_array =  (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
     
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

#    @participant = @visit.try(:enrollments).first.try(:participant) 
#    @enumbers = @visit.enrollments
    
    @vgroup = Vgroup.find(@appointment.vgroup_id)
    @participant = @vgroup.try(:participant)
    @enumbers = @vgroup.enrollments
# participant.enrollments.collect {|e| e.enumber}.join(", ").html_safe %>


    

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @petscan }
    end
  end

  # GET /petscans/new
  # GET /petscans/new.xml
  def new
    @petscan = Petscan.new

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
  end

  # POST /petscans
  # POST /petscans.xml
  def create
     @current_tab = "petscans"
    @petscan = Petscan.new(params[:petscan])

    respond_to do |format|
      if @petscan.save
        format.html { redirect_to(@petscan, :notice => 'Petscan was successfully created.') }
        format.xml  { render :xml => @petscan, :status => :created, :location => @petscan }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @petscan.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /petscans/1
  # PUT /petscans/1.xml
  def update
    @petscan = Petscan.find(params[:id])
    appointment_date = nil
    if !params[:appointment]["#{'appointment_date'}(1i)"].blank? && !params[:appointment]["#{'appointment_date'}(2i)"].blank? && !params[:appointment]["#{'appointment_date'}(3i)"].blank?
         appointment_date = params[:appointment]["#{'appointment_date'}(1i)"] +"-"+params[:appointment]["#{'appointment_date'}(2i)"].rjust(2,"0")+"-"+params[:appointment]["#{'appointment_date'}(3i)"].rjust(2,"0")
    end
      params[:date][:injectiont][0]="1899"
      params[:date][:injectiont][1]="12"
      params[:date][:injectiont][2]="30"
      injectiontime = nil
      if !params[:date][:injectiont][0].blank? && !params[:date][:injectiont][1].blank? && !params[:date][:injectiont][2].blank? && !params[:date][:injectiont][3].blank? && !params[:date][:injectiont][4].blank?
        #weird GMT stuff
        diff = (params[:date][:injectiont][3].to_i-6)
        if diff < 0
           diff = diff + 24
        end
        params[:date][:injectiont][3] = diff.to_s
injectiontime =  params[:date][:injectiont][0]+"-"+params[:date][:injectiont][1]+"-"+params[:date][:injectiont][2]+" "+params[:date][:injectiont][3]+":"+params[:date][:injectiont][4]
      params[:petscan][:injecttiontime] = injectiontime
       end

       params[:date][:scanstartt][0]="1899"
       params[:date][:scanstartt][1]="12"
       params[:date][:scanstartt][2]="30"       
        scanstarttime = nil
      if !params[:date][:scanstartt][0].blank? && !params[:date][:scanstartt][1].blank? && !params[:date][:scanstartt][2].blank? && !params[:date][:scanstartt][3].blank? && !params[:date][:scanstartt][4].blank?
        #weird GMT stuff
        diff = (params[:date][:scanstartt][3].to_i-6)
        if diff < 0
           diff = diff + 24
        end
        params[:date][:scanstartt][3] = diff.to_s
  scanstarttime =  params[:date][:scanstartt][0]+"-"+params[:date][:scanstartt][1]+"-"+params[:date][:scanstartt][2]+" "+params[:date][:scanstartt][3]+":"+params[:date][:scanstartt][4]
       params[:petscan][:scanstarttime] = scanstarttime
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
        @appointment.comment = params[:appointment][:comment]
        @appointment.appointment_date =appointment_date
        @appointment.save
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
    @petscan = Petscan.find(params[:id])
    @petscan.destroy

    respond_to do |format|
      format.html { redirect_to(petscans_url) }
      format.xml  { head :ok }
    end
  end
end
