class DataSearchesController < ApplicationController

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
        "petscans.petscan_note","petscans.range","vgroups.transfer_pet"] # vgroups.id vgroup_id always first, include table name
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
        "lumbarpunctures.lpfasttotaltime","lumbarpunctures.lpfasttotaltime_min","vgroups.completedlumbarpuncture","lumbarpunctures.lumbarpuncture_note"] # vgroups.id vgroup_id always first, include table name
      @tables =['lumbarpunctures'] # trigger joins --- vgroups and appointments by default
      @left_join = ["LEFT JOIN employees on lumbarpunctures.lp_exam_md_id = employees.id"] # left join needs to be in sql right after the parent table!!!!!!!
      @conditions =["scan_procedures.codename='johnson.pipr.visit1'"] # need look up for like, lt, gt, between  
      @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]  
 

# mri 
      @column_headers = ['Protocol','Enumber','RMR','Appt Date','Scan','Path',  'Completed Fast','Fast hrs','Fast min','Mri status','Radiology Outcome','Notes','Appt Note'] # need to look up values
      # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
      @column_number =   @column_headers.size
      @fields =["visits.scan_number","visits.path","CASE visits.completedmrifast WHEN 1 THEN 'Yes' ELSE 'No' end",
        "visits.mrifasttotaltime","visits.mrifasttotaltime_min","vgroups.transfer_mri","CASE visits.radiology_outcome WHEN 1 THEN 'Yes' ELSE 'No' end","visits.notes",] # vgroups.id vgroup_id always first, include table name
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
end
