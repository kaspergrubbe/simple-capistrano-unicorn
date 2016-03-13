# config valid only for current version of Capistrano
lock '3.4.0'

set :application,      "application"
set :repo_url,         "git@github.com:kaspergrubbe/application.git"
set :deploy_to,        "/home/deploy/apps/#{fetch(:application)}"

set :user,               "deploy"
set :use_sudo,           false

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
set :default_env, {
  PATH: "/home/#{fetch(:user)}/.rbenv/shims:/home/#{fetch(:user)}/.rbenv/bin:$PATH"
}

# Default value for keep_releases is 5
set :keep_releases, 5

after 'deploy', 'unicorn:restart'
