# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "simple-capistrano-unicorn/version"

Gem::Specification.new do |gem|
  gem.name        = "simple-capistrano-unicorn"
  gem.version     = Capistrano::Unicorn::Methods::VERSION
  gem.authors     = ["Kasper Grubbe"]
  gem.email       = ["kaspergrubbe@gmail.com"]
  gem.homepage    = "http://github.com/kaspergrubbe/simple-capistrano-unicorn"
  gem.summary     = %q{Contains a collection of simple tasks to manage Unicorn with Capistrano.}
  gem.description = %q{Contains a collection of simple tasks to manage Unicorn with Capistrano.}

  gem.rubyforge_project = "simple-capistrano-unicorn"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake"

  gem.add_runtime_dependency "unicorn"
  gem.add_runtime_dependency 'capistrano', '~> 3.4.0'
end
