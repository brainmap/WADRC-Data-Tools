desc "Set default_params; create harvester instance; run harvester"
task :run_asl_harvester => :environment do
     params = Jobs::ASL::ASLHarvester.production_params
     job = Jobs::ASL::ASLHarvester.new(params)
     job.run(params)
end
