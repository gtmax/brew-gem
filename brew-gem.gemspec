# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "brew_gem/version"

Gem::Specification.new do |s|
  s.name          = "brewgem"
  s.version       = BrewGem::VERSION
  s.authors       = ["Joshua Peek", "...", "Max Rozenoer"]
  s.email         = ["maxr@gett.com"]
  s.description   = %q{Install Systemwide Ruby Gems via Brew}
  s.summary       = %q{Install a ruby gem with a locked gemset environemnt for systemwide use in any rvm context}
  s.homepage      = "https://github.com/gtmax/brewgem"
  s.license       = "MIT"

  s.files         = Dir["lib/**/*", "bin/*", "config/**/*"]
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.required_rubygems_version = ">= 1.8.23"
  s.required_ruby_version = ">= 2.0.0"

  s.add_dependency "thor", "~> 0.19", ">= 0.15.0"
  s.add_development_dependency "bundler", "~> 1.3"
end

