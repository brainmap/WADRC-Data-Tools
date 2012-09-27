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
  connection = ActiveRecord::Base.connection();
  @left_join_vgroup =[]
  if @tables.size == 1  
      # get distinct sp

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
       sql = "select distinct scan_procedure_id from scan_procedures_vgroups where scan_procedures_vgroups.vgroup_id in 
           ( select t1.vgroup_id from ("+sql+") t1 )"

       # get distinct question_id  -- q_form_id
       @results = connection.execute(sql)
       @scanprocedures =ScanProcedure.where("scan_procedures.id in (?)",@results)
       
       @questionform_questions = QuestionformQuestion.where("question_id in  (select questions.id from questions where 
                                       ((value_type_1 != 'text' and value_type_1 != '') or (value_type_2 != 'text' and value_type_2 != '') or (value_type_3 != 'text' and value_type_3 != '')) )
                                                          and question_id not in (select question_id from question_scan_procedures)
                                                                 or (question_id in 
                                                                         (select question_id from question_scan_procedures where  include_exclude ='include' and scan_procedure_id in (?))
                                                                      and
                                                                   question_id not in 
                                              (select question_id from question_scan_procedures where include_exclude ='exclude' and scan_procedure_id in (?)))",
                                                         @scanprocedures,@scanprocedures).where(" questionform_id = ?",@q_form_id.to_s).sort_by(&:display_order)

        # have questionform_questions.question_id and questionform_questions.display_order
        # get the *.id off last field, add back,, same with last header = appt note
        v_last_field =@fields.pop
        v_last_header = @column_headers.pop
        @questionform_questions.each do |q|
          @question = Question.find(q.question_id)
          if @question.value_type_1 != '' and @question.value_type_1 != 'text' and  @question.value_type_2 != '' and @question.value_type_2 != 'text' and  @question.value_type_3 != '' and @question.value_type_3 != 'text'
              @column_headers.push(@question.export_column_header_1)
              @column_headers.push(@question.export_column_header_2)
              @column_headers.push(@question.export_column_header_3)
               col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
               @fields.push(col_1)
               # outer join to table.appointment_id  vs vgroups.participant_id
               if @question.value_link == "appointment"
                   if @question.ref_table_a_1 == "LOOKUP_REFS"
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                       " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_1 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_1+"' where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                   elsif @question.ref_table_a_1 != ""
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                          " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                   else
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                   end
                   @left_join.push(left_join) 
               elsif      @question.value_link == "participant"
                        if @question.ref_table_a_1 == "LOOKUP_REFS"
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                            " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_1 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_1+"' where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                        elsif @question.ref_table_a_1 != ""
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                               " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                        else
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                        end
                        @left_join_vgroup.push(left_join)
                end
          
                col_2 = "b_alias_"+@question.id.to_s+".b_"+@question.id.to_s
                @fields.push(col_2)
                # outer join to table.appointment_id  vs vgroups.participant_id
                if @question.value_link == "appointment"
                    if @question.ref_table_a_2 == "LOOKUP_REFS"
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                        " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_2 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_2+"' where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                    elsif @question.ref_table_a_2 != ""
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description a_"+@question.id.to_s+
                           " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                    else
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                    end
                    @left_join.push(left_join) 
                elsif      @question.value_link == "participant"
                         if @question.ref_table_a_2 == "LOOKUP_REFS"
                             left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                             " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_2 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_2+"' where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                         elsif @question.ref_table_a_2 != ""
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description a_"+@question.id.to_s+
                                " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                         else
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                         end
                         @left_join_vgroup.push(left_join)
                 end
                  
                 
                  col_3 = "c_alias_"+@question.id.to_s+".c_"+@question.id.to_s
                  @fields.push(col_3)
                  # outer join to table.appointment_id  vs vgroups.participant_id
                  if @question.value_link == "appointment"
                      if @question.ref_table_a_3 == "LOOKUP_REFS"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description c_"+@question.id.to_s+
                          " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_3 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_3+"' where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_3 != ""
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join.push(left_join) 
                  elsif      @question.value_link == "participant"
                           if @question.ref_table_a_3 == "LOOKUP_REFS"
                               left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description c_"+@question.id.to_s+
                               " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_3 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_3+"' where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                           elsif @question.ref_table_a_3 != ""
                              left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                                  " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                           else
                              left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                           end
                           @left_join_vgroup.push(left_join)
                   end
              
          elsif @question.value_type_1 != '' and @question.value_type_1 != 'text' and  @question.value_type_2 != '' and @question.value_type_2 != 'text'
            @column_headers.push(@question.export_column_header_1)
            @column_headers.push(@question.export_column_header_2)
             col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
             @fields.push(col_1)
             # outer join to table.appointment_id  vs vgroups.participant_id
             if @question.value_link == "appointment"
                 if @question.ref_table_a_1 == "LOOKUP_REFS"
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                     " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_1 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_1+"' where q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                 elsif @question.ref_table_a_1 != ""
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                        " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                 else
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                 end
                 @left_join.push(left_join) 
             elsif      @question.value_link == "participant"
                      if @question.ref_table_a_1 == "LOOKUP_REFS"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                          " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_1 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_1+"' where q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_1 != ""
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join_vgroup.push(left_join)
              end
         
              col_2 = "b_alias_"+@question.id.to_s+".b_"+@question.id.to_s
              @fields.push(col_2)
              # outer join to table.appointment_id  vs vgroups.participant_id
              if @question.value_link == "appointment"
                  if @question.ref_table_a_2 == "LOOKUP_REFS"
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description b_"+@question.id.to_s+
                      " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_2 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_2+"' where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                  elsif @question.ref_table_a_2 != ""
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                         " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                  else
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                  end
                  @left_join.push(left_join) 
              elsif      @question.value_link == "participant"
                       if @question.ref_table_a_2 == "LOOKUP_REFS"
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description b_"+@question.id.to_s+
                           " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_2 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_2+"' where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                       elsif @question.ref_table_a_2 != ""
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                              " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                       else
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                       end
                       @left_join_vgroup.push(left_join)
               end
                   
          elsif @question.value_type_2 != '' and @question.value_type_2 != 'text' and  @question.value_type_3 != '' and @question.value_type_3 != 'text'
            @column_headers.push(@question.export_column_header_2)
            @column_headers.push(@question.export_column_header_3)
            col_2 = "b_alias_"+@question.id.to_s+".b_"+@question.id.to_s
            @fields.push(col_2)
            # outer join to table.appointment_id  vs vgroups.participant_id
            if @question.value_link == "appointment"
                if @question.ref_table_a_2 == "LOOKUP_REFS"
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description b_"+@question.id.to_s+
                    " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_2 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_2+"' where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                elsif @question.ref_table_a_2 != ""
                   left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                       " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                else
                   left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                end
                @left_join.push(left_join) 
            elsif      @question.value_link == "participant"
                     if @question.ref_table_a_2 == "LOOKUP_REFS"
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description b_"+@question.id.to_s+
                         " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_2 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_2+"' where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                     elsif @question.ref_table_a_2 != ""
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                            " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                     else
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                     end
                     @left_join_vgroup.push(left_join)
             end       
               
              
               col_3 = "c_alias_"+@question.id.to_s+".c_"+@question.id.to_s
               @fields.push(col_3)
               # outer join to table.appointment_id  vs vgroups.participant_id
               if @question.value_link == "appointment"
                   if @question.ref_table_a_3 == "LOOKUP_REFS"
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description c_"+@question.id.to_s+
                       " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_3 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_3+"' where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                   elsif @question.ref_table_a_3 != ""
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                          " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                   else
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                   end
                   @left_join.push(left_join) 
               elsif      @question.value_link == "participant"
                        if @question.ref_table_a_3 == "LOOKUP_REFS"
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description c_"+@question.id.to_s+
                            " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_3 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_3+"' where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                        elsif @question.ref_table_a_3 != ""
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                               " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                        else
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                        end
                        @left_join_vgroup.push(left_join)
                end   
                    
          elsif @question.value_type_1 != '' and @question.value_type_1 != 'text' and  @question.value_type_3 != '' and @question.value_type_3 != 'text'
            @column_headers.push(@question.export_column_header_1)
            @column_headers.push(@question.export_column_header_3)
             col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
             @fields.push(col_1)
             # outer join to table.appointment_id  vs vgroups.participant_id
             if @question.value_link == "appointment"
                 if @question.ref_table_a_1 == "LOOKUP_REFS"
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                     " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_1 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_1+"' where q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                 elsif @question.ref_table_a_1 != ""
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                        " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                 else
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                 end
                 @left_join.push(left_join) 
             elsif      @question.value_link == "participant"
                      if @question.ref_table_a_1 == "LOOKUP_REFS"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                          " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_1 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_1+"' where q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_1 != ""
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join_vgroup.push(left_join)
              end
              
               col_3 = "c_alias_"+@question.id.to_s+".c_"+@question.id.to_s
               @fields.push(col_3)
               # outer join to table.appointment_id  vs vgroups.participant_id
               if @question.value_link == "appointment"
                   if @question.ref_table_a_3 == "LOOKUP_REFS"
                       left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description c_"+@question.id.to_s+
                       " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_3 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_3+"' where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                   elsif @question.ref_table_a_3 != ""
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                          " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                   else
                      left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                   end
                   @left_join.push(left_join) 
               elsif      @question.value_link == "participant"
                        if @question.ref_table_a_3 == "LOOKUP_REFS"
                            left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description c_"+@question.id.to_s+
                            " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_3 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_3+"' where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                        elsif @question.ref_table_a_3 != ""
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                               " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                        else
                           left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                        end
                        @left_join_vgroup.push(left_join)
                end
                      
          elsif @question.value_type_1 != '' and @question.value_type_1 != 'text' 
             @column_headers.push(@question.export_column_header_1)
             col_1 = "a_alias_"+@question.id.to_s+".a_"+@question.id.to_s
             @fields.push(col_1)
             # outer join to table.appointment_id  vs vgroups.participant_id
             if @question.value_link == "appointment"
                 if @question.ref_table_a_1 == "LOOKUP_REFS"
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                     " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_1 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_1+"' where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                 elsif @question.ref_table_a_1 != ""
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                        " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                 else
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on blooddraws.appointment_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                 end
                 @left_join.push(left_join) 
             elsif      @question.value_link == "participant"
                      if @question.ref_table_a_1 == "LOOKUP_REFS"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description a_"+@question.id.to_s+
                          " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_1 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_1+"' where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_1 != ""
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_1.pluralize.underscore+".description a_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_1.pluralize.underscore+" where q_data.value_1 = "+@question.ref_table_a_1.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_1 a_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) a_alias_"+@question.id.to_s+" on vgroups.participant_id = a_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join_vgroup.push(left_join)
              end
          elsif @question.value_type_2 != '' and @question.value_type_2 != 'text' 
            @column_headers.push(@question.export_column_header_2)
            col_2 = "b_alias_"+@question.id.to_s+".b_"+@question.id.to_s
            @fields.push(col_2)
            # outer join to table.appointment_id  vs vgroups.participant_id
            if @question.value_link == "appointment"
                if @question.ref_table_a_2 == "LOOKUP_REFS"
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description b_"+@question.id.to_s+
                    " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_2 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_2+"' where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                elsif @question.ref_table_a_2 != ""
                   left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                       " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                else
                   left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on blooddraws.appointment_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                end
                @left_join.push(left_join) 
            elsif      @question.value_link == "participant"
                     if @question.ref_table_a_2 == "LOOKUP_REFS"
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description b_"+@question.id.to_s+
                         " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_2 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_2+"' where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                     elsif @question.ref_table_a_2 != ""
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_2.pluralize.underscore+".description b_"+@question.id.to_s+
                            " from q_data , "+@question.ref_table_a_2.pluralize.underscore+" where q_data.value_2 = "+@question.ref_table_a_2.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                     else
                        left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_2 b_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) b_alias_"+@question.id.to_s+" on vgroups.participant_id = b_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                     end
                     @left_join_vgroup.push(left_join)
             end        
          elsif  @question.value_type_3 != '' and @question.value_type_3 != 'text'
            @column_headers.push(@question.export_column_header_3)
             col_3 = "c_alias_"+@question.id.to_s+".c_"+@question.id.to_s
             @fields.push(col_3)
             # outer join to table.appointment_id  vs vgroups.participant_id
             if @question.value_link == "appointment"
                 if @question.ref_table_a_3 == "LOOKUP_REFS"
                     left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description c_"+@question.id.to_s+
                     " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_3 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_3+"' where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                 elsif @question.ref_table_a_3 != ""
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                        " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                 else
                    left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on blooddraws.appointment_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                 end
                 @left_join.push(left_join) 
             elsif      @question.value_link == "participant"
                      if @question.ref_table_a_3 == "LOOKUP_REFS"
                          left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", LOOKUP_REFS.description c_"+@question.id.to_s+
                          " from q_data LEFT JOIN LOOKUP_REFS on q_data.value_3 = LOOKUP_REFS.ref_value and LOOKUP_REFS.label ='"+@question.ref_table_b_3+"' where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s                 
                      elsif @question.ref_table_a_3 != ""
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", "+@question.ref_table_a_3.pluralize.underscore+".description c_"+@question.id.to_s+
                             " from q_data , "+@question.ref_table_a_3.pluralize.underscore+" where q_data.value_3 = "+@question.ref_table_a_3.pluralize.underscore+".id and q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s
                      else
                         left_join = "LEFT JOIN (select q_data.value_link id_"+@question.id.to_s+", q_data.value_3 c_"+@question.id.to_s+" from q_data where q_data.question_id ="+q.question_id.to_s+" ) c_alias_"+@question.id.to_s+" on vgroups.participant_id = c_alias_"+@question.id.to_s+".id_"+@question.id.to_s 
                      end
                      @left_join_vgroup.push(left_join)
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
        @fields.push(v_last_field)
        @column_headers.push(v_last_header)

       sql ="SELECT distinct vgroups.id vgroup_id,appointments.appointment_date,  vgroups.rmr , "+@fields.join(',')+",appointments.comment 
        FROM vgroups "+@left_join_vgroup.join(' ')+", appointments,scan_procedures, scan_procedures_vgroups, "+@tables.join(',')+" "+@left_join.join(' ')+"
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
#puts "AAAAAAAAAAAA"+sql
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
