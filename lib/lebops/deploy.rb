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
  set :rvm_type, :system
  require "rvm/capistrano"

  require "bundler/capistrano"

  set :user, "root"
  set :user_sudo, false

  namespace :app do

    desc "Setup or reset: DB and App_server"
    task :setup, :roles => :app do
      rvm.install_ruby
      deploy.setup
      deploy.check
      deploy.update # also does bundle.install
      thin.setup
      thin.config
      db.config
      db.reset
      deploy.precompile_assets
      thin.start
    end

    desc "Update from last release: DB and App_server"
    task :update, :roles => :app do
      deploy.update
      db.migrate
      deploy.precompile_assets
      thin.restart
    end
  end

  namespace :ops do

    desc "Tail the Rails log for the current stage"
    task :log, :roles => :app do
      stream "tail -f #{deploy_to}/shared/log/#{stage}.log"
    end

    desc "Open a console for the current stage"
    task :console, :roles => :app do
      ssh_prompt(%{cd #{current_path} && /usr/local/rvm/bin/rvm-shell -c 'bundle exec rails c #{stage}'})
    end

    desc "Open a ssh connection for the current stage"
    task :ssh, :roles => :app do
      ssh_prompt()
    end
  end

  def ssh_prompt(remote_command = "")
    hostname = find_servers_for_task(current_task).first
    ssh_call = %{ssh #{user}@#{hostname}}

    if remote_command
      ssh_call = %{#{ssh_call} -t "#{remote_command}"}
    end

    exec ssh_call
  end

  namespace :thin do
    desc "Sets up Thin gem"
    task :setup, :roles => :app do
      invoke_command "cd #{current_path} && gem install thin --no-ri --no-rdoc"
      run "mkdir /etc/thin"
      run "chmod 775 /etc/thin"
    end
    desc "Creates config file"
    task :config, :roles => :app do
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
    desc "Configure database.yml"
    task :config, :roles => :db do
      db_config = <<-EOF
      #{stage}: &base
        adapter:  postgresql
        host:     localhost
        encoding: utf8
        pool:     5
        username: #{database_username}
        password: #{database_password}
        template: template0
        database: #{application}_#{stage}
      EOF

      run "mkdir -p #{shared_path}/config"
      put db_config, "#{shared_path}/config/database.yml"
    end
    desc "Sets up the database: drop if exists, create, migrate and seed"
    task :reset, :roles => :db do
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