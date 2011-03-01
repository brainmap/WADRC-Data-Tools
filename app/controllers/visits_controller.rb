class VisitsController < ApplicationController
  
  PER_PAGE = 50
  
  before_filter :set_current_tab
    
  # GET /visits
  # GET /visits.xml  
  def index
    # @visits = Visit.search(params[:search]).paginate(:page => params[:page], :per_page => PER_PAGE)
    @visits = Visit.all
    @collection_title = 'All visits'
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @visits }
    end
  end

  # GET /visits/:scope
  def index_by_scope
    @visits = Visit.send(params[:scope]).paginate(:page => params[:page], :per_page => PER_PAGE)
    @collection_title = "All #{params[:scope].to_s.gsub('_',' ')} visits"
    render :template => "visits/index"
  end
  
  def assigned_to_who
    redirect_to assigned_to_path( :user_login => params[:user][:login] )
  end
  
  # GET /visits/assigned_to/:user_login
  def index_by_user_id
    @visits = Visit.assigned_to(
      User.find_by_login(params[:user_login]).id
    ).paginate(:page => params[:page], :per_page => PER_PAGE)
    
    @collection_title = "All visits assigned to #{params[:user_login]}"
    
    render :template => "visits/index"
  end
  
  def in_scan_procedure
    redirect_to in_scan_procedure_path( :scan_procedure_id => params[:scan_procedure][:id] )
  end

  def index_by_scan_procedure
    sp = ScanProcedure.find_by_id(params[:scan_procedure_id])
    @visits = Visit.in_scan_procedure(sp).paginate(:page => params[:page], :per_page => PER_PAGE)
    
    @collection_title = "All visits enrolled in #{ScanProcedure.find_by_id(params[:scan_procedure_id]).codename}"
    
    render :template => "visits/index"
  end
  
  # GET /visits/by_month
  def by_month
    @visits = Visit.all
    @title = "Visits by month"
    @collection_title = "Visits by month"
    @total_count = @visits.size
    
    render :template => "visits/index_by_month"
  end
  
  # GET /visits/found
  def found
    @visits = Visit.find_by_search_params(params['visit_search']).paginate(:page => params[:page], :per_page => PER_PAGE)
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
  end

  # GET /visits/1
  # GET /visits/1.xml
  def show
    @visit = Visit.find_by_id(params[:id])
    @visits = Visit.find(:all, :conditions => { :date => @visit.date-1.month..@visit.date+1.month } )
    idx = @visits.index(@visit)
    @older_visit = idx + 1 >= @visits.size ? nil : @visits[idx + 1]
    @newer_visit = idx - 1 < 0 ? nil : @visits[idx - 1]
   
    @image_datasets = @visit.image_datasets# .paginate(:page => params[:page], :per_page => PER_PAGE)
    @participant = @visit.try(:enrollment).try(:participant) 
    @enumber = @visit.try(:enrollment).try(:enumber)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @visit }
    end
  end

  # GET /visits/new
  # GET /visits/new.xml
  def new
    @visit = Visit.new
    @visit.enrollment = Enrollment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @visit }
    end
  end

  # GET /visits/1/edit
  def edit
    @visit = Visit.find(params[:id])
    @visit.enrollment = Enrollment.new if @visit.enrollment.blank?
  end

  # POST /visits
  # POST /visits.xml
  def create
    @visit = Visit.new(params[:visit])
    @visit.enrollment = Enrollment.find_or_create_by_enumber(params[:visit][:enrollment_attributes][:enumber])

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
    @visit = Visit.find(params[:id])
    enrollment = Enrollment.find_or_create_by_enumber(params[:visit][:enrollment_attributes][:enumber])
    visit_attributes = params[:visit]
    visit_attributes[:enrollment_id] = enrollment.id
    visit_attributes[:enrollment_attributes] = enrollment.attributes
    logger.info visit_attributes


    respond_to do |format|
      if @visit.update_attributes(visit_attributes)
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
    @visit = Visit.find(params[:id])
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
      VisitMailer.deliver_visit_confirmation(@visit, params[:email])
      flash[:notice] = "Email was succesfully sent."
    rescue LoadError => load_error
      logger.info load_error
      flash[:error] = "Sorry, your email was not delivered: " + load_error.to_s
    end
    redirect_to @visit
  end
  
  private
  
  def set_current_tab
    @current_tab = "visits"
  end
  
end
