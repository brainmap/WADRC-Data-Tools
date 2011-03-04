#default_run_options[:pty] = true
#ssh_options[:paranoid] = false

set :application, "WADRC-Data-Tools"
set :host_server, "nelson.medicine.wisc.edu"
role :app, host_server
role :web, host_server
role :db,  host_server, :primary => true

set :user, "admin"
set :group, "staff"
set :deploy_to, "/Library/WebServer/WADRC-Data-Tools"

set :scm, "git"
#set :scm_command, "/usr/local/git/bin/git"
set :git, "/usr/local/bin/git"
set :repository, "git@github.com:brainmap/WADRC-Data-Tools.git"
set :branch, "master"


namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/db/transfer_scans_production.sqlite3 #{release_path}/db/transfer_scans_production.sqlite3"
    # run "ln -nfs #{shared_path}/system #{release_path}/public/system"
  end

  desc "Restart Apache Passenger"
  task :restart, :roles => :app do
    sudo "#{release_path}/tmp/restart.txt"
  end
 
end

after 'deploy:symlink', 'deploy:symlink_shared'
