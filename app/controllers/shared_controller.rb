#DO NOT ADD TO GITHUB
# encoding: utf-8
require 'csv'
class SharedController < ActionController::Base
  
  def file_upload
    puts " in file upload in shared AaAAAAAAAAAAAA"
    @schedule = Schedule.find(params[:schedule_id]) #where("name in ('adrc_upload')").first
     @schedulerun = Schedulerun.new
     @schedulerun.schedule_id = @schedule.id
     @schedulerun.comment ="starting "+@schedule.name
     @schedulerun.save
     @schedulerun.start_time = @schedulerun.created_at
     @schedulerun.save
     v_comment = ""
     v_comment_warning =""
     v_shared = Shared.new
     
     # NEED FULL LOAD - PARTIAL LOAD OPTION --- CHECK FOR KEY
    # check that database table exisits
    sql = " select table_name from information_schema.tables  where table_name='"+(@schedule.target_table).strip+"' and table_schema='database_name' "
     v_schema ='panda_production'
     if Rails.env=="development" 
       v_schema ='panda_development'
     end
     v_error_flag = "N"
     sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '"+v_schema+"' AND table_name = '"+(@schedule.target_table).strip+"'"
     connection = ActiveRecord::Base.connection();        
     results = connection.execute(sql)
     v_cnt = results.first
     if v_cnt[0] < 1
       v_comment_warning = "The table "+@schedule.target_table+" needs to be created in the database. \n "+v_comment_warning 
       v_error_flag = "Y"
     end
    # check that cg_table exists
    sql = "select COUNT(*) from cg_tns where tn = '"+(@schedule.target_table).strip+"'"
    results = connection.execute(sql)
    v_cnt = results.first
    if v_cnt[0] < 1
      v_comment_warning = "The table "+@schedule.target_table+" needs to be added as a search / cg_ table. \n "+v_comment_warning 
      v_error_flag = "Y"
    end

    if !params[:file_name].blank? and v_error_flag == "N"
       uploaded_io = params[:file_name]
       v_file_name = uploaded_io.original_filename
       v_comment = "file name= "+v_file_name+" |"+v_comment
       @schedulerun.comment =v_comment[0..1990]
       @schedulerun.save

       v_file_content = uploaded_io.read
       v_file_content = v_file_content.gsub("\r","\n")  # getting carriage return instead of newline - but might get newline  --- likes double quote vs single quote!!!!
       v_content_array = v_file_content.split("\n")
       v_file_header = v_content_array[0]
       if v_file_header != @schedule.file_header
         v_comment = "ERROR -file header differs from expected header  actual= "+v_file_header+" != expected= "+@schedule.file_header+" |"+v_comment
         @schedulerun.comment =v_comment[0..1990]
          @schedulerun.save
       else 
         v_comment = "file header match expected |"+v_comment
         @schedulerun.comment =v_comment[0..1990]
          @schedulerun.save
          csv = CSV.parse(uploaded_io.read, :headers => true)
          v_file_columns_included_arr = @schedule.file_columns_included.split(',')
          v_expected_cell_cnt = v_file_columns_included_arr.size
          connection = ActiveRecord::Base.connection();
          v_sql_base_insert = "insert into "+(@schedule.target_table).strip+"_new("+@schedule.target_table_columns+" )values("
          v_sql = "truncate table "+(@schedule.target_table).strip+"_new"
          results = connection.execute(v_sql)
          
          v_include =[]
          v_cnt = 0
          v_file_header = v_content_array[0].split(',')
          v_file_header.each do |c|
            # puts "ddddddd c="+c.to_s
            if v_file_columns_included_arr.include?(c)
              v_include.push(v_cnt)
            end
            v_cnt = v_cnt + 1
          end 
          
          v_cnt = 0
          v_content_array.each do |r|
            v_sql_insert = v_sql_base_insert
            v_internal_cnt = 0
            if v_cnt > 0
             # WHAT ABOUT CSV WITH LAST BATCH OF CELLS BLANK
