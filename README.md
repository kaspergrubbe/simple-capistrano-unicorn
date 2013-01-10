# Simple Capistrano Unicorn

Contains a namespace with methods for administrating the unicorn server through capistrano recipes.

This gem is composed from the gems `capistrano-unicorn-methods` and `capistrano-unicorn`. It is roughly the structure of `capistrano-unicorn-methods` with clever ideas from `capistrano-unicorn`.

## Setup

### 1. Require this gem in deploy.rb

You should add this line in the bottom of `RAILS_ROOT/config/deploy.rb`:

```
require 'simple-capistrano-unicorn'
```

### 2. Restart Unicorn on deploy

You should place this line in `RAILS_ROOT/config/deploy.rb`:

```
after :deploy, "unicorn:restart"
```

### 3. Add unicorn.rb (only for single-stage setup)

Grab the sample Unicorn configuration here: http://unicorn.bogomips.org/examples/unicorn.conf.rb

And place it here: `RAILS_ROOT/config/unicorn.rb`

### 4. Add unicorn stage files (only for multi-stage setup)

Make sure that you are using the multi-stage extension for Capistrano ( https://github.com/capistrano/capistrano/wiki/2.x-Multistage-Extension )

You can get a sample of the Unicorn configuration here: http://unicorn.bogomips.org/examples/unicorn.conf.rb

You should create different Unicorn files to use for each of your different environments. The most common setup is to place the Unicorn configuration files in `RAILS_ROOT/config/unicorn/{staging|beta|production}.rb`.

You can then override the `unicorn_config`-variable that this gem is listening for, by placing this in `RAILS_ROOT/config/deploy.rb`:

```
set(:unicorn_config) { "#{fetch(:current_path)}/config/unicorn/#{fetch(:stage)}.rb" }
```

## Usage

Go through the setup and run: `cap deploy` or `cap production deploy` (for multistage)

The gem gives you access to the following methods within the `unicorn.<method>` namespace.

* `unicorn.start` starts the Unicorn processes
* `unicorn.stop` stops the Unicorn processes
* `unicorn.restart` makes a seamless zero-downtime restart
* `unicorn.hard_restart` basically runs `unicorn.stop` followed with a `unicorn.start` 
* `unicorn.log` prints out from the Unicorn log in `tail -f`-like fashion
* `unicorn.cleanup` removes the old running Unicorn master

## Requirements

* `unicorn`
* `capistrano`

## Customization

You can customize the gems behavior by setting any (or all) of the following options within capistrano's configuration:

* `unicorn_pid` indicates the path for the pid file. Defaults to `"#{shared_path}/pids/unicorn.pid"`.
* `unicorn_old_pid` indicates the path for the old pid file, which Unicorn creates when forking a new master. Defaults to `#{shared_path}/pids/unicorn.pid.oldbin`.
* `unicorn_config` the path to the unicorn config file. Defaults to `"#{current_path}/config/unicorn.rb"`.
* `unicorn_socket` indicates the place that Unicorn should place its socket file. Defaults to `"#{shared_path}/system/unicorn.sock"`.
* `unicorn_log` the path where unicorn places its STDERR-log. Defaults to `"#{shared_path}/log/unicorn.stderr.log"`.
* `unicorn_port` defines the port that unicorn should listen on. Defaults to `"3000"`.
* `use_bundler` defines whether Unicorn should start with `bundle exec` or not. Default to `true`.
* `rails_env` sets the environment that the server will run in. Defaults to `"production"`.