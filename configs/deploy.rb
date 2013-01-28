set :application, "testapp"
set :repository,  "git@github.com:kaspergrubbe/testapp.git"
set :branch,      "master"
set :scm,         :git

# Server settings
set :user,                  "deployer"
#set :ssh_options,           { :forward_agent => true }
set :use_sudo,              false
set :use_bundler,           true
set :deploy_to,             "/home/#{user}/apps/#{application}"

# Unicorn options
set :unicorn_suicide,       true

role :web, "176.58.122.173"                          # Your HTTP server, Apache/etc
role :app, "176.58.122.173"                          # This may be the same as your `Web` server
role :db,  "176.58.122.173", :primary => true # This is where Rails migrations will run
role :db,  "176.58.122.173"

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"

# Restart unicorn after deploy
after :deploy, "unicorn:restart"

# The deploy strategies are:
# checkout (default) - This makes the servers do a git clone to update code
# export             - This makes a git export instead of checkout (But what really happens is a checkout
#                      followed by a deletion of the .git-dirs, use checkout instead)
# remote_cache       - This keeps a remote git repo on the servers, when deploying it does a git pull
#                      and copies the files to the release path.
# copy               - This strategy checks out the branch to your local machine, compresses it, and copies
#                      the code to each server and uncompress it. This is smart when Github is failing.
#                      But if you live in Belgium and need to upload it to the danish servers, you might
#                      not want to use it. 
# 
# source: https://github.com/capistrano/capistrano/tree/master/lib/capistrano/recipes/deploy/strategy
#         https://help.github.com/articles/deploying-with-capistrano
set :deploy_via, :copy

# rbenv
set :default_environment, {
  "PATH" => "/home/#{user}/.rbenv/shims:/home/#{user}/.rbenv/bin:$PATH",
}

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

require "bundler/capistrano"
require 'simple-capistrano-unicorn'