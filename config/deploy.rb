set :application, "TransferScan"
set :repository,  "file:///Data/vtrak1/SysAdmin/rails_repository/trunk/TransferScans"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

set :deploy_to, "/Library/WebServer/TransferScans"

set :mongrel_cmd, "/usr/bin/mongrel_rails"
set :mongrel_ports, "80"
set :mongrel_pid, "tmp/pids/mongrel.pid"

set :user, "admin"
set :group, "admin"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "nelson"
role :web, "nelson"
role :db,  "nelson", :primary => true

namespace :deploy do

  desc "Start Mongrels processes and add them to launchd."
  task :start, :roles => :app do
    mongrel_ports.each do |port|
      sudo "#{mongrel_cmd} start --port #{port} --pid #{mongrel_pid} \
            -e production --user #{user} --group #{group} -c #{current_path} -d"
    end
  end

  desc "Stop Mongrels processes and remove them from launchd."
  task :stop, :roles => :app do
    mongrel_ports.each do |port|
      sudo "#{mongrel_cmd} stop -c #{current_path} -p #{mongrel_pid}"
    end
  end

  desc "Restart Mongrel processes"
  task :restart, :roles => :app do
    stop
    start
  end
 
end


