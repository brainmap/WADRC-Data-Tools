desc "Set default params for driver; create driver instance; run driver instance"
task :run_asl_driver => :environment do
     params = Jobs::ASL::ASLDriver.production_params
     job = Jobs::ASL::ASLDriver.new(params)
     job.run(params)
end
