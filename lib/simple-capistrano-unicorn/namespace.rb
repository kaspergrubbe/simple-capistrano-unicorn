require 'capistrano'
require 'capistrano/version'

module SimpleCapistranoUnicorn
  class CapistranoIntegration
    def self.load_into(capistrano_config)
      capistrano_config.load do
        # Defaulting these variables, because they could end up not being defined in deploy.rb.
        _cset(:unicorn_pid)     { "#{shared_path}/pids/unicorn.pid" }
        _cset(:unicorn_old_pid) { "#{shared_path}/pids/unicorn.pid.oldbin" }
        _cset(:unicorn_config)  { "#{current_path}/config/unicorn.rb" }
        _cset(:unicorn_socket)  { "#{shared_path}/system/unicorn.sock" }
        _cset(:unicorn_port)    { '3000' }
        _cset(:use_bundler)     { true }
        _cset(:rails_env)       { "production" }

        def process_running?(server, pidfile)
          cmd = "if [ -e #{unicorn_pid} ]; then ps cax | grep `cat #{pidfile}` > /dev/null; if [ $? -eq 0 ]; then echo -n running; fi; fi"
          'running' == capture(cmd, :hosts => [server])
        end

        # Command to check if Unicorn is running.
        #
        def unicorn_is_running?(server)
          process_running?(server, unicorn_pid)
        end

        # Command to check if old Unicorn is running.
        #
        def old_unicorn_is_running?(server)
          process_running?(server, unicorn_old_pid)
        end

        def nice_output(output, server = nil)
          "#{server.to_s.ljust(20) if server} #{output}"
        end

        def start_unicorn(server)
          run "cd #{current_path}; #{'bundle exec' if use_bundler} unicorn -c #{unicorn_config} -E #{rails_env}#{" -p #{unicorn_port}" if unicorn_port} -D", :hosts => [server]
        end

        def clean_old_unicorn(server)
          if old_unicorn_is_running?(server)
            run "kill -s QUIT `cat #{unicorn_old_pid}`", :hosts => [server]
            run "if [ -e #{unicorn_pid} ]; then rm #{unicorn_old_pid}; fi", :hosts => [server]
            logger.info nice_output("Cleaned up old Unicorn", server)
          end
        end

        namespace :unicorn do
          # Starts the unicorn process(es)
          #
          desc "Starts unicorn"
          task :start, :roles => :app do            
            find_servers(:roles => :app).each do |server|
              clean_old_unicorn(server)

              if unicorn_is_running?(server)
                logger.info("Unicorn already running on #{server}")
              else
                # Unicorn is not running, remove the pid-file if it exists
                run "if [ -e #{unicorn_pid} ]; then rm #{unicorn_pid}; fi", :hosts => [server]
                start_unicorn(server)
                logger.info nice_output("Started Unicorn!", server)
              end
            end
          end

          # This will quit the unicorn process(es).
          #
          desc "Stop unicorn"
          task :stop, :roles => :app do
            find_servers(:roles => :app).each do |server|
              if unicorn_is_running?(server)
                run "kill -s QUIT `cat #{unicorn_pid}`", :hosts => [server]
                run "rm #{unicorn_pid}", :hosts => [server]
                logger.info nice_output("Stopped Unicorn!", server)
              else
                logger.info nice_output("Unicorn _not_ running, nothing to stop!", server)
              end
            end
          end

          # Restarts the unicorn process(es) with the URS2 code, to gracefully
          # create a new server, and kill of the old one, leaving *no* downtime.
          #
          desc "Zero-downtime restart of Unicorn"
          task :restart do
            find_servers(:roles => :app).each do |server|
              if unicorn_is_running?(server)
                pid = capture "cat #{unicorn_pid}", :hosts => [server]
                run "kill -s USR2 #{pid.to_i}", :hosts => [server] if pid.to_i > 0
                sleep(1)
                clean_old_unicorn(server)
                logger.info nice_output("Restarted Unicorn!", server)
              else
                start_unicorn(server)
                logger.info nice_output("Unicorn wasn't running, starting it!", server)
              end
            end
          end

          desc "Restart of Unicorn with downtime"
          task :hard_restart do
            unicorn.stop
            sleep(1)
            unicorn.start
          end

          # Displays the unicorn log.
          #
          desc "Displays the unicorn log"
          task :log, :roles => :app do
            run "tail -f #{shared_path}/log/unicorn.stderr.log" do |channel,stream,data|
              logger.info nice_output(data, channel[:host])
            end
          end

          # This will clean up any old unicorn servers left behind by the USR2 kill
          # command.
          #
          desc "Cleans up the old unicorn processes"
          task :clean_unicorns, :roles => :app do
            find_servers(:roles => :app).each do |server|
              clean_old_unicorn(server)
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