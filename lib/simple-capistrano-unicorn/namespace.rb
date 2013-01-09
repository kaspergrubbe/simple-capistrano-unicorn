require 'capistrano'
require 'capistrano/version'
require 'shell-spinner'

module SimpleCapistranoUnicorn
  class CapistranoIntegration
    TASKS = [
      'unicorn:start',
      'unicorn:stop',
      'unicorn:restart',
      #'unicorn:reload', 
      'unicorn:log',
    ]

    def self.load_into(capistrano_config)
      capistrano_config.load do
        before(CapistranoIntegration::TASKS) do
          # Defaulting these variables, because they could end up not being defined in deploy.rb 
          _cset(:unicorn_pid)     { "#{shared_path}/pids/unicorn.pid" }
          _cset(:unicorn_old_pid) { "#{shared_path}/pids/unicorn.pid.oldbin" }
          _cset(:unicorn_config)  { "#{current_path}/config/unicorn.rb" }
          _cset(:unicorn_socket)  { "#{shared_path}/system/unicorn.sock" }
          _cset(:unicorn_port)    { 3000 }
          _cset(:use_bundler)     { true }
          _cset(:rails_env)       { "production" }
        end

        namespace :unicorn do

          # Taken from the capistrano code.
          # def _cset(name, *args, &block)
          #   unless exists?(name)
          #     set(name, *args, &block)
          #   end
          # end

          #
          # Starts the unicorn process(es)
          #
          desc "Starts unicorn"
          task :start, :roles => :app do
            ShellSpinner "Positive result" do
              unicorn.cleanup
              start_without_cleanup
            end
          end

          #
          # This will quit the unicorn process(es).
          #
          desc "Stop unicorn"
          task :stop, :roles => :app do
            find_servers(:roles => :app).each do |server|
              run "touch #{unicorn_pid}", :hosts => [server]
              pid = capture "cat #{unicorn_pid}", :hosts => [server]
              run "kill -s QUIT #{pid.to_i}", :hosts => [server] if pid.to_i > 0
            end
          end

          #
          # Restarts the unicorn process(es) with the URS2 code, to gracefully
          # create a new server, and kill of the old one, leaving *no* downtime
          #
          desc "Zero-downtime restart of Unicorn"
          task :restart do
            unicorn.cleanup
            find_servers(:roles => :app).each do |server|
              run "touch #{unicorn_pid}", :hosts => [server]
              pid = capture "cat #{unicorn_pid}", :hosts => [server]
              run "kill -s USR2 #{pid.to_i}", :hosts => [server] if pid.to_i > 0
            end
          end

          #
          # Starts the unicorn servers
          desc "Starts the unicorn server without cleaning up from the previous instance"
          task :start_without_cleanup, :roles => :app do
            run "cd #{current_path}; #{'bundle exec' if use_bundler} unicorn -c #{unicorn_config} -E #{rails_env} -p #{"#{unicorn_port}"} -D"
          end

          #
          # This will clean up any old unicorn servers left behind by the USR2 kill
          # command.
          #
          desc "Cleans up the old unicorn processes"
          task :cleanup, :roles => :app do
            find_servers(:roles => :app).each do |server|
              run "touch #{unicorn_old_pid}", :hosts => [server]
              pid = capture "cat #{unicorn_old_pid}", :hosts => [server]
              run "kill -s QUIT #{pid.to_i}", :hosts => [server] if pid.to_i > 0
            end
          end

          #
          # This will clean up any old unicorn servers left behind by the USR2 kill
          # command.
          #
          desc "Removes all pid files!"
          task :remove_pids, :roles => :app do
            run "touch #{unicorn_old_pid}; touch #{unicorn_pid}"
            run "rm #{unicorn_old_pid}; rm #{unicorn_pid}"
          end

          #
          # Displays the unicorn log
          #
          desc "Displays the unicorn log"
          task :log, :roles => :app do
            run "tail -f #{shared_path}/log/unicorn.stderr.log" do |channel,stream,data|
              puts "#{channel[:host].ljust(20)} #{data}"
            end
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  SimpleCapistranoUnicorn::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
end