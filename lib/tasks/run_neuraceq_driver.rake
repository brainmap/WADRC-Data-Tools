desc "Set default params for driver; create driver instance; run driver instance"
task :run_neuraceq_driver => :environment do
     params = Jobs::Pet::ParallelPetNeuraceqSuvr.production_params
     #params[:dry_run] = false
     #params[:run_by_user] = "panda_user"

     #params[:computer] = "thumper"
     #params[:run_by_user] = "ngretzon"
     #params[:schedule_name] = "parallel_pet_neuraceq_suvr_process"
     #params[:tracer_id] = 10

     job = Jobs::Pet::ParallelPetNeuraceqSuvr.new(params)
     
#     job.setup(params)
#     job.selection(params)
#     job.filter(params)
#     job.matlab_call(params)
     job.run(params)
end