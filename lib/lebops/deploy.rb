configuration = Capistrano::Configuration.respond_to?(:instance) ?
    Capistrano::Configuration.instance(:must_exist) :
    Capistrano.configuration(:must_exist)

configuration.load do
  # Multistaging
  set :stages, %w(vagrant staging production)
  set :default_stage, 'staging'
  require 'capistrano/ext/multistage'

  # Application
  set :scm, :git
  set :default_run_options, {:pty => true}

  set(:deploy_to) {"/var/www/#{application}/#{stage}"} # This makes lazy the load
  set(:rake_command) {"cd #{current_path} && bundle exec rake RAILS_ENV=#{stage}"}


  # CarrierWave: respect uploads
  set :shared_children, shared_children + %w{public/uploads}

  # Thin
  set :thin_config_path, "/etc/thin"
  set(:thin_config_file) {"#{thin_config_path}/#{application}-#{stage}.yml"}

  ## rvm
  set :rvm_ruby_string, "ruby-1.9.3-p448@#{application}"
  set :rvm_type, :system
  require "rvm/capistrano"

  require "bundler/capistrano"

  set :user, "root"
  set :user_sudo, false

  namespace :app do
    desc "Setup or reset: DB and App_server"
    task :setup, :roles => :app do
      rvm.install_rvm
      rvm.install_ruby
      deploy.setup
      deploy.check
      deploy.update # also does bundle.install
      thin.setup
      db.setup
      deploy.precompile_assets
      thin.start
    end
    desc "Update from last release: DB and App_server"
    task :update, :roles => :app do
      deploy.update
      bundle.install
      db.migrate
      deploy.precompile_assets
      thin.restart
    end
  end

  namespace :thin do
    desc "Sets up Thin server environments"
    task :setup, :roles => :app do
      invoke_command "cd #{current_path} && gem install thin --no-ri --no-rdoc"
      run "mkdir /etc/thin"
      run "chmod 775 /etc/thin"
      invoke_command "cd #{current_path} && thin config -C #{thin_config_file} -c #{current_path} -e #{stage} --servers #{thin_servers} --port #{thin_port}"
    end
    desc "Start server"
    task :start, :roles => :app do
      invoke_command "cd #{current_path} && thin start -C #{thin_config_file}"
    end
    desc "Stop server"
    task :stop, :roles => :app do
      invoke_command "cd #{current_path} && thin stop -C #{thin_config_file}"
    end
    desc "Restart server"
    task :restart, :roles => :app do
      stop
      start
    end
  end

  namespace :db do
    desc "Set up the database: create, migrate and seed"
    task :setup, :roles => :db do
      run "#{rake_command} db:drop"
      run "#{rake_command} db:create"
      run "#{rake_command} db:migrate"
      run "#{rake_command} db:seed"
    end
    desc "Only migrates ddbb"
    task :migrate, :roles => :db do
      run "#{rake_command} db:migrate"
    end
  end

  # if you want to clean up old releases on each deploy uncomment this:
  after "deploy:restart", "deploy:cleanup"

  namespace :deploy do
    desc "Precompile all application assets"
    task :precompile_assets, :roles => :app do
      run "#{rake_command} assets:clean"
      run "#{rake_command} assets:precompile"
    end
  end
end