#puts "AAAAA "+v_content_array[v_cnt]
             if !v_content_array[v_cnt].gsub(",","").blank?  # skipping extra blank rows
              csv = CSV.parse(v_content_array[v_cnt])
              csv.each do  |c_row|
                 v_internal_cnt = 0
  #puts "BBBBBB c_row ="+c_row.join("=")
                 c_row.each do |c|
                   v_cell = (c.to_s).gsub("'","''")
                   if v_include.include?(v_internal_cnt)
                      if v_sql_insert > v_sql_base_insert
                         v_sql_insert = v_sql_insert+",'"+v_cell+"'"
                      else
                         v_sql_insert = v_sql_insert+"'"+v_cell+"'"
                      end
                  end
                  v_internal_cnt = v_internal_cnt + 1
                 end
              end
              #puts "aaaaa v_cnt = "+v_cnt.to_s
               if v_expected_cell_cnt > v_internal_cnt # trailing blank cells in the file, need to add some ,NULL
                  v_missing_cells = v_expected_cell_cnt - v_internal_cnt
                  for i in 1..v_missing_cells
                    v_sql_insert = v_sql_insert+", NULL "
                  end                 
               end
               v_sql_insert =  v_sql_insert+")"
               results = connection.execute(v_sql_insert)
             end
            end
            v_cnt = v_cnt + 1
          end 

 
       
    # --- how to also call from a command line?  --- controller--- if big problem duplicate in model or put most of stuff in 

         # update key columns
         if @schedule.key_type == 'enrollment/sp'    # similar to data_searches_controller add-a-row
            # expect enum_v# == @schedule.file_key_source_column
            # update enrollment -- make into a function?
            v_file_col_array = (@schedule.file_columns_included).split(',')
            v_table_col_array = (@schedule.target_table_columns).split(',')
            v_table_key_source = v_table_col_array[v_file_col_array.index(@schedule.file_key_source_column)]
            sql = "update "+(@schedule.target_table).strip+"_new  t set t.enrollment_id = ( select e.id from enrollments e where e.enumber = replace(replace(replace(replace(t."+v_table_key_source+",'_v2',''),'_v3',''),'_v4',''),'_v5',''))"
            results = connection.execute(sql)
            sql = "select distinct "+v_table_key_source+" from "+(@schedule.target_table).strip+"_new"
            results = connection.execute(sql)
            results.each do |r|
              v_sp_id = v_shared.get_sp_id_from_subjectid_v(r[0])
              v_enrollment_id = v_shared.get_enrollment_id_from_subjectid_v(r[0])
              if !v_sp_id.blank?
                sql = "update "+(@schedule.target_table).strip+"_new  t set t.scan_procedure_id = "+v_sp_id.to_s+" where "+v_table_key_source+" ='"+r[0]+"'"
                results = connection.execute(sql)
                sql = "update "+(@schedule.target_table).strip+"_new  t set t.enrollment_id = "+v_enrollment_id.to_s+" where "+v_table_key_source+" ='"+r[0]+"'"
                results = connection.execute(sql)
              end
            end
     
            # report on unmapped rows, not insert unmapped rows 
            sql = "select "+v_table_key_source+", enrollment_id from "+(@schedule.target_table).strip+"_new where scan_procedure_id is null order by "+v_table_key_source
            results = connection.execute(sql)
            results.each do |re|
              v_comment = re.join(' | ')+" ,"+v_comment
            end
            if !results.blank?
               v_comment =  @schedule.target_table+"_new unmapped "+v_table_key_source+",enrollment_id ="+v_comment
               @schedulerun.comment =v_comment[0..1990]
               @schedulerun.save
            end
            
            # populate non-present rows from present if partial load
            if params[:full_partial] == "partial"
              v_sql = "insert into "+(@schedule.target_table).strip+"_new("+@schedule.target_table_columns+",enrollment_id, scan_procedure_id)  select "+@schedule.target_table_columns+",enrollment_id, scan_procedure_id from "+@schedule.target_table+" where "+@schedule.target_table+"."+v_table_key_source+" not in (select "+v_table_key_source+" from "+@schedule.target_table+"_new)"
              results = connection.execute(v_sql)
            end
            
            # -- do the new-old-present-edit pivot
            v_comment = v_shared.move_present_to_old_new_to_present(@schedule.target_table,
            @schedule.target_table_columns+",enrollment_id, scan_procedure_id",
                           "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)
            # apply edits  -- made into a function  in shared model
            v_shared.apply_cg_edits(@schedule.target_table)
         elsif  @schedule.key_type == "reggieid-kc-participant_id"
           v_file_col_array = (@schedule.file_columns_included).split(',')
           v_table_col_array = (@schedule.target_table_columns).split(',')
           v_table_key_source = v_table_col_array[v_file_col_array.index(@schedule.file_key_source_column)]
           sql = "update "+@schedule.target_table+"_new  t set t.participant_id = ( select p.id from participants p where p.reggieid = t."+v_table_key_source +")"
           results = connection.execute(sql)
           # report on unmapped rows, not insert unmapped rows 
           sql = "select "+v_table_key_source+", participant_id from "+@schedule.target_table+"_new where participant_id is null order by "+v_table_key_source
           results = connection.execute(sql)
           results.each do |re|
             v_comment = re.join(' | ')+" ,"+v_comment
           end
           if !results.blank?
              v_comment =  @schedule.target_table+"_new unmapped "+v_table_key_source+",participant_id ="+v_comment
              @schedulerun.comment =v_comment[0..1990]
              @schedulerun.save
           end
           # populate non-present rows from present if partial load
           if params[:full_partial] == "partial"
             v_sql = "insert into "+@schedule.target_table+"_new("+@schedule.target_table_columns+",participant_id)  select "+@schedule.target_table_columns+",participant_id from "+@schedule.target_table+" where "+@schedule.target_table+"."+v_table_key_source+" not in (select "+v_table_key_source+" from "+@schedule.target_table+"_new)"
             results = connection.execute(v_sql)
           end
                                # export_id 
           if @schedule.make_unique_export_id == "Y"
              @schedule.target_table_columns = @schedule.target_table_columns+",export_id"
              v_schema ='panda_production'
              if Rails.env=="development" 
                  v_schema ='panda_development'
              end
              # check @schedule.target_table+"_new, @schedule.target_table+"_edit, @schedule.target_table+"_past,@schedule.target_table+"
              # have export_id column
              # add export_id column if not there
              # check for unique index
              # add unique index if not there
              # copy export_id from @schedule.target_table if there
              # generate any new export_id
               v_table_list = [@schedule.target_table+"_new", @schedule.target_table+"_edit",@schedule.target_table+"_old",@schedule.target_table]
               v_table_list.each do |tn|
                  v_sql = "SELECT count(COLUMN_NAME) cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE 
                     TABLE_SCHEMA = '"+v_schema+"' AND TABLE_NAME = '"+tn+"' and COLUMN_NAME ='export_id'";
                  v_export_results = connection.execute(v_sql)
                  if(v_export_results.first[0] < 1)
                      v_sql = "alter table "+tn+" add(export_id   int)"
                      v_altertable_results = connection.execute(v_sql)
                  end
                  v_sql = "SELECT count(index_name) cnt FROM information_schema.statistics 
                      WHERE column_name = 'export_id' and table_name = '"+tn+"'
                     AND index_schema  IN ( '"+v_schema+"') and non_unique = 0 "
                  v_uniqueind_results = connection.execute(v_sql)
                  if(v_uniqueind_results.first[0] < 1)
                     v_sql = "ALTER TABLE "+tn+"  ADD UNIQUE (export_id)"
                     v_uniqueindex_results = connection.execute(v_sql)
                  end
               end
               v_sql = "update "+@schedule.target_table+"_new t1 
               set t1.export_id = (select t2.export_id from "+@schedule.target_table+"  t2 where t1.participant_id = t2.participant_id)"
               v_update_results = connection.execute(v_sql)

               v_sql = "select export_id from "+@schedule.target_table+"_new where export_id is NOT NULL"
               v_exportid_results = connection.execute(v_sql)
               v_exportid_array = []
               v_exportid_results.each { |r| v_exportid_array << r }

               v_null_check_sql = "select participant_id from "+@schedule.target_table+"_new where export_id is NULL and participant_id is not NULL"
               v_null_check_cnt = 0
               v_null_cnt_threshold = 10  # repeat 10 times increasing upper range
               while v_null_check_cnt < v_null_cnt_threshold
                   v_null_check_cnt = v_null_check_cnt + 1
                   v_null_results = connection.execute(v_null_check_sql)
                   v_null_array = []
                   v_null_results.each { |r| v_null_array << r[0] }
                   v_null_count = v_null_array.count 
                   if v_null_count > 0
                      v_now = Time.new 
                      v_date_seed = (v_now.to_i)*v_null_check_cnt
                      v_array_cnt = 0
                      v_rand_array = Array.new(2*v_null_check_cnt*v_null_results.count) {rand(v_null_count .. v_date_seed)}
                      v_rand_array.each do |val|
                         if(!v_exportid_array.include?(val))  and  (v_array_cnt < v_null_array.count)
                            v_sql = "update "+@schedule.target_table+"_new t1 
                                  set t1.export_id = "+val.to_s+" where t1.participant_id ="+v_null_array[v_array_cnt].to_s
                            v_exportid_array.push(val)
                            v_update_results = connection.execute(v_sql)
                            v_array_cnt = v_array_cnt + 1
                         end
                      end
                   end
               end
           end

           # -- do the new-old-present-edit pivot
           v_comment = v_shared.move_present_to_old_new_to_present(@schedule.target_table,
           @schedule.target_table_columns+",participant_id",
                          "participant_id is not null ",v_comment)
           # apply edits  -- made into a function  in shared model
           v_shared.apply_cg_edits(@schedule.target_table)
         elsif  @schedule.key_type == "wrapnum-kc-participant_id"
           v_file_col_array = (@schedule.file_columns_included).split(',')
           v_table_col_array = (@schedule.target_table_columns).split(',')
           v_table_key_source = v_table_col_array[v_file_col_array.index(@schedule.file_key_source_column)]
           sql = "update "+@schedule.target_table+"_new  t set t.participant_id = ( select p.id from participants p where p.wrapnum = t."+v_table_key_source +")"
           results = connection.execute(sql)
           # report on unmapped rows, not insert unmapped rows 
           sql = "select "+v_table_key_source+", participant_id from "+@schedule.target_table+"_new where participant_id is null order by "+v_table_key_source
           results = connection.execute(sql)
           results.each do |re|
             v_comment = re.join(' | ')+" ,"+v_comment
           end
           if !results.blank?
              v_comment =  @schedule.target_table+"_new unmapped "+v_table_key_source+",participant_id ="+v_comment
              @schedulerun.comment =v_comment[0..1990]
              @schedulerun.save
           end
           # populate non-present rows from present if partial load
           if params[:full_partial] == "partial"
             v_sql = "insert into "+@schedule.target_table+"_new("+@schedule.target_table_columns+",participant_id)  select "+@schedule.target_table_columns+",participant_id from "+@schedule.target_table+" where "+@schedule.target_table+"."+v_table_key_source+" not in (select "+v_table_key_source+" from "+@schedule.target_table+"_new)"
             results = connection.execute(v_sql)
           end
                     # export_id 
           if @schedule.make_unique_export_id == "Y"
              @schedule.target_table_columns = @schedule.target_table_columns+",export_id"
              v_schema ='panda_production'
              if Rails.env=="development" 
                  v_schema ='panda_development'
              end
              # check @schedule.target_table+"_new, @schedule.target_table+"_edit, @schedule.target_table+"_past,@schedule.target_table+"
              # have export_id column
              # add export_id column if not there
              # check for unique index
              # add unique index if not there
              # copy export_id from @schedule.target_table if there
              # generate any new export_id
               v_table_list = [@schedule.target_table+"_new", @schedule.target_table+"_edit",@schedule.target_table+"_old",@schedule.target_table]
               v_table_list.each do |tn|
                  v_sql = "SELECT count(COLUMN_NAME) cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE 
                     TABLE_SCHEMA = '"+v_schema+"' AND TABLE_NAME = '"+tn+"' and COLUMN_NAME ='export_id'";
                  v_export_results = connection.execute(v_sql)
                  if(v_export_results.first[0] < 1)
                      v_sql = "alter table "+tn+" add(export_id   int)"
                      v_altertable_results = connection.execute(v_sql)
                  end
                  v_sql = "SELECT count(index_name) cnt FROM information_schema.statistics 
                      WHERE column_name = 'export_id' and table_name = '"+tn+"'
                     AND index_schema  IN ( '"+v_schema+"') and non_unique = 0 "
                  v_uniqueind_results = connection.execute(v_sql)
                  if(v_uniqueind_results.first[0] < 1)
                     v_sql = "ALTER TABLE "+tn+"  ADD UNIQUE (export_id)"
                     v_uniqueindex_results = connection.execute(v_sql)
                  end
               end
               v_sql = "update "+@schedule.target_table+"_new t1 
               set t1.export_id = (select t2.export_id from "+@schedule.target_table+"  t2 where t1.participant_id = t2.participant_id)"
               v_update_results = connection.execute(v_sql)

               v_sql = "select export_id from "+@schedule.target_table+"_new where export_id is NOT NULL"
               v_exportid_results = connection.execute(v_sql)
               v_exportid_array = []
               v_exportid_results.each { |r| v_exportid_array << r }

               v_null_check_sql = "select participant_id from "+@schedule.target_table+"_new where export_id is NULL and participant_id is not NULL"
               v_null_check_cnt = 0
               v_null_cnt_threshold = 10  # repeat 10 times increasing upper range
               while v_null_check_cnt < v_null_cnt_threshold
                   v_null_check_cnt = v_null_check_cnt + 1
                   v_null_results = connection.execute(v_null_check_sql)
                   v_null_array = []
                   v_null_results.each { |r| v_null_array << r[0] }
                   v_null_count = v_null_array.count 
                   if v_null_count > 0
                      v_now = Time.new 
                      v_date_seed = (v_now.to_i)*v_null_check_cnt
                      v_array_cnt = 0
                      v_rand_array = Array.new(2*v_null_check_cnt*v_null_results.count) {rand(v_null_count .. v_date_seed)}
                      v_rand_array.each do |val|
                         if(!v_exportid_array.include?(val))  and  (v_array_cnt < v_null_array.count)
                            v_sql = "update "+@schedule.target_table+"_new t1 
                                  set t1.export_id = "+val.to_s+" where t1.participant_id ="+v_null_array[v_array_cnt].to_s
                            v_exportid_array.push(val)
                            v_update_results = connection.execute(v_sql)
                            v_array_cnt = v_array_cnt + 1
                         end
                      end
                   end
               end
           end
           # -- do the new-old-present-edit pivot
           v_comment = v_shared.move_present_to_old_new_to_present(@schedule.target_table,
           @schedule.target_table_columns+",participant_id",
                          "participant_id is not null ",v_comment)
           # apply edits  -- made into a function  in shared model
           v_shared.apply_cg_edits(@schedule.target_table)
 
         elsif  @schedule.key_type == "adrcnum-kc-participant_id"
           v_file_col_array = (@schedule.file_columns_included).split(',')
           v_table_col_array = (@schedule.target_table_columns).split(',')
           v_table_key_source = v_table_col_array[v_file_col_array.index(@schedule.file_key_source_column)]
           sql = "update "+@schedule.target_table+"_new  t set t.participant_id = ( select p.id from participants p where p.adrcnum = t."+v_table_key_source +")"
           results = connection.execute(sql)
           # report on unmapped rows, not insert unmapped rows 
           sql = "select "+v_table_key_source+", participant_id from "+@schedule.target_table+"_new where participant_id is null order by "+v_table_key_source
           results = connection.execute(sql)
           results.each do |re|
             v_comment = re.join(' | ')+" ,"+v_comment
           end
           if !results.blank?
              v_comment =  @schedule.target_table+"_new unmapped "+v_table_key_source+",participant_id ="+v_comment
              @schedulerun.comment =v_comment[0..1990]
              @schedulerun.save
           end
           # populate non-present rows from present if partial load
           if params[:full_partial] == "partial"
             v_sql = "insert into "+@schedule.target_table+"_new("+@schedule.target_table_columns+",participant_id)  select "+@schedule.target_table_columns+",participant_id from "+@schedule.target_table+" where "+@schedule.target_table+"."+v_table_key_source+" not in (select "+v_table_key_source+" from "+@schedule.target_table+"_new)"
             results = connection.execute(v_sql)
           end
                                # export_id 
           if @schedule.make_unique_export_id == "Y"
              @schedule.target_table_columns = @schedule.target_table_columns+",export_id"
              v_schema ='panda_production'
              if Rails.env=="development" 
                  v_schema ='panda_development'
              end
              # check @schedule.target_table+"_new, @schedule.target_table+"_edit, @schedule.target_table+"_past,@schedule.target_table+"
              # have export_id column
              # add export_id column if not there
              # check for unique index
              # add unique index if not there
              # copy export_id from @schedule.target_table if there
              # generate any new export_id
               v_table_list = [@schedule.target_table+"_new", @schedule.target_table+"_edit",@schedule.target_table+"_old",@schedule.target_table]
               v_table_list.each do |tn|
                  v_sql = "SELECT count(COLUMN_NAME) cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE 
                     TABLE_SCHEMA = '"+v_schema+"' AND TABLE_NAME = '"+tn+"' and COLUMN_NAME ='export_id'";
                  v_export_results = connection.execute(v_sql)
                  if(v_export_results.first[0] < 1)
                      v_sql = "alter table "+tn+" add(export_id   int)"
                      v_altertable_results = connection.execute(v_sql)
                  end
                  v_sql = "SELECT count(index_name) cnt FROM information_schema.statistics 
                      WHERE column_name = 'export_id' and table_name = '"+tn+"'
                     AND index_schema  IN ( '"+v_schema+"') and non_unique = 0 "
                  v_uniqueind_results = connection.execute(v_sql)
                  if(v_uniqueind_results.first[0] < 1)
                     v_sql = "ALTER TABLE "+tn+"  ADD UNIQUE (export_id)"
                     v_uniqueindex_results = connection.execute(v_sql)
                  end
               end
               v_sql = "update "+@schedule.target_table+"_new t1 
               set t1.export_id = (select t2.export_id from "+@schedule.target_table+"  t2 where t1.participant_id = t2.participant_id)"
               v_update_results = connection.execute(v_sql)

               v_sql = "select export_id from "+@schedule.target_table+"_new where export_id is NOT NULL"
               v_exportid_results = connection.execute(v_sql)
               v_exportid_array = []
               v_exportid_results.each { |r| v_exportid_array << r }

               v_null_check_sql = "select participant_id from "+@schedule.target_table+"_new where export_id is NULL and participant_id is not NULL"
               v_null_check_cnt = 0
               v_null_cnt_threshold = 10  # repeat 10 times increasing upper range
               while v_null_check_cnt < v_null_cnt_threshold
                   v_null_check_cnt = v_null_check_cnt + 1
                   v_null_results = connection.execute(v_null_check_sql)
                   v_null_array = []
                   v_null_results.each { |r| v_null_array << r[0] }
                   v_null_count = v_null_array.count 
                   if v_null_count > 0
                      v_now = Time.new 
                      v_date_seed = (v_now.to_i)*v_null_check_cnt
                      v_array_cnt = 0
                      v_rand_array = Array.new(2*v_null_check_cnt*v_null_results.count) {rand(v_null_count .. v_date_seed)}
                      v_rand_array.each do |val|
                         if(!v_exportid_array.include?(val))  and  (v_array_cnt < v_null_array.count)
                            v_sql = "update "+@schedule.target_table+"_new t1 
                                  set t1.export_id = "+val.to_s+" where t1.participant_id ="+v_null_array[v_array_cnt].to_s
                            v_exportid_array.push(val)
                            v_update_results = connection.execute(v_sql)
                            v_array_cnt = v_array_cnt + 1
                         end
                      end
                   end
               end
           end

           # -- do the new-old-present-edit pivot
           v_comment = v_shared.move_present_to_old_new_to_present(@schedule.target_table,
           @schedule.target_table_columns+",participant_id",
                          "participant_id is not null ",v_comment)
           # apply edits  -- made into a function  in shared model
           v_shared.apply_cg_edits(@schedule.target_table)
         elsif @schedule.key_type == "no_key"
          v_file_col_array = (@schedule.file_columns_included).split(',')
           v_table_col_array = (@schedule.target_table_columns).split(',')
           v_table_key_source = v_table_col_array[v_file_col_array.index(@schedule.file_key_source_column)]
           # report on unmapped rows, not insert unmapped rows 
           sql = "select "+v_table_key_source+" from "+@schedule.target_table+"_new where "+v_table_key_source+" = '' or "+v_table_key_source+" is null"
           results = connection.execute(sql)
           results.each do |re|
             v_comment = re.join(' | ')+" ,"+v_comment
           end
           if !results.blank?
              v_comment =  @schedule.target_table+"_new unmapped "+v_table_key_source+"   "+v_comment
              @schedulerun.comment =v_comment[0..1990]
              @schedulerun.save
           end
           # populate non-present rows from present if partial load
           if params[:full_partial] == "partial"
             v_sql = "insert into "+@schedule.target_table+"_new("+@schedule.target_table_columns+")  select "+@schedule.target_table_columns+" from "+@schedule.target_table+" where "+@schedule.target_table+"."+v_table_key_source+" not in (select "+v_table_key_source+" from "+@schedule.target_table+"_new)"
             results = connection.execute(v_sql)
           end
           # -- do the new-old-present-edit pivot
           v_comment = v_shared.move_present_to_old_new_to_present(@schedule.target_table,
           @schedule.target_table_columns,
                         v_table_key_source+" is not null ",v_comment)
           # apply edits  -- made into a function  in shared model
           v_shared.apply_cg_edits(@schedule.target_table)

         end

    # -- render to schedule runs index
    
           v_comment = "finished "+@schedule.name+"  |"+v_comment
           @schedulerun.comment =v_comment[0..1990]
           @schedulerun.save
        end
    else
      v_comment = "ERROR -- No File was uploaded  |"+v_comment
      @schedulerun.comment =v_comment[0..1990]
      @schedulerun.save
    end
    if !v_comment.include?("ERROR")
       @schedulerun.status_flag ="Y"
     end
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save
    respond_to do |format|
      format.html { redirect_to(schedulerun_search_url) }
      format.xml  { head :ok }
    end
     
  end
  
end