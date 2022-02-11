desc "Set default_params; create harvester instance; run harvester"
task :run_asl_harvester_brave => :environment do
     params = Jobs::ASL::ASLHarvesterBrave.production_params
     job = Jobs::ASL::ASLHarvesterBrave.new(params)
     job.run(params)
end
