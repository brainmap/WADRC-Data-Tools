class DataSearchesController < ApplicationController
   # this isn't used - was a test bed for making sql
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
      @cg_tn_key_y = []
      @cg_tn_key_unique_y = []
      @cg_tns = CgTn.where("table_type='column_group' and status_flag='Y'").order(:id)
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
      respond_to do |format|
          format.html
      end
      
    end
    def cg_edit_table
      # really want to stop edit_table from being used on core tables
      v_exclude_tables_array =['appointments','blooddraws','cg_queries','cg_query_tn_cns','cg_query_tns','cg_tn_cns','cg_tns',
        'cg_tns_users','employees','enrollment_vgroup_memberships','enrollment_visit_memberships','enrollments',
        'image_comments','image_dataset_quality_checks','image_datasets','lumbarpuncture_results','lumbarpunctures','mriperformances','mriscantasks',
        'neuropsyches','participants','petscans','q_data','q_data_forms','question_scan_procedures','questionform_questions','questionform_scan_procedures',
        'questionforms','questionnaires','questions','radiology_comments','roles','scan_procedures','scan_procedures_vgroups','scan_procedures_visits',
        'scheduleruns','schedules','schedules_users','series_descriptions','users','vgroups','visits','vitals'] 
      @cg_tn = CgTn.find(params[:id])
      v_key_columns =""
      if @cg_tn.table_type == 'column_group' and @cg_tn.editable_flag == "Y"  and !v_exclude_tables_array.include?(@cg_tn.tn.downcase) # want to limit to cg tables
        
        
        @cns = []
        @key_cns = []
        @v_key = []
        @cns_type_dict ={}
        @cns_common_name_dict = {}
        @cg_data_dict = {}
        @cg_edit_data_dict = {}
        
        @cg_tn_cns =CgTnCn.where("cg_tn_id in (?)",@cg_tn.id)
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
        sql = "SELECT "+@cns.join(',') +" FROM "+@cg_tn.tn 
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
          if !v_key.blank? and !@v_key.include?(v_key) 
              @v_key.push(v_key)
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
        
        if !params[:cg_edit_table].blank? and !params[:cg_edit_table][:key].blank?
          # remove all params[:cg_edit_table][:key] rows from @cg_tn.tn+"_edit" if delete_edit
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
            params[:cg_edit_table][:key].each do |k|
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
              @cns.each do |cn|
            	    if  !@cg_edit_data_dict[k+cn].blank? and @cg_edit_data_dict[k+cn] != "|" 
            		      v_edit_in_row_flag ="Y"
            		   end
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
                                v_tmp_value_array.push("")
                                v_tmp_cn_array.push(cn)
                              end
                            end
                    end
                    v_cnt_cn = v_cnt_cn + 1
                  end
                  if v_key_value_array.size > 0 and v_tmp_value_array.size > 0 and @cg_edit_data_dict[k+"delete_key_flag"] != "Y"
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
                  @cns.each do |cn|
                    if !params[:cg_edit_table][:edit_col].blank? and  !params[:cg_edit_table][:edit_col][k].blank? and !v_key_cn_array.include?(cn)
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
                                v_tmp_value_array.push("")
                                v_tmp_cn_array.push(cn)
                              end
                            end
                    end
                    v_cnt_cn = v_cnt_cn + 1
                  end
                  if v_key_value_array.size > 0
                      v_tmp_cn_array.concat(v_key_cn_array)
                      v_tmp_value_array.concat(v_key_value_array)
                      sql = "insert into "+@cg_tn.tn+"_edit("+v_tmp_cn_array.join(',')+") values("+v_tmp_value_array.join(",")+")"
                       @results = connection.execute(sql)
                  end
                end
              end
              puts " v_cnt ="+v_cnt.to_s+" end  key="+k
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
      
      @cg_tn_cns =CgTnCn.where("cg_tn_id in (?)",@cg_tn.id)
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
      sql = "SELECT "+@cns.join(',') +" FROM "+@cg_tn.tn 
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
        if !v_key.blank? and !@v_key.include?(v_key) 
            @v_key.push(v_key)
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
        
        
      end
      respond_to do |format|
          format.html
      end
      
    end
   # can not do a self join-- unless two copies of table - unique tn_id, tn_cn_id
    def cg_search   

      scan_procedure_list = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i).join(',')
      # make the sql -- start with base 
      @local_column_headers =["Date","Protocol","Enumber","RMR"]
      @local_fields = []
      @local_conditions =[]
      @conditions = [] # for the q_data_search
      @conditions_bak = []
      @local_tables =[] # need to add outer join to table, -- 
      @table_types =[] 
      @tables_left_join_hash = Hash.new
      @joins = [] # just inner joins
      @sp_array =[]
      @cg_query_tn_id_array = []
      @cg_query_tn_hash = Hash.new
      @cg_query_tn_cn_hash = Hash.new
      @cg_query_cn_hash = Hash.new
      params["search_criteria"] =""
      ####@headers_q_data = []
      @q_data_form_array = []
      @q_data_fields_hash = Hash.new
      @q_data_left_join_hash = Hash.new
      @q_data_left_join_vgroup_hash = Hash.new
      @q_data_headers_hash = Hash.new
      @q_data_tables_hash = Hash.new
      @fields_hash = Hash.new
      
      request_format = request.formats.to_s
      @html_request ="Y"
      case  request_format
        when "text/html" then  # application/html ?
            @html_request ="Y" 
        else
            @html_request ="N"
        end
      
      # get stored cg_search
      if !params[:cg_search].blank? and !params[:cg_search][:cg_query_id].blank?
         @cg_query = CgQuery.find(params[:cg_search][:cg_query_id])
        if !@cg_query.scan_procedure_id_list.blank?
           @sp_array = @cg_query.scan_procedure_id_list.split(",")
         end

         @cg_query_tns =  CgQueryTn.where("cg_query_id = "+@cg_query.id.to_s)
         @cg_query_tns.each do |cg_query_tn|
           v_tn_id = cg_query_tn.cg_tn_id 
            @cg_query_tn_id_array.push(v_tn_id) # need to retrieve for display on the page
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
          # NEED TO BUILD  v_condition = -- LOOK AT OTHER SEARCHES
         @cg_query.cg_name = params[:cg_search][:cg_name]
         @cg_query.rmr = params[:cg_search][:rmr]
         @cg_query.enumber = params[:cg_search][:enumber]
         @cg_query.gender = params[:cg_search][:gender]
         @cg_query.min_age = params[:cg_search][:min_age]
         @cg_query.max_age = params[:cg_search][:max_age]
         @cg_query.save_flag = params[:cg_search][:save_flag]
         @cg_query.status_flag = params[:cg_search][:save_flag] # NOT SURE HOW SAVE_FLAG vs STATUS_FLAG will work
         @cg_query.user_id  = @user.id

         # would like to switch to vgroups.id limit, by run_search_q_data gets conditions, and might expect appointments.id limits
         # build conditions from sp, enumber, rmr, gender, min_age, max_age -- @table_types.push('base')
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

         if !params[:cg_search][:enumber].blank?
            @table_types.push('base')
          
            if params[:cg_search][:enumber].include?(',') # string of enumbers
             v_enumber =  params[:cg_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
             v_enumber = v_enumber.gsub(/,/,"','")
             v_condition ="   appointments.id in (select a2.id from enrollment_vgroup_memberships,enrollments, appointments a2
                  where enrollment_vgroup_memberships.vgroup_id= a2.vgroup_id 
                   and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"'))"
            else
              v_condition ="   appointments.id in (select a2.id from enrollment_vgroup_memberships,enrollments, appointments a2
               where enrollment_vgroup_memberships.vgroup_id= a2.vgroup_id 
                and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:cg_search][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"
            end
             @local_conditions.push(v_condition)
             params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:cg_search][:enumber]
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
             v_condition ="     appointmens.id in (select a2.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments a2
                                where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                             and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                             and a2.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                             and floor(DATEDIFF(a2.appointment_date,participants.dob)/365.25) >= "+params[:cg_search][:min_age].gsub(/[;:'"()=<>]/, '')+"   )"
             @local_conditions.push(v_condition)
             params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:cg_search][:min_age]
         elsif params[:cg_search][:min_age].blank? && !params[:cg_search][:max_age].blank?
             @table_types.push('base')
              v_condition ="     appointmens.id in (select a2.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments a2
                                 where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                              and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                              and a2.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                          and floor(DATEDIFF(a2.appointment_date,participants.dob)/365.25) <= "+params[:cg_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
             @local_conditions.push(v_condition)
             params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:cg_search][:max_age]
         elsif !params[:cg_search][:min_age].blank? && !params[:cg_search][:max_age].blank?
            @table_types.push('base')
            v_condition ="      appointments.id in (select a2.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments a2
                               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                            and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                            and a2.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                        and floor(DATEDIFF(a2.appointment_date,participants.dob)/365.25) between "+params[:cg_search][:min_age].gsub(/[;:'"()=<>]/, '')+" and "+params[:cg_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
           @local_conditions.push(v_condition)
           params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:cg_search][:min_age]+" and "+params[:cg_search][:max_age]
         end    
         @conditions_bak.concat(@local_conditions)     
         if params[:cg_search][:save_search] == "1"    
            @cg_query.save
            params[:cg_search][:cg_query_id] = @cg_query.id.to_s
         end 
         # loop thru each table
         if !params[:cg_search][:tn_id].blank? 
           params[:cg_search][:tn_id].each do |tn_id|
               v_tn_id = tn_id.to_a.to_s
             if (!params[:cg_search][:include_tn].blank? and !params[:cg_search][:include_tn][v_tn_id ].blank?) or !params[:cg_search][:join_type][v_tn_id].blank? or (!params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank? and !params[:cg_search][:include_cn][v_tn_id].blank?) or  !params[:cg_search][:condition][v_tn_id].blank?   
               @cg_query_tn = CgQueryTn.new
               @cg_query_tn.cg_tn_id =v_tn_id
               @cg_query_tn.cg_query_id = @cg_query.id
               if !params[:cg_search][:include_tn].blank? and !params[:cg_search][:include_tn][v_tn_id ].blank?
                 @cg_query_tn.include_tn = 1
               end
               @cg_query_tn.join_type = params[:cg_search][:join_type][v_tn_id]

               @cg_tn = CgTn.find(v_tn_id)
                if @cg_query_tn.join_type == 1  # outer join joins  # NEED PARENT TABLE join_left_parent_tn
                    @table_types.push(@cg_tn.table_type)
                            # need to add outer as part of table length !!!!! THIS HAS TO BE FIXED
                    if @local_tables.index(@cg_tn.join_left_parent_tn).blank?   # WHAT ABOUT ALIAS                        
                                  @local_tables.push(@cg_tn.join_left_parent_tn)                                
                    end
                    if ! @tables_left_join_hash[@cg_tn.join_left_parent_tn ].blank?
                        @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left+"  "+ @tables_left_join_hash[@cg_tn.join_left_parent_tn ]
                    else
                        @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left
                    end
                else # was doing inner join by default , change to outer #### 
                  if  !params[:cg_search][:join_type][v_tn_id].blank? or 
                    (!params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank?) or
                      !params[:cg_search][:condition][v_tn_id].blank? # NEED TO ADD LIMIT BY CN
                      v_include_tn = "N"
                      if !params[:cg_search][:cn_id].blank? and !params[:cg_search][:cn_id][v_tn_id].blank?
                        params[:cg_search][:cn_id][v_tn_id].each do |tn_cn_id|
                           v_tn_cn_id = tn_cn_id.to_a.to_s
                           if (!params[:cg_search][:condition][v_tn_id].blank? and !params[:cg_search][:condition][v_tn_id][v_tn_cn_id].blank?) or
                                 (!params[:cg_search][:include_cn].blank? and !params[:cg_search][:include_cn][v_tn_id].blank? and !params[:cg_search][:include_cn][v_tn_id][v_tn_cn_id].blank? )
                             v_include_tn ="Y"
                           end  
                        end
                      end
                    if v_include_tn == "Y"                       
                        if params[:cg_search][:join_type][v_tn_id].blank? and !@cg_tn.join_left.blank?  # setting default to outer join
                           @table_types.push(@cg_tn.table_type)
                                    # need to add outer as part of table length !!!!! THIS HAS TO BE FIXED
                            if @local_tables.index(@cg_tn.join_left_parent_tn).blank?   # WHAT ABOUT ALIAS                        
                                          @local_tables.push(@cg_tn.join_left_parent_tn)                                
                            end
                            if ! @tables_left_join_hash[@cg_tn.join_left_parent_tn ].blank?
                                @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left+"  "+ @tables_left_join_hash[@cg_tn.join_left_parent_tn ]
                            else
                                @tables_left_join_hash[@cg_tn.join_left_parent_tn ] = @cg_tn.join_left
                            end
                        else
                          @local_tables.push(@cg_tn.tn) # use uniq later
                          @table_types.push(@cg_tn.table_type) # use uniq later  use mix of table_type to define core join
                                 # base, cg_enumber, cg_enumber_sp, cg_rmr, cg_rmr_sp, cg_sp, cg_wrapnum, cg_adrcnum, cg_reggieid
                           @local_conditions.push(@cg_tn.join_right) # use uniq later
                        end
                    end
                  end
                 end
               
                         
               # need hash with cg_tn_id as key
               if params[:cg_search][:save_search] == "1"    
                  @cg_query_tn.save
               end
               @cg_query_tn_hash[v_tn_id] = @cg_query_tn
               if !params[:cg_search][:cn_id].blank? and !params[:cg_search][:cn_id][v_tn_id].blank?
                 params[:cg_search][:cn_id][v_tn_id].each do |tn_cn_id|
                   v_tn_cn_id = tn_cn_id.to_a.to_s
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
                              join_left = "LEFT JOIN (select LOOKUP_REFS.ref_value id_"+v_tn_cn_id.to_s+", LOOKUP_REFS.description a_"+v_tn_cn_id.to_s+"  
                                from  LOOKUP_REFS where   LOOKUP_REFS.label ='"+@cg_tn_cn.ref_table_b+"'  
                                ) cg_alias_"+v_tn_cn_id.to_s+" on "+@cg_tn.tn+"."+@cg_tn_cn.cn+" = cg_alias_"+v_tn_cn_id.to_s+".id_"+v_tn_cn_id.to_s 
                              
                              if !@tables_left_join_hash[v_join_left_tn ].blank?               
                                   @tables_left_join_hash[v_join_left_tn ] =  @tables_left_join_hash[v_join_left_tn ]+"  "+join_left
                              else
                                  @tables_left_join_hash[v_join_left_tn ] = join_left
                              end
                               @local_fields.push("cg_alias_"+v_tn_cn_id.to_s+".a_"+v_tn_cn_id.to_s)
                           elsif !@cg_tn_cn.ref_table_a.blank? # camel case LookupPettracer to lookup_pettracers  - description
                              join_left = "LEFT JOIN (select "+@cg_tn_cn.ref_table_a.pluralize.underscore+".id id_"+v_tn_cn_id.to_s+", "+@cg_tn_cn.ref_table_a.pluralize.underscore+".description a_"+v_tn_cn_id.to_s+
                                      " from "+@cg_tn_cn.ref_table_a.pluralize.underscore+" ) cg_alias_"+v_tn_cn_id.to_s+" on  "+@cg_tn.tn+"."+@cg_tn_cn.cn+" = cg_alias_"+v_tn_cn_id.to_s+".id_"+v_tn_cn_id.to_s
                              if !@tables_left_join_hash[v_join_left_tn ].blank?               
                                    @tables_left_join_hash[v_join_left_tn] = @tables_left_join_hash[v_join_left_tn ]+"  "+join_left
                              else
                                    @tables_left_join_hash[v_join_left_tn ] = join_left
                              end
                               @local_fields.push("cg_alias_"+v_tn_cn_id.to_s+".a_"+v_tn_cn_id.to_s)
                           else
                               @local_fields.push(@cg_tn.tn+"."+@cg_tn_cn.cn)
                           end
                         elsif !@cg_tn_cn.q_data_form_id.blank? and  @html_request =="N"  # need q_data
                           if @html_request =="N"
                               @local_fields.push(@cg_tn.tn+"."+@cg_tn_cn.cn)
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

                           @conditions.concat(@conditions_bak)
                           # @conditions  captured above, after first set of form elements - mainly want sp limit
                           # define q_data form_id  
                           # pass to run_search_q_data and get back fields, columns_headers, conditions, etc.
                           @tables =[@cg_tn.tn]
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
           
                           # ??? PROBLEM WITH participant?
                           @left_join_vgroup.each do |vg|
                                if !@tables_left_join_hash["vgroups" ].blank?  and !@tables_left_join_hash[v_join_left_tn ].blank?             
                                      @tables_left_join_hash["vgroups"] = @tables_left_join_hash[v_join_left_tn ]+"  "+vg
                                else
                                      @tables_left_join_hash["vgroups" ] = vg
                                end  
                           end   
                           #### don't think this is needed@local_fields.concat(@fields)
                           @left_join.each do |lj|
                              if !@tables_left_join_hash[v_join_left_tn ].blank?               
                                    @tables_left_join_hash[v_join_left_tn] = @tables_left_join_hash[v_join_left_tn ]+"  "+lj
                              else
                                    @tables_left_join_hash[v_join_left_tn ] = lj
                              end
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
                     if !params[:cg_search][:condition][v_tn_id].blank?
                        @cg_query_tn_cn.condition = params[:cg_search][:condition][v_tn_id][v_tn_cn_id]
                       # [['=','0'],['>=','1'],['<=','2'],['!=','3'],['between','4'],['is blank','5']]
                        if @cg_query_tn_cn.condition == 0 
                          v_condition =  " "+@cg_tn.tn+"."+@cg_tn_cn.cn+" = '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"'"
                          if !v_condition.blank?
                              @local_conditions.push(v_condition)
                              params["search_criteria"] = params["search_criteria"] +", "+@cg_tn.tn+"."+@cg_tn_cn.cn+" = "+@cg_query_tn_cn.value_1
                          end
                        elsif @cg_query_tn_cn.condition ==  1
                          v_condition =  " "+@cg_tn.tn+"."+@cg_tn_cn.cn+" >= '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' "
                          if !v_condition.blank?
                              @local_conditions.push(v_condition)
                              params["search_criteria"] = params["search_criteria"] +", "+@cg_tn.tn+"."+@cg_tn_cn.cn+" >= "+@cg_query_tn_cn.value_1
                          end
                        elsif @cg_query_tn_cn.condition == 2
                          v_condition =  " "+@cg_tn.tn+"."+@cg_tn_cn.cn+" <= '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' "
                          if !v_condition.blank?
                             @local_conditions.push(v_condition)
                             params["search_criteria"] = params["search_criteria"] +", "+@cg_tn.tn+"."+@cg_tn_cn.cn+" <= "+@cg_query_tn_cn.value_1
                          end
                        elsif @cg_query_tn_cn.condition == 3
                          v_condition =  " "+@cg_tn.tn+"."+@cg_tn_cn.cn+" != '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' "
                          if !v_condition.blank?
                              @local_conditions.push(v_condition)
                              params["search_criteria"] = params["search_criteria"] +", "+@cg_tn.tn+"."+@cg_tn_cn.cn+" != "+@cg_query_tn_cn.value_1                           
                          end
                        elsif @cg_query_tn_cn.condition == 4
                          v_condition =  " "+@cg_tn.tn+"."+@cg_tn_cn.cn+" between '"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' and '"+ @cg_query_tn_cn.value_2.gsub("'","''").gsub(/[;:"()=<>]/, '')+"' "
                          if !v_condition.blank?
                              @local_conditions.push(v_condition)
                              params["search_criteria"] = params["search_criteria"] +", "+@cg_tn.tn+"."+@cg_tn_cn.cn+" between "+@cg_query_tn_cn.value_1+" and "+ @cg_query_tn_cn.value_2
                          end
                        elsif @cg_query_tn_cn.condition == 5
                          v_condition = " trim( "+@cg_tn.tn+"."+@cg_tn_cn.cn+") is NULL "
                          if !v_condition.blank?
                              @local_conditions.push(v_condition)
                              params["search_criteria"] = params["search_criteria"] +", "+@cg_tn.tn+"."+@cg_tn_cn.cn+" is blank"
                          end
                        elsif @cg_query_tn_cn.condition == 6
                          v_condition = " trim( "+@cg_tn.tn+"."+@cg_tn_cn.cn+") is NOT NULL "
                          if !v_condition.blank?
                              @local_conditions.push(v_condition)
                              params["search_criteria"] = params["search_criteria"] +", "+@cg_tn.tn+"."+@cg_tn_cn.cn+" is not blank "
                          end  
                        elsif @cg_query_tn_cn.condition == 7
                          v_condition = "  "+@cg_tn.tn+"."+@cg_tn_cn.cn+" like '%"+@cg_query_tn_cn.value_1.gsub("'","''").gsub(/[;:"()=<>]/, '')+"%' "
                          if !v_condition.blank?
                              @local_conditions.push(v_condition)
                              params["search_criteria"] = params["search_criteria"] +", "+@cg_tn.tn+"."+@cg_tn_cn.cn+" contains "+@cg_query_tn_cn.value_1
                          end
                        end
                      end                
                     
                     if params[:cg_search][:save_search] == "1"    
                        @cg_query_tn_cn.save
                     end
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
                         if params[:cg_search][:condition][v_tn_id][v_tn_cn_id].blank?
                            params[:cg_search][:condition][v_tn_id].delete(v_tn_cn_id)
                         elsif params[:cg_search][:condition][v_tn_id][v_tn_cn_id] == ""
                                params[:cg_search][:condition][v_tn_id].delete(v_tn_cn_id)
                         end
                      else
                        params[:cg_search][:condition].delete(v_tn_id)
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
                    v_tn_cn_id = tn_cn_id.to_a.to_s
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
         end
         
         
       end
      end 
      if !params[:cg_search].blank? and !params[:cg_search][:include_tn].blank?
        params[:cg_search].delete('include_tn') 
      end
      
      
      @sp_array.push("-1") # need something in the array
       # for stored query drop down
      sql = "select  concat(cg_name,' - ',users.username,' - ', date_format(cg_queries.created_at,'%Y %m %d')),cg_queries.id  
      from cg_queries, users where status_flag != 'N' and cg_queries.user_id = users.id  
         order by save_flag desc, users.username, date_format(cg_queries.created_at,'%Y %m %d') desc"
      connection = ActiveRecord::Base.connection();
      @results_stored_search = connection.execute(sql)
      
      # trim leading ","
      params["search_criteria"] = params["search_criteria"].sub(", ","")
      
      if !@table_types.blank? and !@table_types.index('base').blank?  # extend to cg_enumber, cg_enumber_sp, cg_rmr, cg_rmr_sp, cg_sp, cg_wrapnum, cg_adrcnum, cg_reggieid
        @local_tables.push("vgroups")
        @local_tables.push("appointments") # --- include in mri, pet, lp, lh, q views -- need for other limits -- ? switch to vgroup?
        @local_tables.push("scan_procedures")
        @local_tables.push("scan_procedures_vgroups")
        @fields_front =[]
        @fields_front.push("vgroups.id vgroup_id")
        @fields_front.push("vgroups.vgroup_date")
        @fields_front.push("vgroups.rmr")
        @local_fields = @fields_front.concat(@local_fields)
        #@local_conditions.push("vgroups.id = appointments.vgroup_id")
        @local_conditions.push("scan_procedures_vgroups.scan_procedure_id in ("+scan_procedure_list+") ")
        @local_conditions.push("scan_procedures.id = scan_procedures_vgroups.scan_procedure_id")
        @local_conditions.push("scan_procedures_vgroups.vgroup_id = vgroups.id")
        @local_conditions.push("appointments.vgroup_id = vgroups.id")
                                            # everything always joined
        @order_by =["vgroups.vgroup_date DESC", "vgroups.rmr"]
     
        #run_search_q_data tn_cn_id/tn_id in (686/676,687/677,688/688) common_name = "question fields" vs run_search if 
      end     
      @column_number =   @local_column_headers.size
           
  if !params[:cg_search].blank? and !@table_types.blank? and !@table_types.index('base').blank?
    @local_conditions.delete_if {|x| x == "" }   # a blank getting inserted 
    sql = " select distinct "+@local_fields.join(',')+" from "
    @all_tables = []
    @local_tables.uniq.each do |tn|   # need left join right after parent tn
       v_tn = tn
       if !@tables_left_join_hash[tn].blank?
          v_tn = v_tn +" "+ @tables_left_join_hash[tn] 
       end
       @all_tables.push(v_tn)
    end
    sql = sql + @all_tables.join(", ")
    sql = sql + " where "+ @local_conditions.uniq.join(" and ")
    sql = sql+" order by "+@order_by.join(",")
    @sql = sql
    # run the sql ==>@results, after some substitutions

#puts sql

    @results2 = connection.execute(sql)
    @temp_results = @results2

    @results = []   
    i =0
    @temp_results.each do |var|
      @temp = []
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
    if @html_request =="N"  and !@q_data_form_array.blank?
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
    
    @results_total = @results # pageination makes result count wrong
    t = Time.now 
    @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
  end   
  
      respond_to do |format|
        format.xls # cg_search.xls.erb
        if !params[:cg_search].blank? and !@table_types.blank? and !@table_types.index('base').blank?
          format.html  {@results = Kaminari.paginate_array(@results).page(params[:page]).per(100)}  
        else
          format.html 
        end
        format.xml  { render :xml => @lumbarpunctures }
      end
     
    end

 #def run_search
#   copy of def index in application_controller  -- so other controllers can get at  -- need for csv export
# end
    
    
end
