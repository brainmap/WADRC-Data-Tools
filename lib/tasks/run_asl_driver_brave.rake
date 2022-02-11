desc "Set default params for driver; create driver instance; run driver instance"
task :run_asl_driver_brave => :environment do
     params = Jobs::ASL::ASLDriverBrave.production_params
     job = Jobs::ASL::ASLDriverBrave.new(params)
     job.run(params)
end
