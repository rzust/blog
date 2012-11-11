require "rvm/capistrano"
require "bundler/capistrano"

load "config/recipes/base"
load "config/recipes/nginx"
load "config/recipes/unicorn"
load "config/recipes/postgresql"
load "config/recipes/nodejs"
load "config/recipes/rbenv"
load "config/recipes/check"

set :application, "blog"
set :use_sudo, false

set :rvm_ruby_string, "ruby-1.9.3-p0@blog"

set :scm, "git"
set :repository, "git@github.com:rzust/#{application}.git"

set :maintenance_template_path, File.expand_path("../recipes/templates/maintenance.html.erb", __FILE__)

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

task :production do
  server "172.16.194.128", :web, :app, :db, primary: true
  set :user, "eightynine"
  set :rvm_type, :system
  set :deploy_to, "/var/www/apps/#{application}/"
  set :deploy_via, :remote_cache
  set :branch, "production"
  after('deploy:symlink', 'cache:clear')
end

task :staging do
  server "stage.sdhub.net", :web, :app, :db, primary: true
  set :user, "deploy"
  set :rvm_type, :system
  set :deploy_to, "/var/www/apps/#{application}/"
  set :deploy_via, :remote_cache
  set :branch, "staging" 
  after('deploy:symlink', 'cache:clear')
end



after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
  task :seed, :roles => :db, :only => { :primary => true } do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "production")
    migrate_target = fetch(:migrate_target, :latest)

    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest  then latest_release
      else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
      end

    run "cd #{directory} && #{rake} RAILS_ENV=#{rails_env} db:seed"
  end
end