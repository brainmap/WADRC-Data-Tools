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

    if !params[:file_name].blank?
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
         v_comment = "ERROR -file header differs from expected header  actual"+v_file_header+" != expected="+@schedule.file_header+" |"+v_comment
         @schedulerun.comment =v_comment[0..1990]
          @schedulerun.save
       else 
         v_comment = "file header match expected |"+v_comment
         @schedulerun.comment =v_comment[0..1990]
          @schedulerun.save
          csv = CSV.parse(uploaded_io.read, :headers => true)
          v_file_columns_included_arr = @schedule.file_columns_included.split(',')
          connection = ActiveRecord::Base.connection();
          v_sql_base_insert = "insert into "+@schedule.target_table+"_new("+@schedule.target_table_columns+" )values("
          v_sql = "truncate table "+@schedule.target_table+"_new"
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
            if v_cnt > 0
             # WHAT ABOUT CSV WITH LAST BATCH OF CELLS BLANK
              csv = CSV.parse(v_content_array[v_cnt])
              v_internal_cnt = 0
              csv.each do  |c_row|
                 v_internal_cnt = 0
                 c_row.each do |c|
                   if v_include.include?(v_internal_cnt)
                      if v_sql_insert > v_sql_base_insert
                         v_sql_insert = v_sql_insert+",'"+c.to_s+"'"
                      else
                         v_sql_insert = v_sql_insert+"'"+c.to_s+"'"
                      end
                   end
                   v_internal_cnt = v_internal_cnt + 1
                end
              end
              #puts "aaaaa v_cnt = "+v_cnt.to_s
               v_sql_insert =  v_sql_insert+")"
               results = connection.execute(v_sql_insert)
            end
            v_cnt = v_cnt + 1
          end 

 
       
    # --- how to also call from a command line?  --- controller--- if big problem duplicate in model or put most of stuff in 

         # update key columns
         if @schedule.key_type == 'enrollment/sp'
            # expect enum_v# == @schedule.file_key_source_column
            # update enrollment -- make into a function?
            v_file_col_array = (@schedule.file_columns_included).split(',')
            v_table_col_array = (@schedule.target_table_columns).split(',')
            v_table_key_source = v_table_col_array[v_file_col_array.index(@schedule.file_key_source_column)]
            sql = "update "+@schedule.target_table+"_new  t set t.enrollment_id = ( select e.id from enrollments e where e.enumber = replace(replace(replace(replace(t."+v_table_key_source+",'_v2',''),'_v3',''),'_v4',''),'_v5',''))"
            results = connection.execute(sql)
            sql = "select distinct "+v_table_key_source+" from "+@schedule.target_table+"_new"
            results = connection.execute(sql)
            results.each do |r|
              v_sp_id = v_shared.get_sp_id_from_subjectid_v(r[0])
              if !v_sp_id.blank?
                sql = "update "+@schedule.target_table+"_new  t set t.scan_procedure_id = "+v_sp_id.to_s+" where "+v_table_key_source+" ='"+r[0]+"'"
                results = connection.execute(sql)
              end
            end
     
            # report on unmapped rows, not insert unmapped rows 
            sql = "select "+v_table_key_source+", enrollment_id from "+@schedule.target_table+"_new where scan_procedure_id is null order by "+v_table_key_source
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
              v_sql = "insert into "+@schedule.target_table+"_new("+@schedule.target_table_columns+",enrollment_id, scan_procedure_id)  select "+@schedule.target_table_columns+",enrollment_id, scan_procedure_id from "+@schedule.target_table+" where "+@schedule.target_table+"."+v_table_key_source+" not in (select "+v_table_key_source+" from "+@schedule.target_table+"_new)"
              results = connection.execute(v_sql)
            end
            
            # -- do the new-old-present-edit pivot
            v_comment = v_shared.move_present_to_old_new_to_present(@schedule.target_table,
            @schedule.target_table_columns+",enrollment_id, scan_procedure_id",
                           "scan_procedure_id is not null  and enrollment_id is not null ",v_comment)
            # apply edits  -- made into a function  in shared model
            v_shared.apply_cg_edits(@schedule.target_table)
         elsif  @schedule.key_type == 'participant_id'
             # could be wrapno, reggieid, adrcnum ish
             v_comment = "PARTICIPANT_ID IS NOT IMPLEMENTED YET!!!!!! "+v_comment
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