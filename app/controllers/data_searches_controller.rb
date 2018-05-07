# encoding: utf-8
class DataSearchesController < ApplicationController
   # this isn't used - was a test bed for making sql
   require 'cgi'
   require 'csv'

  def index
      # get the tables to join
      # columns and values to add to where
      # columns to return
      # build sql
      # need to get all the enrollments , all the subjectid
# petscan
      @column_headers = ['Protocol','Enumber','RMR','Appt Date','Tracer','Ecatfile','Dose','Injection Time','Scan Start','Note','Range','Pet status','Appt Note'] # need to look up values
      # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
      @column_number =   @column_headers.size
      @fields =["lookup_pettracers.name pettracer","petscans.ecatfilename","petscans.netinjecteddose",
        "time_format(timediff( time(petscans.injecttiontime),subtime(utc_time(),time(localtime()))),'%H:%i')",
        "time_format(timediff( time(scanstarttime),subtime(utc_time(),time(localtime()))),'%H:%i')",
        "petscans.petscan_note","petscans.range","vgroups.transfer_pet","petscans.id"] # vgroups.id vgroup_id always first, include table name
      @tables =['petscans'] # trigger joins --- vgroups and appointments by default
      @left_join = ["LEFT JOIN lookup_pettracers on petscans.lookup_pettracer_id = lookup_pettracers.id",
                  "LEFT JOIN employees on petscans.enteredpetscanwho = employees.id"] # left join needs to be in sql right after the parent table!!!!!!!
      @conditions =["scan_procedures.codename='johnson.predict.visit1'"] # need look up for like, lt, gt, between  
      @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]

# lp   --- NEED lumbarpuncture results
      @column_headers = ['Protocol','Enumber','RMR','Appt Date','LP success','LP abnormality','LP followup','LP MD','Completed Fast','Fast hrs','Fast min','LP status','LP Note','Appt Note'] # need to look up values
      # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
      @column_number =   @column_headers.size
      @fields =["CASE lumbarpunctures.lpsuccess WHEN 1 THEN 'Yes' ELSE 'No' end ","CASE lumbarpunctures.lpabnormality WHEN 1 THEN 'Yes' ELSE 'No' end" ,"lumbarpunctures.lpfollownote",
        "concat(employees.first_name,' ',employees.last_name)",
        "CASE lumbarpunctures.completedlpfast WHEN 1 THEN 'Yes' ELSE 'No' end",
        "lumbarpunctures.lpfasttotaltime","lumbarpunctures.lpfasttotaltime_min","vgroups.completedlumbarpuncture","lumbarpunctures.lumbarpuncture_note","lumbarpunctures.id"] # vgroups.id vgroup_id always first, include table name
      @tables =['lumbarpunctures'] # trigger joins --- vgroups and appointments by default
      @left_join = ["LEFT JOIN employees on lumbarpunctures.lp_exam_md_id = employees.id"] # left join needs to be in sql right after the parent table!!!!!!!
      @conditions =["scan_procedures.codename='johnson.pipr.visit1'"] # need look up for like, lt, gt, between  
      @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]  
 

