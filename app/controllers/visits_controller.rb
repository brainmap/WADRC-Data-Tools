class VisitsController <  AuthorizedController #  ApplicationController
    load_resource
     load_and_authorize_resource  :only => [:show, :edit, :update]  #-- causes problems with the searches, but seems to be needed for the edit, show
    
    
    # to get the ussr scan_procedure array in
    # added in below by find
  
    before_filter :set_current_tab
    
  # GET /visits
  # GET /visits.xml  
  def index
     @var = current_user
    scan_procedure_array =@var.view_low_scan_procedure_array
    # Remove default scope if sorting has been requested.
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Visit.unscoped.search(params[:search]) 
    else
      @search = Visit.search(params[:search]) 
    end
    @visits = @search.relation.where(" visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    @collection_title = 'All visits'
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @visits }
    end
  end

  # GET /visits/:scope
  def index_by_scope
     @var = current_user
    scan_procedure_array =@var.view_low_scan_procedure_array
    @search = Visit.send(params[:scope]).search(params[:search])
    @visits = @search.relation.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    @collection_title = "All #{params[:scope].to_s.gsub('_',' ')} visits"
    render :template => "visits/index"
  end
  
  def assigned_to_who
    redirect_to assigned_to_path( :user_login => params[:user][:username] )
  end
  
  # GET /visits/assigned_to/:user_login
  def index_by_user_id
     @var = current_user
    scan_procedure_array =@var.view_low_scan_procedure_array
    
    @user = User.find(params[:user_login])
    @search = Visit.assigned_to(@user.id).search
    @visits = @search.relation.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    
    @collection_title = "All visits assigned " # to #{params[:user_login]}"
    @visits = nil
    render :template => "visits/index"
  end
  
  def in_scan_procedure
    redirect_to in_scan_procedure_path( :scan_procedure_id => params[:scan_procedure][:id] )
  end

  def index_by_scan_procedure  

     @var = current_user
    scan_procedure_array =@var.view_low_scan_procedure_array
    # sp = ScanProcedure.find_by_id(params[:scan_procedure_id])
    if !params[:search].blank? && !params[:search][:meta_sort].blank?
      @search = Visit.unscoped.includes(:scan_procedures).where(:scan_procedures => {:id => params[:scan_procedure_id]}).search(params[:search])
    else
      @search = Visit.includes(:scan_procedures).where(:scan_procedures => {:id => params[:scan_procedure_id]}).search
    end
    @visits =  @search.relation.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    
    @collection_title = "All visits enrolled in #{ScanProcedure.find_by_id(params[:scan_procedure_id]).codename}"
    
    
    render :template => "visits/index"

  end
  
  # GET /visits/by_month
  def by_month
     @var = current_user
    scan_procedure_array =@var.view_low_scan_procedure_array
    @visits = Visit.relation.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).all
    @title = "Visits by month"
    @collection_title = "Visits by month"
    @total_count = @visits.size
    
    render :template => "visits/index_by_month"
  end
  
  # GET /visits/found
  def found
     @var = current_user
    scan_procedure_array =@var.view_low_scan_procedure_array    
    @visits = Visit.find_by_search_params(params['visit_search']).where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).page(params[:page])
    @collection_title = "Found visits"
    @visit_search = params['visit_search']
    
    if @visits.size == 1
      @visit = @visits.first
      flash[:notice] = "Found 1 visit matching that search."
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
     @var = current_user
    scan_procedure_array =@var.view_low_scan_procedure_array
    @search = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).search(params[:search])
  end

  # GET /visits/1
  # GET /visits/1.xml
  def show
     @var = current_user
    scan_procedure_array =@var.view_low_scan_procedure_array
  
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find_by_id(params[:id])
    # Grab the visits within 1 month +- visit date for "previous" and "back" hack.
    @visits = Visit.where(:date => @visit.date-1.month..@visit.date+1.month).all
    idx = @visits.index(@visit)
    @older_visit = idx + 1 >= @visits.size ? nil : @visits[idx + 1]
    @newer_visit = idx - 1 < 0 ? nil : @visits[idx - 1]
   
    @image_datasets = @visit.image_datasets.page(params[:page])
    @participant = @visit.try(:enrollments).first.try(:participant) 
    @enumbers = @visit.enrollments

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @visit }
    end
  end

  # GET /visits/new
  # GET /visits/new.xml
  def new
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
     @var = current_user
    scan_procedure_array =@var.edit_low_scan_procedure_array    
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @visit.enrollments.build # if @visit.enrollments.blank?
  end

  # POST /visits
  # POST /visits.xml
  def create
    @visit = Visit.new(params[:visit])
    @visit.user = current_user
    respond_to do |format|
      if @visit.save
        flash[:notice] = 'visit was successfully created.'
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
     @var = current_user
    scan_procedure_array =@var.edit_low_scan_procedure_array
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    # HTML Checkbox Hack to remove all if none were checked.
    attributes = {'scan_procedure_ids' => []}.merge(params[:visit] || {})

    respond_to do |format|
      if @visit.update_attributes(attributes)
        flash[:notice] = 'visit was successfully updated.'
        format.html { redirect_to(@visit) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @visit.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /visits/1
  # DELETE /visits/1.xml
  def destroy
     @var = current_user
    scan_procedure_array =@var.edit_low_scan_procedure_array
    @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @visit.destroy

    respond_to do |format|
      format.html { redirect_to(visits_url) }
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
  
  private
  
  def set_current_tab
    @current_tab = "visits"
  end
  
end
