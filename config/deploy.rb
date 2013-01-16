require 'bundler/capistrano'

set :application, "texapp.org"

set :repository,  "git@github.com:texapp/texapp.org.git"
set :scm, :git
set :git_enable_submodules, 1

default_run_options[:pty] = true
set :user, 'thin'
ssh_options[:forward_agent] = true
set :use_sudo, false

set :deploy_via, :remote_cache
set :deploy_to, "/var/www/texapp.org"

role :app, "texapp.org"

after 'deploy:update_code', 'deploy:symlink_credentials'

namespace :deploy do
  task :start, :roles => [:web, :app] do
    run "cd #{deploy_to}/current && nohup bundle exec thin -C thin.yml start"
  end
 
  task :stop, :roles => [:web, :app] do
    run "cd #{deploy_to}/current && nohup bundle exec thin -C thin.yml stop"
  end
 
  task :restart, :roles => [:web, :app] do
    deploy.stop
    deploy.start
  end
 
  task :cold do
    deploy.update
    deploy.start
  end

  task :symlink_credentials, :roles => :app do
    run "rm -f #{release_path}/config/credentials.yml"
    run "ln -nfs #{deploy_to}/shared/config/credentials.yml #{release_path}/config/credentials.yml"
  end
end

after 'deploy:update_code', 'deploy:symlink_credentials'

before 'deploy:restart', 'barista:brew'

_cset(:barista_role) { :app }

namespace :barista do
  task :brew, :roles => lambda { fetch(:barista_role) } do
    run("cd #{current_path} ; bundle exec rake barista:brew")
  end
end
