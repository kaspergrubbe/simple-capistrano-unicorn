require 'capistrano'
require 'capistrano/version'

require 'colorize'

module SimpleCapistranoUnicorn
  class CapistranoIntegration
    def self.load_into(capistrano_config)
      capistrano_config.load do
        # Defaulting these variables, because they could end up not being defined in deploy.rb.
        _cset(:unicorn_pid)     { "#{shared_path}/pids/unicorn.pid" }
        _cset(:unicorn_old_pid) { "#{shared_path}/pids/unicorn.pid.oldbin" }
        _cset(:unicorn_config)  { "#{current_path}/config/unicorn.rb" }
        _cset(:unicorn_log)     { "#{shared_path}/log/unicorn.stderr.log" }
        _cset(:rails_env)       { "production" }

        def process_running?(server, pidfile)
          cmd = "if [ -e #{pidfile} ]; then ps cax | grep `cat #{pidfile}` > /dev/null; if [ $? -eq 0 ]; then echo -n running; fi; fi"
          'running' == capture(cmd, :hosts => [server])
        end

        def unicorn_is_running?(server)
          process_running?(server, unicorn_pid)
        end

        def old_unicorn_is_running?(server)
          process_running?(server, unicorn_old_pid)
        end

        def nice_output(output, server = nil)
          "#{server.to_s.ljust(20) if server} #{output}".colorize(:blue)
        end

        def start_unicorn(server)
          run "cd #{current_path}; bundle exec unicorn -c #{unicorn_config} -E #{rails_env} -D", :hosts => [server]
        end

        namespace :unicorn do
          # Starts the unicorn process(es)
          #
          desc "Starts unicorn"
          task :start, :roles => :app do
            find_servers(:roles => :app).each do |server|

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
                run "if [ -e #{unicorn_pid} ]; then kill -s QUIT `cat #{unicorn_pid}`; fi", :hosts => [server]
                logger.info nice_output("Stopped Unicorn!", server)
              else
                logger.info nice_output("Unicorn _not_ running, nothing to stop!", server)
              end
            end
          end

          # Restarts the unicorn process(es) with the USR2 signal, to gracefully
          # create a new server, and kill of the old one, leaving *no* downtime.
          #
          # It's following the: http://unicorn.bogomips.org/SIGNALS.html
          #
          desc "Zero-downtime restart of Unicorn"
          task :restart do
            STDOUT.sync

            # 0. PRINT STATUS OF ALL APP-SERVERS AND UNICORN STATUTES
            print "Deploying to these app-servers:\n".colorize(:light_white).bold
            find_servers(:roles => :app).each do |server|
              if unicorn_is_running?(server)
                print "♞".colorize(:green)
              else
                print "♞".colorize(:red)
              end
              print " -#{server.host}\n".colorize(:white)
            end

            # 1. MAKES SURE ALL SERVERS ARE RUNNING!
            print "Making sure all servers are running".colorize(:light_white).bold
            print ".......|".colorize(:white)
            find_servers(:roles => :app).each do |server|
              unless unicorn_is_running?(server)
                start_unicorn(server)
                logger.info nice_output("Started Unicorn!", server)
                print ".".colorize(:yellow)
              else
                print ".".colorize(:green)
              end
            end
            print "✓\n".colorize(:green).bold

            # 2. MAKE ALL SERVERS RELOAD THE NEW CODE!
            print "Reloading new code (USR2)".colorize(:light_white).bold
            print ".................|".colorize(:white)
            sleep(10)
            find_servers(:roles => :app).each do |server|
              pid = capture("cat #{unicorn_pid}", :hosts => [server]).to_i
              run "kill -s USR2 #{pid}", :hosts => [server]
              print ".".colorize(:green)
            end
            print "✓\n".colorize(:green).bold

            # 3. MAKE ALL SERVERS STOP SENDING TRAFFIC TO OLD MASTER
            print "Killing workers from old masters (WINCH)".colorize(:light_white).bold
            print "..|".colorize(:white)
            sleep(10)
            find_servers(:roles => :app).each do |server|
              old_pid = capture("cat #{unicorn_old_pid}", :hosts => [server]).to_i
              run "kill -s WINCH #{old_pid}", :hosts => [server]
              print ".".colorize(:green)
            end
            print "✓\n".colorize(:green).bold

            # 3.1 ALL TRAFFIC GOES TO NEW SERVERS, WANT TO KILL OLD?
            while(true)
              print "Traffic is handled by new master, are you happy (y/n)? ".colorize(:white)
              answer = STDIN.gets.downcase.gsub("\n",'')
              break if ['y','n'].include?(answer)
            end

            if answer == 'y'
              # 4.1 NOW ALL OLD WORKERS ARE DOwN! KILL OLD MASTER!
              print "Killing old masters (QUIT)".colorize(:light_white).bold
              print "................|".colorize(:white)
              sleep(10)
              find_servers(:roles => :app).each do |server|
                old_pid = capture("cat #{unicorn_old_pid}", :hosts => [server]).to_i
                run "kill -s QUIT #{old_pid}", :hosts => [server]
                print ".".colorize(:green)
              end
              print "✓\n".colorize(:green).bold

              print ".. code deployed!\n".colorize(:white).bold
            else
              # 4.2 DEPLOY WENT WRONG, GO BACK
              print "Reloading old master! (HUP)".colorize(:light_white).bold
              print "...............|".colorize(:white)
              sleep(10)
              find_servers(:roles => :app).each do |server|
                old_pid = capture("cat #{unicorn_old_pid}", :hosts => [server]).to_i
                run "kill -s HUP #{old_pid}", :hosts => [server]
                print ".".colorize(:green)
              end
              print "✓\n".colorize(:green).bold

              print "Killing new master! (QUIT)".colorize(:light_white).bold
              print "................|".colorize(:white)
              sleep(10)
              find_servers(:roles => :app).each do |server|
                pid = capture("cat #{unicorn_pid}", :hosts => [server]).to_i
                run "kill -s QUIT #{pid}", :hosts => [server]
                print ".".colorize(:green)
              end
              print "✓\n".colorize(:green).bold

              print ".. code _NOT_ deployed!\n".colorize(:red).bold
            end
          end

          # desc "Restart of Unicorn with downtime"
          task :hard_restart do
            unicorn.stop
            sleep(1)
            unicorn.start
          end

          desc "Prints out variables that this gem listens for"
          task :debug do
            logger.info "unicorn_pid:\t#{fetch(:unicorn_pid)}"
            logger.info "unicorn_old_pid:\t#{fetch(:unicorn_old_pid)}"
            logger.info "unicorn_config:\t#{fetch(:unicorn_config)}"
            logger.info "unicorn_log:\t#{fetch(:unicorn_log)}"
            logger.info "rails_env:   \t#{fetch(:rails_env)}"
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  SimpleCapistranoUnicorn::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
end
