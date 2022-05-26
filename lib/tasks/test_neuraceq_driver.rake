#Run like this from command line: RAILS_ENV=production rake test_pet_driver\['wls631039s','asthana.wls.visit1','NEURACEQ'\]

desc "Test individual PET case for driver"
task :test_neuraceq_driver, [:enumber, :scan_procedure, :tracer]  => :environment do |task, args|

     #Set up instance
     params = Jobs::Pet::ParallelPetNeuraceqSuvr.production_params
     
     #params[:dry_run] = true

     job = Jobs::Pet::ParallelPetNeuraceqSuvr.new(params)
     job.setup(params)
     job.selection(params)
     

     #Get appointment_id from enumber to query petscans with

     #Get vgroup_id of enumber to get Appointment
     v_out = Vgroup.where("primary_enumber = \'#{args[:enumber]}\' and primary_scan_procedure = \'#{args[:scan_procedure]}\'")
     if v_out.size != 1
     	puts "Multiple or no Vgroups for #{args[:enumber]} for procedure #{args[:scan_procedure]}"
	exit
     end

     #Get Appointment with vgroup_id and appointment_type = "pet_scan"
     pet_appts = Appointment.where("vgroup_id = \'#{v_out.first['id']}\' and appointment_type = 'pet_scan'")
     neura_pet = nil
     pet_appts.each do |pet|
       pet_scan = Petscan.where("appointment_id = \'#{pet['id']}\'")
       tracer_id = 
       if LookupPettracer.where("id = #{pet_scan.first['lookup_pettracer_id']}").first['name'].casecmp(args[:tracer]) == 0 #strings are case insensitive matching
         neura_pet = pet
       end
     end
     
     if neura_pet.nil?
     	puts "No args[:tracer] Pet Scan Appointments found for #{args[:enumber]} for procedure #{args[:scan_procedure]}"
	exit
     end
     
     #Get only petscan for enumber arg
     job.petscans = job.petscans.where("appointment_id = \'#{neura_pet['id']}\'")
     if job.petscans.size != 1
     	puts "Multiple or no args[:tracer] PET Scans found from selected job.petscans for #{args[:enumber]} for procedure #{args[:scan_procedure]}"
	exit
     end

     job.filter(params)
     job.matlab_call(params)
#     job.run(params)
end