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
            puts "ddddddd c="+c.to_s
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
                   puts "ddddddddd c="+c[v_internal_cnt].to_s
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
              puts "aaaaa v_cnt = "+v_cnt.to_s
               v_sql_insert =  v_sql_insert+")"
               results = connection.execute(v_sql_insert)
            end
            v_cnt = v_cnt + 1
          end 

 
       
    # --- how to also call from a command line?  --- controller--- if big problem duplicate in model or put most of stuff in 

    # update key columns
    # -- do the new-old-present-edit pivot
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