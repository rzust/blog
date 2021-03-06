set_default(:mysql_host, "localhost")
set(:mysql_user, Capistrano::CLI.ui.ask("User name: ") )
set_default(:mysql_password) { Capistrano::CLI.password_prompt "MySQL Password: " }
set_default(:mysql_database) { "#{application}_#{enviroment}" }

namespace :postgresql do
  desc "Install the latest stable release of PostgreSQL."
  task :install, roles: :db, only: {primary: true} do
    run "#{sudo} add-apt-repository ppa:pitti/postgresql"
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install postgresql libpq-dev"
  end
  #after "deploy:install", "postgresql:install"

  desc "Create a database for this application."
  # task :create_database, roles: :db, only: {primary: true} do
  #   run %Q{#{sudo} -u postgres psql -c "create user #{postgresql_user} with password '#{postgresql_password}';"}
  #   run %Q{#{sudo} -u postgres psql -c "create database #{postgresql_database} owner #{postgresql_user};"}
  # end
  #after "deploy:setup", "postgresql:create_database"

  desc "Create a database for this application."
  task :create_database, roles: :db, only: {primary: true} do
    cmd = "CREATE DATABASE IF NOT EXISTS #{mysql_database}"
    run "mysql -u #{mysql_user} -p -e '#{cmd}'" do |channel, stream, data|
      if data =~ /^Enter password:/
         channel.send_data "#{mysql_password}\n"
       end
    end       
  end

  desc "Generate the database.yml configuration file."
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "postgresql.yml.erb", "#{shared_path}/config/database.yml"
  end
  after "deploy:setup", "postgresql:setup"

  desc "Symlink the database.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "postgresql:symlink"
end
