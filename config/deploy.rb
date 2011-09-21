set :application, 'solar'
set :repository,  'git@github.com:wwagner33/solar.git'
set :deploy_to, "/var/www/projects/production/#{application}"
set :scm, :git
set :deploy_via, :remote_cache

role :web, 'apolo11.virtual.ufc.br'                          # Your HTTP server, Apache/etc
role :app, 'apolo11.virtual.ufc.br'                          # This may be the same as your `Web` server
role :db,  'apolo11.virtual.ufc.br', :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

set :user, 'rails'
set :use_sudo, false
set :ssh_options, {:forward_agent => true, :port => 4858}
set :rvm_type, :user # Rvm instalado no home do usuario

# utilizando-se de tags
set :branch do
  default_tag = `git tag`.split("\n").last
  tag = Capistrano::CLI.ui.ask "Tag to deploy: [#{default_tag}]"
  tag = default_tag if tag.empty?
  tag
end

# Utilizar Capistrano junto com RVM
$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require 'rvm/capistrano'                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, '1.9.2'
set :keep_releases, 5

# tasks
after :deploy, 'deploy:database'
after :deploy, 'deploy:symlink'

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} rm -rf #{current_path} && #{try_sudo} ln -s #{release_path} #{deploy_to}/current && #{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :database, :roles => :app do
    run "cp #{deploy_to}/shared/database.yml #{current_path}/config/"
  end

  # backup dos arquivos enviados para o servidor
  task :symlink, :roles => :app do
    run "rm -rf  #{release_path}/media ; ln -s #{shared_path}/media #{release_path}/"
  end

end
