# encoding: utf-8
class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery

#   include AuthenticatedSystem
   # need to skip if json and search and path_contains -- set a userid
   # deprecated before_filter :authenticate_user! 
   before_action :authenticate_user! 
 
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
  #puts "DDDDD"
  #    puts "FFFFFF"+current_user.view_low_scan_procedure_array
  # puts "EEEEEEE"
  
  scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
  if @tables.size == 1  or @tables.include?("image_datasets")
       sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date,  vgroups.rmr , "+@fields.join(',')+",appointments.comment 
        FROM vgroups, appointments,scan_procedures, scan_procedures_vgroups, "+@tables.join(',')+" "+@left_join.join(' ')+"
        WHERE vgroups.id = appointments.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "
        @tables.each do |tab|
          if tab == "image_datasets"
            sql = sql +" AND "+tab+".visit_id = visits.id  "
          else
            sql = sql +" AND "+tab+".appointment_id = appointments.id  "
          end
        end
        sql = sql +" AND scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
        AND scan_procedures_vgroups.vgroup_id = vgroups.id "

        if @conditions.size > 0
            sql = sql +" AND "+@conditions.join(' and ')
        end
        if !@group_by.nil? and @group_by.size > 0
             sql = sql +@group_by
        end
       #conditions - feed thru ActiveRecord? stop sql injection -- replace : ; " ' ( ) = < > - others?
        if @order_by.size > 0
          sql = sql +" ORDER BY "+@order_by.join(',')
        end 
   end

puts "aaa run_search="+sql    
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

         t_appt_comment = var.last
         var.pop
         t_appt_id = var.last
         var.pop
         var.push(t_appt_comment)
         var.push(t_appt_id)
       # seems to want comment , id, and some other field 
         var.push(t_appt_comment)
          
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
  @v_petfile_cnt.to_s
    return @results
 end
# place where lumbarpuncture, blooddraw, visits, and other controllers can get at
def run_search_ids 
  #puts "DDDDD"
  #    puts "FFFFFF"+current_user.view_low_scan_procedure_array
  # puts "EEEEEEE"
  
  scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
  if @tables.size == 1  or @tables.include?("image_datasets")
       sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date,  vgroups.rmr , "+@fields.join(',')+",appointments.comment 
        FROM vgroups, appointments,scan_procedures, scan_procedures_vgroups, "+@tables.join(',')+" "+@left_join.join(' ')+"
        WHERE vgroups.id = appointments.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "
        @tables.each do |tab|
          if tab == "image_datasets"
            sql = sql +" AND "+tab+".visit_id = visits.id  "
          else
            sql = sql +" AND "+tab+".appointment_id = appointments.id  "
          end
        end
        sql = sql +" AND scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
        AND scan_procedures_vgroups.vgroup_id = vgroups.id "

        if @conditions.size > 0
            sql = sql +" AND "+@conditions.join(' and ')
        end
        if !@group_by.nil? and @group_by.size > 0
             sql = sql +@group_by
        end
       #conditions - feed thru ActiveRecord? stop sql injection -- replace : ; " ' ( ) = < > - others?
        if @order_by.size > 0
          sql = sql +" ORDER BY "+@order_by.join(',')
        end 
   end

puts "aaa run_search="+sql    
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

        
         t_appt_mri_comment = var.last

        # var.pop
        # t_appt_id = var.last
        # var.pop
        # var.push(t_appt_comment)
        # var.push(t_appt_id)
       # seems to want comment , id, and some other field 
       #  var.push(t_appt_comment)
          
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
  @v_petfile_cnt.to_s
    return @results
 end


