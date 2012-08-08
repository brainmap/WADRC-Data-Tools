class DataSearchesController < ApplicationController

  def index
      # get the tables to join
      # columns and values to add to where
      # columns to return
      # build sql
      # need to get all the enrollments , all the subjectid

      @column_headers = ['Protocol','Enumber','RMR','Appt Date','Ecat File']
      @column_number =   @column_headers.size
      sql ="SELECT vgroups.id vgroup_id,  vgroups.rmr,appointments.appointment_date ,petscans.ecatfilename 
            FROM vgroups, appointments, petscans 
            WHERE vgroups.id = appointments.vgroup_id
            AND appointments.id = petscans.appointment_id
            ORDER BY appointments.appointment_date"
            
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
          # SLOWER THAN sql
          #vgroup = Vgroup.find(var[0])
          #@temp[0]=vgroup.scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ")
          #@temp[1]=vgroup.enrollments.collect {|e| e.enumber }.join(", ")
          
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
