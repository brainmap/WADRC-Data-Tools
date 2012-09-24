class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery

#   include AuthenticatedSystem
   # need to skip if json and search and path_contains -- set a userid
   before_filter :authenticate_user! 

 
# respond_to do |format|
#   format.html  before_filter :authenticate_user!
#    format.xml  {      }
# end
 
# rescue_from CanCan::AccessDenied do |exception|
#   flash[:error] = exception.message
#   redirect_to root_url
# end 
  # deny_access unless signed_in? or format is "xml" 
  # list_visits from metamri doesn't have validation 
  # how can limit what the xml format can do? 

  # adding unless right after login_required
 # before_filter :username_required unless super params[:format] == 'xml' #, :only => [:edit, :update, :new, :create ]
####   before_filter :username_required #, :only => [:edit, :update, :new, :create ]  
  #before_filter { |c| User.current_user = c.current_user }
  
  # without super getting error frm params
  # super has to be callled from in a procedure -- 

# place where lumbarpuncture, blooddraw, visits, and other controllers can get at
def run_search
  scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
  if @tables.size == 1  
       sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date,  vgroups.rmr , "+@fields.join(',')+",appointments.comment 
        FROM vgroups, appointments,scan_procedures, scan_procedures_vgroups, "+@tables.join(',')+" "+@left_join.join(' ')+"
        WHERE vgroups.id = appointments.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "
        @tables.each do |tab|
          sql = sql +" AND "+tab+".appointment_id = appointments.id  "
        end
        sql = sql +" AND scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
        AND scan_procedures_vgroups.vgroup_id = vgroups.id "

        if @conditions.size > 0
            sql = sql +" AND "+@conditions.join(' and ')
        end
       #conditions - feed thru ActiveRecord? stop sql injection -- replace : ; " ' ( ) = < > - others?
        if @order_by.size > 0
          sql = sql +" ORDER BY "+@order_by.join(',')
        end 
    end

puts sql    
    connection = ActiveRecord::Base.connection();
    @results2 = connection.execute(sql)
    @temp_results = @results2

    @results = []   
    i =0
    @temp_results.each do |var|
      @temp = []
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
          
      else  # need to only get the sp and enums which are displayed - and need object to make link
        @temp[1] = var[0].to_s
        @temp[2] = var[0].to_s
      end 
      var.delete_at(0) # get rid of vgroup_id
      var.delete_at(0) # get rid of extra copy of appt date
      
      @temp_row = @temp + var
      @results[i] = @temp_row
      i = i+1
    end   
    return @results
 end
 
# for q_data forms -- only run in export?
def run_search_q_data
  scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
  if @tables.size == 1  
       sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date,  vgroups.rmr , "+@fields.join(',')+",appointments.comment 
        FROM vgroups, appointments,scan_procedures, scan_procedures_vgroups, "+@tables.join(',')+" "+@left_join.join(' ')+"
        WHERE vgroups.id = appointments.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "
        @tables.each do |tab|
          sql = sql +" AND "+tab+".appointment_id = appointments.id  "
        end
        sql = sql +" AND scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
        AND scan_procedures_vgroups.vgroup_id = vgroups.id "

        if @conditions.size > 0
            sql = sql +" AND "+@conditions.join(' and ')
        end
       #conditions - feed thru ActiveRecord? stop sql injection -- replace : ; " ' ( ) = < > - others?
        if @order_by.size > 0
          sql = sql +" ORDER BY "+@order_by.join(',')
        end 
    end

puts sql    
    connection = ActiveRecord::Base.connection();
    @results2 = connection.execute(sql)
    @temp_results = @results2

    @results = []   
    i =0
    @temp_results.each do |var|
      @temp = []
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
          
      else  # need to only get the sp and enums which are displayed - and need object to make link
        @temp[1] = var[0].to_s
        @temp[2] = var[0].to_s
      end 
      var.delete_at(0) # get rid of vgroup_id
      var.delete_at(0) # get rid of extra copy of appt date
      
      @temp_row = @temp + var
      @results[i] = @temp_row
      i = i+1
    end   
    return @results
 end
 
end
