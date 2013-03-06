require 'bundler/capistrano'

#default_run_options[:pty] = true
#ssh_options[:paranoid] = false

set :application, "WADRC-Data-Tools"
set :host_server, "nelson.medicine.wisc.edu" #adrcdev.....
role :app, host_server
role :web, host_server
role :db,  host_server, :primary => true

set :user, "admin"   # panda_admin
set :group, "staff"  # admin
set :deploy_to, "/Library/WebServer/WADRC-Data-Tools"

set :scm, "git"
#set :scm_command, "/usr/local/git/bin/git"
set :git, "/usr/local/bin/git"
set :repository, "git@github.com:brainmap/WADRC-Data-Tools.git"
set :branch, "master"

# Used to find git & bundler in path
default_environment['PATH'] = "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin"

# Bundler depends on this to use the gem version of metamri
default_environment['RAILS_ENV'] = "production" # development

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
   # run "ln -nfs #{shared_path}/db/transfer_scans_production.sqlite3 #{release_path}/db/transfer_scans_production.sqlite3"
    run "ln -nfs  #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs  #{shared_path}/config/ldap.yml #{release_path}/config/ldap.yml"
    run "ln -nfs  #{shared_path}/config/deploy.rb #{release_path}/config/deploy.rb"
    run "ln -nfs  #{shared_path}/app/models/radiology_comment.rb #{release_path}/app/models/radiology_comment.rb"
    # run "ln -nfs #{shared_path}/system #{release_path}/public/system"
  end

  # If you are using Passenger mod_rails uncomment this:
  # if you're still using the script/reapear helper you will need
  # these http://github.com/rails/irs_process_scripts
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

end

after 'deploy:symlink', 'deploy:symlink_shared'
