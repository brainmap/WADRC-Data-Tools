class EnrollmentsController < ApplicationController
  
  PER_PAGE = 50
  
  before_filter :set_current_tab
  
  def set_current_tab
    @current_tab = "enrollments"
  end
  
  # GET /enrollments
  # GET /enrollments.xml
  def index
    @enrollments = Enrollment.all.paginate(:page => params[:page], :per_page => PER_PAGE)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @enrollments }
    end
  end

  # GET /enrollments/1
  # GET /enrollments/1.xml
  def show
    @enrollment = Enrollment.find(params[:id])

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
    @enrollment = Enrollment.find(params[:id])
    
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
    @enrollment = Enrollment.find(params[:id])

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
    @enrollment = Enrollment.find(params[:id])
    @enrollment.destroy

    respond_to do |format|
      format.html { redirect_to(enrollments_url) }
      format.xml  { head :ok }
    end
  end
end
