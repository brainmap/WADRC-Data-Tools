desc "Set default_params; create harvester instance; run harvester"
task :run_neuraceq_harvester => :environment do
     params = Jobs::Pet::NeuraceqSuvrHarvest.production_params
     job = Jobs::Pet::NeuraceqSuvrHarvest.new(params)
#     job.setup(params)
#     job.harvest(params)
#      job.close(params)
     job.run(params)
end