# mri 
      @column_headers = ['Protocol','Enumber','RMR','Appt Date','Scan','Path',  'Completed Fast','Fast hrs','Fast min','Mri status','Radiology Outcome','Notes','Appt Note'] # need to look up values
      # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
      @column_number =   @column_headers.size
      @fields =["visits.scan_number","visits.path","CASE visits.completedmrifast WHEN 1 THEN 'Yes' ELSE 'No' end",
        "visits.mrifasttotaltime","visits.mrifasttotaltime_min","vgroups.transfer_mri","CASE visits.radiology_outcome WHEN 1 THEN 'Yes' ELSE 'No' end","visits.notes","visits.id"] # vgroups.id vgroup_id always first, include table name
      @tables =['visits'] # trigger joins --- vgroups and appointments by default
      @left_join = [ ] # left join needs to be in sql right after the parent table!!!!!!!
      @conditions =["scan_procedures.codename='johnson.predict.visit1'"] # need look up for like, lt, gt, between  
      @order_by =["appointments.appointment_date DESC", "vgroups.rmr"] 
     
      if @tables.size == 1  
        
        #if @tables[0] == "petscans"
           # need to add in join to lookup_= 
           # or look for field name lookup_? 
  
           sql ="SELECT distinct vgroups.id vgroup_id,  vgroups.rmr,appointments.appointment_date , "+@fields.join(',')+",appointments.comment 
            FROM vgroups, appointments,scan_procedures, scan_procedures_vgroups, "+@tables.join(',')+" "+@left_join.join(' ')+"
            WHERE vgroups.id = appointments.vgroup_id"
            @tables.each do |tab|
              sql = sql +" AND "+tab+".appointment_id = appointments.id  "
            end
            sql = sql +" AND scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
            AND scan_procedures_vgroups.vgroup_id = vgroups.id
            AND "+@conditions.join(' and ')
            
            if @order_by.size > 0
              sql = sql +" ORDER BY "+@order_by.join(',')
            end

           # faster -- but not sure about adding enumber , and the group by , and outer join for chain of joins
            # 2095 msec vs 3193 msec
           sql_groupconcat = "      SELECT vgroups.id vgroup_id, GROUP_CONCAT(scan_procedures.codename), vgroups.rmr,appointments.appointment_date ,"+@fields.join(',') +"
                        FROM vgroups, appointments ,scan_procedures, scan_procedures_vgroups, "+@tables[0]+"  
                           "+@left_join.join(' ')+"  
                        WHERE vgroups.id = appointments.vgroup_id
                        AND appointments.id = petscans.appointment_id
                        AND scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
                        AND scan_procedures_vgroups.vgroup_id = vgroups.id
                        AND "+@conditions.join(' and ')+"
                        group by vgroups.id,  vgroups.rmr,appointments.appointment_date ,"+@fields.join(',')+"
                        ORDER BY appointments.appointment_date"      
        
        end
        connection = ActiveRecord::Base.connection();
        @results2 = connection.execute(sql)
        @temp_results = @results2
      
        @results = []   
        i =0
        @temp_results.each do |var|
          @temp = []
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
          sql_sp = "SELECT distinct scan_procedures.codename 
                    FROM scan_procedures, scan_procedures_vgroups
                    WHERE scan_procedures.id = scan_procedures_vgroups.scan_procedure_id
                    AND scan_procedures_vgroups.vgroup_id = "+var[0].to_s
          @results_sp = connection.execute(sql_sp)
          @temp[0] =@results_sp.to_a.join(", ")
          
          sql_enum = "SELECT distinct enrollments.enumber 
                    FROM enrollments, enrollment_vgroup_memberships
                    WHERE enrollments.id = enrollment_vgroup_memberships.enrollment_id
                    AND enrollment_vgroup_memberships.vgroup_id = "+var[0].to_s
          @results_enum = connection.execute(sql_enum)
          @temp[1] =@results_enum.to_a.join(", ")
          
          var.delete_at(0) # get rid of vgroup_id
          @temp_row = @temp + var
          @results[i] = @temp_row
          i = i+1
        end    
    end
    
    def cg_tables
      scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
      v_user_id = current_user.id.to_s

      @cg_tn_key_y = []
      @cg_tn_key_unique_y = []
      @cg_tns = CgTn.where("table_type='column_group' and status_flag='Y' and table_type in 
        (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in (select protocol_roles.protocol_id from protocol_roles where protocol_roles.user_id in ("+v_user_id+")))").order(:display_order)  
      @cg_fs_tns = CgTn.where("table_type='free_surfer' and status_flag='Y' and table_type in 
        (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in (select protocol_roles.protocol_id from protocol_roles where protocol_roles.user_id in ("+v_user_id+")))").order(:display_order) 
      @cg_tracker_tns = CgTn.where("table_type='tracker' and status_flag='Y' and table_type in 
       (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in (select protocol_roles.protocol_id from protocol_roles where protocol_roles.user_id in ("+v_user_id+")))").order(:display_order) 
      @cg_combio_tns = CgTn.where("table_type='combio' and status_flag='Y' and table_type in 
        (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in (select protocol_roles.protocol_id from protocol_roles where protocol_roles.user_id in ("+v_user_id+")))").order(:display_order)    
      @cg_scan_export_tns = CgTn.where("table_type='scan_export' and status_flag='Y' and table_type in 
        (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in (select protocol_roles.protocol_id from protocol_roles where protocol_roles.user_id in ("+v_user_id+")))").order(:display_order)   
      @cg_up_tns = CgTn.where("table_type='up' and status_flag='Y' and table_type in 
        (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in (select protocol_roles.protocol_id from protocol_roles where protocol_roles.user_id in ("+v_user_id+")))").order(:display_order)  
      @cg_inprocess_tns = CgTn.where("table_type='InProcess' and status_flag='Y' and table_type in 
        (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in (select protocol_roles.protocol_id from protocol_roles where protocol_roles.user_id in ("+v_user_id+")))").order(:display_order)  

        # not rights - protocol_id - but up not have scan_procedure_id - hide scan_procedure_id from most drop downs or get protocol_id ist vs sp_id list 
        #table_type='column_group' and status_flag='Y' and table_type in 
        #(select table_type from cg_table_types where cg_table_types.protocol_id is null 
        #or cg_table_types.protocol_id in (select scan_procedures.protocol_id from scan_procedures where id in ("+scan_procedure_list+")))").order(:display_order) 

       if !params[:archive_up_tables].nil? and params[:archive_up_tables] == "Y"
      @cg_up_archive_tns = CgTn.where("table_type='up_archive' and status_flag='Y' and table_type in 
        (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in (select protocol_roles.protocol_id from protocol_roles where protocol_roles.user_id in ("+v_user_id+")))").order(:display_order) 
       # (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in ("+scan_procedure_list+"))").order(:display_order) 
       end
        # issues where adrc or wai data in up table, but user not in up - cg_table_types.protocol_id needs to be changed to multiple values
   
      # no edit/key things with tracker
      @cg_tns.each do |cg_tn|
          cg_tn_key_array = []
          cg_tn_cns =CgTnCn.where("cg_tn_id in (?)",cg_tn.id)
          cg_tn_cns.each do |cg_tn_cn|
               if cg_tn_cn.key_column_flag == "Y"
                   @cg_tn_key_y[cg_tn.id] = "Y"
                   cg_tn_key_array.push(cg_tn_cn.cn)
               end
          end
          @cg_tn_key_unique_y[cg_tn.id] = "Y"
          if @cg_tn_key_y[cg_tn.id] == "Y"
              sql = "select "+cg_tn_key_array.join(',')+" from "+cg_tn.tn+" group by "+cg_tn_key_array.join(',')+" having count(*) > 1"
              connection = ActiveRecord::Base.connection();
              @results = connection.execute(sql)
              @cg_tn_key_unique_y[cg_tn.id] = "Y"
              @results.each do |r|
                if @cg_tn_key_unique_y[cg_tn.id] == "Y"
                  @cg_tn_key_unique_y[cg_tn.id] = r[0].to_s
                else
                  @cg_tn_key_unique_y[cg_tn.id] = @cg_tn_key_unique_y[cg_tn.id]+", "+r[0].to_s
                end
              end
         end
      end
      #need inprocess
      @cg_inprocess_tns.each do |cg_tn|
          cg_tn_key_array = []
          cg_tn_cns =CgTnCn.where("cg_tn_id in (?)",cg_tn.id)
          cg_tn_cns.each do |cg_tn_cn|
               if cg_tn_cn.key_column_flag == "Y"
                   @cg_tn_key_y[cg_tn.id] = "Y"
                   cg_tn_key_array.push(cg_tn_cn.cn)
               end
          end
          @cg_tn_key_unique_y[cg_tn.id] = "Y"
          if @cg_tn_key_y[cg_tn.id] == "Y"
              sql = "select "+cg_tn_key_array.join(',')+" from "+cg_tn.tn+" group by "+cg_tn_key_array.join(',')+" having count(*) > 1"
              connection = ActiveRecord::Base.connection();
              @results = connection.execute(sql)
              @cg_tn_key_unique_y[cg_tn.id] = "Y"
              @results.each do |r|
                if @cg_tn_key_unique_y[cg_tn.id] == "Y"
                  @cg_tn_key_unique_y[cg_tn.id] = r[0].to_s
                else
                  @cg_tn_key_unique_y[cg_tn.id] = @cg_tn_key_unique_y[cg_tn.id]+", "+r[0].to_s
                end
              end
         end
      end
      respond_to do |format|
          format.html
      end
      
    end
    def cg_edit_dashboard_table
      v_schema ='panda_production'
      if Rails.env=="development" 
        v_schema ='panda_development'
      end
      scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
      # really want to stop edit_table from being used on core tables
      v_exclude_tables_array =['appointments','blooddraws','cg_queries','cg_query_tn_cns','cg_query_tns','cg_tn_cns','cg_tns',
        'cg_tns_users','employees','enrollment_vgroup_memberships','enrollment_visit_memberships','enrollments',
        'image_comments','image_dataset_quality_checks','image_datasets','lumbarpuncture_results','lumbarpunctures','mriperformances','mriscantasks',
        'neuropsyches','participants','petscans','q_data','q_data_forms','question_scan_procedures','questionform_questions','questionform_scan_procedures',
        'questionforms','questionnaires','questions','radiology_comments','roles','scan_procedures','scan_procedures_vgroups','scan_procedures_visits',
        'scheduleruns','schedules','schedules_users','series_descriptions','users','vgroups','visits','vitals'] 
      @cg_tn = CgTn.find(params[:id])
      v_new_key_value =""
      @enumber_search =""
      v_sp =""
      @sp_array =[]
      v_condition =""
      @conditions = []
      params["search_criteria"] =""
      v_key_columns =""
      v_delete_data_row="N"

      
      # build up condition and join from @cg_tn
      if !params[:cg_edit_dashboard_table].blank? and  !params[:cg_edit_dashboard_table][:enumber].blank?
          if params[:cg_edit_dashboard_table][:enumber].include?(',') # string of enumbers
            v_enumber =  params[:cg_edit_dashboard_table][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
             @enumber_search = v_enumber
             v_enumber = v_enumber.gsub(/,/,"','")
            v_condition ="   appointments.id in (select a2.id from enrollment_vgroup_memberships,enrollments, appointments a2
                              where enrollment_vgroup_memberships.vgroup_id= a2.vgroup_id 
                               and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"')) "
          else
             v_enumber = params[:cg_edit_dashboard_table][:enumber].gsub(/[;:'"()=<>]/, '')
             v_condition ="   appointments.id in (select a2.id from enrollment_vgroup_memberships,enrollments, appointments a2
                            where enrollment_vgroup_memberships.vgroup_id= a2.vgroup_id 
                             and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:cg_edit_dashboard_table][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"
          end
          @conditions.push(v_condition)
          params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:cg_edit_dashboard_table][:enumber]
      end

      if !params[:cg_edit_dashboard_table].blank? and !params[:cg_edit_dashboard_table][:scan_procedure_id].blank?
           @sp_array = params[:cg_edit_dashboard_table][:scan_procedure_id]
           v_sp = params[:cg_edit_dashboard_table][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')

           v_condition ="   appointments.id in (select a2.id from appointments a2,scan_procedures_vgroups where 
                                                              a2.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                              and scan_procedure_id in ("+params[:cg_edit_dashboard_table][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+"))"
           @conditions.push(v_condition)
           @scan_procedures = ScanProcedure.where("id in (?)",params[:cg_edit_dashboard_table][:scan_procedure_id])
           params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end
       # non-blank search down by the @v_dashboard_edit_columns

      if (@cg_tn.table_type == 'column_group' or @cg_tn.table_type == 'InProcess'  ) and @cg_tn.secondary_edit_flag == "Y"  and !v_exclude_tables_array.include?(@cg_tn.tn.downcase) # want to limit to cg tables
        @cns = []
        @key_cns = []
        @v_key = []
        @v_dashboard_edit_columns = []
        @cns_type_dict ={}
        @cns_common_name_dict = {}
        @cg_data_dict = {}
        @cg_edit_data_dict = {}
        @ref_table_a_dict ={}
        @ref_table_b_dict ={}
        @value_list_dict ={}
        
        @cg_tn_cns =CgTnCn.where("cg_tn_id in (?) and status_flag='Y'",@cg_tn.id)
        @cg_tn_cns.each do |cg_tn_cn|
  # puts "AAAAAAA cg_tn_cn.cn="+cg_tn_cn.cn
            if !cg_tn_cn.ref_table_a.blank?
              @ref_table_a_dict[cg_tn_cn.cn] = cg_tn_cn.ref_table_a
            end
            if !cg_tn_cn.ref_table_b.blank?
              @ref_table_b_dict[cg_tn_cn.cn] = cg_tn_cn.ref_table_b
            end
            if !cg_tn_cn.value_list.blank?
               @value_list_dict[cg_tn_cn.cn] = cg_tn_cn.value_list
            end             
            @cns.push(cg_tn_cn.cn)
            @cns_common_name_dict[cg_tn_cn.cn] = cg_tn_cn.common_name
            # make so its the first column in display
            if cg_tn_cn.key_column_flag == "Y"
              @key_cns.push(cg_tn_cn.cn)
            end 
            # make so its the first columns after the keys
            if cg_tn_cn.dashboard_edit_flag == "Y"
              @v_dashboard_edit_columns.push(cg_tn_cn.cn)
            end 
            if !cg_tn_cn.data_type.blank?
              @cns_type_dict[cg_tn_cn.cn] = cg_tn_cn.data_type
            end
        end  
        @v_key_columns = @key_cns.join(',') 
        if   @key_cns.size == 0
          # NEED TO ADD FLASH
        end
        #adjusting column order so key first, then editable columns, then the rest
        @cns = @cns - @key_cns
        @cns = @cns - @v_dashboard_edit_columns
        @cns = @key_cns + @v_dashboard_edit_columns + @cns

      if !params[:cg_edit_dashboard_table].blank? and !params[:cg_edit_dashboard_table][:blank_values].blank? and params[:cg_edit_dashboard_table][:blank_values] == "Y"
                 
           @cg_tn.tn
           @v_dashboard_edit_columns.each do |cn|
               v_condition =""
               v_condition = v_condition+" ("+@cg_tn.tn+"."+cn+" is NULL or "+@cg_tn.tn+"."+cn+"= '' or "+@cg_tn.tn+"."+cn+"= '|' ) "
               @conditions.push(v_condition)
           end
           @conditions.push(v_condition)
      end

      if !params[:cg_edit_dashboard_table].blank? and  !params[:cg_edit_dashboard_table][:key].blank?
         connection = ActiveRecord::Base.connection();
          params[:cg_edit_dashboard_table][:key].each do |r_val|
            v_key_array = []
            v_cnt  = 0
            v_key =""
            r = r_val.split("|")
            r.each do |rc| # make and save cn-value| key
              rc_array = rc.split("^")
              if @key_cns.include?(@cns[v_cnt]) # key column
                v_key = v_key+"^"+rc.to_s+"|"
               #v_key = v_key+@cns[v_cnt] +"^"+rc.to_s+"|"
                v_key_array.push( @cns[v_cnt]+"='"+rc_array[1].to_s+"'")
              end
              v_cnt = v_cnt + 1
            end  
            if !v_key.blank? and !@v_key.include?(v_key) 
                @v_key.push(v_key)
            end
            # update cg_data
            v_cnt = 0
            v_col_value_dict = {}
            v_col_value_array = []
            if !params[:cg_edit_dashboard_table][:edit_col].blank? 
                if !params[:cg_edit_dashboard_table][:edit_col][r_val].blank?
                    v_col_value_dict =params[:cg_edit_dashboard_table][:edit_col][r_val]
                    v_col_value_array.push(v_col_value_dict.keys.first.to_s+"='"+v_col_value_dict[v_col_value_dict.keys.first.to_s].to_s.gsub(/[;:"()=<>]/, '').gsub(/'/, "''")+"' ")
                end
            end

            if v_delete_data_row=="N"
                if v_col_value_array.size > 0
                  sql = "update "+@cg_tn.tn+" set "+v_col_value_array.join(',')+" where "+v_key_array.join(" and ")
                  @results = connection.execute(sql)
                 end
            else
                sql = "delete from "+@cg_tn.tn+" where "+v_key_array.join(" and ")
                #### @results = connection.execute(sql)
            end
          end
      end
        #NOT NEED ACL here - only getting cg_edit to compare with returned form values
        sql = "SELECT "+@cns.join(',')+" FROM "+@cg_tn.tn+" order by "+@key_cns.join(',') 
              #apply acl limits
      @conditions.push(" scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") " )
      @conditions.push(" scan_procedures.id = scan_procedures_vgroups.scan_procedure_id " )
      @conditions.push(" scan_procedures_vgroups.vgroup_id = vgroups.id ")
      @conditions.push(" appointments.vgroup_id = vgroups.id ")
      @conditions.push(@cg_tn.join_right)
      @key_cns.each do |k|
          @conditions.push(@cg_tn.tn+"."+k+" is not null ")
      end  
      @cns_plus_tn = []
      @cns.each do |cn|
          @cns_plus_tn.push(@cg_tn.tn+"."+cn)
      end
      sql = "SELECT distinct "+@cns_plus_tn.join(',')+" FROM appointments,scan_procedures,scan_procedures_vgroups,vgroups, "+ @cg_tn.tn+" where "+@conditions.uniq.join(' and ')+" order by "+@key_cns.join(',')  # add in conditions from search # NEED TO ADD ACL   WHERE keys in ( select keys where vgroup_id in ( normal acl ))    
        connection = ActiveRecord::Base.connection();
        @results = connection.execute(sql)
        @v_key = [] # start fresh
        @results.each do |r|   # populate keys and data
          v_cnt  = 0
          v_key =""
          r.each do |rc| # make and save cn-value| key
            if @key_cns.include?(@cns[v_cnt]) # key column
              v_key = v_key+@cns[v_cnt] +"^"+rc.to_s+"|"   # params seem to not like "=" in a key
            end
            v_cnt = v_cnt + 1
          end
          if !v_key.blank? and !@v_key.include?(v_key) 
              @v_key.push(v_key)
          end          
          # load data dict
          v_cnt = 0
          r.each do |rc|
             v_temp = v_key+@cns[v_cnt]
    #puts "v_temp="+v_temp+"   rc.to_s="+rc.to_s
             @cg_data_dict[v_temp] = rc.to_s
             v_cnt = v_cnt + 1
          end         
        end
      end

     respond_to do |format|
          format.html {@v_key = Kaminari.paginate_array(@v_key).page(params[:page]).per(50)}
      end
    end

    def cg_edit_table
      v_schema ='panda_production'
      if Rails.env=="development" 
        v_schema ='panda_development'
      end
      scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
      # really want to stop edit_table from being used on core tables
      v_exclude_tables_array =['appointments','blooddraws','cg_queries','cg_query_tn_cns','cg_query_tns','cg_tn_cns','cg_tns',
        'cg_tns_users','employees','enrollment_vgroup_memberships','enrollment_visit_memberships','enrollments',
        'image_comments','image_dataset_quality_checks','image_datasets','lumbarpuncture_results','lumbarpunctures','mriperformances','mriscantasks',
        'neuropsyches','participants','petscans','q_data','q_data_forms','question_scan_procedures','questionform_questions','questionform_scan_procedures',
        'questionforms','questionnaires','questions','radiology_comments','roles','scan_procedures','scan_procedures_vgroups','scan_procedures_visits',
        'scheduleruns','schedules','schedules_users','series_descriptions','users','vgroups','visits','vitals'] 
      @cg_tn = CgTn.find(params[:id])
      v_new_key_value =""
      @enumber_search =""
      v_sp =""
      @sp_array =[]
      v_condition =""
      @conditions = []
      params["search_criteria"] =""
      # add a row
      if !params[:cg_edit_table].blank? and !params[:cg_edit_table][:add_a_row_key_value].blank?
              params[:cg_edit_table][:enumber] = params[:cg_edit_table][:add_a_row_key_value]
              # check if already in table
              v_cg_tn_cn = CgTnCn.where("key_column_flag ='Y' and cg_tn_id in (?)",@cg_tn.id)
              # expect only one key column --- want an error if 
              v_new_key_value =  params[:cg_edit_table][:add_a_row_key_value].gsub(/ /,'').gsub(/'/,'').downcase
              if v_cg_tn_cn.size == 1
                 sql = "select count(*) from "+@cg_tn.tn+" where "+v_cg_tn_cn[0].cn+"= '"+v_new_key_value+"'"
                 connection = ActiveRecord::Base.connection();
                 @results = connection.execute(sql)
                 if @results.first.to_s.to_i > 0
                     flash[:notice] = v_new_key_value+" is already in  "+@cg_tn.common_name+"."
                 else # new key
                    # get link type from join table and joins --- only good for subject_v# => enrollment_id and scan_procedure_id 
                    v_key_type =""   # should this be moved from schedule to cg_tns?
                    if @cg_tn.join_left_parent_tn == "vgroups" and @cg_tn.join_right.include?("scan_procedures_vgroups.scan_procedure_id") and @cg_tn.join_right.include?("enrollment_vgroup_memberships.enrollment_id")
                      v_key_type = "enrollment/sp"
                    elsif @cg_tn.join_left_parent_tn == "vgroups" and @cg_tn.join_right.include?("vgroups.participant_id") 
                      connection = ActiveRecord::Base.connection();
                      sql = "SELECT `COLUMN_NAME`,`DATA_TYPE`, `CHARACTER_MAXIMUM_LENGTH` FROM `INFORMATION_SCHEMA`.`COLUMNS` WHERE `TABLE_SCHEMA`='"+v_schema+"' AND `TABLE_NAME`='"+@cg_tn.tn+"'"
                      @results_cg_tn_cn = connection.execute(sql)
                      v_cols = [] 
                      @results_cg_tn_cn.each do |c|
                            v_cols.push(c[0])
                      end
                       v_key_type = "participant_id"
                       if v_cols.include?('participant_id') and v_cols.include?('reggieid_kc') 
                         v_key_type = "reggieid-kc-participant_id"
                       elsif v_cols.include?('participant_id') and v_cols.include?('wrapnum_kc') 
                         v_key_type = "wrapnum-kc-participant_id"
                       elsif v_cols.include?('participant_id') and v_cols.include?('adrcnum_kc') 
                         v_key_type = "adrcnum-kc-participant_id"
                        end
                    else
                      flash[:notice] = " The  linkage to vgroup is unclear -- the add-a-row will not function."
                    end
                    if v_key_type == "enrollment/sp"
                       # insert into _new 
                       sql = "truncate table "+@cg_tn.tn+"_new"
                       @results = connection.execute(sql)
                       sql = "insert into "+@cg_tn.tn+"_new ( "+v_cg_tn_cn[0].cn+ ")values('"+v_new_key_value+"')"
                       @results = connection.execute(sql)
                      # map key to link column 
                      v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload
                      sql = "update "+@cg_tn.tn+"_new  t set t.enrollment_id = ( select e.id from enrollments e where e.enumber = replace(replace(replace(replace(t."+v_cg_tn_cn[0].cn+",'_v2',''),'_v3',''),'_v4',''),'_v5',''))"
                      results = connection.execute(sql)
                      sql = "select distinct "+v_cg_tn_cn[0].cn+" from "+@cg_tn.tn+"_new"
                      results = connection.execute(sql)
                      results.each do |r|
                        v_sp_id = v_shared.get_sp_id_from_subjectid_v(r[0])
                        if !v_sp_id.blank?
                          sql = "update "+@cg_tn.tn+"_new  t set t.scan_procedure_id = "+v_sp_id.to_s+" where "+v_cg_tn_cn[0].cn+" ='"+r[0]+"'"
                          results = connection.execute(sql)
                        end
                      end
                      # check if expected columns mapped?
                      sql = "select "+v_cg_tn_cn[0].cn+", enrollment_id from "+@cg_tn.tn+"_new where "+v_cg_tn_cn[0].cn+" = '"+v_new_key_value+"' and scan_procedure_id is null order by "+v_cg_tn_cn[0].cn
                      results = connection.execute(sql)
                      v_msg =""
                      results.each do |re|
                        v_msg = re.join(' | ')+" ,"+v_msg
                        flash[:notice] = v_new_key_value+" could not be mapped to an enrollment and scan procedure."
                      end
                                     
                      # insert present into new, apply edit -- like the partial file reload
                      # get all the columns from @cg_tn.tn+"_new
                      sql = "SHOW COLUMNS FROM "+@cg_tn.tn+"_new"
                      connection = ActiveRecord::Base.connection();
                      v_cols =[]
                      @results = connection.execute(sql)
                      @results.each do |c|
                         v_cols.push(c[0])
                      end
                      # this will get all the _edit into _new , but _edit is still ok
                      v_sql = "insert into "+@cg_tn.tn+"_new("+v_cols.join(',')+")  select "+v_cols.join(',')+" from "+@cg_tn.tn+" where "+@cg_tn.tn+"."+v_cg_tn_cn[0].cn+" not in (select "+v_cg_tn_cn[0].cn+" from "+@cg_tn.tn+"_new)"
                      results = connection.execute(v_sql)
                      
                      v_msg = v_shared.move_present_to_old_new_to_present(@cg_tn.tn,
                      v_cols.join(','), "scan_procedure_id is not null  and enrollment_id is not null ",v_msg)
                      v_shared.apply_cg_edits(@cg_tn.tn)
                    elsif v_key_type == "reggieid-kc-participant_id"   
                      # insert into _new 
                      sql = "truncate table "+@cg_tn.tn+"_new"
                      @results = connection.execute(sql)
                      sql = "insert into "+@cg_tn.tn+"_new ( "+v_cg_tn_cn[0].cn+ ")values('"+v_new_key_value+"')"
                      @results = connection.execute(sql)   
                      # map key to link column 
                      v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload
                      sql = "update "+@cg_tn.tn+"_new  t set t.participant_id = ( select distinct p.id from participants p where p.reggieid = t."+v_cg_tn_cn[0].cn+")"
                      results = connection.execute(sql) 
                      # check if expected columns mapped?
                      sql = "select "+v_cg_tn_cn[0].cn+", participant_id from "+@cg_tn.tn+"_new where "+v_cg_tn_cn[0].cn+" = '"+v_new_key_value+"' and participant_id is null order by "+v_cg_tn_cn[0].cn
                      results = connection.execute(sql)
                      v_msg =""
                      results.each do |re|
                        v_msg = re.join(' | ')+" ,"+v_msg
                        flash[:notice] = v_new_key_value+" could not be mapped to a participant."
                      end  
                      # insert present into new, apply edit -- like the partial file reload
                      # get all the columns from @cg_tn.tn+"_new
                      sql = "SHOW COLUMNS FROM "+@cg_tn.tn+"_new"
                      connection = ActiveRecord::Base.connection();
                      v_cols =[]
                      @results = connection.execute(sql)
                      @results.each do |c|
                         v_cols.push(c[0])
                      end
                      # this will get all the _edit into _new , but _edit is still ok
                      v_sql = "insert into "+@cg_tn.tn+"_new("+v_cols.join(',')+")  select "+v_cols.join(',')+" from "+@cg_tn.tn+" where "+@cg_tn.tn+"."+v_cg_tn_cn[0].cn+" not in (select "+v_cg_tn_cn[0].cn+" from "+@cg_tn.tn+"_new)"
                      results = connection.execute(v_sql)
                      
                      v_msg = v_shared.move_present_to_old_new_to_present(@cg_tn.tn,
                      v_cols.join(','), "participant_id is not null  ",v_msg)
                      v_shared.apply_cg_edits(@cg_tn.tn)       
                      
                    elsif v_key_type == "wrapnum-kc-participant_id"
                      # insert into _new 
                      sql = "truncate table "+@cg_tn.tn+"_new"
                      @results = connection.execute(sql)
                      sql = "insert into "+@cg_tn.tn+"_new ( "+v_cg_tn_cn[0].cn+ ")values('"+v_new_key_value+"')"
                      @results = connection.execute(sql)
                      # map key to link column 
                      v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload
                      sql = "update "+@cg_tn.tn+"_new  t set t.participant_id = ( select distinct p.id from participants p where p.wrapnum = t."+v_cg_tn_cn[0].cn+")"
                      results = connection.execute(sql)
                      # check if expected columns mapped?
                      sql = "select "+v_cg_tn_cn[0].cn+", participant_id from "+@cg_tn.tn+"_new where "+v_cg_tn_cn[0].cn+" = '"+v_new_key_value+"' and participant_id is null order by "+v_cg_tn_cn[0].cn
                      results = connection.execute(sql)
                      v_msg =""
                      results.each do |re|
                        v_msg = re.join(' | ')+" ,"+v_msg
                        flash[:notice] = v_new_key_value+" could not be mapped to a participant."
                      end
                      # insert present into new, apply edit -- like the partial file reload
                      # get all the columns from @cg_tn.tn+"_new
                      sql = "SHOW COLUMNS FROM "+@cg_tn.tn+"_new"
                      connection = ActiveRecord::Base.connection();
                      v_cols =[]
                      @results = connection.execute(sql)
                      @results.each do |c|
                         v_cols.push(c[0])
                      end
                      # this will get all the _edit into _new , but _edit is still ok
                      v_sql = "insert into "+@cg_tn.tn+"_new("+v_cols.join(',')+")  select "+v_cols.join(',')+" from "+@cg_tn.tn+" where "+@cg_tn.tn+"."+v_cg_tn_cn[0].cn+" not in (select "+v_cg_tn_cn[0].cn+" from "+@cg_tn.tn+"_new)"
                      results = connection.execute(v_sql)
                      
                      v_msg = v_shared.move_present_to_old_new_to_present(@cg_tn.tn,
                      v_cols.join(','), "participant_id is not null  ",v_msg)
                      v_shared.apply_cg_edits(@cg_tn.tn)
                      
                    elsif v_key_type == "adrcnum-kc-participant_id"
                      # insert into _new 
                      sql = "truncate table "+@cg_tn.tn+"_new"
                      @results = connection.execute(sql)
                      sql = "insert into "+@cg_tn.tn+"_new ( "+v_cg_tn_cn[0].cn+ ")values('"+v_new_key_value+"')"
                      @results = connection.execute(sql)
                      # map key to link column 
                      v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload
                      sql = "update "+@cg_tn.tn+"_new  t set t.participant_id = ( select distinct p.id from participants p where p.adrcnum = t."+v_cg_tn_cn[0].cn+")"
                      results = connection.execute(sql)
                      # check if expected columns mapped?
                      sql = "select "+v_cg_tn_cn[0].cn+", participant_id from "+@cg_tn.tn+"_new where "+v_cg_tn_cn[0].cn+" = '"+v_new_key_value+"' and participant_id is null order by "+v_cg_tn_cn[0].cn
                      results = connection.execute(sql)
                      v_msg =""
                      results.each do |re|
                        v_msg = re.join(' | ')+" ,"+v_msg
                        flash[:notice] = v_new_key_value+" could not be mapped to a participant."
                      end
                      # insert present into new, apply edit -- like the partial file reload
                      # get all the columns from @cg_tn.tn+"_new
                      sql = "SHOW COLUMNS FROM "+@cg_tn.tn+"_new"
                      connection = ActiveRecord::Base.connection();
                      v_cols =[]
                      @results = connection.execute(sql)
                      @results.each do |c|
                         v_cols.push(c[0])
                      end
                      # this will get all the _edit into _new , but _edit is still ok
                      v_sql = "insert into "+@cg_tn.tn+"_new("+v_cols.join(',')+")  select "+v_cols.join(',')+" from "+@cg_tn.tn+" where "+@cg_tn.tn+"."+v_cg_tn_cn[0].cn+" not in (select "+v_cg_tn_cn[0].cn+" from "+@cg_tn.tn+"_new)"
                      results = connection.execute(v_sql)
                      
                      v_msg = v_shared.move_present_to_old_new_to_present(@cg_tn.tn,
                      v_cols.join(','), "participant_id is not null  ",v_msg)
                      v_shared.apply_cg_edits(@cg_tn.tn)                     
                    end# ok key link
                 end
              end
              
            end
            
      
      # build up condition and join from @cg_tn
      if !params[:cg_edit_table].blank? and  !params[:cg_edit_table][:enumber].blank?
          if params[:cg_edit_table][:enumber].include?(',') # string of enumbers
            v_enumber =  params[:cg_edit_table][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
             @enumber_search = v_enumber
             v_enumber = v_enumber.gsub(/,/,"','")
            v_condition ="   appointments.id in (select a2.id from enrollment_vgroup_memberships,enrollments, appointments a2
                              where enrollment_vgroup_memberships.vgroup_id= a2.vgroup_id 
                               and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"')) "
          else
             v_enumber = params[:cg_edit_table][:enumber].gsub(/[;:'"()=<>]/, '')
             v_condition ="   appointments.id in (select a2.id from enrollment_vgroup_memberships,enrollments, appointments a2
                            where enrollment_vgroup_memberships.vgroup_id= a2.vgroup_id 
                             and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:cg_edit_table][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"
          end
          @conditions.push(v_condition)
          params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:cg_edit_table][:enumber]
      end

      if !params[:cg_edit_table].blank? and !params[:cg_edit_table][:scan_procedure_id].blank?
           @sp_array = params[:cg_edit_table][:scan_procedure_id]
           v_sp = params[:cg_edit_table][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')

           v_condition ="   appointments.id in (select a2.id from appointments a2,scan_procedures_vgroups where 
                                                              a2.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                              and scan_procedure_id in ("+params[:cg_edit_table][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+"))"
           @conditions.push(v_condition)
           @scan_procedures = ScanProcedure.where("id in (?)",params[:cg_edit_table][:scan_procedure_id])
           params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
      end

      v_key_columns =""
      if (@cg_tn.table_type == 'column_group' or @cg_tn.table_type == 'InProcess') and @cg_tn.editable_flag == "Y"  and !v_exclude_tables_array.include?(@cg_tn.tn.downcase) # want to limit to cg tables
        

        
        
        @cns = []
        @key_cns = []
        @v_key = []
        @cns_type_dict ={}
        @cns_common_name_dict = {}
        @cg_data_dict = {}
        @cg_edit_data_dict = {}
        @ref_table_a_dict ={}
        @ref_table_b_dict ={}
        @value_list_dict ={}
        
        @cg_tn_cns =CgTnCn.where("cg_tn_id in (?) and status_flag='Y'",@cg_tn.id)
        @cg_tn_cns.each do |cg_tn_cn|
  # puts "AAAAAAA cg_tn_cn.cn="+cg_tn_cn.cn
            if !cg_tn_cn.ref_table_a.blank?
              @ref_table_a_dict[cg_tn_cn.cn] = cg_tn_cn.ref_table_a
            end
            if !cg_tn_cn.ref_table_b.blank?
              @ref_table_b_dict[cg_tn_cn.cn] = cg_tn_cn.ref_table_b
            end
            if !cg_tn_cn.value_list.blank?
               @value_list_dict[cg_tn_cn.cn] = cg_tn_cn.value_list
            end             
            @cns.push(cg_tn_cn.cn)
            @cns_common_name_dict[cg_tn_cn.cn] = cg_tn_cn.common_name
            if cg_tn_cn.key_column_flag == "Y"
              @key_cns.push(cg_tn_cn.cn)
            end 
            if !cg_tn_cn.data_type.blank?
              @cns_type_dict[cg_tn_cn.cn] = cg_tn_cn.data_type
            end
        end  
        @v_key_columns = @key_cns.join(',') 
        if   @key_cns.size == 0
          # NEED TO ADD FLASH
        end
        #NOT NEED ACL here - only getting cg_edit to compare with returned form values
        sql = "SELECT "+@cns.join(',')+" FROM "+@cg_tn.tn        
        
        connection = ActiveRecord::Base.connection();
        @results = connection.execute(sql)
        @results.each do |r|   # populate keys and data
          v_cnt  = 0
          v_key =""
          r.each do |rc| # make and save cn-value| key
            if @key_cns.include?(@cns[v_cnt]) # key column
              v_key = v_key+@cns[v_cnt] +"^"+rc.to_s+"|"   # params seem to not like "=" in a key
            end
            v_cnt = v_cnt + 1
          end
          if !v_key.blank? and !@v_key.include?(v_key) 
              @v_key.push(v_key)
          end          
          # load data dict
          v_cnt = 0
          r.each do |rc|
             v_temp = v_key+@cns[v_cnt]
             @cg_data_dict[v_temp] = rc.to_s
             v_cnt = v_cnt + 1
          end         
        end
        
        
        # get current state of cg_edit
        sql = "SELECT "+@cns.join(',') +",delete_key_flag FROM "+@cg_tn.tn+"_edit" 
        @edit_results = connection.execute(sql)  
        @edit_results.each do |r|
          v_cnt  = 0
          v_key =""
          r.each do |rc| # make and save cn-value| key
            if @key_cns.include?(@cns[v_cnt]) # key column
              v_key = v_key+@cns[v_cnt] +"^"+rc.to_s+"|"
            end
            v_cnt = v_cnt + 1
          end
          # pushing in edit rows if not in data
          if !v_key.blank? and !@v_key.include?(v_key) 
            if current_user.role == 'Admin_High'
                @v_key.push(v_key)
            end
          end          
    
          # load data dict
          v_cnt = 0
          r.each do |rc| 
            v_col = @cns[v_cnt]
            if @cns[v_cnt].blank?
              v_col = "delete_key_flag"
            end
             v_temp = v_key+v_col
             @cg_edit_data_dict[v_temp] = rc.to_s
             v_cnt = v_cnt + 1
          end         
        end
        
        if !params[:cg_edit_table].blank? and !params[:cg_edit_table][:key_data].blank?   
  # using key_data instead of key because of problem of edit rows showing when no row displayed
  # this will become a problem with pageation or acl where a data row may not be displayed
          # remove all params[:cg_edit_table][:key_data] rows from @cg_tn.tn+"_edit" if delete_edit
          # make sql -- split params[:cg_edit_table][:key] by "|", then split by "="
          #      put ' ' around [1] value
          # loop thru keys
            # insert _edit row  
            #   if delete_data
            #       make delete statement for cg_data_table
            #   if not delete_edit
            #   if any in row - cg_edit_table[edit_col][key+cn].value !=  @cg_data_dict[key+cn]
            #      make one edit_table insert statement  @col_list.push, @value_list.push
            #      make update statement form data_table  @col_value_list.push
            v_cnt = 0
            v_key_pipe_array = []
            params[:cg_edit_table][:key_data].each do |k|
              #puts "AAAAAA start of key="+k +" v_cnt = "+v_cnt.to_s
              # make v_key -- split k on | , wrap value in ''
              v_key = ""
              v_tmp = ""
              v_key_array = []
              v_key_pipe_array = k.split("|")
              v_key_cn_array = []
              v_key_value_array = []
              v_key_pipe_array.each do |cn_v|
                v_tmp = cn_v.split("^")
                v_key_array.push(v_tmp[0]+"='"+v_tmp[1].gsub(/'/, "''")+"'")
                v_key_cn_array.push(v_tmp[0])
                v_key_value_array.push("'"+v_tmp[1].gsub(/'/, "''")+"'")
              end
              v_edit_in_row_flag ="N"
  #puts "CCCCCCC blank to nil"
              @cns.each do |cn|
            	    if  !@cg_edit_data_dict[k+cn].nil? and @cg_edit_data_dict[k+cn] != "|" and cn != "delete_key_flag" and !v_key_cn_array.include?(cn)
            		      v_edit_in_row_flag ="Y"
            		      
            		   end
            	end
            	v_delete_edit_row ="Y"
            	@cns.each do |cn|  # deleting all | only row
            	    if @cg_edit_data_dict[k+cn] != "|" and cn != "delete_key_flag" and !v_key_cn_array.include?(cn)
            	      v_delete_edit_row ="N"
            	    end
            	end
            	if v_delete_edit_row == "Y"
            	  sql = " delete from "+@cg_tn.tn+"_edit  where "+v_key_array.join(" and ")
                 @results = connection.execute(sql)
            	end
            	
              if !params[:cg_edit_table][:delete_data].blank? and !params[:cg_edit_table][:delete_data][v_cnt.to_s].blank?              
                # check if key in edit_table
                if v_edit_in_row_flag =="Y"
                   sql ="update "+@cg_tn.tn+"_edit set delete_key_flag ='Y' where "+v_key_array.join(" and ")
                    @results = connection.execute(sql)
                else            
                   sql = "insert into "+@cg_tn.tn+"_edit("+v_key_cn_array.join(",")+",delete_key_flag) values("+v_key_value_array.join(",")+",'Y' )"
                    @results = connection.execute(sql)
                end
              elsif !params[:cg_edit_table][:delete_edit].blank? and !params[:cg_edit_table][:delete_edit][v_cnt.to_s].blank? and params[:cg_edit_table][:delete_edit][v_cnt.to_s] == "1"
                  sql = " delete from "+@cg_tn.tn+"_edit  where "+v_key_array.join(" and ")
                   @results = connection.execute(sql)
              else
                if v_edit_in_row_flag =="Y" 
                  # make delete and insert - evaluate vs incoming values vs exisiting edits - loop thru cns, make keys
                  sql = " delete from "+@cg_tn.tn+"_edit  where "+v_key_array.join(" and ")
                   @results = connection.execute(sql)
                  v_cnt_cn = 0
                  v_tmp_value_array = []
                  v_tmp_cn_array = []
                  @cns.each do |cn|
                    if !params[:cg_edit_table][:edit_col].blank? and  !params[:cg_edit_table][:edit_col][k].blank? and !v_key_cn_array.include?(cn)
                           #puts "aaaaaa !params[:cg_edit_table][:edit_col][v_cnt.to_s].blank?"
                           if !params[:cg_edit_table][:edit_col][k][cn].blank?
                              # value in cell
                              if @cg_data_dict[k+cn] != params[:cg_edit_table][:edit_col][k][cn] or @cg_edit_data_dict[k+cn] == params[:cg_edit_table][:edit_col][k][cn] 
                                v_tmp_value_array.push("'"+params[:cg_edit_table][:edit_col][k][cn].gsub(/'/, "''")+"'")
                                v_tmp_cn_array.push(cn)
                              end
                           else
                              # blank cell == |
                              if @cg_data_dict[k+cn] != params[:cg_edit_table][:edit_col][k][cn] or @cg_edit_data_dict[k+cn] == params[:cg_edit_table][:edit_col][k][cn] 
                                v_tmp_value_array.push("''")
                                v_tmp_cn_array.push(cn)
                              end
                            end
                    end                   
                    
                    v_cnt_cn = v_cnt_cn + 1
                  end
                  if v_key_value_array.size > 0 and v_tmp_value_array.size > 0 and @cg_edit_data_dict[k+"delete_key_flag"] != "Y"
                      # existing edit
                      v_tmp_cn_array.concat(v_key_cn_array)
                      v_tmp_value_array.concat(v_key_value_array)
                      sql = "insert into "+@cg_tn.tn+"_edit("+v_tmp_cn_array.join(',')+") values("+v_tmp_value_array.join(",")+")"
                       @results = connection.execute(sql)
                  end                  
                  
                else
                  # make insert  loop thru cns, make keys
                  v_cnt_cn = 0
                  v_tmp_value_array = []
                  v_tmp_cn_array = []
   #puts "BBBBBBBB blank to nil"               
                  @cns.each do |cn|
                    if !params[:cg_edit_table][:edit_col].nil? and  !params[:cg_edit_table][:edit_col][k].blank? and !v_key_cn_array.include?(cn)
                           #puts "aaaaaa !params[:cg_edit_table][:edit_col][v_cnt.to_s].blank?"
                           if !params[:cg_edit_table][:edit_col][k][cn].blank?
                              # value in cell
                              if @cg_data_dict[k+cn] != params[:cg_edit_table][:edit_col][k][cn]
                                v_tmp_value_array.push("'"+params[:cg_edit_table][:edit_col][k][cn].gsub(/'/, "''")+"'")
                                v_tmp_cn_array.push(cn)
                              end
                           else
                              # blank cell == |
                              if @cg_data_dict[k+cn] != params[:cg_edit_table][:edit_col][k][cn]
                                v_tmp_value_array.push("''")
                                v_tmp_cn_array.push(cn)
                              end
                            end
                    end
                    v_cnt_cn = v_cnt_cn + 1
                  end
                  if v_key_value_array.size > 0 
                      v_insert_edit_flag ='N'
      #puts "DDDDDD blank to nil"
                      @cns.each do |cn|
                       # if   !params[:cg_edit_table][:edit_col][k][cn].blank? and params[:cg_edit_table][:edit_col][k][cn] != @cg_data_dict[k+cn] and cn != "delete_key_flag" and !v_key_cn_array.include?(cn)
                      if   !params[:cg_edit_table][:edit_col][k][cn].nil? and params[:cg_edit_table][:edit_col][k][cn] != "|" and cn != "delete_key_flag" and !v_key_cn_array.include?(cn)  and params[:cg_edit_table][:edit_col][k][cn] != @cg_data_dict[k+cn]
                          v_insert_edit_flag ='Y'
                        end
                      end
                      if v_insert_edit_flag == 'Y'
                         # new edit
                          v_tmp_cn_array.concat(v_key_cn_array)
                          v_tmp_value_array.concat(v_key_value_array)
                          sql = "insert into "+@cg_tn.tn+"_edit("+v_tmp_cn_array.join(',')+") values("+v_tmp_value_array.join(",")+")"
                          @results = connection.execute(sql)
                      end
                  end
                end
              end
              
              v_delete_edit_row ="Y"
            	@cns.each do |cn|  # deleting all | only row
            	    if @cg_edit_data_dict[k+cn] != "|" and cn != "delete_key_flag" and !v_key_cn_array.include?(cn)
            	      v_delete_edit_row ="N"
            	    end
            	end
            	if v_delete_edit_row == "Y"
            	  sql = " delete from "+@cg_tn.tn+"_edit  where "+v_key_array.join(" and ")
                 @results = connection.execute(sql)
            	end
              # puts " v_cnt ="+v_cnt.to_s+" end  key="+k
              v_cnt = v_cnt +1
            end
        end
        
      if !params[:cg_edit_table].blank? and !params[:cg_edit_table][:key].blank?  
        # apply cg_edit to cg_data and refresh cg_edit , same as above, but no key array ---  made into a function  in shared model - needswitch to that function
        sql = "SELECT "+@cns.join(',') +",delete_key_flag FROM "+@cg_tn.tn+"_edit" 
        @edit_results = connection.execute(sql)         
        @edit_results.each do |r|
            v_key_array = []
            v_cnt  = 0
            v_key =""
            v_delete_data_row="N"
            r.each do |rc| # make and save cn-value| key
              if @key_cns.include?(@cns[v_cnt]) # key column
                v_key = v_key+@cns[v_cnt] +"^"+rc.to_s+"|"
                v_key_array.push( @cns[v_cnt] +"='"+rc.to_s+"'")
              end
              v_cnt = v_cnt + 1
            end  
            if !v_key.blank? and !@v_key.include?(v_key) 
                @v_key.push(v_key)
            end
            # update cg_data
            v_cnt = 0
            v_col_value_array = []
            r.each do |rc|
              if !@key_cns.include?(@cns[v_cnt])
                # might need to int, to date, etc from datatype
                if @cns[v_cnt].blank?
                 # v_col_value_array.push(" delete_key_flag ='"+rc.to_s+"' ")
                   if rc.to_s == "Y"
                    v_delete_data_row="Y"
                  end
                else
                    if rc.to_s != "|"
                        v_col_value_array.push(@cns[v_cnt]+"='"+rc.to_s.gsub(/'/, "''")+"' ")
                    end
                end
              end               
              v_cnt = v_cnt + 1
            end
            if v_delete_data_row=="N"
                if v_col_value_array.size > 0
                  sql = "update "+@cg_tn.tn+" set "+v_col_value_array.join(',')+" where "+v_key_array.join(" and ")
                   @results = connection.execute(sql)
                 end
            else
                sql = "delete from "+@cg_tn.tn+" where "+v_key_array.join(" and ")
                 @results = connection.execute(sql)
            end        
        end
      end        
        
      ## problems with getting clean, new copy- think its the keys
      # refresh cg_data and cg_edit
      @cns = []
      @key_cns = []
      @v_key = []
      @cns_type_dict ={}
      @cns_common_name_dict = {}
      @cg_data_dict = {}
      @cg_edit_data_dict = {}
      
      @cg_tn_cns =CgTnCn.where("cg_tn_id in (?) and status_flag = 'Y' ",@cg_tn.id).order("display_order")
      @cg_tn_cns.each do |cg_tn_cn|
          @cns.push(cg_tn_cn.cn)
          @cns_common_name_dict[cg_tn_cn.cn] = cg_tn_cn.common_name
          if cg_tn_cn.key_column_flag == "Y"
            @key_cns.push(cg_tn_cn.cn)
          end 
          if !cg_tn_cn.data_type.blank?
            @cns_type_dict[cg_tn_cn.cn] = cg_tn_cn.data_type
          end
      end  
      @v_key_columns = @key_cns.join(',') 
      if   @key_cns.size == 0
        # NEED TO ADD FLASH
      end
      #apply acl limits
      @conditions.push(" scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") " )
      @conditions.push(" scan_procedures.id = scan_procedures_vgroups.scan_procedure_id " )
      @conditions.push(" scan_procedures_vgroups.vgroup_id = vgroups.id ")
      @conditions.push(" appointments.vgroup_id = vgroups.id ")
      @conditions.push(@cg_tn.join_right)
      @key_cns.each do |k|
          @conditions.push(@cg_tn.tn+"."+k+" is not null ")
      end  
      @cns_plus_tn = []
      @cns.each do |cn|
          @cns_plus_tn.push(@cg_tn.tn+"."+cn)
      end
      sql = "SELECT distinct "+@cns_plus_tn.join(',')+" FROM appointments,scan_procedures,scan_procedures_vgroups,vgroups, "+ @cg_tn.tn+" where "+@conditions.uniq.join(' and ') # add in conditions from search # NEED TO ADD ACL   WHERE keys in ( select keys where vgroup_id in ( normal acl ))    
      # sql = "SELECT "+@cns.join(',')+" FROM "+@cg_tn.tn        


 
    
      connection = ActiveRecord::Base.connection();
      @results = connection.execute(sql)
      @results.each do |r|
        v_cnt  = 0
        v_key =""
        r.each do |rc| # make and save cn-value| key
          if @key_cns.include?(@cns[v_cnt]) # key column
            v_key = v_key+@cns[v_cnt] +"^"+rc.to_s+"|"   # params seem to not like "=" in a key
          end
          v_cnt = v_cnt + 1
        end
        if !v_key.blank? and !@v_key.include?(v_key) 
            @v_key.push(v_key)
        end          
        # load data dict
        v_cnt = 0
        r.each do |rc|
           v_temp = v_key+@cns[v_cnt]
           @cg_data_dict[v_temp] = rc.to_s
           v_cnt = v_cnt + 1
        end         
      end
      
      
      # get current state of cg_edit
      sql = "SELECT "+@cns.join(',') +",delete_key_flag FROM "+@cg_tn.tn+"_edit" 
      @edit_results = connection.execute(sql)  
      @edit_results.each do |r|
        v_cnt  = 0
        v_key =""
        r.each do |rc| # make and save cn-value| key
          if @key_cns.include?(@cns[v_cnt]) # key column
            v_key = v_key+@cns[v_cnt] +"^"+rc.to_s+"|"
          end
          v_cnt = v_cnt + 1
        end
        if !v_key.blank? and !@v_key.include?(v_key)  # pushing in edit key rows not in data
            if current_user.role == 'Admin_High'
                # @v_key.push(v_key)   ## hiding edits not in data -- causing problems in delete - displacing the index 0-1-2-... by the exitra edit rows
            end
        end    
        @v_key = @v_key.sort      
        # load data dict
        v_cnt = 0
        r.each do |rc| 
          v_col = @cns[v_cnt]
          if @cns[v_cnt].blank?
            v_col = "delete_key_flag"
          end
           v_temp = v_key+v_col
           @cg_edit_data_dict[v_temp] = rc.to_s
           v_cnt = v_cnt + 1
        end         
      end
        
        
      end
      respond_to do |format|
          format.html {@v_key = Kaminari.paginate_array(@v_key).page(params[:page]).per(50)}
      end
      
    end
   # can not do a self join-- unless two copies of table - unique tn_id, tn_cn_id
   # this has glimpses of maddness and wonder
    def cg_search 
      
      if(!params["cg_search"].blank?) 
         @cg_search_params  = cg_search_params() 
      end  

      v_debug = "N" # Y"
      scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
      @scan_procedure_list = scan_procedure_list
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end 
      # make the sql -- start with base 
      v_secondary_key_tn_array =[]
      @local_column_headers =["Date (vgroup)","Protocol","Enumber","RMR"]
      @local_fields = []
      @local_conditions =[]
      @conditions = [] # for the q_data_search
      @conditions_bak = []
      @all_table_ids_in_query = [] # trying to get a list of inner/outer join tables for participant_centric order by
      @local_tables =[] # need to add outer join to table, -- 
      @local_tables_alias_hash =Hash.new # need to make pet tracer select -- tracker?
      @table_types =[] 
      @tables_left_join_hash = Hash.new
      @tables_secondary_key_join_hash = Hash.new
      @joins = [] # just inner joins
      @sp_array =[]
      @pet_tracer_array = []
      @cg_query_tn_id_array = []
      @cn_p_vg_array = [] # used to flag column as participant specific
      @cg_query_tn_hash = Hash.new
      @cg_query_tn_cn_hash = Hash.new
      @cg_query_cn_hash = Hash.new
      @cg_query_tn_not_in_hash = Hash.new
      params["search_criteria"] =""
      ####@headers_q_data = []
      @q_data_form_array = []
      @q_data_fields_hash = Hash.new
      @q_data_left_join_hash = Hash.new
      @q_data_left_join_vgroup_hash = Hash.new
      @q_data_headers_hash = Hash.new
      @q_data_tables_hash = Hash.new
      @q_data_tables_p_vg_hash = Hash.new # used to identify if table is joined on participant_id
      @fields_hash = Hash.new

      @add_cg_tn_id = []
      
      @image_datasets_tn =  CgTn.where("tn = 'image_datasets' ")
      # ALSO IN IDS_SEARCH !!!!!!  need to update if added new categories
      #       @series_desc_categories = {"ASL" => "ASL", 
      # "DSC_Perfusion" => "DSC_Perfusion", 
      # "DTI" => "DTI", 
      # "Fieldmap" => "Fieldmap", 
      # "fMRI_Task" => "fMRI_Task", 
      # "HYDI" => "HYDI", 
      # "mcDESPOT" => "mcDESPOT", 
      # "MRA" => "MRA", 
      # "MT" => "MT", 
      # "Other" => "Other", 
      # "PCVIPR" => "PCVIPR", 
      # "PD/T2" => "PD/T2", 
      # "resting_fMRI" => "resting_fMRI", 
      # "SWI" => "SWI", 
      # "T1_Volumetric" => "T1_Volumetric", 
      # "T2" => "T2", 
      # "T2_Flair" => "T2_Flair", 
      # "T2*" => "T2*"}
     
      #request_format = request.formats.to_s 
      v_request_format_array = request.formats
       request_format = v_request_format_array[0]
      @html_request ="Y"
      # html and non-html have different column_names as output
      case  request_format
        when "[text/html]","text/html" then  # application/html ?
            @html_request ="Y" 
        else
            @html_request ="N"
        end
      if v_debug == "Y"
          # puts "aaaaaa @html_request= "+@html_request
       end
      # get stored cg_search - this populates all the params like a submited search
      # @cg_query carries the search parameters from saved search or from search params
      if !params[:cg_search].blank? and !params[:cg_search][:cg_query_id].blank? 
         @cg_query = CgQuery.find(params[:cg_search][:cg_query_id])
        if !@cg_query.scan_procedure_id_list.blank?
           @sp_array = @cg_query.scan_procedure_id_list.split(",")
        end
      
         if !@cg_query.pet_tracer_id_list.blank?
            @pet_tracer_array = @cg_query.pet_tracer_id_list.split(",")
         end

         @cg_query_tns =  CgQueryTn.where("cg_query_id = "+@cg_query.id.to_s).where("cg_tn_id in ( select cg_tns.id from cg_tns where cg_tns.table_type in 
        (select table_type from cg_table_types where cg_table_types.protocol_id is null or cg_table_types.protocol_id in ("+scan_procedure_list+")))").order("cg_query_tns.display_order")
         @cg_query_tns.each do |cg_query_tn|

           v_tn_id = cg_query_tn.cg_tn_id 
            @cg_query_tn_id_array.push(v_tn_id) # need to retrieve for display on the page
            # if cg table needd to propagate from search to search
           v_cg_tn = CgTn.find(v_tn_id)
           if v_cg_tn.table_type != 'base'  
  puts "zzzzz add_table id = "+v_tn_id.to_s 
             @add_cg_tn_id.push(v_tn_id.to_s) 
           end
           @cg_query_tn_hash[v_tn_id.to_s] = cg_query_tn  
           @cg_query_tn_cns = CgQueryTnCn.where("cg_query_tn_id = "+cg_query_tn.id.to_s) 
           @cg_query_tn_cns.each do |cg_query_tn_cn|
             v_tn_cn_id = cg_query_tn_cn.cg_tn_cn_id.to_s
             @cg_query_cn_hash[v_tn_cn_id] = cg_query_tn_cn
           end 
           @cg_query_tn_cn_hash[v_tn_id.to_s] = @cg_query_cn_hash         
         end   
      else # make new cg_search      
        if !params[:cg_search].blank? and !params[:cg_search][:stored_cg_query_id].blank? and    params[:cg_search][:save_search] == "1"   # update an exisiting CgQuery
          @cg_query = CgQuery.find(params[:cg_search][:stored_cg_query_id])
          @user = current_user
          if @user.id  == @cg_query.user_id and @cg_query.cg_name == params[:cg_search][:cg_name]
            @cg_query.destroy   # cg query tns and cg_query_tn_cns also destroyed
          end

        end
        
       @cg_query = CgQuery.new
       @user = current_user

       if !params[:cg_search].blank?
          # NEED TO BUILD  v_condition = -- LOOK AT OTHER SEARCHES    --- not saving the image_dataset conditions
         @cg_query.id = params[:cg_search][:cg_query_id]
         @cg_query.cg_name = params[:cg_search][:cg_name]
         @cg_query.rmr = params[:cg_search][:rmr]
         if !params[:cg_search][:enumber].blank?
            params[:cg_search][:enumber] = params[:cg_search][:enumber].gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
         end
         @cg_query.enumber = params[:cg_search][:enumber]
         if !params[:cg_search][:enumber_not_in].blank?
             params[:cg_search][:enumber_not_in] = params[:cg_search][:enumber_not_in].gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
          end

         @cg_query.enumber_not_in = params[:cg_search][:enumber_not_in]
         @cg_query.participant_centric = params[:cg_search][:participant_centric]
         @cg_query.gender = params[:cg_search][:gender]
         @cg_query.min_age = params[:cg_search][:min_age]
         @cg_query.max_age = params[:cg_search][:max_age]
         @cg_query.save_flag = params[:cg_search][:save_flag]
         @cg_query.status_flag = params[:cg_search][:save_flag] # NOT SURE HOW SAVE_FLAG vs STATUS_FLAG will work
         @cg_query.user_id  = @user.id

         # would like to switch to vgroups.id limit, by run_search_q_data gets conditions, and might expect appointments.id limits
         # build conditions from sp, enumber, rmr, gender, min_age, max_age -- @table_types.push('base')
         if !params[:cg_search][:series_description_type_id].blank? # image_dataset
            v_ids_tn_id = @image_datasets_tn[0].id
            if params[:cg_search][:join_type][v_ids_tn_id.to_s] == "0" # inner affects full query- outer doesn't affect full query
             v_condition = " vgroups.id in ( select a3.vgroup_id from appointments a3,visits v3, image_datasets ids3 where a3.id = v3.appointment_id 
                                                         and a3.appointment_type = 'mri'
                                                         and v3.id = ids3.visit_id and ids3.series_description in (select series_description from series_description_maps 
                                                          where series_description_type_id = '"+params[:cg_search][:series_description_type_id]+"' ) ) "
             @local_conditions.push(v_condition)
              params["search_criteria"] = params["search_criteria"] +" series description "+SeriesDescriptionType.find(params[:cg_search][:series_description_type_id]).series_description_type+", "
            end
         end
         
         if !params[:cg_search][:scan_procedure_id].blank?
            @table_types.push('base')
            v_condition ="   appointments.id in (select a2.id from appointments a2,scan_procedures_vgroups where 
                                                   a2.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                   and scan_procedure_id in ("+params[:cg_search][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+"))"
            @scan_procedures = ScanProcedure.where("id in (?)",params[:cg_search][:scan_procedure_id])
            @local_conditions.push(v_condition)
            params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
            
            @cg_query.scan_procedure_id_list = params[:cg_search][:scan_procedure_id].join(',')
            @sp_array = @cg_query.scan_procedure_id_list.split(",")
         end
         
         if !params[:cg_search][:pet_tracer_id].blank?
            @cg_query.pet_tracer_id_list = params[:cg_search][:pet_tracer_id].join(',')
            @pet_tracer_array = @cg_query.pet_tracer_id_list.split(",")
         end

         if !params[:cg_search][:enumber].blank?
            @table_types.push('base')
            # adding a not in
            v_in_not_in = " in "
            if !params[:cg_search][:enumber_not_in].blank? and params[:cg_search][:enumber_not_in] == "1"
                v_in_not_in = " not in "
             end
            params[:cg_search][:enumber] = params[:cg_search][:enumber].gsub(/\xef\xbc\x8c/,',').gsub(/\\xef\\xbc\\x8c/,',') # utf-8 full length comma - ? fron IE out of excel?
            if params[:cg_search][:enumber].include?(',') # string of enumbers
             v_enumber =  params[:cg_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
             v_enumber = v_enumber.gsub(/,$/,"")  # trimming trailing comma 
             v_enumber = v_enumber.gsub(/,/,"','")
             
             v_condition ="   appointments.id in (select a2.id from enrollment_vgroup_memberships,enrollments, appointments a2
                  where enrollment_vgroup_memberships.vgroup_id= a2.vgroup_id 
                   and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) "+v_in_not_in+" ('"+v_enumber.gsub(/[\\;:"()=<>]/, '')+"'))"
            else
              v_condition ="   appointments.id in (select a2.id from enrollment_vgroup_memberships,enrollments, appointments a2
               where enrollment_vgroup_memberships.vgroup_id= a2.vgroup_id 
                and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) "+v_in_not_in+" (lower('"+params[:cg_search][:enumber].gsub(/[\\;:'"()=<>]/, '')+"')))"
            end
             @local_conditions.push(v_condition)
             params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:cg_search][:enumber].gsub(/\\/,"")
         end      

         if !params[:cg_search][:rmr].blank? 
            @table_types.push('base')
             v_condition ="   appointments.id in (select a2.id from appointments a2,vgroups
                       where a2.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower('"+params[:cg_search][:rmr].gsub(/[;:'"()=<>]/, '')+"')   ))"
                       @local_conditions.push(v_condition)
             params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:cg_search][:rmr]
         end
         
         if !params[:cg_search][:gender].blank?
           @table_types.push('base')
            v_condition ="    appointments.id in (select a2.id from participants,  enrollment_vgroup_memberships, enrollments,appointments a2
             where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
             and enrollment_vgroup_memberships.vgroup_id = a2.vgroup_id
                    and participants.gender is not NULL and participants.gender in ("+params[:cg_search][:gender].gsub(/[;:'"()=<>]/, '')+") )"
             @local_conditions.push(v_condition)
             if params[:cg_search][:gender] == 1
                params["search_criteria"] = params["search_criteria"] +",  sex is Male"
             elsif params[:cg_search][:gender] == 2
                params["search_criteria"] = params["search_criteria"] +",  sex is Female"
             end
         end   

         if !params[:cg_search][:min_age].blank? && params[:cg_search][:max_age].blank?
            @table_types.push('base')
             v_condition ="     appointments.id in (select a2.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments a2
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and a2.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                             and  round((DATEDIFF(a2.appointment_date,participants.dob)/365.25),2) >= "+params[:cg_search][:min_age].gsub(/[;:'"()=<>]/, '')+"   )"
             @local_conditions.push(v_condition)
             params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:cg_search][:min_age]
         elsif params[:cg_search][:min_age].blank? && !params[:cg_search][:max_age].blank?
             @table_types.push('base')
              v_condition ="     appointments.id in (select a2.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments a2
                                 where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                              and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                              and a2.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                          and round((DATEDIFF(a2.appointment_date,participants.dob)/365.25),2) <= "+params[:cg_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
             @local_conditions.push(v_condition)
             params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:cg_search][:max_age]
         elsif !params[:cg_search][:min_age].blank? && !params[:cg_search][:max_age].blank?
            @table_types.push('base')
            v_condition ="      appointments.id in (select a2.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments a2
                               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                            and a2.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                        and round((DATEDIFF(a2.appointment_date,participants.dob)/365.25),2) between "+params[:cg_search][:min_age].gsub(/[;:'"()=<>]/, '')+" and "+params[:cg_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
           @local_conditions.push(v_condition)
           params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:cg_search][:min_age]+" and "+params[:cg_search][:max_age]
         end    
         @conditions_bak.concat(@local_conditions) 

         if params[:cg_search][:save_search] == "1" 
            params[:cg_search][:log_flag] = "N"
            @cg_query.save
            params[:cg_search][:cg_query_id] = @cg_query.id.to_s # being used in export file don't populate unless save search
            params[:cg_search][:cg_query_id_log] = @cg_query.id.to_s
         else
             params[:cg_search][:log_flag] = "Y"
             @cg_query.log_flag ="Y"
             @cg_query.save
             @cg_query.log_flag = "N"
             params[:cg_search][:cg_query_id_log] = @cg_query.id.to_s
         end 
         # lsaving all queries as a log for UP protocol checks

         # loop thru each table
         if !params[:cg_search][:tn_id].blank? 
           params[:cg_search][:tn_id].each do |tn_id|
            v_tn_id = tn_id.to_s

            v_cg_tn_array = []  
            # pet with a tracer picked - could be many tracers - artifically make more "tables"
            @cg_tn = CgTn.find(v_tn_id)
            if @cg_tn.tn == "view_petscan_appts" and !params[:cg_search][:pet_tracer_id].blank?
                # need to loop thru each pet tracer picked
                params[:cg_search][:pet_tracer_id].each do |tr|
                     @cg_tn = CgTn.find(v_tn_id)
                     # remake the @cg_tn with pet_tracer_id  - alias includes tracer so can have multiple pet
                     @cg_tn.alias = @cg_tn.tn+"_"+tr
                     @cg_tn.tn = "(select * from view_petscan_appts where view_petscan_appts.lookup_pettracer_id = '"+tr+"')  "+@cg_tn.alias
                     @cg_tn.join_right = "view_petscan_appts_"+tr+".petscan_vgroup_id = vgroups.id"
                     @cg_tn.join_left ="LEFT JOIN (select * from view_petscan_appts where view_petscan_appts.lookup_pettracer_id = '"+tr+"')  "+@cg_tn.alias+" on  vgroups.id = view_petscan_appts_"+tr+".petscan_vgroup_id"
                     @local_tables_alias_hash[@cg_tn.tn] = @cg_tn.alias
                     v_cg_tn_array.push(@cg_tn)
                end
            elsif @cg_tn.table_type == "tracker"  # e.g. fs edit, mcd trackers
                @cg_tn.alias = @cg_tn.tn
                v_tracker_column_array = ["scan_procedures_vgroups.vgroup_id",   "trfiles.subjectid","trfiles.secondary_key","trfiles.enrollment_id","trfiles.scan_procedure_id", "trfiles.file_completed_flag","trfiles.qc_value","trfiles.qc_notes"]
    # just putting the tables in with common -- problem with left joins and commas from the array join -- need trfiles last in tn list
                v_tracker_table_array = ["scan_procedures_vgroups,enrollment_vgroup_memberships,trfiles"]
                v_tracker_table_conditions =[" trfiles.trtype_id = "+@cg_tn.tracker_id.to_s+" ", "scan_procedures_vgroups.scan_procedure_id = trfiles.scan_procedure_id",
                             "enrollment_vgroup_memberships.enrollment_id = trfiles.enrollment_id", "scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id"]

                @tractiontypes = Tractiontype.where("trtype_id in (?)",@cg_tn.tracker_id).where("tractiontypes.form_display_label is not null and tractiontypes.form_display_label >''" ).order(:display_order)
                @tractiontypes.each do |act|
                    v_value_sql = ""
                    # ("trfiles.id = v_"+act.id.to_s+".trfile_id")
                    v_col = (act.form_display_label).gsub(/ /,"").gsub(/\'/,"_").gsub(/\"/,"_").gsub(/\-/,"_").downcase+"_" 
                    v_tracker_column_array.push("v_"+act.id.to_s+"."+v_col) 
                    # need last edit
                    if !act.ref_table_b_1.blank?
                      v_value_sql = "LEFT JOIN  (select "+act.ref_table_a_1+".description "+v_col+", trfile2.id  trfile_id from  trfiles trfile2, tredits , tredit_actions, "+act.ref_table_a_1+" 
                      where trfile2.id = tredits.trfile_id 
                      and tredits.id = tredit_actions.tredit_id 
                      and tredit_actions.tractiontype_id = "+act.id.to_s+" 
                      and "+act.ref_table_a_1+".label = '"+act.ref_table_b_1+"'
                      and tredit_actions.value = "+act.ref_table_a_1+".ref_value
                      and tredits.id in ( select max(tredit2.id) from tredits tredit2 where tredit2.trfile_id = trfile2.id) ) v_"+act.id.to_s+" on trfiles.id = v_"+act.id.to_s+".trfile_id "
                      v_tracker_table_array.push(v_value_sql)

                    elsif !act.ref_table_a_1.blank?
                      v_value_sql = "LEFT JOIN  (select "+act.ref_table_a_1.pluralize.underscore+".description "+v_col+", trfile2.id  trfile_id from  trfiles trfile2, tredits , tredit_actions, "+act.ref_table_a_1.pluralize.underscore+" 
                      where trfile2.id = tredits.trfile_id 
                      and tredits.id = tredit_actions.tredit_id 
                      and tredit_actions.tractiontype_id = "+act.id.to_s+" 
                      and "+act.ref_table_a_1+".label = '"+act.ref_table_b_1+"'
                      and tredit_actions.value = "+act.ref_table_a_1.pluralize.underscore+".id
                      and tredits.id in ( select max(tredit2.id) from tredits tredit2 where tredit2.trfile_id = trfile2.id) ) v_"+act.id.to_s+" on trfiles.id = v_"+act.id.to_s+".trfile_id "
                      v_tracker_table_array.push(v_value_sql)

                    else
                      v_value_sql = "LEFT JOIN (select tredit_actions.value "+v_col+", trfile2.id  trfile_id from  trfiles trfile2, tredits , tredit_actions 
                      where trfile2.id = tredits.trfile_id 
                      and tredits.id = tredit_actions.tredit_id 
                      and tredit_actions.tractiontype_id = "+act.id.to_s+" 
                      and tredits.id in ( select max(tredit2.id) from tredits tredit2 where tredit2.trfile_id = trfile2.id) ) v_"+act.id.to_s+" on trfiles.id = v_"+act.id.to_s+".trfile_id "
                      v_tracker_table_array.push(v_value_sql)
                    end
                end
                # using LEFT JOIN
                v_tracker_sql = "( select "+v_tracker_column_array.join(',')+" from "+v_tracker_table_array.join('   ')+" where "+v_tracker_table_conditions.join(' and ') +" ) "

                @cg_tn.tn = v_tracker_sql +@cg_tn.alias
                @cg_tn.join_right = @cg_tn.alias+".vgroup_id = vgroups.id"
                @cg_tn.join_left ="LEFT JOIN "+v_tracker_sql +"  "+@cg_tn.alias+" on  vgroups.id = "+@cg_tn.alias+".vgroup_id"
                @local_tables_alias_hash[@cg_tn.tn] = @cg_tn.alias
                v_cg_tn_array.push(@cg_tn)                 

            else # just a regular table
                @cg_tn = CgTn.find(v_tn_id)  
                @cg_tn.alias = @cg_tn.tn
                v_cg_tn_array.push(@cg_tn)
                @local_tables_alias_hash[@cg_tn.tn] =  @cg_tn.alias
            end
            v_cg_tn_array.each do |tn_object| 
             @cg_tn = tn_object  
             # q_data are the questionaire forms -- hiding because of performance issues -- export in tab searches           
             if (@cg_tn.join_left).downcase.include?("vgroups.participant_id")
                   @q_data_tables_p_vg_hash[@cg_tn.id] ="participant"
             else
                   @q_data_tables_p_vg_hash[@cg_tn.id] ="not_participant"
             end
             if (!params[:cg_search][:include_tn].blank? and !params[:cg_search][:include_tn][v_tn_id ].blank?) or !params[:cg_search][:join_type][v_tn_id].blank? or (!params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank? and !params[:cg_search][:include_cn][v_tn_id].blank?) or  ( !params[:cg_search][:condition].blank? and !params[:cg_search][:condition][v_tn_id].blank? )  
                @cg_query_tn = CgQueryTn.new
                @cg_query_tn.cg_tn_id =v_tn_id
                @cg_query_tn.cg_query_id = @cg_query.id
                if !params[:cg_search][:include_tn].blank? and !params[:cg_search][:include_tn][v_tn_id ].blank?
                  @cg_query_tn.include_tn = 1
                end
                @cg_query_tn.join_type = params[:cg_search][:join_type][v_tn_id]
                if @cg_query_tn.join_type != 2 # exclude NOT IN
              ### getting populated elsewhere - only want ones which are included       @all_table_ids_in_query.push(v_tn_id)
                end

                if @cg_query_tn.join_type == 0  # inner join joins  
                    @table_types.push(@cg_tn.table_type)                     
                    @local_tables.push(@cg_tn.tn)  
                    @local_tables_alias_hash[@cg_tn.tn] =  @cg_tn.alias                         
                    @local_conditions.push(@cg_tn.join_right)
                    @all_table_ids_in_query.push(@cg_tn.id)
                 
                elsif @cg_query_tn.join_type == 2 # NOT IN , but also need an outer join if any cols selected 
                   # build up sql for vgroup not in 
                   # @cg_query_tn_not_in_hash 
                     if @cg_tn.join_left_parent_tn == "vgroups"
                       v_not_in_condition =" select not_in_"+v_tn_id.to_s+".id from "+@cg_tn.tn+","+@cg_tn.join_left_parent_tn+" not_in_"+v_tn_id.to_s+" where "+@cg_tn.join_right
                     else 
                       v_not_in_condition =" select not_in_"+v_tn_id.to_s+".vgroup_id from "+@cg_tn.tn+","+@cg_tn.join_left_parent_tn+" not_in_"+v_tn_id.to_s+" where "+@cg_tn.join_right
                      end
                   # need to add conditions to not_in_condition and divert from normal left join conditions
                    @cg_query_tn_not_in_hash[v_tn_id] = v_not_in_condition 
                   if !params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank?
      
                         # NEED TO DO OUTER JOIN 
                         @table_types.push(@cg_tn.table_type)
                            # need to add outer as part of table length !!!!! THIS HAS TO BE FIXED
                         if @local_tables.index(@cg_tn.join_left_parent_tn).blank?   # WHAT ABOUT ALIAS                        
                                  @local_tables.push(@cg_tn.join_left_parent_tn)  
                                  @local_tables_alias_hash[@cg_tn.join_left_parent_tn] =   @cg_tn.join_left_parent_tn                             
                         end
                         if ! @tables_left_join_hash[@cg_tn.join_left_parent_tn ].blank?
                              @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left+"  "+ @tables_left_join_hash[@cg_tn.join_left_parent_tn ]
                         else
                              @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left
                         end
                   end
                    
                elsif @cg_query_tn.join_type == 1  # outer join joins  # NEED PARENT TABLE join_left_parent_tn
                    @table_types.push(@cg_tn.table_type)
                    @all_table_ids_in_query.push(@cg_tn.id)
                            # need to add outer as part of table length !!!!! THIS HAS TO BE FIXED
                    if @local_tables.index(@cg_tn.join_left_parent_tn).blank?   # WHAT ABOUT ALIAS                        
                                  @local_tables.push(@cg_tn.join_left_parent_tn)  
                                  @local_tables_alias_hash[@cg_tn.join_left_parent_tn] =   @cg_tn.join_left_parent_tn                             
                    end
                    if ! @tables_left_join_hash[@cg_tn.join_left_parent_tn ].blank?
                        @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left+"  "+ @tables_left_join_hash[@cg_tn.join_left_parent_tn ]
                    else
                        @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left
                    end
                else # was doing inner join by default , change to outer #### 
                  if  !params[:cg_search][:join_type][v_tn_id].blank? or 
                    (!params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank?) or
                      (!params[:cg_search][:condition].blank? and !params[:cg_search][:condition][v_tn_id].blank?) # NEED TO ADD LIMIT BY CN
                      v_include_tn = "N"
                      if !params[:cg_search][:cn_id].blank? and !params[:cg_search][:cn_id][v_tn_id].blank?
                        params[:cg_search][:cn_id][v_tn_id].each do |tn_cn_id|
                           v_tn_cn_id = tn_cn_id.to_s
                           if (!params[:cg_search][:condition].blank? and !params[:cg_search][:condition][v_tn_id].blank? and !params[:cg_search][:condition][v_tn_id][v_tn_cn_id].blank?) or
                                 (!params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank? and !params[:cg_search][:include_cn][v_tn_id][v_tn_cn_id].blank? )
                             v_include_tn ="Y"
                           end  
                        end
                      end
                    if v_include_tn == "Y"   
                        @all_table_ids_in_query.push(@cg_tn.id)                 
                        if params[:cg_search][:join_type][v_tn_id].blank? and !@cg_tn.join_left.blank?  # setting default to outer join
                           @table_types.push(@cg_tn.table_type)
                                    # need to add outer as part of table length !!!!! THIS HAS TO BE FIXED
                            if @local_tables.index(@cg_tn.join_left_parent_tn).blank?   # WHAT ABOUT ALIAS                        
                                          @local_tables.push(@cg_tn.join_left_parent_tn) 
                                          @local_tables_alias_hash[@cg_tn.join_left_parent_tn] =   @cg_tn.join_left_parent_tn                                 
                            end
                            if ! @tables_left_join_hash[@cg_tn.join_left_parent_tn ].blank?
                                @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left+"  "+ @tables_left_join_hash[@cg_tn.join_left_parent_tn ]
                            else
                                @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left
                            end
                        else
                          @local_tables.push(@cg_tn.tn) # use uniq later
                          @local_tables_alias_hash[@cg_tn.tn] =   @cg_tn.alias   
                          @table_types.push(@cg_tn.table_type) # use uniq later  use mix of table_type to define core join
                                 # base, cg_enumber, cg_enumber_sp, cg_rmr, cg_rmr_sp, cg_sp, cg_wrapnum, cg_adrcnum, cg_reggieid
                           @local_conditions.push(@cg_tn.join_right) # use uniq later
                        end
                    end
                  end
                 end
               
               # trying to delete empty condition and join_type params to shorten the url in pagenation /Kaminari 
               # include_cn, value_# and others empty params being deleted below
               # could shorten names
               if params[:cg_search][:join_type][v_tn_id].blank?
                 params[:cg_search][:join_type].delete(v_tn_id)                 
               end
               if !params[:cg_search][:condition].blank?
                 if params[:cg_search][:condition][v_tn_id].blank?
                  #params[:cg_search][:condition].delete(v_tn_id)
                  # puts "aaaaaaaaaa"
                 else
                     params[:cg_search][:condition][v_tn_id].each do |temp_tn_cn_id|
                       v_temp_tn_cn_id = temp_tn_cn_id.to_s #to_a.to_s   not sure why .to_a was in there
                       if params[:cg_search][:condition][v_tn_id][v_temp_tn_cn_id].blank?
                         params[:cg_search][:condition][v_tn_id].delete(v_temp_tn_cn_id)
                       end
                     end
                 end
               end         
               # need hash with cg_tn_id as key
            #always save- for log    if params[:cg_search][:save_search] == "1"    
                  @cg_query_tn.save
             #  end
               @cg_query_tn_hash[v_tn_id] = @cg_query_tn
               if !params[:cg_search][:cn_id].blank? and !params[:cg_search][:cn_id][v_tn_id].blank?
                 params[:cg_search][:cn_id][v_tn_id].each do |tn_cn_id|
                   v_tn_cn_id = tn_cn_id.to_s                  
                   if (!params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank? and  !params[:cg_search][:include_cn][v_tn_id][v_tn_cn_id].blank?) or (!params[:cg_search][:condition].blank? and !params[:cg_search][:condition][v_tn_id].blank? and !params[:cg_search][:condition][v_tn_id][v_tn_cn_id].blank?)
                       @cg_tn_cn = CgTnCn.find(v_tn_cn_id)
                       @cg_query_tn_cn = CgQueryTnCn.new 
                       @cg_query_tn_cn.cg_tn_cn_id =v_tn_cn_id
                       if !params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank? and !params[:cg_search][:include_cn][v_tn_id][v_tn_cn_id].blank?
                         @cg_query_tn_cn.include_cn = 1
                         if @cg_tn_cn.q_data_form_id.blank? # q_data
                           @local_column_headers.push(@cg_tn_cn.export_name)
                           v_join_left_tn = @cg_tn.tn 
                           if @local_tables.index(@cg_tn.tn).blank?   # left join of left join?
                             v_join_left_tn = @cg_tn.join_left_parent_tn
                           end
                           if !@cg_tn_cn.ref_table_b.blank?  # LOOKUP_REFS and label= 
                             # problem with petscan/tracers and  alias -- picking up last 3 chars from @local_tables_alias_hash[@cg_tn.tn] and adding to lookup alias
                              v_unique = @local_tables_alias_hash[@cg_tn.tn].reverse[0...3].reverse
                              join_left = "LEFT JOIN (select lookup_refs.ref_value id_"+v_tn_cn_id.to_s+", lookup_refs.description a_"+v_tn_cn_id.to_s+"  
                                from  lookup_refs where   lookup_refs.label ='"+@cg_tn_cn.ref_table_b+"'  
                                ) cg_alias_"+v_tn_cn_id.to_s+v_unique+" on "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" = cg_alias_"+v_tn_cn_id.to_s+v_unique+".id_"+v_tn_cn_id.to_s 
                              
                              if !@tables_left_join_hash[v_join_left_tn ].blank?               
                                   @tables_left_join_hash[v_join_left_tn ] =  @tables_left_join_hash[v_join_left_tn ]+"  "+join_left
                              else
                                  @tables_left_join_hash[v_join_left_tn ] = join_left
                              end
                               @local_fields.push("cg_alias_"+v_tn_cn_id.to_s+v_unique+".a_"+v_tn_cn_id.to_s)
                           elsif !@cg_tn_cn.ref_table_a.blank? # camel case LookupPettracer to lookup_pettracers  - description
                              # problem with petscan/tracers and  alias -- picking up last 3 chars from @local_tables_alias_hash[@cg_tn.tn] and adding to lookup alias
                              v_unique = @local_tables_alias_hash[@cg_tn.tn].reverse[0...3].reverse
                              join_left = "LEFT JOIN (select "+@cg_tn_cn.ref_table_a.pluralize.underscore+".id id_"+v_tn_cn_id.to_s+", "+@cg_tn_cn.ref_table_a.pluralize.underscore+".description a_"+v_tn_cn_id.to_s+
                                      " from "+@cg_tn_cn.ref_table_a.pluralize.underscore+" ) cg_alias_"+v_tn_cn_id.to_s+v_unique+" on  "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" = cg_alias_"+v_tn_cn_id.to_s+v_unique+".id_"+v_tn_cn_id.to_s
                              if !@tables_left_join_hash[v_join_left_tn ].blank?               
                                    @tables_left_join_hash[v_join_left_tn] = @tables_left_join_hash[v_join_left_tn ]+"  "+join_left
                              else
                                    @tables_left_join_hash[v_join_left_tn ] = join_left
                              end
                               @local_fields.push("cg_alias_"+v_tn_cn_id.to_s+v_unique+".a_"+v_tn_cn_id.to_s)
                           else
                               @local_fields.push(@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn)
                           end
                         elsif !@cg_tn_cn.q_data_form_id.blank? and  @html_request =="N"  # need q_data
                           if @html_request =="N"
                               @local_fields.push(@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn)
                               @local_column_headers.push("q_data_form_"+@cg_tn_cn.q_data_form_id.to_s)
                               # WHAT ABOUT THE view into tables_local, join and left_join
                           end
                           # push col_header with form_id, push appt id linked to this form_id
                           v_join_left_tn = @cg_tn.tn
                           if @local_tables.index(@cg_tn.tn).blank?   # left join of left join?
                             v_join_left_tn = @cg_tn.join_left_parent_tn
                           end
                           @cg_search_q_data  ="Y"
                           # variables for run_search_q_data
                           @fields =[]
                           @fields_q_data =[]
                           @tables =[]
                           @left_join =[]
                           @left_join_q_data =[]
                           @column_headers =[]
                           @conditions = []
                           @left_join_vgroup = []
                           @column_headers_q_data =[]
                           @headers_q_data =[]
                                 
                           # trying to get secondary key in conditions
                           @conditions.concat(@conditions_bak)
                           # @conditions  captured above, after first set of form elements - mainly want sp limit
                           # define q_data form_id  
                           # pass to run_search_q_data and get back fields, columns_headers, conditions, etc.
                           @tables =[@cg_tn.tn]  # leaving alone @local_tables_alias_hash[ no q_data in pet
                           @q_form_id = @cg_tn_cn.q_data_form_id
   
                           @q_data_form_array.unshift(@q_form_id)                       
                          
                           (@fields,@tables, @left_join,@left_join_vgroup,@fields_q_data, @left_join_q_data,@headers_q_data) = run_search_q_data(@tables,@fields ,@left_join,@left_join_vgroup)                       

                           # put @q_form_id.to_s in array --- use as key
                           # make array of array for @left_join_vgroup,@fields_q_data, @left_join_q_data                      
                           @q_data_fields_hash[@q_form_id] = @fields_q_data
                           @q_data_left_join_hash[@q_form_id] = @left_join_q_data
                           @q_data_left_join_vgroup_hash[@q_form_id] = @left_join_vgroup
                           @q_data_headers_hash[@q_form_id] = @headers_q_data
                           @q_data_tables_hash[@q_form_id] = @tables
                           @fields_hash[@q_form_id] = @fields

    
                           # could there be multiple q_data forms???????
                           #NEED TO SPLIT OFF q_data sql , need to keep number tables in sql < 61 ( left joins up to 2 tables per leftjoin)
                           # get all results, index by link_id/link type in array, add fields, reuslts to end of query -- what if 2 form_id's-- keep adding in
                           # if > 25 , keep getting results and adding to array with same key
                    # get form_id named arrays - column names, results , leave question_field column as marker
                    # REMOVED q_form LH, NP, Q   data export from cg_search - view that joined all teh 3-question rows into one row took to long
                    # now can only export LH, NP, Q data is in the LH, NP, Q tabs
                    # also the form name/sp is only displayed in the LH,NP,Q tabs
           
                           # ??? PROBLEM WITH participant?
                           @left_join_vgroup.each do |vg|
                                if !@tables_left_join_hash["vgroups" ].blank?  and !@tables_left_join_hash[v_join_left_tn ].blank?             
                                      @tables_left_join_hash["vgroups"] = @tables_left_join_hash[v_join_left_tn ]+"  "+vg
                                else
                                      @tables_left_join_hash["vgroups" ] = vg
                                end  
    puts "AAAAA line 1408 vg left joins="+@tables_left_join_hash["vgroups" ]
                           end   
                           #### don't think this is needed@local_fields.concat(@fields)
                           @left_join.each do |lj|
                              if !@tables_left_join_hash[v_join_left_tn ].blank?               
                                    @tables_left_join_hash[v_join_left_tn] = @tables_left_join_hash[v_join_left_tn ]+"  "+lj
                              else
                                    @tables_left_join_hash[v_join_left_tn ] = lj
                              end
    puts "BBBBBB line 1417 other left join "+@tables_left_join_hash[v_join_left_tn ]
                           end 
                           @cg_search_q_data = nil                          
                         end
                       end
                       @cg_query_tn_cn.cg_query_tn_id =@cg_query_tn.id
                       if !params[:cg_search][:value_1].blank? and !params[:cg_search][:value_1][v_tn_id].blank?
                         @cg_query_tn_cn.value_1 = params[:cg_search][:value_1][v_tn_id][v_tn_cn_id]
                       end
                       if !params[:cg_search][:value_2].blank? and !params[:cg_search][:value_2][v_tn_id].blank?
                         @cg_query_tn_cn.value_2 = params[:cg_search][:value_2][v_tn_id][v_tn_cn_id]
                       end

                       # dates                
                       if !params[:cg_search][:value_1].blank? && !params[:cg_search][:value_1][v_tn_id].blank? && !params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(1i)"].blank? && !params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(2i)"].blank? && !params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(3i)"].blank?
                         v_value_1 = params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(1i)"] +"-"+params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(2i)"].rjust(2,"0")+"-"+params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(3i)"].rjust(2,"0")
                         @cg_query_tn_cn.value_1 = v_value_1
                         v_value_1 =""
                       end
                       if !params[:cg_search][:value_2].blank? && !params[:cg_search][:value_2][v_tn_id].blank? && !params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(1i)"].blank? && !params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(2i)"].blank? && !params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(3i)"].blank?
                           v_value_2 = params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(1i)"] +"-"+params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(2i)"].rjust(2,"0")+"-"+params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(3i)"].rjust(2,"0")
                           @cg_query_tn_cn.value_2 = v_value_2
                           v_value_2 =""
                       end     
                       if !params[:cg_search][:condition].blank? and  !params[:cg_search][:condition][v_tn_id].blank?
                         @cg_query_tn_cn.condition = params[:cg_search][:condition][v_tn_id][v_tn_cn_id]
                         # [['=','0'],['>=','1'],['<=','2'],['!=','3'],['between','4'],['is blank','5']]
                         if @cg_query_tn_cn.condition == 0 
                           # letting wrapno, reggieid, adrcnum be IN () condition
                           if !@cg_query_tn_cn.value_1.blank?
                               @cg_query_tn_cn.value_1 = @cg_query_tn_cn.value_1.gsub(/\xef\xbc\x8c/,',').gsub(/\\xef\\xbc\\x8c/,',') # utf-8 full width comma - ? coming from IE from excel?
                           end
                           if @cg_query_tn_cn.value_1.include?(',') and ((@cg_tn.tn+"."+@cg_tn_cn.cn) == "view_participants.wrapnum" or (@cg_tn.tn+"."+@cg_tn_cn.cn) == "view_participants.adrcnum" or (@cg_tn.tn+"."+@cg_tn_cn.cn) == "view_participants.reggieid" )
                              @cg_query_tn_cn.value_1 = @cg_query_tn_cn.value_1.gsub(/ /,'').gsub(/'/,'').gsub(/ /,'').gsub(/\t/,'').gsub(/\n/,'').gsub(/\r/,'')
                              @cg_query_tn_cn.value_1 = @cg_query_tn_cn.value_1.gsub(/,$/,"") # trailing comma
                              @cg_query_tn_cn.value_1 = @cg_query_tn_cn.value_1.gsub(/,/,"','")
                              v_condition =  " "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" in ( '"+@cg_query_tn_cn.value_1.gsub(/[;:"()=<>]/, '')+"')"
                           else
                              # letting : thru in seach on mri coil dropdown
                              v_condition =  " "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" = '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;"()=<>]/, '')+"'"
                           end
                           if !v_condition.blank?
                              if !params[:cg_search][:join_type][v_tn_id].blank? and params[:cg_search][:join_type][v_tn_id] == "2" 
                                 @cg_query_tn_not_in_hash[v_tn_id] = @cg_query_tn_not_in_hash[v_tn_id]+" and "+v_condition
                              else
                                  @local_conditions.push(v_condition)
                                  params["search_criteria"] = params["search_criteria"] +", "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" = "+@cg_query_tn_cn.value_1
                              end
                           end
                         elsif @cg_query_tn_cn.condition ==  1 and !@cg_query_tn_cn.value_1.nil?
                           v_condition =  " "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" >= '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' "
                           if !v_condition.blank?
                              if !params[:cg_search][:join_type][v_tn_id].blank? and params[:cg_search][:join_type][v_tn_id] == "2" 
                                 @cg_query_tn_not_in_hash[v_tn_id] = @cg_query_tn_not_in_hash[v_tn_id]+" and "+v_condition
                              else
                                  @local_conditions.push(v_condition)
                                  params["search_criteria"] = params["search_criteria"] +", "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" >= "+@cg_query_tn_cn.value_1
                              end
                           end
                         elsif @cg_query_tn_cn.condition == 2 and !@cg_query_tn_cn.value_1.nil?
                           v_condition =  " "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" <= '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' "
                           if !v_condition.blank?
                              if !params[:cg_search][:join_type][v_tn_id].blank? and params[:cg_search][:join_type][v_tn_id] == "2" 
                                 @cg_query_tn_not_in_hash[v_tn_id] = @cg_query_tn_not_in_hash[v_tn_id]+" and "+v_condition
                              else
                                 @local_conditions.push(v_condition)
                                 params["search_criteria"] = params["search_criteria"] +", "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" <= "+@cg_query_tn_cn.value_1
                              end
                           end
                         elsif @cg_query_tn_cn.condition == 3 and !@cg_query_tn_cn.value_1.nil?
                           v_condition =  " (if("+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" IS NULL,'',"+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+") )  != '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' "
                           if !v_condition.blank?
                              if !params[:cg_search][:join_type][v_tn_id].blank? and params[:cg_search][:join_type][v_tn_id] == "2" 
                                 @cg_query_tn_not_in_hash[v_tn_id] = @cg_query_tn_not_in_hash[v_tn_id]+" and "+v_condition
                              else
                                @local_conditions.push(v_condition)
                                params["search_criteria"] = params["search_criteria"] +", "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" != "+@cg_query_tn_cn.value_1      
                              end                     
                           end
                         elsif @cg_query_tn_cn.condition == 4 and !@cg_query_tn_cn.value_1.nil?  and !@cg_query_tn_cn.value_2.nil?
                           v_condition =  " "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" between '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' and '"+ @cg_query_tn_cn.value_2.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' "
                           if !v_condition.blank?
                              if !params[:cg_search][:join_type][v_tn_id].blank? and params[:cg_search][:join_type][v_tn_id] == "2" 
                                 @cg_query_tn_not_in_hash[v_tn_id] = @cg_query_tn_not_in_hash[v_tn_id]+" and "+v_condition
                              else
                                @local_conditions.push(v_condition)
                                params["search_criteria"] = params["search_criteria"] +", "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" between "+@cg_query_tn_cn.value_1+" and "+ @cg_query_tn_cn.value_2
                              end      
                           end
                         elsif @cg_query_tn_cn.condition == 5
                           v_condition = " ( trim( "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+") is NULL or trim( "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+") = '' ) "
                           if !v_condition.blank?
                              if !params[:cg_search][:join_type][v_tn_id].blank? and params[:cg_search][:join_type][v_tn_id] == "2" 
                                 @cg_query_tn_not_in_hash[v_tn_id] = @cg_query_tn_not_in_hash[v_tn_id]+" and "+v_condition
                              else
                                @local_conditions.push(v_condition)
                                params["search_criteria"] = params["search_criteria"] +", "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" is blank"
                              end
                           end
                         elsif @cg_query_tn_cn.condition == 6
                           v_condition = " trim( "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+") is NOT NULL and  trim( "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+")  != '' "
                           if !v_condition.blank?
                              if !params[:cg_search][:join_type][v_tn_id].blank? and params[:cg_search][:join_type][v_tn_id] == "2" 
                                 @cg_query_tn_not_in_hash[v_tn_id] = @cg_query_tn_not_in_hash[v_tn_id]+" and "+v_condition
                              else
                                @local_conditions.push(v_condition)
                                params["search_criteria"] = params["search_criteria"] +", "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" is not blank "
                              end  
                           end  
                         elsif @cg_query_tn_cn.condition == 7 and !@cg_query_tn_cn.value_1.nil?
                           v_condition = "  "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" like '%"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"%' "
                           if !v_condition.blank?
                              if !params[:cg_search][:join_type][v_tn_id].blank? and params[:cg_search][:join_type][v_tn_id] == "2" 
                                 @cg_query_tn_not_in_hash[v_tn_id] = @cg_query_tn_not_in_hash[v_tn_id]+" and "+v_condition
                              else
                                @local_conditions.push(v_condition)
                                params["search_criteria"] = params["search_criteria"] +", "+@local_tables_alias_hash[@cg_tn.tn]+"."+@cg_tn_cn.cn+" contains "+@cg_query_tn_cn.value_1
                              end
                           end
                         end
                       end            
                     
                       # always save for logging if params[:cg_search][:save_search] == "1"    
                          @cg_query_tn_cn.save
                       #end
                       @cg_query_cn_hash[v_tn_cn_id] = @cg_query_tn_cn  
                       if !params[:cg_search][:condition].blank? and !params[:cg_search][:condition][v_tn_id].blank? and ( params[:cg_search][:condition][v_tn_id][v_tn_cn_id].blank? or params[:cg_search][:condition][v_tn_id][v_tn_cn_id] == "") and (!params[:cg_search][:include_cn][v_tn_id].blank? and (params[:cg_search][:include_cn][v_tn_id][v_tn_cn_id].blank? or params[:cg_search][:include_cn][v_tn_id][v_tn_cn_id] == "" ))
                           params[:cg_search][:cn_id][v_tn_id].delete(v_tn_cn_id)
                       end
                       if !params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank? 
                         if params[:cg_search][:include_cn][v_tn_id][v_tn_cn_id].blank?
                           params[:cg_search][:include_cn][v_tn_id].delete(v_tn_cn_id)
                         end
                       else
                         if !params[:cg_search][:include_cn].blank?
                             params[:cg_search][:include_cn].delete(v_tn_id)
                         end
                       end
                       if !params[:cg_search][:condition].blank? and !params[:cg_search][:condition][v_tn_id].blank?
                         #puts "params[:cg_search][:condition][v_tn_id][v_tn_cn_id] ="+params[:cg_search][:condition][v_tn_id][v_tn_cn_id]
                         if params[:cg_search][:condition][v_tn_id][v_tn_cn_id].blank?
                            params[:cg_search][:condition][v_tn_id].delete(v_tn_cn_id)
                         elsif params[:cg_search][:condition][v_tn_id][v_tn_cn_id] == ""
                                params[:cg_search][:condition][v_tn_id].delete(v_tn_cn_id)
                         end
                       else
                         if !params[:cg_search][:condition].blank? and params[:cg_search][:condition][v_tn_id].blank?
                             params[:cg_search][:condition].delete(v_tn_id)
                         end
                       end
                       if !params[:cg_search][:value_1].blank? and !params[:cg_search][:value_1][v_tn_id].blank? 
                         if params[:cg_search][:value_1][v_tn_id][v_tn_cn_id].blank?
                           params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id)
                         elsif params[:cg_search][:value_1][v_tn_id][v_tn_cn_id] == ""
                                params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id)
                         end
                         if params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(1i)"].blank?
                           params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(1i)")
                         elsif params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(1i)"] == ""
                          params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(1i)")                           
                         end
                         if params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(2i)"].blank?
                               params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(2i)")
                         elsif params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(2i)"] == ""
                              params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(2i)")                           
                         end
                         if params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(3i)"].blank?
                             params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(3i)")
                         elsif params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(3i)"] == ""
                            params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(3i)")                           
                         end                      
                       end
                       if !params[:cg_search][:value_2].blank? and !params[:cg_search][:value_2][v_tn_id].blank? 
                         if params[:cg_search][:value_2][v_tn_id][v_tn_cn_id].blank?
                            params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id)
                         elsif params[:cg_search][:value_2][v_tn_id][v_tn_cn_id] == ""
                          params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id)
                         end
                        
                         if params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(1i)"].blank?
                            params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(1i)")
                         elsif params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(1i)"] == ""
                           params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(1i)")                           
                         end
                         if params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(2i)"].blank?
                                params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(2i)")
                         elsif params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(2i)"] == ""
                               params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(2i)")                           
                         end
                         if params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(3i)"].blank?
                              params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(3i)")
                         elsif params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(3i)"] == ""
                             params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(3i)")                           
                         end                        
                       end
                       
                    else # another set of deletes
                       # :conditions seems to be needed
                       
                       if !params[:cg_search][:value_1].blank? and !params[:cg_search][:value_1][v_tn_id].blank? 
                         if params[:cg_search][:value_1][v_tn_id][v_tn_cn_id].blank?
                            params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id)
                         elsif params[:cg_search][:value_1][v_tn_id][v_tn_cn_id] == ""
                                 params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id)
                         end
                         if params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(1i)"].blank?
                            params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(1i)")
                          elsif params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(1i)"] == ""
                           params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(1i)")                           
                          end
                          if params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(2i)"].blank?
                                params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(2i)")
                          elsif params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(2i)"] == ""
                               params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(2i)")                           
                          end
                          if params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(3i)"].blank?
                              params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(3i)")
                          elsif params[:cg_search][:value_1][v_tn_id][v_tn_cn_id+"(3i)"] == ""
                             params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id+"(3i)")                           
                          end                      
                       end
                       if !params[:cg_search][:value_2].blank? and !params[:cg_search][:value_2][v_tn_id].blank? 
                          if params[:cg_search][:value_2][v_tn_id][v_tn_cn_id].blank?
                             params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id)
                          elsif params[:cg_search][:value_2][v_tn_id][v_tn_cn_id] == ""
                           params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id)
                          end

                          if params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(1i)"].blank?
                             params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(1i)")
                           elsif params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(1i)"] == ""
                            params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(1i)")                           
                           end
                           if params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(2i)"].blank?
                                 params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(2i)")
                           elsif params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(2i)"] == ""
                                params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(2i)")                           
                           end
                           if params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(3i)"].blank?
                               params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(3i)")
                           elsif params[:cg_search][:value_2][v_tn_id][v_tn_cn_id+"(3i)"] == ""
                              params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id+"(3i)")                           
                           end                        
                       end
                    end  
                    if !params[:cg_search].blank? and !params[:cg_search][:include_tn].blank? and params[:cg_search][:include_tn][v_tn_id].blank?
                       params[:cg_search][:include_tn].delete(v_tn_id)   
                    end
                 end
               end
               @cg_query_tn_cn_hash[v_tn_id] = @cg_query_cn_hash
               # trying to delete more params to shorten url -- might be able to shorten url  some more -- more deletes, shorter var name
             else  # try deleting empty params
               if !params[:cg_search][:cn_id][v_tn_id].blank?
                 params[:cg_search][:cn_id][v_tn_id].each do |tn_cn_id|
                    v_tn_cn_id = tn_cn_id.to_s
                    if !params[:cg_search][:condition].blank? and !params[:cg_search][:condition][v_tn_id].blank? and !params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank?
                      if (( params[:cg_search][:condition][v_tn_id][v_tn_cn_id].blank? or params[:cg_search][:condition][v_tn_id][v_tn_cn_id] == "") and params[:cg_search][:include_cn][v_tn_id][v_tn_cn_id].blank? )                   
                       params[:cg_search][:cn_id][v_tn_id].delete(v_tn_cn_id.to_s)
                       params[:cg_search][:cn_id][v_tn_id].delete(v_tn_cn_id)
                       params[:cg_search][:condition][v_tn_id].delete(v_tn_cn_id.to_s)
                       params[:cg_search][:condition][v_tn_id].delete(v_tn_cn_id)
                       if !params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank? 
                          if params[:cg_search][:include_cn][v_tn_id][v_tn_cn_id].blank?
                              params[:cg_search][:include_cn][v_tn_id].delete(v_tn_cn_id)
                          end
                         end
                        if !params[:cg_search][:value_1].blank? and !params[:cg_search][:value_1][v_tn_id].blank? 
                          if params[:cg_search][:value_1][v_tn_id][v_tn_cn_id].blank?
                              params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id)
                          elsif params[:cg_search][:value_1][v_tn_id][v_tn_cn_id] == ""
                              params[:cg_search][:value_1][v_tn_id].delete(v_tn_cn_id)
                          end
                         end
                         if !params[:cg_search][:value_2].blank? and !params[:cg_search][:value_2][v_tn_id].blank? 
                           if params[:cg_search][:value_2][v_tn_id][v_tn_cn_id].blank?
                               params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id)
                           elsif params[:cg_search][:value_2][v_tn_id][v_tn_cn_id] == ""
                             params[:cg_search][:value_2][v_tn_id].delete(v_tn_cn_id)
                           end
                          end
                      end 
                    end
                  end
                end
               
                if !params[:cg_search].blank? and  !params[:cg_search][:join_type].blank? and params[:cg_search][:join_type][v_tn_id].blank?
                     params[:cg_search][:join_type].delete(v_tn_id)
                end                     
             end
             # trying to reduce number of params if blank -- afraid url will get to long in pageation and download
             if params[:cg_search][:rmr].blank?
                  params[:cg_search].delete('rmr')
             end

             if params[:cg_search][:enumber].blank?
                  params[:cg_search].delete('enumber')
             end

             if params[:cg_search][:gender].blank?
                  params[:cg_search].delete('gender')
             end

             if params[:cg_search][:min_age].blank?
                  params[:cg_search].delete('min_age')
             end

             if params[:cg_search][:max_age].blank?
                  params[:cg_search].delete('max_age')
             end
             if !params[:cg_search][:include_tn].blank?
               params[:cg_search][:include_tn].delete(v_tn_id) 
               params[:cg_search][:include_tn].delete(v_tn_id.to_s)
             end
           end

             if !@cg_query_tn_not_in_hash[v_tn_id].nil?
                            v_not_in_condition = " vgroups.id not in ("+@cg_query_tn_not_in_hash[v_tn_id]+")"
                            @local_conditions.push(v_not_in_condition)
                            params["search_criteria"] = params["search_criteria"] +", NOT IN ("+CgTn.find(v_tn_id).tn+")"
             end  

          end 
         end
       end
      end 

      if !params[:cg_search].blank? and !params[:cg_search][:include_tn].blank?
        params[:cg_search].delete('include_tn') 
      end
      
      
      @sp_array.push("-1") # need something in the array
      v_log_flag ="N"
       # for stored query drop down
      sql = "select  concat(cg_name,' - ',users.username,' - ', date_format(cg_queries.created_at,'%Y %m %d')) name,cg_queries.id  
      from cg_queries, users where status_flag != 'N' and cg_queries.user_id = users.id  and log_flag ='"+v_log_flag+"' 
         order by save_flag desc, users.username, date_format(cg_queries.created_at,'%Y %m %d') desc"
      if !params[:admin_query_check].nil? and !params[:admin_query_check][:user_id].blank? 
         v_log_flag ="Y" # getting saved and logged - not re-logging saved
         sql = "select  concat(users.username,' - ', date_format(cg_queries.created_at,'%Y %m %d'),'-',cg_queries.id) name,cg_queries.id  
         from cg_queries, users where status_flag != 'N' and cg_queries.user_id = users.id  
         and cg_queries.user_id = "+params[:admin_query_check][:user_id]+"
         order by save_flag desc, users.username, date_format(cg_queries.created_at,'%Y %m %d') desc"
      end
      connection = ActiveRecord::Base.connection();
      @results_stored_search = connection.execute(sql)
      @data_for_select_stored_search = @results_stored_search.each { |hash| [hash[0], hash[1]] }
      
      # trim leading ","
      params["search_criteria"] = params["search_criteria"].sub(", ","")
       if v_debug == "Y" and @table_types.blank?
            puts "DDDDDDDD @table_types blank"
       end 

     # not sure how to use this with base vs column_group or other -- if no table_type, sql is not run below
     #mysql 5.7 only allows order by on fields which are in the select statement
     # can get around the by having a select distinct val1 from ( select val1, orderby2 from all stuff order by orderby2)
     # not sure how the 
      if !@table_types.blank? # and !@table_types.index('base').blank?  # extend to cg_enumber, cg_enumber_sp, cg_rmr, cg_rmr_sp, cg_sp, cg_wrapnum, cg_adrcnum, cg_reggieid  
        @table_types.push('base')    
        @local_tables.push("vgroups")
        @local_tables_alias_hash["vgroups"] =   "vgroups" 
        @local_tables.push("appointments") # --- include in mri, pet, lp, lh, q views -- need for other limits -- ? switch to vgroup?
        @local_tables_alias_hash["appointments"]
        @local_tables.push("scan_procedures")
        @local_tables_alias_hash["scan_procedures"]
        @local_tables.push("scan_procedures_vgroups")
        @local_tables_alias_hash["scan_procedures_vgroups"]
        @fields_front =[]
        if !@cg_query.participant_centric.nil? and ( @cg_query.participant_centric == "1" or @cg_query.participant_centric == "2" ) and @local_fields.length() > 0
           # do not want to add vgroup centric columns
           # not working yet  @order_by =[]   # newer version of mysql 5.7 in dev? only do order by on columns in select? 
             # breaks all the longitudinal stuff
        else
            @fields_front.push("vgroups.id vgroup_id")
            @fields_front.push("vgroups.vgroup_date")
            @fields_front.push("vgroups.rmr")
           # not working yet, reverting to previous with @order_by defined line 1815 @order_by =["vgroups.vgroup_date DESC", "vgroups.rmr"]  # newer version of mysql 5.7 in dev? only do order by on columns in select?
        end
        @local_fields = @fields_front.concat(@local_fields)
        #@local_conditions.push("vgroups.id = appointments.vgroup_id")
        @local_conditions.push("scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") ")
        @local_conditions.push("scan_procedures.id = scan_procedures_vgroups.scan_procedure_id")
        @local_conditions.push("scan_procedures_vgroups.vgroup_id = vgroups.id")
        @local_conditions.push("appointments.vgroup_id = vgroups.id")
                                            # everything always joined
        # undoing - need in mysql 5.6
        @order_by =["vgroups.vgroup_date DESC", "vgroups.rmr"] # newer version of mysql in dev? only do orderby on columns in select?
     
        #run_search_q_data tn_cn_id/tn_id in (686/676,687/677,688/688) common_name = "question fields" vs run_search if 
      end     
      if !@cg_query.participant_centric.nil? and @cg_query.participant_centric == "1"  and @local_fields.length() > 0
          @local_column_headers.delete_at(@local_column_headers.index("Date (vgroup)"))
          @local_column_headers.delete_at(@local_column_headers.index("Protocol"))
          @local_column_headers.delete_at(@local_column_headers.index("Enumber"))
          @local_column_headers.delete_at(@local_column_headers.index("RMR"))
      end
      if !@cg_query.participant_centric.nil? and @cg_query.participant_centric == "2"  and @local_fields.length() > 0
          @local_column_headers.delete_at(@local_column_headers.index("Date (vgroup)"))
          @local_column_headers.delete_at(@local_column_headers.index("Protocol"))
         # @local_column_headers.delete_at(@local_column_headers.index("Enumber"))
          @local_column_headers.delete_at(@local_column_headers.index("RMR"))
      end
      if !@cg_query.participant_centric.nil? and ( @cg_query.participant_centric == "1" or @cg_query.participant_centric == "2" )   and @local_fields.length() > 0 and !params[:longitudinal].nil? and params[:longitudinal] == "Y"
                @local_fields = ["vgroups.participant_id"].concat(@local_fields)   # for @cg_query.participant_centric == "2" adding leading vgroups.participant_id - could trailing  vgroups.participant_id be used instead
      end
      @column_number =   @local_column_headers.size
      if v_debug == "Y"
          puts "hhhhhhhhh line 1808"
      end
      if v_debug == "Y" and params[:cg_search].blank?
            puts "hhhhhhhhh params[:cg_search]  blank "
      end
      if v_debug == "Y" and @table_types.blank?
             puts " hhhhhhhh @table_types   blank"
      end
      if v_debug == "Y" and @table_types.index('base').blank?
           puts "hhhhhhh @table_types.index('base') blank"
      end
  if !params[:cg_search].blank? and !@table_types.blank? and !@table_types.index('base').blank?
    if v_debug == "Y"
        puts "jjjjjjjj line 1849"
    end

    @local_conditions.delete_if {|x| x == "" }   # a blank getting inserted 
   # moved further down - hide cols sql = " select distinct "+@local_fields.join(',')+" from "
    @all_tables = []
    # participant_centic order by 
    if !@cg_query.participant_centric.nil? and ( @cg_query.participant_centric == "1" or @cg_query.participant_centric == "2" )   and @local_fields.length() > 0
       @all_table_ids_in_query.uniq.each do |r|
             v_cg_tn_cns = CgTnCn.where("cg_tn_id in (?) and order_by_flag in (?)",r,'Y')
             v_cg_tn_cns.each do |n|   # need to only include tables which are in tn_id in select  #ERROR!!!
                     v_temp_tn = CgTn.find(n.cg_tn_id)
                     @order_by = [v_temp_tn.tn+"."+n.cn+" DESC"].concat(@order_by)  # might be problem if alias is used
             end
       end
    end
    # ADDING A JOIN ON THE SECONDARY KEY - Will nor probably work for alias or trackers 
    # always expect column called secondary_key
    v_includes_view_mri_appts = "N"
    v_includes_hide_date_tns  = "N"
    v_tn_cn_match_mri_path_array = []
    v_table_type_hide_date_array = []
    v_table_types = CgTableType.where(" hide_date_flag = 'Y'")
    v_table_types.each do |tt|
         v_table_type_hide_date_array.push(tt.table_type)
    end 

    # adding in secondary key and path like to inner joins
    # changing outer join if has a path like -- also then changing for the outer join to include secondary key
    # I think the secondary key and path like always/usually happen together
    # this is a mess based on asumptions
    #  but seems to be working 
    # weird part is changing the outer joins from vgroups to view_mri_appts

 # add in secondary_key_protocol -- 
        @tables_secondary_key_protocol = CgTn.where("cg_tns.id  in (?) and cg_tns.id in (select cg_tn_cns.cg_tn_id from cg_tn_cns where cg_tn_cns.secondary_key_protocol_flag = 'Y')",  @all_table_ids_in_query).order("cg_tns.display_order")  
        if @tables_secondary_key_protocol.count > 1
           v_key_protocol_cnt = 0
           v_key_protocol_base_table = ""
           v_key_protocol_base_col = ""
           v_key_protocol_next_table = ""
           v_key_protocol_next_col = ""
           @tables_secondary_key_protocol.each do |tn|
              if v_key_protocol_cnt < 1
                v_key_protocol_cnt = v_key_protocol_cnt +1
                v_key_protocol_base_table = tn.tn
                v_cn_secondary_key_protocol = CgTnCn.where("cg_tn_id in (?) and secondary_key_protocol_flag = 'Y' ",tn.id)
                v_key_protocol_base_col = v_cn_secondary_key_protocol.first.cn
               else
                  v_key_protocol_cnt = v_key_protocol_cnt +1
                v_key_protocol_next_table = tn.tn
                v_cn_secondary_key_protocol = CgTnCn.where("cg_tn_id in (?) and secondary_key_protocol_flag = 'Y' ",tn.id)
                v_key_protocol_next_col = v_cn_secondary_key_protocol.first.cn
              v_secondary_key_protocol_join =" coalesce("+v_key_protocol_base_table+"."+v_key_protocol_base_col+","+v_key_protocol_next_table+"."+v_key_protocol_next_col+",'') = coalesce("+v_key_protocol_next_table+"."+v_key_protocol_next_col+","+v_key_protocol_base_table+"."+v_key_protocol_base_col+",'') "        
              @local_conditions.push(v_secondary_key_protocol_join) 
               end
           end
        end
       
                 # add in secondary_key_visitno
        @tables_secondary_key_visitno = CgTn.where("cg_tns.id  in (?) and cg_tns.id in (select cg_tn_cns.cg_tn_id from cg_tn_cns where cg_tn_cns.secondary_key_visitno_flag = 'Y')", @all_table_ids_in_query).order("cg_tns.display_order") 
        if @tables_secondary_key_visitno.count > 1
           v_key_visitno_cnt = 0
           v_key_visitno_base_table = ""
           v_key_visitno_base_col = ""
           v_key_visitno_next_table = ""
           v_key_visitno_next_col = ""
           @tables_secondary_key_visitno.each do |tn|
              if v_key_visitno_cnt < 1
                v_key_visitno_cnt = v_key_visitno_cnt +1
                v_key_visitno_base_table = tn.tn
                v_cn_secondary_key_visitno = CgTnCn.where("cg_tn_id in (?) and secondary_key_visitno_flag = 'Y' ",tn.id)
                v_key_visitno_base_col = v_cn_secondary_key_visitno.first.cn
               else
                  v_key_visitno_cnt = v_key_visitno_cnt +1
                v_key_visitno_next_table = tn.tn
                v_cn_secondary_key_visitno = CgTnCn.where("cg_tn_id in (?) and secondary_key_visitno_flag = 'Y' ",tn.id)
                v_key_visitno_next_col = v_cn_secondary_key_visitno.first.cn
              v_secondary_key_visitno_join =" coalesce("+v_key_visitno_base_table+"."+v_key_visitno_base_col+","+v_key_visitno_next_table+"."+v_key_visitno_next_col+",'') = coalesce("+v_key_visitno_next_table+"."+v_key_visitno_next_col+","+v_key_visitno_base_table+"."+v_key_visitno_base_col+",'') "
              @local_conditions.push(v_secondary_key_visitno_join) 
               end
           end
        end

     # secondary_ket likes coalesce( col, ''), but the secondary_key_protocol/visitno likes coalesce(col1,col2,'') ???? why ????
    @all_table_ids_in_query.uniq.each do |r|
        v_temp_tn = CgTn.find(r)
        if v_temp_tn.secondary_key_flag == "Y"
            @tables_secondary_key_join_hash[v_temp_tn.tn] = " coalesce(view_mri_appts.secondary_key,'') = coalesce("+v_temp_tn.tn+".secondary_key,'') "
        end

        if  (@local_tables.include?v_temp_tn.tn) or  v_temp_tn.tn == 'view_mri_appts'  
           if v_temp_tn.secondary_key_flag == "Y"
              v_secondary_key_join =" coalesce(appointments.secondary_key,'') = coalesce("+v_temp_tn.tn+".secondary_key,'') "
              @local_conditions.push(v_secondary_key_join) 
           end
        else 
           # need to add to outer join
        end
        # if include mri table, and table with a column with match_mri_path_flag 
        if v_temp_tn.tn == 'view_mri_appts'
             v_includes_view_mri_appts = "Y"
        end
        if (v_table_type_hide_date_array.include? v_temp_tn.table_type)
          v_includes_hide_date_tns  = "Y"
        end
        v_tmp_tn_cns = CgTnCn.where("cg_tn_id in (?) and match_mri_path_flag ='Y' ",v_temp_tn.id)
        v_tmp_tn_cns.each do |cn|
              v_tn_cn_match_mri_path_array.push(v_temp_tn.tn+"."+cn.cn)
        end
    end 
    if v_includes_view_mri_appts == "Y"   # ACTING AS INNER JOIN, NEED TO MAKE OUTER ?????
         v_tn_cn_match_mri_path_array.uniq.each do |tn_cn|
            v_temp_split = tn_cn.split(".")
            if (@local_tables.include?v_temp_split[0])
                # this gets rid of matches between dual enrollments -- pdt and lead etc.
               v_mri_path_match_join = " view_mri_appts.path LIKE CONCAT('%',substring("+tn_cn+",1,6),'%') "
               @local_conditions.push(v_mri_path_match_join ) 
            else 
               # need to add to outer join --- move 
               # LEFT JOIN cg_rbm_icv on vgroups.id in ( select spv2.vgroup_id from scan_procedures_vgroups spv2 where spv2.scan_procedure_id = cg_rbm_icv.scan_procedure_id and spv2.vgroup_id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships where enrollment_vgroup_memberships.enrollment_id = cg_rbm_icv.enrollment_id))  
               # to view_mri_appts
               # if secondary key, if path match
               # add
               #     and  view_mri_appts.path LIKE CONCAT('%',substring(cg_rbm_icv.subjectid,1,6),'%')  
               #     and coalesce(view_mri_appts.secondary_key,'') = coalesce(cg_rbm_icv.secondary_key,'')
               # THIS IS WHERE THE DOUBLE LEFT JOIN S ARE COMING FROM
               @local_tables.uniq.each do |tn|
                       if !@tables_left_join_hash[tn].nil? and @tables_left_join_hash[tn].include? "LEFT JOIN "+v_temp_split[0]+" on vgroups.id"
                           v_left_join_temp = @tables_left_join_hash[tn].split("LEFT JOIN")
                           @tables_left_join_hash[tn] = ""
                           v_replaced = ""
                           v_left_join_temp.each do |lj|
                               lj = "LEFT JOIN"+lj
                               if lj.include? "LEFT JOIN "+v_temp_split[0]+" on"
                                  v_replaced = v_replaced +" "+lj.gsub("LEFT JOIN "+v_temp_split[0]+" on vgroups.id", "LEFT JOIN "+v_temp_split[0]+" on view_mri_appts.mri_vgroup_id")
                                  v_replaced = v_replaced +" and view_mri_appts.path LIKE CONCAT('%',substring("+tn_cn+",1,6),'%') "
                                  if !@tables_secondary_key_join_hash[v_temp_split[0]].nil?
                                     v_replaced = v_replaced +" and "+@tables_secondary_key_join_hash[v_temp_split[0]]
                                  end
                               end
                           end
                           v_left_join_temp.each do |lj|
                               lj = "LEFT JOIN"+lj
                               if lj.include? "LEFT JOIN "+v_temp_split[0]+" on" or lj.strip == "LEFT JOIN"
                                # don't do anything 
                               elsif lj.include? "LEFT JOIN view_mri_appts"
                                     @tables_left_join_hash[tn] = @tables_left_join_hash[tn]+" "+lj+" "+v_replaced
                               else
                                    @tables_left_join_hash[tn] = @tables_left_join_hash[tn]+" "+lj
                               end
                           end
                      end
              end

            end
         end
         # need same thing for path and secondary key
    end
             # putting participant_id out front to get enumber 
  if !@cg_query.participant_centric.nil? and @cg_query.participant_centric == "2"
        @local_fields.unshift("vgroups.participant_id as p_id")  # might have been able to use vgroups.participant_id ==> the last column in participant_centric's ???/
  end

    if v_includes_hide_date_tns  == "Y"
        # need to exclude hide columns   # format tn.cn # up tables hide other date columns
       #Problem with vgroup date 
        @local_fields_chop = @local_fields.dup  
         # copy array with .dup but as new array, else deleteing from array messes with loop
        @local_fields_chop.each do |lf|
            v_temp_split = lf.split(".")
            v_temp_tn = CgTn.where("tn in (?)",v_temp_split[0])
            if !v_temp_tn.nil? and !v_temp_tn.first.blank?
               v_temp_cn = CgTnCn.where("cg_tn_id in (?) and  cn in (?) and hide_column_flag = 'Y' and status_flag ='Y'", v_temp_tn.first.id,v_temp_split[1])
               if !v_temp_cn.nil? and !v_temp_cn.first.blank?
                  v_name_hide =v_temp_cn.first.export_name
                  v_index_hide =@local_column_headers.index(v_name_hide)
                  if v_name_hide == "Date (vgroup)" and v_index_hide == 0
                      # Date (vgroup) is still showing in the out put
                      # this delete skip doesn't seem to do anything
                      # more problem if vgroups date checked 
                  else
                     if(!v_index_hide.nil? ) 
                        @local_column_headers.delete_at(v_index_hide)
                        v_index_local_field =@local_fields.index(lf)
                        @local_fields.delete_at(v_index_local_field)
                     end
                  end
               end
            end
        end
        sql = " select distinct "+@local_fields.join(',')+" from "
    else
        sql = " select distinct "+@local_fields.join(',')+" from "
    end
    
    @local_tables.uniq.each do |tn|   # need left join right after parent tn
       v_tn = tn
       if !@tables_left_join_hash[tn].blank?
          v_tn = v_tn +" "+ @tables_left_join_hash[tn] 
       end
       @all_tables.push(v_tn)
    end
    sql = sql + @all_tables.uniq.join(", ")
    sql = sql + " where "+ @local_conditions.uniq.join(" and ")
    sql = sql+" order by "+@order_by.join(",")
    @sql = sql
    v_sql_log = sql.gsub("'","")
    if !v_sql_log[11911..15880].nil?
       sql_log = "insert into cg_query_log(user_id,created_at,updated_at,sql_text,sql_text_2,sql_text_3,sql_text_4)values('"+@user.id.to_s+"',NOW(),NOW(),'"+v_sql_log[0..3970]+"','"+v_sql_log[3971..7940]+"','"+v_sql_log[7941..11910]+"','"+v_sql_log[11911..15880]+"')"
     elsif !v_sql_log[7941..11910].nil?
       sql_log = "insert into cg_query_log(user_id,created_at,updated_at,sql_text,sql_text_2,sql_text_3)values('"+@user.id.to_s+"',NOW(),NOW(),'"+v_sql_log[0..3970]+"','"+v_sql_log[3971..7940]+"','"+v_sql_log[7941..11910]+"')"
     elsif !v_sql_log[3971..7940].nil?
        sql_log = "insert into cg_query_log(user_id,created_at,updated_at,sql_text,sql_text_2)values('"+@user.id.to_s+"',NOW(),NOW(),'"+v_sql_log[0..3970]+"','"+v_sql_log[3971..7940]+"')"
     else
        sql_log = "insert into cg_query_log(user_id,created_at,updated_at,sql_text)values('"+@user.id.to_s+"',NOW(),NOW(),'"+v_sql_log[0..3970]+"')"
     end
       




    @results_log = connection.execute(sql_log)
    # run the sql ==>@results, after some substitutions

    if !params[:cg_search].blank? and !params[:cg_search][:series_description_type_id].blank? and !params[:cg_search][:image_dataset_file].blank?

      # image_datasets
      # get list of columns from ids_search
      # @column_headers_ids = ['Date','Protocol','Enumber','RMR','series_description','dicom_series_uid','dcm_file_count','timestamp','scanned_file','image_uid','id','rep_time','glob','path','bold_reps', 'mri_coil_name','slices_per_volume','visit.age_at_visit','visit.scanner_source','image_dataset_quality_checks.motion_warning','image_dataset_quality_checks.incomplete_series','image_dataset_quality_checks.omnibus_f_comment','image_dataset_quality_checks.fov_cutoff','image_dataset_quality_checks.banding_comment','image_dataset_quality_checks.spm_mask','image_dataset_quality_checks.garbled_series_comment','image_dataset_quality_checks.motion_warning_comment','image_dataset_quality_checks.user_id','image_dataset_quality_checks.banding','image_dataset_quality_checks.field_inhomogeneity','image_dataset_quality_checks.nos_concerns_comment','image_dataset_quality_checks.garbled_series','image_dataset_quality_checks.created_at','image_dataset_quality_checks.incomplete_series_comment','image_dataset_quality_checks.omnibus_f','image_dataset_quality_checks.other_issues','image_dataset_quality_checks.fov_cutoff_comment','image_dataset_quality_checks.nos_concerns','image_dataset_quality_checks.registration_risk','image_dataset_quality_checks.ghosting_wrapping','image_dataset_quality_checks.field_inhomogeneity_comment','image_dataset_quality_checks.updated_at','image_dataset_quality_checks.registration_risk_comment','image_dataset_quality_checks.ghosting_wrapping_comment','image_dataset_quality_checks.image_dataset_id','image_dataset_quality_checks.spm_mask_comment','image_comments.comment','image_comments.updated_at','image_comments.created_at','image_comments.user_id','image_comments.image_dataset_id','Appt Note'] # need to look up values
       if @hide_page_flag  == "Y"   # e.g. UP Only -- weird delete of rmr value -- puyting twice    
        # removing path,'timestamp'
        @column_headers_ids =   ['RMR','Protocol','Enumber','series_description','use_as_default_scan','Do_Not_Share','dicom_series_uid','dcm_file_count','scanned_file','image_uid','id','rep_time','glob','bold_reps','mri_coil_name','slices_per_volume','visit.age_at_visit','visit.scanner_source','image_comments.comment',
   'image_dataset_quality_checks.incomplete_series','image_dataset_quality_checks.incomplete_series_comment','image_dataset_quality_checks.garbled_series','image_dataset_quality_checks.garbled_series_comment','image_dataset_quality_checks.fov_cutoff','image_dataset_quality_checks.fov_cutoff_comment','image_dataset_quality_checks.field_inhomogeneity','image_dataset_quality_checks.field_inhomogeneity_comment','image_dataset_quality_checks.ghosting_wrapping','image_dataset_quality_checks.ghosting_wrapping_comment',
   'image_dataset_quality_checks.banding','image_dataset_quality_checks.banding_comment','image_dataset_quality_checks.registration_risk','image_dataset_quality_checks.registration_risk_comment','image_dataset_quality_checks.nos_concerns','image_dataset_quality_checks.nos_concerns_comment','image_dataset_quality_checks.motion_warning','image_dataset_quality_checks.motion_warning_comment',
      'image_dataset_quality_checks.omnibus_f','image_dataset_quality_checks.omnibus_f_comment','image_dataset_quality_checks.spm_mask','image_dataset_quality_checks.spm_mask_comment','image_dataset_quality_checks.other_issues',
      'image_dataset_quality_checks.user_id','image_dataset_quality_checks.image_dataset_id','image_comments.user_id','image_comments.image_dataset_id','Appt Note'] # need to look up values
          
          # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
      @column_number_ids =   @column_headers_ids.size
      # try left joins on quality check tables, user name
      # weird utc transformations -- utc in db but timestamps from files seem different
      # @fields_ids = ["vgroups.id","vgroups.vgroup_date","vgroups.rmr","image_datasets.series_description","image_datasets.dicom_series_uid","image_datasets.dcm_file_count","concat(date_format(image_datasets.timestamp,'%m/%d/%Y'),time_format(timediff( time(image_datasets.timestamp),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_datasets.scanned_file","image_datasets.image_uid","image_datasets.id","image_datasets.rep_time","image_datasets.glob","image_datasets.path","image_datasets.bold_reps","image_datasets.slices_per_volume","appointments.age_at_appointment","visits.scanner_source","image_dataset_quality_checks.motion_warning","image_dataset_quality_checks.incomplete_series","image_dataset_quality_checks.omnibus_f_comment","image_dataset_quality_checks.fov_cutoff","image_dataset_quality_checks.banding_comment","image_dataset_quality_checks.spm_mask","image_dataset_quality_checks.garbled_series_comment","image_dataset_quality_checks.motion_warning_comment","concat(qc_users.last_name,', ',qc_users.first_name)","image_dataset_quality_checks.banding","image_dataset_quality_checks.field_inhomogeneity","image_dataset_quality_checks.nos_concerns_comment","image_dataset_quality_checks.garbled_series","concat(date_format(image_dataset_quality_checks.created_at,'%m/%d/%Y'),time_format(timediff( time(image_dataset_quality_checks.created_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_dataset_quality_checks.incomplete_series_comment","image_dataset_quality_checks.omnibus_f","image_dataset_quality_checks.other_issues","image_dataset_quality_checks.fov_cutoff_comment","image_dataset_quality_checks.nos_concerns","image_dataset_quality_checks.registration_risk","image_dataset_quality_checks.ghosting_wrapping","image_dataset_quality_checks.field_inhomogeneity_comment","concat(date_format(image_dataset_quality_checks.updated_at,'%m/%d/%Y'),time_format(timediff( time(image_dataset_quality_checks.updated_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_dataset_quality_checks.registration_risk_comment","image_dataset_quality_checks.ghosting_wrapping_comment","image_dataset_quality_checks.image_dataset_id","image_dataset_quality_checks.spm_mask_comment","image_comments.comment","concat(date_format(image_comments.updated_at,'%m/%d/%Y'),time_format(timediff( time(image_comments.updated_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(date_format(image_comments.created_at,'%m/%d/%Y'),time_format(timediff( time(image_comments.created_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(users.last_name,', ',users.first_name)","image_comments.image_dataset_id"]
      # removed "path,"concat(date_format(image_datasets.timestamp,'%m/%d/%Y'),time_format(timediff( time(image_datasets.timestamp),subtime(utc_time(),time(localtime()))),' %H:%i'))","
      @fields_ids =["vgroups.id","vgroups.rmr","image_datasets.series_description","image_datasets.use_as_default_scan_flag","image_datasets.do_not_share_scans_flag","image_datasets.dicom_series_uid","image_datasets.dcm_file_count","image_datasets.scanned_file","image_datasets.image_uid","image_datasets.id","image_datasets.rep_time","image_datasets.glob","image_datasets.bold_reps","image_datasets.mri_coil_name", "image_datasets.slices_per_volume","appointments.age_at_appointment","visits.scanner_source","group_concat(image_comments.comment separator ', ')",
"image_dataset_quality_checks.incomplete_series","image_dataset_quality_checks.incomplete_series_comment","image_dataset_quality_checks.garbled_series","image_dataset_quality_checks.garbled_series_comment","image_dataset_quality_checks.fov_cutoff","image_dataset_quality_checks.fov_cutoff_comment","image_dataset_quality_checks.field_inhomogeneity","image_dataset_quality_checks.field_inhomogeneity_comment","image_dataset_quality_checks.ghosting_wrapping","image_dataset_quality_checks.ghosting_wrapping_comment",
"image_dataset_quality_checks.banding","image_dataset_quality_checks.banding_comment","image_dataset_quality_checks.registration_risk","image_dataset_quality_checks.registration_risk_comment","image_dataset_quality_checks.nos_concerns","image_dataset_quality_checks.nos_concerns_comment","image_dataset_quality_checks.motion_warning","image_dataset_quality_checks.motion_warning_comment",
        "image_dataset_quality_checks.omnibus_f","image_dataset_quality_checks.omnibus_f_comment","image_dataset_quality_checks.spm_mask","image_dataset_quality_checks.spm_mask_comment","image_dataset_quality_checks.other_issues",
       "concat(qc_users.last_name,', ',qc_users.first_name)","image_dataset_quality_checks.image_dataset_id","concat(users.last_name,', ',users.first_name)","image_comments.image_dataset_id"]
      

       else

        @column_headers_ids =   ['Date (vgroup)','Protocol','Enumber','RMR','series_description','use_as_default_scan','Do_Not_Share','dicom_series_uid','dcm_file_count','timestamp','scanned_file','image_uid','id','rep_time','glob','path','bold_reps','mri_coil_name','slices_per_volume','visit.age_at_visit','visit.scanner_source','image_comments.comment',
   'image_dataset_quality_checks.incomplete_series','image_dataset_quality_checks.incomplete_series_comment','image_dataset_quality_checks.garbled_series','image_dataset_quality_checks.garbled_series_comment','image_dataset_quality_checks.fov_cutoff','image_dataset_quality_checks.fov_cutoff_comment','image_dataset_quality_checks.field_inhomogeneity','image_dataset_quality_checks.field_inhomogeneity_comment','image_dataset_quality_checks.ghosting_wrapping','image_dataset_quality_checks.ghosting_wrapping_comment',
   'image_dataset_quality_checks.banding','image_dataset_quality_checks.banding_comment','image_dataset_quality_checks.registration_risk','image_dataset_quality_checks.registration_risk_comment','image_dataset_quality_checks.nos_concerns','image_dataset_quality_checks.nos_concerns_comment','image_dataset_quality_checks.motion_warning','image_dataset_quality_checks.motion_warning_comment',
      'image_dataset_quality_checks.omnibus_f','image_dataset_quality_checks.omnibus_f_comment','image_dataset_quality_checks.spm_mask','image_dataset_quality_checks.spm_mask_comment','image_dataset_quality_checks.other_issues',
      'image_dataset_quality_checks.user_id','image_dataset_quality_checks.created_at','image_dataset_quality_checks.updated_at','image_dataset_quality_checks.image_dataset_id','image_comments.updated_at','image_comments.created_at','image_comments.user_id','image_comments.image_dataset_id','Appt Note'] # need to look up values
          
          # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
      @column_number_ids =   @column_headers_ids.size
      # try left joins on quality check tables, user name
      # weird utc transformations -- utc in db but timestamps from files seem different
      # @fields_ids = ["vgroups.id","vgroups.vgroup_date","vgroups.rmr","image_datasets.series_description","image_datasets.dicom_series_uid","image_datasets.dcm_file_count","concat(date_format(image_datasets.timestamp,'%m/%d/%Y'),time_format(timediff( time(image_datasets.timestamp),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_datasets.scanned_file","image_datasets.image_uid","image_datasets.id","image_datasets.rep_time","image_datasets.glob","image_datasets.path","image_datasets.bold_reps","image_datasets.slices_per_volume","appointments.age_at_appointment","visits.scanner_source","image_dataset_quality_checks.motion_warning","image_dataset_quality_checks.incomplete_series","image_dataset_quality_checks.omnibus_f_comment","image_dataset_quality_checks.fov_cutoff","image_dataset_quality_checks.banding_comment","image_dataset_quality_checks.spm_mask","image_dataset_quality_checks.garbled_series_comment","image_dataset_quality_checks.motion_warning_comment","concat(qc_users.last_name,', ',qc_users.first_name)","image_dataset_quality_checks.banding","image_dataset_quality_checks.field_inhomogeneity","image_dataset_quality_checks.nos_concerns_comment","image_dataset_quality_checks.garbled_series","concat(date_format(image_dataset_quality_checks.created_at,'%m/%d/%Y'),time_format(timediff( time(image_dataset_quality_checks.created_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_dataset_quality_checks.incomplete_series_comment","image_dataset_quality_checks.omnibus_f","image_dataset_quality_checks.other_issues","image_dataset_quality_checks.fov_cutoff_comment","image_dataset_quality_checks.nos_concerns","image_dataset_quality_checks.registration_risk","image_dataset_quality_checks.ghosting_wrapping","image_dataset_quality_checks.field_inhomogeneity_comment","concat(date_format(image_dataset_quality_checks.updated_at,'%m/%d/%Y'),time_format(timediff( time(image_dataset_quality_checks.updated_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_dataset_quality_checks.registration_risk_comment","image_dataset_quality_checks.ghosting_wrapping_comment","image_dataset_quality_checks.image_dataset_id","image_dataset_quality_checks.spm_mask_comment","image_comments.comment","concat(date_format(image_comments.updated_at,'%m/%d/%Y'),time_format(timediff( time(image_comments.updated_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(date_format(image_comments.created_at,'%m/%d/%Y'),time_format(timediff( time(image_comments.created_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(users.last_name,', ',users.first_name)","image_comments.image_dataset_id"]
      @fields_ids =["vgroups.id","vgroups.vgroup_date","vgroups.rmr","image_datasets.series_description","image_datasets.use_as_default_scan_flag","image_datasets.do_not_share_scans_flag","image_datasets.dicom_series_uid","image_datasets.dcm_file_count","concat(date_format(image_datasets.timestamp,'%m/%d/%Y'),time_format(timediff( time(image_datasets.timestamp),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_datasets.scanned_file","image_datasets.image_uid","image_datasets.id","image_datasets.rep_time","image_datasets.glob","image_datasets.path","image_datasets.bold_reps", "image_datasets.mri_coil_name", "image_datasets.slices_per_volume","appointments.age_at_appointment","visits.scanner_source","group_concat(image_comments.comment separator ', ')",
"image_dataset_quality_checks.incomplete_series","image_dataset_quality_checks.incomplete_series_comment","image_dataset_quality_checks.garbled_series","image_dataset_quality_checks.garbled_series_comment","image_dataset_quality_checks.fov_cutoff","image_dataset_quality_checks.fov_cutoff_comment","image_dataset_quality_checks.field_inhomogeneity","image_dataset_quality_checks.field_inhomogeneity_comment","image_dataset_quality_checks.ghosting_wrapping","image_dataset_quality_checks.ghosting_wrapping_comment",
"image_dataset_quality_checks.banding","image_dataset_quality_checks.banding_comment","image_dataset_quality_checks.registration_risk","image_dataset_quality_checks.registration_risk_comment","image_dataset_quality_checks.nos_concerns","image_dataset_quality_checks.nos_concerns_comment","image_dataset_quality_checks.motion_warning","image_dataset_quality_checks.motion_warning_comment",
        "image_dataset_quality_checks.omnibus_f","image_dataset_quality_checks.omnibus_f_comment","image_dataset_quality_checks.spm_mask","image_dataset_quality_checks.spm_mask_comment","image_dataset_quality_checks.other_issues",
       "concat(qc_users.last_name,', ',qc_users.first_name)","concat(date_format(image_dataset_quality_checks.created_at,'%m/%d/%Y'),time_format(timediff( time(image_dataset_quality_checks.created_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(date_format(image_dataset_quality_checks.updated_at,'%m/%d/%Y'),time_format(timediff( time(image_dataset_quality_checks.updated_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_dataset_quality_checks.image_dataset_id","concat(date_format(image_comments.updated_at,'%m/%d/%Y'),time_format(timediff( time(image_comments.updated_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(date_format(image_comments.created_at,'%m/%d/%Y'),time_format(timediff( time(image_comments.created_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(users.last_name,', ',users.first_name)","image_comments.image_dataset_id"]
      end
      @local_conditions_ids =["visits.appointment_id = appointments.id", "visits.id = image_datasets.visit_id","image_datasets.series_description in (select series_description from series_description_maps where series_description_type_id = '"+params[:cg_search][:series_description_type_id]+"')"]
      @left_join_ids_hash = {
                "image_datasets" => "LEFT JOIN image_dataset_quality_checks on image_datasets.id = image_dataset_quality_checks.image_dataset_id 
                                     LEFT JOIN users qc_users on image_dataset_quality_checks.user_id = qc_users.id
                                     LEFT JOIN image_comments  on image_datasets.id = image_comments.image_dataset_id
                                     LEFT JOIN users on image_comments.user_id = users.id" }
      @tables_ids =['visits','image_datasets'] # trigger joins --- vgroups and appointments by default
       @group_by_ids = " group by vgroups.id,appointments.appointment_date, vgroups.rmr , image_datasets.series_description,image_datasets.dicom_series_uid,image_datasets.dcm_file_count,image_datasets.image_uid,image_datasets.id,image_dataset_quality_checks.id"

      @order_by_ids =["appointments.appointment_date DESC", "vgroups.rmr"]
      @local_tables.each do |tmp|
      end
      @tables_ids.concat(@local_tables)
      @local_conditions_ids.concat(@local_conditions)
      # merge not working ???? @left_join_ids_hash.merge(@tables_left_join_hash)
      # make sql based on parts
      sql_ids = " select distinct "+@fields_ids.join(',')+" from "
      @all_tables_ids = []
      @tables_ids.uniq.each do |tn|   # need left join right after parent tn
         v_tn = tn
         if !@left_join_ids_hash[tn].blank?
            v_tn = v_tn +" "+ @left_join_ids_hash[tn] 
         end
         if !@tables_left_join_hash[tn].blank?
            v_tn = v_tn +" "+ @tables_left_join_hash[tn] 
         end
         @all_tables_ids.push(v_tn)
      end
      sql_ids = sql_ids + @all_tables_ids.uniq.join(", ")
      sql_ids = sql_ids + " where "+ @local_conditions_ids.uniq.join(" and ")
      sql_ids = sql_ids+@group_by_ids+" order by "+@order_by_ids.join(",")
      puts sql_ids
      sql = sql_ids


#       @column_headers_ids = ['Date','Protocol','Enumber','RMR','series_description','dicom_series_uid','dcm_file_count','timestamp','scanned_file','image_uid','id','rep_time','glob','path','bold_reps','mri_coil_name','slices_per_volume','visit.age_at_visit','visit.scanner_source','image_dataset_quality_checks.motion_warning','image_dataset_quality_checks.incomplete_series','image_dataset_quality_checks.omnibus_f_comment','image_dataset_quality_checks.fov_cutoff','image_dataset_quality_checks.banding_comment','image_dataset_quality_checks.spm_mask','image_dataset_quality_checks.garbled_series_comment','image_dataset_quality_checks.motion_warning_comment','image_dataset_quality_checks.user_id','image_dataset_quality_checks.banding','image_dataset_quality_checks.field_inhomogeneity','image_dataset_quality_checks.nos_concerns_comment','image_dataset_quality_checks.garbled_series','image_dataset_quality_checks.created_at','image_dataset_quality_checks.incomplete_series_comment','image_dataset_quality_checks.omnibus_f','image_dataset_quality_checks.other_issues','image_dataset_quality_checks.fov_cutoff_comment','image_dataset_quality_checks.nos_concerns','image_dataset_quality_checks.registration_risk','image_dataset_quality_checks.ghosting_wrapping','image_dataset_quality_checks.field_inhomogeneity_comment','image_dataset_quality_checks.updated_at','image_dataset_quality_checks.registration_risk_comment','image_dataset_quality_checks.ghosting_wrapping_comment','image_dataset_quality_checks.image_dataset_id','image_dataset_quality_checks.spm_mask_comment','image_comments.comment','image_comments.updated_at','image_comments.created_at','image_comments.user_id','image_comments.image_dataset_id','Appt Note'] # need to look up values
 #      @column_headers_ids =   ['Date','Protocol','Enumber','RMR','series_description','dicom_series_uid','dcm_file_count','timestamp','scanned_file','image_uid','id','rep_time','glob','path','bold_reps','mri_coil_name', 'slices_per_volume','visit.age_at_visit','visit.scanner_source','image_comments.comment',
 # 'image_dataset_quality_checks.incomplete_series','image_dataset_quality_checks.incomplete_series_comment','image_dataset_quality_checks.garbled_series','image_dataset_quality_checks.garbled_series_comment','image_dataset_quality_checks.fov_cutoff','image_dataset_quality_checks.fov_cutoff_comment','image_dataset_quality_checks.field_inhomogeneity','image_dataset_quality_checks.field_inhomogeneity_comment','image_dataset_quality_checks.ghosting_wrapping','image_dataset_quality_checks.ghosting_wrapping_comment',
 # 'image_dataset_quality_checks.banding','image_dataset_quality_checks.banding_comment','image_dataset_quality_checks.registration_risk','image_dataset_quality_checks.registration_risk_comment','image_dataset_quality_checks.nos_concerns','image_dataset_quality_checks.nos_concerns_comment','image_dataset_quality_checks.motion_warning','image_dataset_quality_checks.motion_warning_comment',
 #    'image_dataset_quality_checks.omnibus_f','image_dataset_quality_checks.omnibus_f_comment','image_dataset_quality_checks.spm_mask','image_dataset_quality_checks.spm_mask_comment','image_dataset_quality_checks.other_issues',
 #    'image_dataset_quality_checks.user_id','image_dataset_quality_checks.created_at','image_dataset_quality_checks.updated_at','image_dataset_quality_checks.image_dataset_id','image_comments.updated_at','image_comments.created_at','image_comments.user_id','image_comments.image_dataset_id','Appt Note'] # need to look up values
 # 
       @local_column_headers = @column_headers_ids  
    end
    # more image_dataset column things below

puts "bbbbb "+sql

    @results2 = connection.execute(sql)

    @temp_results = @results2

    @results = []     
    i =0
    @temp_results.each do |var|
      @temp = []
      @temp[0] = var[1] # want appt date first
         if @hide_page_flag == "Y" 
              if !params[:cg_search].blank? and !params[:cg_search][:series_description_type_id].blank? and !params[:cg_search][:image_dataset_file].blank?
                  # alread doing something with vgroup date????
              else
             @temp[0] = ""
              end
        end
      if @html_request =="N"  and @local_fields.length() > 0 and (@cg_query.participant_centric.nil? or (!@cg_query.participant_centric.nil? and @cg_query.participant_centric != "1" and @cg_query.participant_centric != "2" ) )
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
        if !@cg_query.participant_centric.nil? and @cg_query.participant_centric == "1" and  @local_fields.length() > 0 
           # not do anything
        elsif !@cg_query.participant_centric.nil? and @cg_query.participant_centric == "2" and  @local_fields.length() > 0 
          if var[0].to_s > ''
                    sql_enum = "SELECT distinct enrollments.enumber 
                FROM enrollments where enrollments.participant_id  in ("+var[0].to_s+")"
                @results_enum = connection.execute(sql_enum)
                @temp[0] =@results_enum.to_a.join(", ")
          else
               @temp[0] =""
          end
          #@temp[1] = var[0].to_s

        else
           @temp[1] = var[0].to_s
           @temp[2] = var[0].to_s
        end

      end 
      @temp_vgroupid =[]
      if !params[:longitudinal].nil?  and params[:longitudinal] == "Y"
          @temp_vgroupid[0] =  var[0].to_s
      end
      if !@cg_query.participant_centric.nil? and @cg_query.participant_centric == "1" and  @local_fields.length() > 0
        @temp = []
      elsif !@cg_query.participant_centric.nil? and @cg_query.participant_centric == "2" and  @local_fields.length() > 0
        # @temp = [] #not doing anything???
        var.delete_at(0) # get rid of view_particpant.id
      else
        if v_request_format_array[0] == "application/json"
          # not so simple - the 4 leading columns vs vgroup_id
          v_tmp_array = var[0]
          var.push(v_tmp_array)
          var.delete_at(0) # get rid of vgroup_id
          var.delete_at(0) # get rid of extra copy of appt date
        else
           var.delete_at(0) # get rid of vgroup_id
           var.delete_at(0) # get rid of extra copy of appt date
        end
      end
      if !params[:longitudinal].nil?  and params[:longitudinal] == "Y"
        # need vgroup_id in logintudinal to get participant_id or enrollment_id 
        @temp_row = @temp_vgroupid + @temp + var
      else
         @temp_row = @temp + var
      end
      @results[i] = @temp_row
      i = i+1
# puts "aaaaa results "+i.to_s     
    end
    if @html_request =="N" and !params[:cg_search].blank? and !params[:cg_search][:series_description_type_id].blank? and !params[:cg_search][:image_dataset_file].blank?
       @column_number =   @local_column_headers.size
      
    elsif @html_request =="N"  and !@q_data_form_array.blank?
      @results_q_data =[]
      @q_data_form_array.each do |id| 

          # use @q_data_fields_hash[id], @q_data_fields_left_join_hash[id], @q_data_fields_left_join_vgroup_hash[id]
          # plus sql to get results for each id
          # insert results based on location of q_data_+id.to_s column name   --- need to check that in column name list
                      
          @local_column_headers = @local_column_headers+@q_data_headers_hash[id]

          @column_number =   @local_column_headers.size
          @questionform = Questionform.find(id)
           
           # same approach as in applications controller         
           v_limit = 10  # like the chunk approach issue with multiple appts in a vgroup and multiple enrollments
           @q_data_fields_hash[id].each_slice(v_limit) do |fields_local|

             @results_q_data_temp = []
             # get all the aliases, find in @left_join_q_data and @left_join_vgroup_q_data
             @left_join_q_data_local = []
             @left_join_vgroup_q_data_local = []
             alias_local =[]
             fields_local.each do |v|
               (a,b) = v.split('.')
               if !alias_local.include?(a)
                  alias_local.push(a)
                  @q_data_left_join_hash[id].each do |d|
                    if d.include?(a)
                      @left_join_q_data_local.push(d)
                    end
                  end

                  @q_data_left_join_vgroup_hash[id].each do |d|
                    if d.include?(a)
                     @left_join_vgroup_q_data_local.push(d)
                   end
                  end
               end
             end
             
              sql ="SELECT distinct appointments.id appointment_id, "+fields_local.join(',')+"
               FROM vgroups "+@left_join_vgroup_q_data_local.join(' ')+", appointments ,  scan_procedures_vgroups, "+@q_data_tables_hash[id].join(',')+" "+@left_join_q_data_local.join(' ')+"
               WHERE vgroups.id = appointments.vgroup_id  and scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") "
               @q_data_tables_hash[id].each do |tab|
                 sql = sql +" AND "+tab+".appointment_id = appointments.id  "
               end
               sql = sql +" AND scan_procedures_vgroups.vgroup_id = vgroups.id "

               if @conditions.size > 0
                   sql = sql +" AND "+@conditions.join(' and ')
               end
               

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
                        @results_q_data[appointment_id].concat(var)
                    else
                        @results_q_data[appointment_id] = var
                    end
                 end
               end            
           end
           # need appointment_id in @results for this form_id
           # get index in header array of q_data_form_+id
           v_index =@local_column_headers.index("q_data_form_"+id.to_s)
           @local_column_headers.delete_at(v_index)
           @column_number =   @local_column_headers.size
           @temp = []
           i =0
           @results.each do |result|
             if !result[v_index].blank? and !@results_q_data[result[v_index]].blank?
                 result = result.concat(@results_q_data[result[v_index]])
             else
                 v_array_cell_cnt =@q_data_headers_hash[id].size
                 v_empty_array = Array.new(v_array_cell_cnt)
                 result = result+v_empty_array
             end
             result.delete_at(v_index)
             @results[i] = result

             i = i + 1
           end
           
     end
    end

    if !params[:longitudinal].nil? and params[:longitudinal] == "Y" and !@cg_query.participant_centric.nil? and ( @cg_query.participant_centric == "1" or  @cg_query.participant_centric == "2"  ) and @local_fields.length() > 0  
# UP TO HERE 
       # first colum IS participant id -- no sp or enrollment cols in summary
       if @cg_query.participant_centric == "2"
            @local_column_headers.delete_at(0)
       end
       v_max_length = 0
       @participants = []
       @participant_result = {}
       @participant_size = {}
       if !params[:direction].nil? and params[:direction] =="reverse"
         @results.reverse! 
       end
       @results.each do |r|
          v_participant_id = r[0] 
 # puts "aaaaaa p.id="+v_participant_id.to_s
          # some null participant_id
          r.delete_at(0)
          # ??? getting 2 
          r.delete_at(0)
          if @cg_query.participant_centric == "2"  # extra p_id?
               r.delete_at(0)
          end


          if @participant_result[v_participant_id].nil? and !v_participant_id.nil? and v_participant_id > ''
             puts "bbbbp.id="+v_participant_id.to_s+"===" +r[0].to_s+"==="+r[1].to_s

                 @participants.push(v_participant_id)
                 @participant_result[v_participant_id] = r
                 @participant_size[v_participant_id] = 1
                 # @participant_sp    # build up unique list
                 # @participant_enrollment  # build up unique list
          elsif !v_participant_id.nil? and v_participant_id > ''
                 @participant_result[v_participant_id] = r + @participant_result[v_participant_id]
                 puts "ccccp.id="+v_participant_id.to_s+"==="+ r[0].to_s+"==="+r[1].to_s
                 @participant_size[v_participant_id]  = @participant_size[v_participant_id] + 1
          end
          if !v_participant_id.nil? and v_participant_id > '' and v_max_length < @participant_size[v_participant_id]
                 v_max_length = @participant_size[v_participant_id]
          end
       end 
       @results = []
       @participants.each do |p|
                 longitudinal_base_array = []
                 v_participant = Participant.find(p)
                 longitudinal_base_array.push(v_participant.reggieid)
                 longitudinal_base_array.push(v_participant.wrapnum)
                 if @cg_query.participant_centric == "2" #enumber
                      enrollment_array = []
                      v_enrollments = Enrollment.where("participant_id in (?)",p)
                      v_enrollments.each do |e|
                           enrollment_array.push( e.enumber  )
                      end
                      longitudinal_base_array.push((enrollment_array.uniq).join(', '))
                 end
                 @participant_result[p] = longitudinal_base_array + @participant_result[p]
                 @results.push(@participant_result[p])
                 # add new lead columns
       end

       @longitudinal_column_headers = []
       for v_cnt in 1 .. (v_max_length)
             @local_column_headers.each do |col|
                 @longitudinal_column_headers.push(v_cnt.to_s+"_"+col)
             end
       end
       v_longitudinal_base_col = ['Reggieid','Wrapno']
       if @cg_query.participant_centric == "2"  # enumbers
            v_longitudinal_base_col = ['Reggieid','Wrapno','Enumber']
       end
      @local_column_headers = v_longitudinal_base_col + @longitudinal_column_headers
      # add new lead columns
      @column_number = @local_column_headers.size

    # NEED TO MOVE UP BEFORE DELETE OF VGROUP_ID
    elsif (!params[:longitudinal].nil? and params[:longitudinal] == "Y") 
       # need to flip rows so each participant/enrollment has one row with #row* cols
       v_max_length = 0
       @participants = []
       @enrollments = []
       @participant_result = {}
       @participant_size = {}
       @participant_vgroup = {}
       @enrollment_result = {}
       @enrollment_size = {}
       @enrollment_vgroup = {}
       # 
       if !params[:direction].nil? and params[:direction] =="reverse"
         @results.reverse! 
       end
       @results.each do |r|
          v_vgroupid = r[0]
          v_vgroup  = Vgroup.find(v_vgroupid)
          r.delete_at(0)
          vgroup_array = []
          if !(v_vgroup.participant_id).nil?
             if @participant_result[v_vgroup.participant_id].nil? 
                 @participants.push(v_vgroup.participant_id)
                 @participant_result[v_vgroup.participant_id] = r
                 @participant_size[v_vgroup.participant_id] = 1
                 vgroup_array.push(v_vgroupid)
                 @participant_vgroup[v_vgroup.participant_id] = vgroup_array
                 # @participant_sp    # build up unique list
                 # @participant_enrollment  # build up unique list
              else
                  @participant_result[v_vgroup.participant_id] = r + @participant_result[v_vgroup.participant_id]
                  @participant_size[v_vgroup.participant_id]  = @participant_size[v_vgroup.participant_id] + 1
                  vgroup_array = @participant_vgroup[v_vgroup.participant_id]
                  vgroup_array.push(v_vgroupid)
                  @participant_vgroup[v_vgroup.participant_id] = vgroup_array
                 # @participant_sp    # build up unique list
                 # @participant_enrollment  # build up unique list
              end
              if v_max_length < @participant_size[v_vgroup.participant_id]
                 v_max_length = @participant_size[v_vgroup.participant_id]
              end 
          else
             # GET ENROLLMENT_ID's  --- this breaks down on dual enrollment
             enrollment_array = []
             enrollment_array.push( v_vgroup.enrollments.collect {|e| e.id } )
             if @enrollment_result[enrollment_array].nil?
                @enrollments.push(enrollment_array )
                @enrollment_result[enrollment_array] = r
                @enrollment_size[enrollment_array] = 1
                vgroup_array.push(v_vgroupid)
                @enrollment_vgroup[enrollment_array] = vgroup_array

              else
                  @enrollment_result[enrollment_array] = r + @enrollment_result[enrollment_array]
                  @enrollment_size[enrollment_array]   = @enrollment_size[enrollment_array]  + 1
                  vgroup_array = @participant_vgroup[v_vgroup.participant_id]
                 if vgroup_array.nil? # some record lacking vgroup?  will break further down 
                      vgroup_array = []
                       vgroup_array.push(v_vgroupid)
                  end
                  @enrollment_vgroup[enrollment_array] = vgroup_array

              end
              if v_max_length < @enrollment_size[enrollment_array]
                 v_max_length = @enrollment_size[enrollment_array]
              end 

          end
         # get vgroup -- where is vgroup_id 
         # P_participant_id
         # if vgroup.participant_id null , use enrollment_id
         # E_enrollment_id
    #     if !@results_participant[P_participant_id].nil?
    #           @results_participant[P_participant_id] = concat(r,@results_participant[P_participant_id])
    #           @participant_size[P_participant_id] = @participant_size[P_participant_id] + 1
    #     else
    #           @results_participant[P_participant_id] = r
    #           @participant_size[P_participant_id] = 1
    #     end
    #     if @participant_size[P_participant_id] > v_max_length
    #       v_max_length = @participant_size[P_participant_id]
    #     end
    #      @participant_sp[P_participant_id] from vgroup
    #      participant_enrollment[P_participant_id] from vgroup
       end
       @results = []
       @participants.each do |p|
                 longitudinal_base_array = []
                 sp_array =[]
                 enrollment_array = []
                 v_participant = Participant.find(p)
                 v_vgroups = Vgroup.where("id in (?)",@participant_vgroup[p])
                 v_vgroups.each do |vg|
                      sp_array.push(vg.scan_procedures.collect {|sp| sp.codename} )
                      enrollment_array.push( vg.enrollments.collect {|e| e.enumber } )
                 end
                 longitudinal_base_array.push((sp_array.uniq).join(', '))
                 longitudinal_base_array.push((enrollment_array.uniq).join(', '))
                 longitudinal_base_array.push(v_participant.reggieid)
                 longitudinal_base_array.push(v_participant.wrapnum)
                 @participant_result[p] = longitudinal_base_array + @participant_result[p]
                 @results.push(@participant_result[p])
                 # add new lead columns
       end
       # breaks down for dual enrollments with no participant_id
       @enrollments.each do |es|
                 longitudinal_base_array = []
                 sp_array =[]
                 enrollment_array = []
                 es.each do |e|
                    # problems with a nil somewhere
                       v_tmp_enumbers = Enrollment.find(e)
                     if !v_tmp_enumbers[0].nil?
                       v_enumber = (v_tmp_enumbers[0]).enumber
                       enrollment_array.push(v_enumber)
                     end
                 end
                 longitudinal_base_array.push('')
                 longitudinal_base_array.push((enrollment_array.uniq).join(', '))
                 longitudinal_base_array.push('')
                 longitudinal_base_array.push('')
                 @enrollment_result[es] = longitudinal_base_array + @enrollment_result[es]
                 @results.push(@enrollment_result[es])
                 # add new lead columns
       end


       # make leading header fields for sp's, enrollments', reggie, wrap
       # make header names with #_ 
       # loop v_max_length @header
       @longitudinal_column_headers = []
       for v_cnt in 1 .. (v_max_length)
             @local_column_headers.each do |col|
                 @longitudinal_column_headers.push(v_cnt.to_s+"_"+col)
             end
       end
       v_longitudinal_base_col = ['Protocols','Enumbers','Reggieid','Wrapno']
      @local_column_headers = v_longitudinal_base_col + @longitudinal_column_headers
      # add new lead columns
      @column_number = @local_column_headers.size

    end
    
    @results_total = @results # pageination makes result count wrong
    t = Time.now 
    @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
    # making csv - html xls file not working with excel2016
        @csv_array = []
    @results_tmp_csv = []
    @results_tmp_csv.push(@export_file_title)
    @csv_array.push(@results_tmp_csv )
    @csv_array.push( @local_column_headers)
    if v_request_format_array[0] == "application/json"
      # want a unique id for lumbarpuncture - not dropping last column
      @results.each do |result| 
         @results_tmp_csv = []
         for i in 0..@column_number  # results is an array of arrays%>
            @results_tmp_csv.push(result[i])
         end 
         @csv_array.push(@results_tmp_csv)
      end 

    else
      @results.each do |result| 
         @results_tmp_csv = []
         for i in 0..@column_number-1  # results is an array of arrays%>
            @results_tmp_csv.push(result[i])
         end 
         @csv_array.push(@results_tmp_csv)
      end 
     end
    @csv_str = @csv_array.inject([]) { |csv, row|  csv << CSV.generate_line(row) }.join("")  

  end   
  puts "end ="+@local_column_headers.join(',')
       if v_request_format_array[0] == "application/json"
        @csv_array_json = @csv_array
        @csv_array_json.shift
        @csv_array_json_header = @csv_array_json[0]
        @csv_array_json_header.push("vgroup_id")
        @csv_array_json.shift  # deleted the first row
        @json_hash_of_hash = Hash[]
        @json_array_of_hash = Array[]
        @csv_array_json.each do |item|
          @h = Hash[]
          @h2 = Hash[]
          v_cnt = 0
          @csv_array_json_header.each do |header_col|
            @h[v_cnt.to_s+"_"+header_col] = item[v_cnt]
            v_cnt = v_cnt + 1
          end
         #@json_hash_of_hash[item[v_cnt-1]]= @h
         @h2["vgroup_participant"]= @h
         @json_array_of_hash.push(@h2)
        end

    end
      respond_to do |format|
        format.xls # cg_search.xls.erb
        if !params[:cg_search].blank? and !@table_types.blank? and !@table_types.index('base').blank?
          # need to change from get to post or delete lots of empty conditions 
          # cg_search[condition][][]=""
          # paginate @users, :method => :post
          format.html  {@results = Kaminari.paginate_array(@results).page(params[:page]).per(100)}  
        else
          format.html 
        end
        format.xml  { render :xml => @results }
        format.csv { send_data @csv_str }
        format.json { send_data @json_array_of_hash.to_json}#render :json =>  @json_array_of_hash.to_json}
      end
     
    end

 #def run_search
#   copy of def index in application_controller  -- so other controllers can get at  -- need for csv export
# end
# make_in_source_schema, load_from_source_schema
def cg_up_load
     v_up_table_name = params[:up_table_name]
     v_up_display_table_name = params[:up_display_table_name]
     v_up_table_yyyymmdd = params[:up_table_yyyymmdd]
     v_up_table_name_key_column = params[:up_table_name_key_column]

     v_key_type = params[:key_type]
     v_source_up_table_name = params[:source_up_table_name]
     v_source_schema = params[:source_schema]
     v_make_load_table_schema = params[:make_load_table_schema]

  if (!v_up_table_name.blank? and  !v_up_display_table_name.blank? and  !v_up_table_yyyymmdd.blank? and  !v_up_table_name_key_column.blank? and  !v_key_type.blank? and  !v_source_up_table_name.blank? and  !v_source_schema.blank? and !v_make_load_table_schema.blank?)
    v_schema ='panda_production'
    if Rails.env=="development" 
      v_schema ='panda_development'
    end
    v_msg = ""
    v_definition_table ="cg_up_table_definitions_new"
    connection = ActiveRecord::Base.connection();
      # THIS NEEDS TO NOT WIPE OUT THE TABLE EACH RELOAD
      # check in cg_up_table_definitions_new   for v_up_table_name
    v_sql = "Select count(*) from "+v_definition_table+" where target_table ='"+v_up_table_name+"'"  
    results = connection.execute(v_sql)
    v_cnt = results.first

    if v_cnt[0].to_i > 0 
      # in definitions table , go ahead
     if  v_make_load_table_schema == "make_in_source_schema"  # make in source schema
        v_msg = "Making table in source schema"
        v_sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '"+v_source_schema+"' AND table_name = '"+v_source_up_table_name+"' "     
        results = connection.execute(v_sql)
        v_cnt = results.first
        if v_cnt[0].to_i > 0
               v_msg = v_source_up_table_name+" table already exists in source schema "+v_source_schema
        else
          v_create_sql = "CREATE table "+v_source_schema+"."+v_source_up_table_name+"("
          v_sql_cols = "Select distinct lower(col_db), upper(col_type), col_size,col_function, col_format from "+v_definition_table+" where table_name ='"+v_up_table_name+"'"   
        result_cols = connection.execute(v_sql_cols)
        v_loop_cnt = 0
        result_cols.each do |col|
              if v_loop_cnt > 0
                v_create_sql = v_create_sql+", "
              else
                 v_loop_cnt = 1
              end
              if col[1] == "VARCHAR"
                  v_create_sql = v_create_sql+" "+col[0]+"   VARCHAR("+col[2]+") "
              elsif col[1] =="INT"
                   if col[2] >""
                      v_create_sql = v_create_sql+" "+col[0]+"   INT("+col[2]+") "
                   else
                      v_create_sql = v_create_sql+" "+col[0]+"   INT "
                   end
              elsif col[1] == "DATE"
                     v_create_sql = v_create_sql+" "+col[0]+"   DATE "
              elsif col[1] == "DATETIME"
                     v_create_sql = v_create_sql+" "+col[0]+"   DATETIME "
              elsif col[1] == "TEXT"
                     v_create_sql = v_create_sql+" "+col[0]+"   TEXT "
              end
               if col[3] == "date"  # making a colname_date   DATE and age_at_activity
                      v_create_sql = v_create_sql+" "+col[0]+"_date   DATE "
                      v_create_sql = v_create_sql+" "+col[0]+"_age_at_activity   FLOAT "
               end
         end

         v_create_sql = v_create_sql+")"
          # make new table in source schema 
         results = connection.execute(v_create_sql) 
         v_msg = v_source_up_table_name+" table made in source schema "+v_source_schema
        end
        flash[:notice] = v_msg
     else
      #check if exisiting table v_up_table_name +/- v_up_table_yyyymmdd
      v_tn = v_up_table_name+"_"+v_up_table_yyyymmdd
      v_sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '"+v_schema+"' AND table_name = '"+v_tn+"' "     
      results = connection.execute(v_sql)
      v_cnt = results.first
      if v_cnt[0].to_i > 0
         # if
          v_msg = "Reloading existing UP Table "+v_tn
          v_cg_tns_archive = CgTn.where("tn in (?)", v_tn)
          v_cg_tns_archive[0].status_flag ='N'
          v_cg_tns_archive[0].save
          # if exisiting with same v_up_table_yyyymmdd => replace contents  === new-present-old-edit?
          # drop table, remake, load
        if ( !params[:append_full_replace].empty? and params[:append_full_replace] == "full_replace" )
           v_sql = "DROP TABLE "+v_schema+"."+v_tn
           results = connection.execute(v_sql)
           v_msg = v_msg+"; Dropped UP Table "+v_tn 
         end
  # NEED TO DO !!!!! collect key_columns/subjectid/reggiied/secondary_key_protocol, secondary_key_visitno
        v_create_sql = "CREATE table "+v_schema+"."+v_tn+"("
        v_create_index_key_type = "create index ind_key_"+v_tn+" ON "+v_schema+"."+v_tn+"(participant_id)"
        # add key columns
        if v_key_type == "enrollment/sp"
             v_create_sql = v_create_sql+" enrollment_id int,
                                           scan_procedure_id int"
        v_create_index_key_type = "create index ind_key_"+v_tn+" ON "+v_schema+"."+v_tn+"(enrollment_id,scan_procedure_id)"
        elsif v_key_type == "subjectid-kc-participant_id"
             v_create_sql = v_create_sql+" participant_id int "
        elsif v_key_type == "reggieid-kc-participant_id"
             v_create_sql = v_create_sql+" participant_id int "
        elsif v_key_type == "wrapnum-kc-participant_id"
             v_create_sql = v_create_sql+" participant_id int "
        elsif v_key_type == "adrcnum-kc-participant_id"
             v_create_sql = v_create_sql+" participant_id int "
        end 

        v_col_array = []
        v_key_col_array = []
        v_col_multi_key_array = []
        # need to make _date and _age_at_activity cols, and do upddate based on format
        v_date_source_col_array = []
        v_date_date_col_hash = {}
        v_date_format_col_hash = {}
        v_age_at_activity_col_hash = {}
        v_sql_cols = "Select distinct lower(col_db), upper(col_type), col_size,col_function, col_format from "+v_definition_table+" where target_table ='"+v_up_table_name+"'"   
        result_cols = connection.execute(v_sql_cols)
        result_cols.each do |col|
              v_col_array.push(col[0])
              if col[3] == "subjectid" or col[3] == "secondary_key_protocol" or col[3] == "secondary_key_visitno" or col[0] == "secondary_key"
                  v_col_multi_key_array.push(col[0])
              end 
              if col[3] == "subjectid"
                 v_key_col_array.push(col[0])
              elsif col[3] == "wrapnum"
                 v_key_col_array.push(col[0])
                 v_col_multi_key_array.push(col[0])
              elsif col[3] == "reggieid"
                 v_key_col_array.push(col[0])
                 v_col_multi_key_array.push(col[0])
              end
              if col[1] == "VARCHAR"
                  v_create_sql = v_create_sql+", "+col[0]+"   VARCHAR("+col[2]+") "
              elsif col[1] =="INT"
                   if col[2] >""
                      v_create_sql = v_create_sql+", "+col[0]+"   INT("+col[2]+") "
                   else
                      v_create_sql = v_create_sql+", "+col[0]+"   INT "
                   end
              elsif col[1] == "DATE"
                     v_create_sql = v_create_sql+", "+col[0]+"   DATE "
              elsif col[1] == "DATETIME"
                     v_create_sql = v_create_sql+", "+col[0]+"   DATETIME "
              elsif col[1] == "TEXT"
                     v_create_sql = v_create_sql+", "+col[0]+"   TEXT "
              end
              if col[3] == "date"  # making a colname_date   DATE and age_at_activity
                      v_date_source_col_array.push(col[0])
                      v_date_date_col_hash[col[0]] = col[0]+"_date"
                      v_date_format_col_hash[col[0]] = col[4]
                      v_age_at_activity_col_hash[col[0]] = col[0]+"_age_at_activity"
                      v_create_sql = v_create_sql+", "+col[0]+"_date   DATE "
                      v_create_sql = v_create_sql+", "+col[0]+"_age_at_activity   FLOAT "
              end
         end
         v_create_sql = v_create_sql+")"
         if ( !params[:append_full_replace].empty? and params[:append_full_replace] == "full_replace" )
             # make new table with v_up_table_yyyymmdd, 
            results = connection.execute(v_create_sql)   # new-present-old_edit ?
            results = connection.execute(v_create_index_key_type)
            v_msg = v_msg+"; Created table "+v_tn
         end
         if ( !params[:append_full_replace].empty? and params[:append_full_replace] == "append" )
# NEED TO DO !!! delete exisiting rows based on key column/subjectid/secondary_key_protocol, secondary_key
#coalesce (not working -why using?) vs concat and NULLS ???   #concat('',"+ v_col_multi_key_array.join(",'=|',") +")
               v_delete_sql = " DELETE FROM "+v_schema+"."+v_tn+" WHERE concat('',IFNULL("+ v_col_multi_key_array.join(",'_'),'=|',IFNULL(") +",'_'))  IN 
                        (SELECT concat('',IFNULL("+ v_col_multi_key_array.join(",'_'),'=|',IFNULL(") +",'_')) FROM "+v_source_schema+"."+v_source_up_table_name+")"
               #puts "BBBBBBB="+v_delete_sql
               results = connection.execute(v_delete_sql)
               v_msg = v_msg+"; Deleted shared data  for append from table "+v_tn
         end
         if ( !params[:append_full_replace].empty? and params[:append_full_replace] == "append_by_participant" )
# ???delete exisiting rows based on key column/subjectid/secondary_key_protocol, secondary_key
# letting NULL key columns to accumulate


               # issues when using wrapnum from one source files, adrcnum from another source
               v_delete_sql = " DELETE FROM "+v_schema+"."+v_tn+" WHErE concat('',IFNULL("+ v_col_multi_key_array.join(",'_'),'=|',IFNULL(") +",'_'))  IN 
                      (SELECT concat('',IFNULL("+ v_col_multi_key_array.join(",'_'),'=|',IFNULL(") +",'_')) FROM "+v_source_schema+"."+v_source_up_table_name+")
                        "
               v_col_multi_key_array.each do |key_col|
                    v_delete_sql = v_delete_sql+" and IFNULL("+key_col+",'') > '' "  
               end
            #puts "AAAAAAA="+v_delete_sql
               results = connection.execute(v_delete_sql)
               v_msg = v_msg+"; Deleted shared data  for append from table "+v_tn
         end
       v_insert_sql = "INSERT INTO "+v_schema+"."+v_tn+"("
        v_insert_end_sql = ") "
        v_select_sql =" SELECT "
        v_select_end_sql = " FROM "+v_source_schema+"."+v_source_up_table_name
        
        # load from source schema, source table
        v_insert_sql = v_insert_sql+v_col_array.join(",")+v_insert_end_sql+v_select_sql+v_col_array.join(",")+v_select_end_sql
        puts v_insert_sql
        results = connection.execute(v_insert_sql)
        v_msg = v_msg+"; Inserted data into table "+v_tn
         # update key columns -- expect one key column
         v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload             
        if v_key_type == "enrollment/sp"
            v_key_col = v_key_col_array[0]
            sql = "update "+v_schema+"."+v_tn+"  t set t.enrollment_id = ( select e.id from enrollments e where e.enumber = replace(replace(replace(replace(t."+v_key_col+",'_v2',''),'_v3',''),'_v4',''),'_v5',''))"
                      results = connection.execute(sql)
                      sql = "select distinct "+v_key_col+" from "+v_schema+"."+v_tn
                      results = connection.execute(sql)
                      results.each do |r|
                        v_sp_id = v_shared.get_sp_id_from_subjectid_v(r[0])
                        if !v_sp_id.blank?
                          sql = "update "+v_schema+"."+v_tn+"  t set t.scan_procedure_id = "+v_sp_id.to_s+" where "+v_key_col+" ='"+r[0]+"'"
                          results = connection.execute(sql)
                        end
                      end
        elsif v_key_type == "subjectid-kc-participant_id"
            v_key_col = v_key_col_array[0]
             sql = "update "+v_schema+"."+v_tn+"  t set t.participant_id = ( select distinct e.participant_id from enrollments e where e.enumber = replace(replace(replace(replace(t."+v_key_col+",'_v2',''),'_v3',''),'_v4',''),'_v5',''))
             where  t.participant_id  is null and t."+v_key_col+" is not null and t."+v_key_col+" > '' "
              results = connection.execute(sql) 
        elsif v_key_type == "reggieid-kc-participant_id"
            v_key_col = v_key_col_array[0]
             sql = "update "+v_schema+"."+v_tn+"  t set t.participant_id = ( select distinct p.id from participants p where p.reggieid = t."+v_key_col+")
             where  t.participant_id  is null and t."+v_key_col+" is not null and t."+v_key_col+" > '' "
              results = connection.execute(sql) 
        elsif v_key_type == "wrapnum-kc-participant_id"
             v_key_col = v_key_col_array[0]
             sql = "update "+v_schema+"."+v_tn+"  t 
             set t.participant_id = ( select distinct p.id from participants p where p.wrapnum = t."+v_key_col+")
             where t.participant_id  is null  and t."+v_key_col+" is not null and t."+v_key_col+" > '' "
              results = connection.execute(sql) 
        elsif v_key_type == "adrcnum-kc-participant_id"
            v_key_col = v_key_col_array[0]
             sql = "update "+v_schema+"."+v_tn+"  t set t.participant_id = ( select distinct p.id from participants p where p.adrcnum = t."+v_key_col+")
             where  t.participant_id  is null and t."+v_key_col+" is not null and t."+v_key_col+" > '' "
              results = connection.execute(sql) 
        end

        v_date_source_col_array.each do |key|
             # make the date
             v_date_format = '%m/%d/%Y'
             if v_date_format_col_hash[key] == "MM/DD/YY"
                  v_date_format = '%m/%d/%y'
             elsif v_date_format_col_hash[key] == "MM/D/YY"
                  v_date_format = '%m/%e/%y'
             end

            sql = "UPDATE "+v_schema+"."+v_tn+"  t set "+v_date_date_col_hash[key]+" = str_to_date("+key+",'"+v_date_format+"') where "+key+"  > '' and "+key+" IS NOT NULL "
            results = connection.execute(sql) 
            if v_key_type == "enrollment/sp" # use enrollment_id to link to participant
                sql = "UPDATE "+v_schema+"."+v_tn+"  t set "+v_age_at_activity_col_hash[key]+" = 
                    ( SELECT distinct round((DATEDIFF( "+v_date_date_col_hash[key]+",  p.dob)/365.25),2)  FROM participants p,enrollments e
                                           where p.dob is not null and p.dob > '' and e.participant_id = p.id
                                             and e.id = t.enrollment_id)
                        WHERE  "+v_date_date_col_hash[key]+"  > '' and "+v_date_date_col_hash[key]+" IS NOT NULL
                        AND t.enrollment_id IS NOT NULL AND t.enrollment_id >'' "
            results = connection.execute(sql) 

            elsif v_key_type == "subjectid-kc-participant_id" or v_key_type == "reggieid-kc-participant_id"   or v_key_type == "wrapnum-kc-participant_id" or v_key_type == "adrcnum-kc-participant_id"
                 sql = "UPDATE "+v_schema+"."+v_tn+"  t set "+v_age_at_activity_col_hash[key]+" = 
                    ( SELECT distinct round((DATEDIFF( "+v_date_date_col_hash[key]+",  p.dob)/365.25),2)  FROM participants p
                                           where p.dob is not null and p.dob > ''
                                           and t.participant_id = p.id)
                        WHERE  "+v_date_date_col_hash[key]+"  > '' and "+v_date_date_col_hash[key]+" IS NOT NULL
                        AND t.participant_id IS NOT NULL AND t.participant_id >'' "
            results = connection.execute(sql) 
            end
        end
        v_msg = v_msg+"; Updated key column in table "+v_tn
          # update cg_serach columns  -- want to keep as many cn.id's for stored query
          v_cg_tns_archive[0].common_name = v_up_display_table_name
          v_cg_tn_cns = CgTnCn.where("cg_tn_id in (?)", v_cg_tns_archive[0].id)
        v_sql_cols = "Select lower(col_db), upper(col_type), col_size,col_display,col_function, col_format,column_active,search_list,column_searchable from "+v_definition_table+" where target_table ='"+v_up_table_name+"' order by display_order"   
        result_cols = connection.execute(v_sql_cols)
        v_cnt =1
        result_cols.each do |col|
              v_cnt = v_cnt + 1
              v_existing_cg_tn_cn = v_cg_tn_cns.where("cn in (?)",col[0])
              if(v_existing_cg_tn_cn.blank?)
                  v_cg_tn_cn = CgTnCn.new
               else
                  v_cg_tn_cn = v_existing_cg_tn_cn[0]
               end
              v_cg_tn_cn.display_order = v_cnt
             if col[1] == "DATE"
              v_cg_tn_cn.data_type ="date"
              v_cg_tn_cn.hide_column_flag = "Y"
            elsif col[1].include?('int')
              v_cg_tn_cn.data_type ="integer"
            elsif col[1] == "FLOAT"
               v_cg_tn_cn.data_type ="float"
            elsif col[1].include?('VARCHAR')
               v_cg_tn_cn.data_type ="string"
            elsif col[1].include?('TEXT')
               v_cg_tn_cn.data_type ="string"
            end
            v_cg_tn_cn.cn = col[0]
            v_cg_tn_cn.common_name = col[3]
            v_cg_tn_cn.export_name = col[3]
            if col[4] == "secondary_key_visitno"
                  v_cg_tn_cn.secondary_key_visitno_flag = "Y"
            elsif col[4] == "secondary_key_protocol"
                  v_cg_tn_cn.secondary_key_protocol_flag = "Y"
            elsif col[4] == "date"
                # need date_date and age_at_activity calculate
                #v_cg_tn_cn..order_by_flag = "Y"
                v_cg_tn_cn.hide_column_flag = "Y"
                if ( v_date_date_col_hash[col[0]] > '')
                    v_date_date_existing_cg_tn_cn = v_cg_tn_cns.where("cn in (?)",v_date_date_col_hash[col[0]])
                    if(v_date_date_existing_cg_tn_cn.blank?)
                      v_cg_tn_cn.cn = v_date_date_col_hash[col[0]]
                      v_cg_tn_cn.order_by_flag = "Y"
                      v_cg_tn_cn.data_type ="date"
                      v_cg_tn_cn.status_flag ="N" # hiding up date field ?????
                    end
                end
                if ( v_age_at_activity_col_hash[col[0]] > ''  )
                    v_age_existing_cg_tn_cn = v_cg_tn_cns.where("cn in (?)",v_age_at_activity_col_hash[col[0]])
                    if(v_age_existing_cg_tn_cn.blank?)
                      v_cg_tn_cn_age = CgTnCn.new
                      v_cnt = v_cnt + 1
                      v_cg_tn_cn_age.display_order = v_cnt
                      v_cg_tn_cn_age.cn = v_age_at_activity_col_hash[col[0]]
                      v_cg_tn_cn_age.order_by_flag = "Y"
                      v_cg_tn_cn_age.common_name = col[3]+" age at activity"
                      v_cg_tn_cn_age.export_name = col[3]+" age at activity"
                      v_cg_tn_cn_age.cg_tn_id = v_cg_tns_archive[0].id
                      v_cg_tn_cn_age.data_type ="float"
                      v_cg_tn_cn_age.save
                    end
                end

            end
            v_cg_tn_cn.status_flag = col[6]  # column_active
            v_cg_tn_cn.value_list = col[7]  # search_list
            v_cg_tn_cn.searchable_flag = col[8] # column searchable
            v_cg_tn_cn.cg_tn_id = v_cg_tns_archive[0].id
              v_cg_tn_cn.save
        end


          # change status in cg_search so not there while load
          # load from source schema, source table
          # update key columns
          #change cg_search status = active
          v_cg_tns_archive[0].status_flag ='Y'
          v_cg_tns_archive[0].save
      else
        sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '"+v_schema+"'
             AND table_name like '"+v_up_table_name+"%' AND table_name in (select table_name from cg_tns where table_type = 'up')"
        connection = ActiveRecord::Base.connection();        
        results = connection.execute(sql)
        v_cnt = results.first
        if v_cnt[0].to_i > 0
            v_msg = "Archiving exisiting UP Table"
            v_cg_tns_archive = CgTn.where("tn like '"+v_up_table_name+"%' and table_type ='up'")
            v_cg_tns_archive[0].table_type = "up_archive"
            v_cg_tns_archive[0].save
             #if exisiting with different v_up_table_yyyymmdd => change table type to up_archive
        end   
        v_msg = "Create UP Table "+v_tn 
        v_create_sql = "CREATE table "+v_schema+"."+v_tn+"("

        # add key columns
        v_create_index_key_type = "create index ind_key_"+v_tn+" ON "+v_schema+"."+v_tn+"(participant_id)"
        if v_key_type == "enrollment/sp"
             v_create_sql = v_create_sql+" enrollment_id int,
                                           scan_procedure_id int"
          v_create_index_key_type = "create index ind_key_"+v_tn+" ON "+v_schema+"."+v_tn+"(enrollment_id,scan_procedure_id)"
        elsif v_key_type == "subjectid-kc-participant_id"
             v_create_sql = v_create_sql+" participant_id int "
        elsif v_key_type == "reggieid-kc-participant_id"
             v_create_sql = v_create_sql+" participant_id int "
        elsif v_key_type == "wrapnum-kc-participant_id"
             v_create_sql = v_create_sql+" participant_id int "
        elsif v_key_type == "adrcnum-kc-participant_id"
             v_create_sql = v_create_sql+" participant_id int "
        end 

        v_col_array = []
        v_key_col_array = []
        v_sql_cols = "Select distinct lower(col_db), upper(col_type), col_size,col_function,col_format from "+v_definition_table+" where target_table ='"+v_up_table_name+"'"   
        result_cols = connection.execute(v_sql_cols)
        # need to make _date and _age_at_activity cols, and do upddate based on format
        v_date_source_col_array = []
        v_date_date_col_hash = {}
        v_date_format_col_hash = {}
        v_age_at_activity_col_hash = {}
        result_cols.each do |col|
              v_col_array.push(col[0])
              if col[3] == "subjectid"
                 v_key_col_array.push(col[0])
              elsif col[3] == "wrapnum"
                 v_key_col_array.push(col[0])
              elsif col[3] == "reggieid"
                 v_key_col_array.push(col[0])
              end
              if col[1] == "VARCHAR"
                  v_create_sql = v_create_sql+", "+col[0]+"   VARCHAR("+col[2]+") "
              elsif col[1] =="INT"
                   if col[2] >""
                      v_create_sql = v_create_sql+", "+col[0]+"   INT("+col[2]+") "
                   else
                      v_create_sql = v_create_sql+", "+col[0]+"   INT "
                   end
              elsif col[1] == "DATE"
                     v_create_sql = v_create_sql+", "+col[0]+"   DATE "
              elsif col[1] == "DATETIME"
                     v_create_sql = v_create_sql+", "+col[0]+"   DATETIME "
              elsif col[1] == "TEXT"
                     v_create_sql = v_create_sql+", "+col[0]+"   TEXT "
              end
              if col[3] == "date"  # making a colname_date   DATE and age_at_activity
                      v_date_source_col_array.push(col[0])
                      v_date_date_col_hash[col[0]] = col[0]+"_date"
                      v_date_format_col_hash[col[0]] = col[4]
                      v_age_at_activity_col_hash[col[0]] = col[0]+"_age_at_activity"
                      v_create_sql = v_create_sql+", "+col[0]+"_date   DATE "
                      v_create_sql = v_create_sql+", "+col[0]+"_age_at_activity   FLOAT "
              end
         end
         v_create_sql = v_create_sql+")"
          # make new table with v_up_table_yyyymmdd, 
         results = connection.execute(v_create_sql)   # new-present-old_edit ?
         results = connection.execute(v_create_index_key_type)

       v_insert_sql = "INSERT INTO "+v_schema+"."+v_tn+"("
        v_insert_end_sql = ") "
        v_select_sql =" SELECT "
        v_select_end_sql = " FROM "+v_source_schema+"."+v_source_up_table_name
        
        # load from source schema, source table
        v_insert_sql = v_insert_sql+v_col_array.join(",")+v_insert_end_sql+v_select_sql+v_col_array.join(",")+v_select_end_sql
puts "CCCCCCC="+v_insert_sql        
        results = connection.execute(v_insert_sql)
        v_msg = v_msg+"; Insert data into table "+v_tn
         # update key columns -- expect one key column
         v_shared = Shared.new # using some functions in the Shared model --- this is the same as in schedule file upload             
        if v_key_type == "enrollment/sp"
            v_key_col = v_key_col_array[0]
            sql = "update "+v_schema+"."+v_tn+"  t set
             t.enrollment_id = ( select e.id from enrollments e where e.enumber = replace(replace(replace(replace(t."+v_key_col+",'_v2',''),'_v3',''),'_v4',''),'_v5',''))"
                      results = connection.execute(sql)
                      sql = "select distinct "+v_key_col+" from "+v_schema+"."+v_tn
                      results = connection.execute(sql)
                      results.each do |r|
                        v_sp_id = v_shared.get_sp_id_from_subjectid_v(r[0])
                        if !v_sp_id.blank?
                          sql = "update "+v_schema+"."+v_tn+"  t set t.scan_procedure_id = "+v_sp_id.to_s+" where "+v_key_col+" ='"+r[0]+"'"
                          results = connection.execute(sql)
                        end
                      end
        elsif v_key_type == "subjectid-kc-participant_id"
          v_key_col = v_key_col_array[0]
             sql = "update "+v_schema+"."+v_tn+"  t set t.participant_id = ( select distinct e.participant_id from enrollments e where e.enumber = replace(replace(replace(replace(t."+v_key_col+",'_v2',''),'_v3',''),'_v4',''),'_v5',''))
             where t.participant_id is null  and t."+v_key_col+" is not null and t."+v_key_col+" > '' "
              results = connection.execute(sql)
        elsif v_key_type == "reggieid-kc-participant_id"
            v_key_col = v_key_col_array[0]
             sql = "update "+v_schema+"."+v_tn+"  t set t.participant_id = ( select distinct p.id from participants p where p.reggieid = t."+v_key_col+")
             where t.participant_id is null  and t."+v_key_col+" is not null and t."+v_key_col+" > '' "
              results = connection.execute(sql) 
        elsif v_key_type == "wrapnum-kc-participant_id"
          v_key_col = v_key_col_array[0]
             sql = "update "+v_schema+"."+v_tn+"  t set t.participant_id = ( select distinct p.id from participants p where p.wrapnum = t."+v_key_col+")
             where t.participant_id is null  and t."+v_key_col+" is not null and t."+v_key_col+" > '' "

              results = connection.execute(sql) 
        elsif v_key_type == "adrcnum-kc-participant_id"
            v_key_col = v_key_col_array[0]
             sql = "update "+v_schema+"."+v_tn+"  t set t.participant_id = ( select distinct p.id from participants p where p.adrcnum = t."+v_key_col+")
                   where t.participant_id is null  and t."+v_key_col+" is not null and t."+v_key_col+" > '' "
              results = connection.execute(sql) 
        end 
        v_date_source_col_array.each do |key|
             # make the date
             v_date_format = '%m/%d/%Y'
             if v_date_format_col_hash[key] == "MM/DD/YY"
                  v_date_format = '%m/%d/%y'
             elsif v_date_format_col_hash[key] == "MM/D/YY"
                  v_date_format = '%m/%e/%y'
             end
               
            sql = "UPDATE "+v_schema+"."+v_tn+"  t set "+v_date_date_col_hash[key]+" = str_to_date("+key+",'"+v_date_format+"') where "+key+"  > '' and "+key+" IS NOT NULL "
            results = connection.execute(sql) 
            if v_key_type == "enrollment/sp" # use enrollment_id to link to participant
                sql = "UPDATE "+v_schema+"."+v_tn+"  t set "+v_age_at_activity_col_hash[key]+" = 
                    ( SELECT distinct round((DATEDIFF( "+v_date_date_col_hash[key]+",  p.dob)/365.25),2)  FROM participants p,enrollments e
                                           where p.dob is not null and p.dob > '' and e.participant_id = p.id
                                             and e.id = t.enrollment_id)
                        WHERE  "+v_date_date_col_hash[key]+"  > '' and "+v_date_date_col_hash[key]+" IS NOT NULL
                        AND t.enrollment_id IS NOT NULL AND t.enrollment_id >'' "
            results = connection.execute(sql) 

            elsif v_key_type == "subjectid-kc-participant_id" or v_key_type == "reggieid-kc-participant_id"   or v_key_type == "wrapnum-kc-participant_id" or v_key_type == "adrcnum-kc-participant_id"
                 sql = "UPDATE "+v_schema+"."+v_tn+"  t set "+v_age_at_activity_col_hash[key]+" = 
                    ( SELECT distinct round((DATEDIFF( "+v_date_date_col_hash[key]+",  p.dob)/365.25),2)  FROM participants p
                                           where p.dob is not null and p.dob > ''
                                           and t.participant_id = p.id)
                        WHERE  "+v_date_date_col_hash[key]+"  > '' and "+v_date_date_col_hash[key]+" IS NOT NULL
                        AND t.participant_id IS NOT NULL AND t.participant_id >'' "
            results = connection.execute(sql) 
            end 

        end
      
        v_msg = v_msg+"; Updated key column in table "+v_tn
         # make new cg_search table - inactive
                v_cg_search = CgTn.new
         # make new cg_search table 
    v_cg_search.tn =  v_tn.downcase
    v_tn = v_tn.downcase 
    v_cg_search.common_name = v_up_display_table_name
    v_cg_search.editable_flag ="N"
    v_cg_search.status_flag ="N"   # wait till add all the columns
    v_cg_search.table_type ="up"
    sql = "select max(display_order) from cg_tns where table_type ='up'"
    connection = ActiveRecord::Base.connection();
    @results = connection.execute(sql)
    v_display_order = (@results.first.to_s.to_i)+1
    v_cg_search.display_order = v_display_order.to_s
    if v_key_type == 'enrollment/sp'
      v_cg_search.join_left_parent_tn ="vgroups"
      v_cg_search.join_left ="LEFT JOIN "+v_tn+" on vgroups.id in ( select spv2.vgroup_id from scan_procedures_vgroups spv2 where spv2.scan_procedure_id = "+v_tn+".scan_procedure_id and spv2.vgroup_id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships where enrollment_vgroup_memberships.enrollment_id = "+v_tn+".enrollment_id))"
      v_cg_search.join_right ="appointments.appointment_type is not NULL and scan_procedures_vgroups.scan_procedure_id = "+v_tn+".scan_procedure_id and vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships where enrollment_vgroup_memberships.enrollment_id = "+v_tn+".enrollment_id)"
    elsif v_key_type  == 'participant_id'
      v_cg_search.join_left_parent_tn ="vgroups"
      v_cg_search.join_left="LEFT JOIN "+v_tn+" on vgroups.participant_id = "+v_tn+".participant_id"
      v_cg_search.join_right="vgroups.participant_id = "+v_tn+".participant_id"
    elsif v_key_type  == 'subjectid-kc-participant_id'
      v_cg_search.join_left_parent_tn ="vgroups"
      v_cg_search.join_left="LEFT JOIN "+v_tn+" on vgroups.participant_id = "+v_tn+".participant_id"
      v_cg_search.join_right="vgroups.participant_id = "+v_tn+".participant_id"     
    elsif v_key_type  == 'reggieid-kc-participant_id'
      v_cg_search.join_left_parent_tn ="vgroups"
      v_cg_search.join_left="LEFT JOIN "+v_tn+" on vgroups.participant_id = "+v_tn+".participant_id"
      v_cg_search.join_right="vgroups.participant_id = "+v_tn+".participant_id"      
    elsif v_key_type  == 'wrapnum-kc-participant_id'
      v_cg_search.join_left_parent_tn ="vgroups"
      v_cg_search.join_left="LEFT JOIN "+v_tn+" on vgroups.participant_id = "+v_tn+".participant_id"
      v_cg_search.join_right="vgroups.participant_id = "+v_tn+".participant_id"      
    elsif v_key_type  == 'adrcnum-kc-participant_id'
      v_cg_search.join_left_parent_tn ="vgroups"
      v_cg_search.join_left="LEFT JOIN "+v_tn+" on vgroups.participant_id = "+v_tn+".participant_id"
      v_cg_search.join_right="vgroups.participant_id = "+v_tn+".participant_id"      
    end
    v_cg_search.save

    # add columns 
         # change cg_search status = active
         #
        v_sql_cols = "Select lower(col_db), upper(col_type), col_size,col_display, col_function, col_format from "+v_definition_table+" where target_table ='"+v_up_table_name+"' order by display_order"   
        result_cols = connection.execute(v_sql_cols)
        v_cnt =1
        result_cols.each do |col|
              v_cnt = v_cnt + 1
              v_cg_tn_cn = CgTnCn.new
              v_cg_tn_cn.display_order = v_cnt
             if col[1] == "DATE"
              v_cg_tn_cn.data_type ="date"
              v_cg_tn_cn.hide_column_flag = "Y"
            elsif col[1].include?('int')
              v_cg_tn_cn.data_type ="integer"
            elsif col[1] == "FLOAT"
               v_cg_tn_cn.data_type ="float"
            elsif col[1].include?('VARCHAR')
               v_cg_tn_cn.data_type ="string"
            elsif col[1].include?('TEXT')
               v_cg_tn_cn.data_type ="string"
            end
            v_cg_tn_cn.cn = col[0]
            v_cg_tn_cn.common_name = col[3]
            v_cg_tn_cn.export_name = col[3]
           if col[4] == "secondary_key_visitno" 
                  v_cg_tn_cn.secondary_key_visitno_flag = "Y"
            elsif col[4] == "secondary_key_protocol"
                  v_cg_tn_cn.secondary_key_protocol_flag = "Y"
            elsif col[4] == "date"
                # need date_date and age_at_activity calculate
                #v_cg_tn_cn..order_by_flag = "Y"
                v_cg_tn_cn.hide_column_flag = "Y"
                if ( v_date_date_col_hash[col[0]] > '')
                    v_cg_tn_cn.cn = v_date_date_col_hash[col[0]]
                    v_cg_tn_cn.order_by_flag = "Y"
                    v_cg_tn_cn.data_type ="date"
                    v_cg_tn_cn.status_flag ="N" # hiding up date field  ????
                end
                if ( v_age_at_activity_col_hash[col[0]] > '')
                    v_cg_tn_cn_age = CgTnCn.new
                    v_cnt = v_cnt + 1
                    v_cg_tn_cn_age.display_order = v_cnt
                    v_cg_tn_cn_age.cn = v_age_at_activity_col_hash[col[0]]
                    v_cg_tn_cn_age.order_by_flag = "Y"
                    v_cg_tn_cn_age.common_name = col[3]+" age at activity"
                    v_cg_tn_cn_age.export_name = col[3]+" age at activity"
                    v_cg_tn_cn_age.cg_tn_id = v_cg_search.id
                    v_cg_tn_cn_age.data_type ="float"
                    v_cg_tn_cn_age.save
                end

            end
              v_cg_tn_cn.cg_tn_id = v_cg_search.id
              v_cg_tn_cn.save
        end
        v_cg_search.status_flag ="Y"
        v_cg_search.save 
      end
       flash[:notice] = v_msg+'; Everything is fine '+v_up_table_name+'  '+v_up_display_table_name+'     '+v_up_table_yyyymmdd+'    '+v_up_table_name_key_column+'     '+v_key_type+'    '+v_source_up_table_name+'    '+v_source_schema
     
      end # make in source schema
     else
          v_msg = "UP table definition not found in "+v_definition_table
          flash[:notice] = v_msg
      end
    else
         flash[:notice] = 'All the fields are required'
    end # if blank fields  
       render :template => "data_searches/cg_up_load"

end

 def cg_create_table_db
     if !params[:key_type].blank? and !params[:table_name_base].blank?
       v_table_name = "cg_"+params[:table_name_base].downcase
       v_table_name = v_table_name.gsub(' ','_').gsub('"','_').gsub("'","_").gsub("/","_").gsub(".","_").gsub("\\","_").gsub(";","").gsub(":","")
       # check for cg_ tn in database
       v_schema ='panda_production'
       if Rails.env=="development" 
         v_schema ='panda_development'
       end
       sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '"+v_schema+"' AND table_name = '"+v_table_name+"'"
       connection = ActiveRecord::Base.connection();        
       results = connection.execute(sql)
       v_cnt = results.first
       if v_cnt[0].to_i > 0
         flash[:notice] = 'Error: Table '+v_table_name+' already exists in the database.'
         render :template => "data_searches/cg_table_create_db"
       else
         v_key_col_sql = "enrollment_id integer, scan_procedure_id integer"
         v_key_col_edit_sql = "enrollment_id varchar(50) DEFAULT '|', scan_procedure_id varchar(50) DEFAULT '|'"
         if params[:key_type] == "reggieid-kc-participant_id"
             v_key_col_sql ="reggieid_kc varchar(50) "
             v_key_col_join_sql = "participant_id integer"
             v_key_col_edit_join_sql = "participant_id varchar(50) DEFAULT '|'"
             v_key_col_index = "participant_id"
          elsif params[:key_type] == "wrapnum-kc-participant_id"
            v_key_col_sql ="wrapnum_kc varchar(50) "
             v_key_col_join_sql = "participant_id integer"             
             v_key_col_edit_join_sql = "participant_id varchar(50) DEFAULT '|'"
             v_key_col_index = "participant_id"
          elsif params[:key_type] == "adrcnum-kc-participant_id"
             v_key_col_sql ="adrcnum_kc varchar(50) "
              v_key_col_join_sql = "participant_id integer"             
              v_key_col_edit_join_sql = "participant_id varchar(50) DEFAULT '|'"
              v_key_col_index = "participant_id"
         elsif  params[:key_type] == "enrollment/sp"
              v_key_col_sql ="subjectid varchar(50) "
              v_key_col_join_sql = "enrollment_id integer, scan_procedure_id integer"
              v_key_col_edit_join_sql = "enrollment_id varchar(50) DEFAULT '|', scan_procedure_id varchar(50) DEFAULT '|'"
              v_key_col_index = "enrollment_id,scan_procedure_id"
         end
         sql ="create table "+v_table_name+" ("+v_key_col_sql+", general_comment varchar(2000),done_flag varchar(1),status_flag varchar(1),status_comment varchar(500),"+v_key_col_join_sql+")"
         results = connection.execute(sql)
         sql_index = "create index ind_"+v_table_name+" on "+v_table_name+"("+v_key_col_index+")"
         results_index = connection.execute(sql_index)
         sql ="create table "+v_table_name+"_old ("+v_key_col_sql+", general_comment varchar(2000),done_flag varchar(1),status_flag varchar(1),status_comment varchar(500),"+v_key_col_join_sql+")"
         results = connection.execute(sql)
         sql ="create table "+v_table_name+"_new ("+v_key_col_sql+", general_comment varchar(2000),done_flag varchar(1),status_flag varchar(1),status_comment varchar(500),"+v_key_col_join_sql+")"
         results = connection.execute(sql)
         sql ="create table "+v_table_name+"_edit ("+v_key_col_sql+", general_comment varchar(2000) DEFAULT '|',done_flag varchar(1) DEFAULT '|',status_flag varchar(1) DEFAULT '|',status_comment varchar(500) DEFAULT '|',"+v_key_col_edit_join_sql+",delete_key_flag varchar(1) DEFAULT 'N')"
         results = connection.execute(sql)
         flash[:notice] = 'Table '+v_table_name+' was successfully created in the database.'
          
         respond_to do |format|
            format.html { redirect_to( '/cg_table_edit_db?cg_table_name='+v_table_name, :notice => 'Table '+v_table_name+' was successfully created in the database.' )}
  
          end
      
       end
     else 
      render :template => "data_searches/cg_table_create_db"
     end
 end  
 
 def cg_edit_table_db
    v_schema ='panda_production'
    if Rails.env=="development" 
       v_schema ='panda_development'
    end
    sql = "SELECT table_name FROM information_schema.tables WHERE table_schema = '"+v_schema+"' 
    AND table_name LIKE 'cg_%' and table_name NOT LIKE '%_new'  and table_name NOT LIKE '%_old'  and table_name NOT LIKE '%_edit' 
    order by table_name"
    connection = ActiveRecord::Base.connection();        
    @results_cg_tn = connection.execute(sql)
    @v_cg_table_name = ""
    @results_cg_tn_cn = []

    if !params[:cg_action].blank?
      v_tn = params[:cg_table_name]
      
      if params[:cg_action] == "alter"
          # ??? ALTER TABLE <tablename> CHANGE COLUMN <colname> <colname> VARCHAR(65536);
          # keep _edit varchar(50) DEFAULT '|'" 
          v_cn = params[:cg_tn_column_name].gsub(" ","_").gsub(".","_").gsub("-","_").gsub(",","_").gsub(";","_").gsub("'","_").gsub("/","_").gsub("(","_").gsub(")","_").gsub('"','_').downcase
          if params[:cg_table_edit][:datatype]["0"] == "varchar"
              sql = "alter table "+v_tn+" modify "+v_cn+" VARCHAR("+params[:cg_table_edit][:datasize]["0"]+") "
              results = connection.execute(sql)
              sql = "alter table "+v_tn+"_old modify "+v_cn+" VARCHAR("+params[:cg_table_edit][:datasize]["0"]+") "
              results = connection.execute(sql)
              sql = "alter table "+v_tn+"_new modify "+v_cn+" VARCHAR("+params[:cg_table_edit][:datasize]["0"]+") "
              results = connection.execute(sql)
          elsif params[:cg_table_edit][:datatype]["0"] == "int"
              sql = "alter table "+v_tn+" modify "+v_cn+" int "
              results = connection.execute(sql)
              sql = "alter table "+v_tn+"_old modify "+v_cn+" int "
              results = connection.execute(sql)
              sql = "alter table "+v_tn+"_new modify "+v_cn+" int "
              results = connection.execute(sql)
          elsif params[:cg_table_edit][:datatype]["0"] == "float"
            sql = "alter table "+v_tn+" modify "+v_cn+" float "
            results = connection.execute(sql)
            sql = "alter table "+v_tn+"_old modify "+v_cn+" float "
            results = connection.execute(sql)
            sql = "alter table "+v_tn+"_new modify "+v_cn+" float "
            results = connection.execute(sql)
          end
      elsif params[:cg_action] == "change"
        v_cn = params[:cg_tn_column_name].gsub(" ","_").gsub(".","_").gsub("-","_").gsub(",","_").gsub(";","_").gsub("'","_").gsub("/","_").gsub("(","_").gsub(")","_").gsub('"','_').downcase
        v_cn_new = params[:cg_table_edit_db][:cg_tn_column_name_new].gsub(" ","_").gsub(".","_").gsub("-","_").gsub(",","_").gsub(";","_").gsub("'","_").gsub("/","_").gsub("(","_").gsub(")","_").gsub('"','_').downcase
        if params[:cg_table_edit][:datatype]["0"] == "varchar"
           sql = "alter table "+v_tn+" change "+v_cn+ " "+v_cn_new + " VARCHAR("+params[:cg_table_edit][:datasize]["0"]+") "
           results = connection.execute(sql)
           sql = "alter table "+v_tn+"_old change "+v_cn+" "+v_cn_new +" VARCHAR("+params[:cg_table_edit][:datasize]["0"]+") "
           results = connection.execute(sql)
           sql = "alter table "+v_tn+"_new change "+v_cn+" "+v_cn_new +" VARCHAR("+params[:cg_table_edit][:datasize]["0"]+") "
           results = connection.execute(sql)
            sql = "alter table "+v_tn+"_edit change "+v_cn+" "+v_cn_new +" VARCHAR("+params[:cg_table_edit][:datasize]["0"]+") "
            results = connection.execute(sql)
         elsif params[:cg_table_edit][:datatype]["0"] == "int"
            sql = "alter table "+v_tn+" change "+v_cn+" "+v_cn_new +" INT "
            results = connection.execute(sql)
            sql = "alter table "+v_tn+"_old change "+v_cn+" "+v_cn_new +" INT "
            results = connection.execute(sql)
            sql = "alter table "+v_tn+"_new change "+v_cn+" "+v_cn_new +" INT "
            results = connection.execute(sql)
            sql = "alter table "+v_tn+"_edit change "+v_cn+" "+v_cn_new +" VARCHAR(50) "
            results = connection.execute(sql)
          elsif params[:cg_table_edit][:datatype]["0"] == "float"
             sql = "alter table "+v_tn+" change "+v_cn+" "+v_cn_new +" FLOAT "
             results = connection.execute(sql)
             sql = "alter table "+v_tn+"_old change "+v_cn+" "+v_cn_new +" FLOAT "
             results = connection.execute(sql)
             sql = "alter table "+v_tn+"_new change "+v_cn+" "+v_cn_new +" FLOAT "
             results = connection.execute(sql)
             sql = "alter table "+v_tn+"_edit change "+v_cn+" "+v_cn_new +" VARCHAR(50) "
             results = connection.execute(sql)  
             v_cn = v_cn_new  # redefine so where below finds a cn
          end
          # change cg_table column
          cg_tn = CgTn.where("tn in (?)",v_tn)
          cg_tn_cn = CgTnCn.where("cg_tn_id in (?) and cn in ('"+v_cn+"')",cg_tn[0].id)
          if !cg_tn_cn.blank?
          #  puts "aaaaa cg_tn_cn="+cg_tn_cn[0].id.to_s
            cg_tn_cn[0].cn = v_cn_new
            cg_tn_cn[0].save
          end      
      elsif params[:cg_action] == "delete"
         v_cn = params[:cg_tn_column_name]
         sql = "alter table "+v_tn+" drop column "+v_cn
         results = connection.execute(sql) 
         sql = "alter table "+v_tn+"_old drop column "+v_cn
         results = connection.execute(sql)
         sql = "alter table "+v_tn+"_new drop column "+v_cn
         results = connection.execute(sql)
         sql = "alter table "+v_tn+"_edit drop column "+v_cn
         results = connection.execute(sql) 
         # delete cg_table column
         cg_tn = CgTn.where("tn in (?)",v_tn)
         # getting nil error
         if !v_cn.blank? and !cg_tn.blank? and !cg_tn[0].blank? and !(cg_tn[0].id).blank?
           cg_tn_cn = CgTnCn.where("cg_tn_id in (?) and cn in (?)",cg_tn[0].id,v_cn)
           if !cg_tn_cn.blank?
             cg_tn_cn[0].delete       
           end
         end
      elsif params[:cg_action] == "add"
          # loop thru key, check for check box  
          params[:cg_table_edit][:key].each do |v|
            if !params[:cg_table_edit][:add_column_name].blank? and !params[:cg_table_edit][:add_column_name][v].blank? and params[:cg_table_edit][:add_column][v] == "1"
             v_add_column_name = params[:cg_table_edit][:add_column_name][v].downcase
             v_add_column_name = v_add_column_name.gsub(' ','_').gsub('"','_').gsub("'","_").gsub("/","_").gsub(".","_").gsub("\\","_").gsub(";","").gsub(":","").gsub("-","_").gsub("/","_").gsub("(","_").gsub(")","_")
             sql = "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = '"+v_schema+"' AND table_name = '"+v_tn+"' and column_name='"+v_add_column_name+"'"
             connection = ActiveRecord::Base.connection();        
             results = connection.execute(sql)
             v_cnt = results.first
             if v_cnt[0].to_i > 0
                 flash[:notice] = 'Error: Column '+v_add_column_name+' in Table '+v_tn+' already exists in the database.'              
             else
              if params[:cg_table_edit][:datatype][v] == "varchar"
                  sql = "alter table "+v_tn+" add "+v_add_column_name+" VARCHAR("+params[:cg_table_edit][:datasize][v]+") "
                  results = connection.execute(sql)
                  sql = "alter table "+v_tn+"_old add "+v_add_column_name+" VARCHAR("+params[:cg_table_edit][:datasize][v]+") "
                  results = connection.execute(sql)
                  sql = "alter table "+v_tn+"_new add "+v_add_column_name+" VARCHAR("+params[:cg_table_edit][:datasize][v]+") "
                  results = connection.execute(sql)
                  sql = "alter table "+v_tn+"_edit add "+v_add_column_name+" VARCHAR("+params[:cg_table_edit][:datasize][v]+")  DEFAULT '|' "
                  results = connection.execute(sql)
              elsif params[:cg_table_edit][:datatype][v] == "int"
                  sql = "alter table "+v_tn+" add "+v_add_column_name+" int "
                  results = connection.execute(sql)
                  sql = "alter table "+v_tn+"_old add "+v_add_column_name+" int "
                  results = connection.execute(sql)
                  sql = "alter table "+v_tn+"_new add "+v_add_column_name+" int "
                  results = connection.execute(sql)
                  sql = "alter table "+v_tn+"_edit add "+v_add_column_name+"  varchar(50) DEFAULT '|' "
                  results = connection.execute(sql)
              elsif params[:cg_table_edit][:datatype][v] == "float"
                sql = "alter table "+v_tn+" add "+v_add_column_name+" float "
                results = connection.execute(sql)
                sql = "alter table "+v_tn+"_old add "+v_add_column_name+" float "
                results = connection.execute(sql)
                sql = "alter table "+v_tn+"_new add "+v_add_column_name+" float "
                results = connection.execute(sql)
                sql = "alter table "+v_tn+"_edit add "+v_add_column_name+"  varchar(50) DEFAULT '|'"
                results = connection.execute(sql)
              end
             end
            end 
          end        
      end
      
    end

   	if !params[:cg_table_name].blank?
   		@v_cg_table_name = params[:cg_table_name]
   		sql = "SELECT `COLUMN_NAME`,`DATA_TYPE`, `CHARACTER_MAXIMUM_LENGTH` FROM `INFORMATION_SCHEMA`.`COLUMNS` WHERE `TABLE_SCHEMA`='"+v_schema+"' AND `TABLE_NAME`='"+@v_cg_table_name +"'"
   		@results_cg_tn_cn = connection.execute(sql)
   	end
   	@v_cg_tn_column_name =""
   	@v_cg_tn_column_datatype=""
   	@v_cg_tn_column_datasize=""
   	if !params[:cg_tn_column_name].blank?
   	  @v_cg_tn_column_name  = params[:cg_tn_column_name]
   	  @results_cg_tn_cn.each do |c|
   	    if c[0] == @v_cg_tn_column_name
   	      @v_cg_tn_column_datatype=c[1]
         	@v_cg_tn_column_datasize=c[2].to_s
   	    end
   	  end
   	end
   	@v_cg_action =""
   	if !params[:cg_action].blank?
   	  @v_cg_action  = params[:cg_action]
   	end
    @v_data_types=[["varchar","varchar"],["int","int"],["float","float"]]
    @v_data_sizes=[["1","1"],["10","10"],["30","30"],["50","50"],["100","100"],["200","200"],["500","500"],["1000","1000"],["2000","2000"]] 
    
    # determine key_type from columns  
    # enrollment/sp =>subjectid,enrollment_id,scan_procedure_id
    # participant_id => participant_id
    v_cols = []	
    @results_cg_tn_cn.each do |c|
 	    v_cols.push(c[0])
 	  end
    @v_key_type = ""
    if v_cols.include?('subjectid') and v_cols.include?('enrollment_id') and v_cols.include?('scan_procedure_id') 
        @v_key_type = "enrollment/sp"
    elsif v_cols.include?('participant_id') and v_cols.include?('reggieid_kc') 
      @v_key_type = "reggieid-kc-participant_id"
    elsif v_cols.include?('participant_id') and v_cols.include?('wrapnum_kc') 
      @v_key_type = "wrapnum-kc-participant_id"
    elsif v_cols.include?('participant_id') and v_cols.include?('adrcnum_kc') 
      @v_key_type = "adrcnum-kc-participant_id"
    end
    @v_link_cg_table_setup = "N"
    if @v_key_type > ""
       sql = "select count(*) from cg_tns where tn ='"+@v_cg_table_name+"'"
       @results_check_cg = connection.execute(sql)
       if @results_check_cg.first.to_s.to_i < 1
         @v_link_cg_table_setup = "Y"
      end 
    end
    
     render :template => "data_searches/cg_table_edit_db"
 end  
 
  private    
 def cg_search_params
        params.require(:cg_search).permit!
 end       
       
    
end
