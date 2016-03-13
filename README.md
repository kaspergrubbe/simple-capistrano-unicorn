# Simple Capistrano Unicorn

Contains a namespace with methods for administrating the unicorn server through capistrano recipes.

This gem is composed from the gems `capistrano-unicorn-methods` and `capistrano-unicorn`. It is roughly the structure of `capistrano-unicorn-methods` with clever ideas from `capistrano-unicorn`.

## Setup

### 1. Add Gem to Gemfile

```ruby
gem 'simple-capistrano-unicorn'
```

### 2. Require this gem in deploy.rb

You should add this line to your `Capfile`:

```ruby
require 'simple-capistrano-unicorn'
```

### 3. Restart Unicorn on deploy

You should place this line in `PROJECT_ROOT/config/deploy.rb`:

```ruby
after 'deploy', 'unicorn:restart'
```

### 4. Add your `unicorn.rb`

Grab the sample Unicorn configuration here: https://github.com/kaspergrubbe/simple-capistrano-unicorn/blob/master/configs/unicorn.conf.rb

And place it here: `PROJECT_ROOT/config/unicorn.rb` change the `app_root` variable if you deploy user isn't named `deployer`.

## Usage

Go through the setup and run: `cap production deploy`

The gem gives you access to the following tasks:

* `unicorn:start` starts the Unicorn processes
* `unicorn:stop` stops the Unicorn processes
* `unicorn.restart` makes a seamless zero-downtime restart
* `unicorn.hard_restart` basically runs `unicorn:stop` followed with a `unicorn:start`

## Requirements

* `unicorn`
* `capistrano`

## Customization

You can customize the gems behavior by setting any (or all) of the following options within capistrano's configuration:

* `unicorn_pid` indicates the path for the pid file. Defaults to `"#{shared_path}/pids/unicorn.pid"`.
* `unicorn_old_pid` indicates the path for the old pid file, which Unicorn creates when forking a new master. Defaults to `#{shared_path}/pids/unicorn.pid.oldbin`.
* `unicorn_config` the path to the unicorn config file. Defaults to `"#{current_path}/config/unicorn.rb"`.
* `unicorn_log` the path where unicorn places its STDERR-log. Defaults to `"#{shared_path}/log/unicorn.stderr.log"`.
* `rack_env` sets the environment that the server will run in. Defaults to `"production"`.
