# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "simple-capistrano-unicorn/version"

Gem::Specification.new do |s|
  s.name        = "simple-capistrano-unicorn"
  s.version     = Capistrano::Unicorn::Methods::VERSION
  s.authors     = ["Kasper Grubbe"]
  s.email       = ["kaspergrubbe@gmail.com"]
  s.homepage    = "http://kaspergrubbe.dk"
  s.summary     = %q{Contains a collection of simple tasks to manage Unicorn with Capistrano.}
  s.description = %q{Contains a collection of simple tasks to manage Unicorn with Capistrano.}

  s.rubyforge_project = "simple-capistrano-unicorn"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "shell-spinner"
  s.add_runtime_dependency "unicorn"
end
