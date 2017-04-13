# encoding: utf-8
class EmployeesController < ApplicationController   
  before_action :set_employee, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  # GET /employees
  # GET /employees.xml
  def index
    @employees = Employee.all.sort_by(&:last_name)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @employees }
    end
  end

  # GET /employees/1
  # GET /employees/1.xml
  def show
    @employee = Employee.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @employee }
    end
  end

  # GET /employees/new
  # GET /employees/new.xml
  def new
    @employee = Employee.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @employee }
    end
  end

  # GET /employees/1/edit
  def edit
    @employee = Employee.find(params[:id])
  end

  # POST /employees
  # POST /employees.xml
  def create
    @employee = Employee.new(employee_params)#params[:employee])
    @employee.description = @employee.last_name+", "+@employee.first_name+" "+@employee.mi
    respond_to do |format|
      if @employee.save
        format.html { redirect_to(@employee, :notice => 'Employee was successfully created.') }
        format.xml  { render :xml => @employee, :status => :created, :location => @employee }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /employees/1
  # PUT /employees/1.xml
  def update
    @employee = Employee.find(params[:id])

    respond_to do |format|
      if @employee.update(employee_params)#params[:employee], :without_protection => true)
        @employee.description = @employee.last_name+", "+@employee.first_name+" "+@employee.mi
        @employee.save
        format.html { redirect_to(@employee, :notice => 'Employee was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /employees/1
  # DELETE /employees/1.xml
  def destroy
    @employee = Employee.find(params[:id])
    @employee.destroy

    respond_to do |format|
      format.html { redirect_to(employees_url) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_employee
       @employee = Employee.find(params[:id])
    end
   def employee_params
          params.require(:employee).permit(:description,:user_id,:lookup_status_id,:initials,:status,:last_name,:mi,:first_name,:id)
   end
end