def run_search_pet  # need to add the petfiles - file_name, path and note
  scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')    
  if @tables.size == 1  or @tables.include?("image_datasets")
    # moved ,appointments.comment  to be in field list
       sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date,  vgroups.rmr , "+@fields.join(',')+" 
        FROM vgroups, appointments,scan_procedures, scan_procedures_vgroups, "+@tables.join(',')+" "+@left_join.join(' ')+"
        WHERE vgroups.id = appointments.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "
        @tables.each do |tab|
          if tab == "image_datasets"
            sql = sql +" AND "+tab+".visit_id = visits.id  "
          else
            sql = sql +" AND "+tab+".appointment_id = appointments.id  "
          end
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

      
      #moving petscan_id to front
      v_length = var.length
      v_petscan_id = var[v_length-2]
      if @html_request =="Y"
          @temp.unshift(v_petscan_id)
      end
      var.delete_at(v_length-2)
      #if @html_request =="N"
         #var.delete_at(0) # seems to need to delete another blank field?
      #end
      v_petfiles = Petfile.where("petscan_id in (?)", v_petscan_id)
      v_petfiles.each do |pf|
         var.push(pf.file_name)
         var.push(pf.path)
         var.push(pf.note)
      end 
      
      @temp_row = @temp + var  

      @results[i] = @temp_row
      i = i+1
    end   
  @v_petfile_cnt.to_s
    return @results
 end
 def run_search_participant
  scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
  if @tables.size == 1  or @tables.include?("image_datasets")
     sql = "SELECT distinct participants.id,"+@fields.join(',')+"
            FROM "+@tables.join(',')+" "+@left_join.join(' ')+"
            WHERE participants.id in (select vgroups.participant_id from vgroups, scan_procedures_vgroups where 
                     vgroups.id = scan_procedures_vgroups.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") ) "


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
          sql_enum = "SELECT distinct enrollments.enumber 
                FROM enrollments, enrollment_vgroup_memberships
                WHERE enrollments.participant_id = "+var[0].to_s
          @results_enum = connection.execute(sql_enum)
          @temp[0] =@results_enum.to_a.join(", ")

      var.delete_at(0) # get rid of participant_id
       @temp_row  = var.push(@temp[0])
      @results[i] = @temp_row
      i = i+1
    end   
    return @results
 end

  def run_search_enrollment # copied from run_search_participant
  scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
  if @tables.size == 1  or @tables.include?("image_datasets")
     sql = "SELECT distinct enrollments.id,"+@fields.join(',')+"
            FROM "+@tables.join(',')+" "+@left_join.join(' ')+"
            WHERE enrollments.id in (select enrollment_vgroup_memberships.enrollment_id from vgroups, scan_procedures_vgroups, enrollment_vgroup_memberships  where 
                    enrollment_vgroup_memberships.vgroup_id = vgroups.id
                    and  vgroups.id = scan_procedures_vgroups.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") ) "


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
      var.delete_at(0) # get rid of enrollment_id
       @temp_row  = var
      @results[i] = @temp_row
      i = i+1
    end   
    return @results
 end
 
# for q_data forms -- only run in export?
def run_search_q_data ( tables,fields,p_left_join,p_left_join_vgroup,*p_raw_data)

  v_raw_data = "N"
  if !p_raw_data.nil? and !p_raw_data.blank? and !p_raw_data[0].nil? and !p_raw_data[0].blank?
     v_raw_data = p_raw_data[0]
  end

  scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
  connection = ActiveRecord::Base.connection();
  @left_join_vgroup_q_data =[]  # used when participant is data_link
  left_join_vgroup = []
  @column_headers_q_data = []
  @fields_q_data = []
  @left_join_q_data = []
  @column_headers_q_data = []
  
  if tables.size == 1  
     v_table_base_appt = tables[0]
      # get distinct sp
      if !fields.blank?
        sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date,  vgroups.rmr , "+fields.join(',')  +" ,appointments.comment "
      else  # calll from cg_search doesn't have fields
          sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date,  vgroups.rmr  ,appointments.comment "
      end
       sql =sql+" FROM vgroups, appointments,scan_procedures, scan_procedures_vgroups, "+tables.join(',')+" "+p_left_join.join(' ')+"
       WHERE vgroups.id = appointments.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "
       tables.each do |tab|
         sql = sql +" AND "+tab+".appointment_id = appointments.id  "
       end
       sql = sql +" AND scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
       AND scan_procedures_vgroups.vgroup_id = vgroups.id "

       if @conditions.size > 0
           sql = sql +" AND "+@conditions.join(' and ')
       end

       sql_sp = "select distinct scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id in 
           ( select t1.vgroup_id from ("+sql+") t1 )"

       # get distinct question_id  -- q_form_id
       @results = connection.execute(sql_sp)
       if @results.size == 0
          @results = ['-1']
       end
       #POSSIBLE TUNING!!!!!!!!!!!!
       # could get appointment list, simplify the left join sql by getting rid of all tables/joins which don't have fields
       # remove left_join and conditions
       sql_apptid = "select distinct appointments.id from appointments where appointments.vgroup_id in 
           ( select t1.vgroup_id from ("+sql+") t1 )"       
       
       @questionform_questions = QuestionformQuestion.where("question_id in  (select questions.id from questions where 
                                       ((value_type_1 != 'text' and value_type_1 != '') or (value_type_2 != 'text' and value_type_2 != '') or (value_type_3 != 'text' and value_type_3 != '')) )
                                                          and question_id not in (select question_id from question_scan_procedures)
                                                                 or (question_id in 
                                                                         (select question_id from question_scan_procedures where  include_exclude ='include' and scan_procedure_id in ("+@results.to_a.join(',')+"))
                                                                      and
                                                                   question_id not in 
                                              (select question_id from question_scan_procedures where include_exclude ='exclude' and scan_procedure_id in ("+@results.to_a.join(',')+")))"
                                              ).where(" questionform_id = ?",@q_form_id.to_s).sort_by(&:display_order)

        # have questionform_questions.question_id and questionform_questions.display_order
        # get the *.id off last field, add back,, same with last header = appt note
        if !fields.blank? # cg_search blank fields and column header
          v_last_field =fields.pop
        end
        if !@column_headers.blank?
          v_last_header = @column_headers.pop
        end 

        @questionform_questions.each do |q|
          @question = Question.find(q.question_id)
  
          if @question.value_type_1 != '' and @question.value_type_1 != 'text' and  @question.value_type_2 != '' and @question.value_type_2 != 'text' and  @question.value_type_3 != '' and @question.value_type_3 != 'text'          
              @column_headers_q_data.push(@question.export_column_header_1)
              @column_headers_q_data.push(@question.export_column_header_2)
              @column_headers_q_data.push(@question.export_column_header_3)

               # outer join to table.appointment_id  vs vgroups.participant_id
               if @question.value_link == "appointment" and @question.ref_table_a_1 == "" and @question.ref_table_a_2 == "" and @question.ref_table_a_3 == ""
                 col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
                 @fields_q_data.push(col_1)
                 col_2 = "a_alias_"+@question.id.to_s+".b_"+@question.id.to_s
                 @fields_q_data.push(col_2)
                 col_3 = "a_alias_"+@question.id.to_s+".c_"+@question.id.to_s
                 @fields_q_data.push(col_3)
                 left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" 
                 from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                 @left_join_q_data.push(left_join)

               elsif @question.value_link == "participant" and @question.ref_table_a_1 == "" and @question.ref_table_a_2 == "" and @question.ref_table_a_3 == ""
                 col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
                  @fields_q_data.push(col_1)
                  col_2 = "a_alias_"+@question.id.to_s+".b_"+@question.id.to_s
                  @fields_q_data.push(col_2)
                  col_3 = "a_alias_"+@question.id.to_s+".c_"+@question.id.to_s
                  @fields_q_data.push(col_3)
                  left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" 
                  from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                  @left_join_vgroup_q_data.push(left_join)
                  
               else
                 col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
                 @fields_q_data.push(col_1)
                 col_2 = "b_alias_"+@question.id.to_s+".b_"+@question.id.to_s
                 @fields_q_data.push(col_2)
                 col_3 = "c_alias_"+@question.id.to_s+".c_"+@question.id.to_s
                 @fields_q_data.push(col_3)
                 if @question.value_link == "appointment"
                   if @question.ref_table_a_1 == "lookup_refs" and v_raw_data != "Y"
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description a_"+@question.id.to_s+
                       " from q_data,lookup_refs where q_data.value_1 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_1+"' and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                   elsif @question.ref_table_a_1 != "" and v_raw_data != "Y"
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                          " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                   else
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                   end
                   @left_join_q_data.push(left_join)

                 elsif      @question.value_link == "participant"
                        if @question.ref_table_a_1 == "lookup_refs" and v_raw_data != "Y"
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description a_"+@question.id.to_s+
                            " from q_data, lookup_refs where q_data.value_1 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_1+"' and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                        elsif @question.ref_table_a_1 != "" and v_raw_data != "Y"
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                               " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                        else
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                        end
                        @left_join_vgroup_q_data.push(left_join)   
                  end
          
                # outer join to table.appointment_id  vs vgroups.participant_id
                 if @question.value_link == "appointment"
                    if @question.ref_table_a_2 == "lookup_refs" and v_raw_data != "Y"
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description b_"+@question.id.to_s+
                        " from q_data , lookup_refs where q_data.value_2 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_2+"' and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                    elsif @question.ref_table_a_2 != "" and v_raw_data != "Y"
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                           " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                    else
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                    end
                    @left_join_q_data.push(left_join)

                  elsif      @question.value_link == "participant"
                         if @question.ref_table_a_2 == "lookup_refs" and v_raw_data != "Y"
                             left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description b_"+@question.id.to_s+
                             " from q_data, lookup_refs where q_data.value_2 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_2+"' and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                         elsif @question.ref_table_a_2 != "" and v_raw_data != "Y"
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                                " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                         else
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                         end
                         @left_join_vgroup_q_data.push(left_join) 
                   end
                  
                  # outer join to table.appointment_id  vs vgroups.participant_id
                    if @question.value_link == "appointment"
                      if @question.ref_table_a_3 == "lookup_refs" and v_raw_data != "Y"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description c_"+@question.id.to_s+
                          " from q_data, lookup_refs where q_data.value_3 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_3+"' and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_3 != "" and v_raw_data != "Y"
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join_q_data.push(left_join)
                      
                    elsif      @question.value_link == "participant"
                           if @question.ref_table_a_3 == "lookup_refs" and v_raw_data != "Y"
                               left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description c_"+@question.id.to_s+
                               " from q_data, lookup_refs where q_data.value_3 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_3+"' and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                           elsif @question.ref_table_a_3 != "" and v_raw_data != "Y"
                              left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                                  " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                           else
                              left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                           end
                           @left_join_vgroup_q_data.push(left_join)
                           
                     end
                  end
              
          elsif @question.value_type_1 != '' and @question.value_type_1 != 'text' and  @question.value_type_2 != ''  and @question.value_type_2 != 'text'    
            @column_headers_q_data.push(@question.export_column_header_1)
            @column_headers_q_data.push(@question.export_column_header_2)
            # outer join to table.appointment_id  vs vgroups.participant_id
            if @question.value_link == "appointment" and @question.ref_table_a_1 == "" and @question.ref_table_a_2 == "" 
              col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
              @fields_q_data.push(col_1)
              col_2 = "a_alias_"+@question.id.to_s+".b_"+@question.id.to_s
              @fields_q_data.push(col_2)
              left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" 
              from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
              @left_join_q_data.push(left_join)
              
            elsif @question.value_link == "participant" and @question.ref_table_a_1 == "" and @question.ref_table_a_2 == "" 
              col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
               @fields_q_data.push(col_1)
               col_2 = "a_alias_"+@question.id.to_s+".b_"+@question.id.to_s
               @fields_q_data.push(col_2)
               left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" 
               from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
               @left_join_vgroup_q_data.push(left_join)
               
            else
             col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
             @fields_q_data.push(col_1)
             # outer join to table.appointment_id  vs vgroups.participant_id
             if @question.value_link == "appointment"
                 if @question.ref_table_a_1 == "lookup_refs" and v_raw_data != "Y"
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description a_"+@question.id.to_s+
                     " from q_data, lookup_refs where q_data.value_1 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_1+"' and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                 elsif @question.ref_table_a_1 != "" and v_raw_data != "Y"
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                        " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                 else
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                 end
                 @left_join_q_data.push(left_join)
                  
             elsif      @question.value_link == "participant"
                      if @question.ref_table_a_1 == "lookup_refs" and v_raw_data != "Y"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description a_"+@question.id.to_s+
                          " from q_data, lookup_refs where q_data.value_1 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_1+"' and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_1 != "" and v_raw_data != "Y"
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join_vgroup_q_data.push(left_join)    
              end
         
              col_2 = "b_alias_"+@question.id.to_s+".b_"+@question.id.to_s
              @fields_q_data.push(col_2)
              # outer join to table.appointment_id  vs vgroups.participant_id
              if @question.value_link == "appointment"
                  if @question.ref_table_a_2 == "lookup_refs" and v_raw_data != "Y"
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description b_"+@question.id.to_s+
                      " from q_data, lookup_refs where q_data.value_2 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_2+"' and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                  elsif @question.ref_table_a_2 != "" and v_raw_data != "Y"
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                         " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                  else
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                  end
                  @left_join_q_data.push(left_join) 
                  
              elsif      @question.value_link == "participant"
                       if @question.ref_table_a_2 == "lookup_refs" and v_raw_data != "Y"
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description b_"+@question.id.to_s+
                           " from q_data, lookup_refs where q_data.value_2 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_2+"' and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                       elsif @question.ref_table_a_2 != "" and v_raw_data != "Y"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                              " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                       else
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                       end
                       @left_join_vgroup_q_data.push(left_join)
                       
               end
              end     
          elsif @question.value_type_2 != '' and @question.value_type_2 != 'text' and  @question.value_type_3 != '' and @question.value_type_3 != 'text'
            @column_headers_q_data.push(@question.export_column_header_2)
            @column_headers_q_data.push(@question.export_column_header_3)
            # outer join to table.appointment_id  vs vgroups.participant_id
            if @question.value_link == "appointment" and  @question.ref_table_a_2 == "" and @question.ref_table_a_3 == ""
              col_2 = "a_alias_"+@question.id.to_s+".b_"+@question.id.to_s
              @fields_q_data.push(col_2)
              col_3 = "a_alias_"+@question.id.to_s+".c_"+@question.id.to_s
              @fields_q_data.push(col_3)
              left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+",  q_data.value_2 b_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" 
              from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
              @left_join_q_data.push(left_join)
              
            elsif @question.value_link == "participant" and  @question.ref_table_a_2 == "" and @question.ref_table_a_3 == ""
               col_2 = "a_alias_"+@question.id.to_s+".b_"+@question.id.to_s
               @fields_q_data.push(col_2)
               col_3 = "a_alias_"+@question.id.to_s+".c_"+@question.id.to_s
               @fields_q_data.push(col_3)
               left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" 
               from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
               @left_join_vgroup_q_data.push(left_join)
               
            else
            col_2 = "b_alias_"+@question.id.to_s+".b_"+@question.id.to_s
            @fields_q_data.push(col_2)
            # outer join to table.appointment_id  vs vgroups.participant_id
            if @question.value_link == "appointment"
                if @question.ref_table_a_2 == "lookup_refs" and v_raw_data != "Y"
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description b_"+@question.id.to_s+
                    " from q_data, lookup_refs where q_data.value_2 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_2+"' and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                elsif @question.ref_table_a_2 != "" and v_raw_data != "Y"
                   left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                       " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                else
                   left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                end
                @left_join_q_data.push(left_join) 
                
            elsif      @question.value_link == "participant"
                     if @question.ref_table_a_2 == "lookup_refs" and v_raw_data != "Y"
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description b_"+@question.id.to_s+
                         " from q_data, lookup_refs where q_data.value_2 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_2+"' and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                     elsif @question.ref_table_a_2 != "" and v_raw_data != "Y"
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                            " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                     else
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                     end
                     @left_join_vgroup_q_data.push(left_join)
                     
             end       
               
               col_3 = "c_alias_"+@question.id.to_s+".c_"+@question.id.to_s
               @fields_q_data.push(col_3)
               # outer join to table.appointment_id  vs vgroups.participant_id
               if @question.value_link == "appointment"
                   if @question.ref_table_a_3 == "lookup_refs" and v_raw_data != "Y"
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description c_"+@question.id.to_s+
                       " from q_data, lookup_refs where q_data.value_3 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_3+"' and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                   elsif @question.ref_table_a_3 != "" and v_raw_data != "Y"
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                          " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                   else
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                   end
                   @left_join_q_data.push(left_join)
                    
               elsif      @question.value_link == "participant"
                        if @question.ref_table_a_3 == "lookup_refs" and v_raw_data != "Y"
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description c_"+@question.id.to_s+
                            " from q_data, lookup_refs where q_data.value_3 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_3+"' and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                        elsif @question.ref_table_a_3 != "" and v_raw_data != "Y"
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                               " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                        else
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                        end
                        @left_join_vgroup_q_data.push(left_join)
                        
                end   
              end      
          elsif @question.value_type_1 != '' and @question.value_type_1 != 'text' and  @question.value_type_3 != '' and @question.value_type_3 != 'text'
            @column_headers_q_data.push(@question.export_column_header_1)
            @column_headers_q_data.push(@question.export_column_header_3)
            # outer join to table.appointment_id  vs vgroups.participant_id
            if @question.value_link == "appointment" and @question.ref_table_a_1 == ""  and @question.ref_table_a_3 == ""
              col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
              @fields_q_data.push(col_1)
              col_3 = "a_alias_"+@question.id.to_s+".c_"+@question.id.to_s
              @fields_q_data.push(col_3)
              left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+",  q_data.value_3 c_"+@question.id.to_s+" 
              from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
              @left_join_q_data.push(left_join)

            elsif @question.value_link == "participant" and @question.ref_table_a_1 == "" and @question.ref_table_a_3 == ""
              col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
               @fields_q_data.push(col_1)
               col_3 = "a_alias_"+@question.id.to_s+".c_"+@question.id.to_s
               @fields_q_data.push(col_3)
               left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+",  q_data.value_3 c_"+@question.id.to_s+" 
               from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
               @left_join_vgroup_q_data.push(left_join)
                
            else
             col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
             @fields_q_data.push(col_1)
             # outer join to table.appointment_id  vs vgroups.participant_id
             if @question.value_link == "appointment"
                 if @question.ref_table_a_1 == "lookup_refs" and v_raw_data != "Y"
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description a_"+@question.id.to_s+
                     " from q_data, lookup_refs where q_data.value_1 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_1+"' and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                 elsif @question.ref_table_a_1 != "" and v_raw_data != "Y"
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                        " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                 else
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                 end
                 @left_join_q_data.push(left_join)
                 
             elsif      @question.value_link == "participant"
                      if @question.ref_table_a_1 == "lookup_refs" and v_raw_data != "Y"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description a_"+@question.id.to_s+
                          " from q_data, lookup_refs where q_data.value_1 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_1+"' and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_1 != "" and v_raw_data != "Y"
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join_vgroup_q_data.push(left_join)  
              end
              
               col_3 = "c_alias_"+@question.id.to_s+".c_"+@question.id.to_s
               @fields_q_data.push(col_3)
               # outer join to table.appointment_id  vs vgroups.participant_id
               if @question.value_link == "appointment"
                   if @question.ref_table_a_3 == "lookup_refs" and v_raw_data != "Y"
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description c_"+@question.id.to_s+
                       " from q_data, lookup_refs where q_data.value_3 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_3+"' and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                   elsif @question.ref_table_a_3 != "" and v_raw_data != "Y"
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                          " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                   else
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                   end
                   @left_join_q_data.push(left_join)
                    
               elsif      @question.value_link == "participant"
                        if @question.ref_table_a_3 == "lookup_refs" and v_raw_data != "Y"
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description c_"+@question.id.to_s+
                            " from q_data, lookup_refs where q_data.value_3 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_3+"' and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                        elsif @question.ref_table_a_3 != "" and v_raw_data != "Y"
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                               " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                        else
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                        end
                        @left_join_vgroup_q_data.push(left_join)
                        
                end
              end        
          elsif @question.value_type_1 != '' and @question.value_type_1 != 'text' 

             @column_headers_q_data.push(@question.export_column_header_1)
             col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
             @fields_q_data.push(col_1)
             # outer join to table.appointment_id  vs vgroups.participant_id
             if @question.value_link == "appointment"
                 if @question.ref_table_a_1 == "lookup_refs" and v_raw_data != "Y"
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description a_"+@question.id.to_s+
                     " from q_data, lookup_refs where q_data.value_1 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_1+"' and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                 elsif @question.ref_table_a_1 != "" and v_raw_data != "Y"
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                        " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                 else
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                 end
                 @left_join_q_data.push(left_join) 
                 
             elsif      @question.value_link == "participant"
                      if @question.ref_table_a_1 == "lookup_refs" and v_raw_data != "Y"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description a_"+@question.id.to_s+
                          " from q_data, lookup_refs where q_data.value_1 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_1+"' and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_1 != "" and v_raw_data != "Y"
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join_vgroup_q_data.push(left_join)
                      
              end
          elsif @question.value_type_2 != '' and @question.value_type_2 != 'text' 
            @column_headers_q_data.push(@question.export_column_header_2)
            col_2 = "b_alias_"+@question.id.to_s+".b_"+@question.id.to_s
            @fields_q_data.push(col_2)
            # outer join to table.appointment_id  vs vgroups.participant_id
            if @question.value_link == "appointment"
                if @question.ref_table_a_2 == "lookup_refs" and v_raw_data != "Y"
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description b_"+@question.id.to_s+
                    " from q_data, lookup_refs where q_data.value_2 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_2+"' and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                elsif @question.ref_table_a_2 != "" and v_raw_data != "Y"
                   left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                       " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                else
                   left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                end
                @left_join_q_data.push(left_join)
                 
            elsif      @question.value_link == "participant"
                     if @question.ref_table_a_2 == "lookup_refs" and v_raw_data != "Y"
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description b_"+@question.id.to_s+
                         " from q_data, lookup_refs where q_data.value_2 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_2+"' and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                     elsif @question.ref_table_a_2 != "" and v_raw_data != "Y"
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                            " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                     else
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                     end
                     @left_join_vgroup_q_data.push(left_join)
                     
             end        
          elsif  @question.value_type_3 != '' and @question.value_type_3 != 'text'
            @column_headers_q_data.push(@question.export_column_header_3)
             col_3 = "c_alias_"+@question.id.to_s+".c_"+@question.id.to_s
             @fields_q_data.push(col_3)
             # outer join to table.appointment_id  vs vgroups.participant_id
             if @question.value_link == "appointment"
                 if @question.ref_table_a_3 == "lookup_refs" and v_raw_data != "Y"
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description c_"+@question.id.to_s+
                     " from q_data, lookup_refs where q_data.value_3 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_3+"' and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                 elsif @question.ref_table_a_3 != "" and v_raw_data != "Y"
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                        " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                 else
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on "+v_table_base_appt+".appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                 end
                 @left_join_q_data.push(left_join)
                  
             elsif      @question.value_link == "participant"
                      if @question.ref_table_a_3 == "lookup_refs" and v_raw_data != "Y"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", lookup_refs.description c_"+@question.id.to_s+
                          " from q_data, lookup_refs where q_data.value_3 = lookup_refs.ref_value and lookup_refs.label ='"+@question.ref_table_b_3+"' and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_3 != "" and v_raw_data != "Y"
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join_vgroup_q_data.push(left_join)   
              end             
          end
          # check value_type_1, value_type_2, value_type_3 != '', != 'text', not null
          # get value_link
          # get export_column_header_1, export_column_header_2, export_column_header_3 -- add to @column_headers.push() 
          # select q_data.value_1 a+@question.id, q_data.value_2 b+@question.id, q_data.value_3 b+@question.id, q_data.value_link from q_data where question_id = @question.id.to_s
          # need to look at ref_table_a_1, ref_table_b_1, ref_table_a_2, ref_table_b_2, ref_table_a_3, ref_table_b_3 -- do lookup
          # -- (select ...) alias_+@question.id  -- add to tables
          # add to conditions? where  q_data.value_link = ( appt or participant based on questions.value_link = appointment or participant-- drive by appointment_id )
          
          # make different sql for when value_type_1, value_type_2, value_type_3 are = text or ''
          
        end
        @results_q_data =[]
        v_limit =  10  # like the chunk approach issue with multiple appts in a vgroup and multiple enrollments
        # when increased, get repeat rows
        @column_headers.push(*@column_headers_q_data)

        if @fields_q_data.size < v_limit # should be less than 61 table limit  # this makes multiple rows
                   fields.push(*@fields_q_data)
                   p_left_join.push(*@left_join_q_data)
                   left_join_vgroup.push(*@left_join_vgroup_q_data)
        else # get data in v_limit sized chunks  # this does weird bleed over of row data if different sp'd have different questions
          @fields_q_data.each_slice(v_limit) do |fields_local|
            @results_q_data_temp = []
            # get all the aliases, find in @left_join_q_data and @left_join_vgroup_q_data
            @left_join_q_data_local = []
            @left_join_vgroup_q_data_local = []
            alias_local =[]
            fields_local.each do |v|
              (a,b) = v.split('.')
              if !alias_local.include?(a)
                 alias_local.push(a)
                 @left_join_q_data.each do |d|
                   if d.include?(a)
                     @left_join_q_data_local.push(d)
                   end
                 end
                 
                 @left_join_vgroup_q_data.each do |d|
                   if d.include?(a)
                    @left_join_vgroup_q_data_local.push(d)
                  end
                 end
              end
            end
             sql ="SELECT distinct appointments.id appointment_id, "+fields_local.join(',')+"
              FROM vgroups "+@left_join_vgroup_q_data_local.join(' ')+", appointments, scan_procedures_vgroups, "+tables.join(',')+" "+@left_join_q_data_local.join(' ')+"
              WHERE vgroups.id = appointments.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "
              tables.each do |tab|
                sql = sql +" AND "+tab+".appointment_id = appointments.id  "
              end
              sql = sql +" AND scan_procedures_vgroups.vgroup_id = vgroups.id "

              if @conditions.size > 0
                  sql = sql +" AND "+@conditions.join(' and ')
              end
              #weird cross row issues when mixing q_data across sp's with different set of questions
              # think the sql is letting values cross sps  -- participant_id is in some questions 
              # linking to vgroups.participant_id, but not getting values link==appt id
          puts "bbbbbbb q_data 858= "+sql
              @results_q_data_temp = []
              @results_q_data_temp = connection.execute(sql)
              # @results_q_data
              # getting duplicate appts??-- multiple enrollments
              last_appointment =-1
              @results_q_data_temp.each do |var|
                appointment_id = var[0]
                var.delete_at(0) # get rid of appointment_id
                if last_appointment != appointment_id
                    last_appointment = appointment_id
                   if !@results_q_data[appointment_id].blank?
                       @results_q_data[appointment_id] = @results_q_data[appointment_id]+var
                   else
                       @results_q_data[appointment_id]  = var
                   end
                end
              end            
          end                    
        end
        # NEED TO RETURN q_data columns-- to cg_search -- rest of processing is used by simple search q_data export 

        if !@cg_search_q_data.blank?
          return fields,tables, p_left_join,@left_join_vgroup_q_data,@fields_q_data, @left_join_q_data,@column_headers_q_data
        end 

        fields.push(v_last_field)
        @column_headers.push(v_last_header)


       sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date, appointments.id, vgroups.rmr , "+fields.join(',')+",appointments.comment 
        FROM vgroups "+left_join_vgroup.to_a.join(' ')+", appointments, 
         scan_procedures_vgroups, "+tables.join(',')+
         " "+p_left_join.to_a.join(' ')+"
        WHERE vgroups.id = appointments.vgroup_id and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "
        tables.each do |tab|
          sql = sql +" AND "+tab+".appointment_id = appointments.id  "
        end
        sql = sql +" AND scan_procedures_vgroups.vgroup_id = vgroups.id "

        if @conditions.size > 0
            sql = sql +" AND "+@conditions.join(' and ')
        end
       #conditions - feed thru ActiveRecord? stop sql injection -- replace : ; " ' ( ) = < > - others?
        if @order_by.size > 0
          sql = sql +" ORDER BY "+@order_by.join(',')
        end 
    end  
    # removed scan_procedures,  ---- AND scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
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
        appointment_id = var[0]
        var.delete_at(0) # get rid of extra copy of appt id
        @temp_row = @temp+var
        # last var field is comment, next last field is id 
        # what if no appointment match and 
        if !@results_q_data[appointment_id].blank? and @html_request =="N"

          t_appt_comment = var.last
          @temp_end = []
          @temp_end.push(t_appt_comment) #var.last)
          var.pop
          var.pop
           # doing some end delete to get rid of id in non-q-data results
           # just adding comment twice so can delete once
           @delete_end = [t_appt_comment]
            @temp_row = []
          @temp_row = @temp+var+@results_q_data[appointment_id].push(t_appt_comment)+@delete_end

        end
      @results[i] = @temp_row
      i = i+1
    end   
    return @results   #,tables,fields, left_join
 end
 

 
end
