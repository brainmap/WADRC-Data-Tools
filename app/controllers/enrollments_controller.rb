class EnrollmentsController < ApplicationController
  
  before_filter :set_current_tab
  
  def set_current_tab
    @current_tab = "enrollments"
  end
  
  # GET /enrollments
  # GET /enrollments.xml
  def index
       scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ')
    # Hack for Autocomplete Enrollment Number AJAX Search
    if params[:search].kind_of? String
      search_hash = {:enumber_contains => params[:search]}
    else
      search_hash = params[:search]
    end
    @search = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).search(search_hash).relation.page(params[:page])
    @enrollments = @search
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @enrollments }
      format.js { render :action => 'index.js.erb'}
    end
  end

  # GET /enrollments/1
  # GET /enrollments/1.xml
  def show
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ')
    @enrollment = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])

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
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ')
    @enrollment = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])
    
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
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ')
    @enrollment = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])

    respond_to do |format|
      if @enrollment.update_attributes(params[:enrollment])
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
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ')
    @enrollment = Enrollment.where(" enrollments.id in (select enrollment_visit_memberships.enrollment_id from enrollment_visit_memberships where enrollment_visit_memberships.visit_id in
     (select visit_id from scan_procedures_visits where scan_procedure_id in (?))) ", scan_procedure_array).find(params[:id])
    @enrollment.destroy

    respond_to do |format|
      format.html { redirect_to(enrollments_url) }
      format.xml  { head :ok }
    end
  end
end
