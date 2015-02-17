# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "emque/consuming/version"

Gem::Specification.new do |spec|
  spec.name          = "emque-consuming"
  spec.version       = Emque::Consuming::VERSION
  spec.authors       = ["Ryan Williams", "Dan Matthews"]
  spec.email         = ["oss@teamsnap.com"]
  spec.summary       = %q{Microservices framework for Ruby}
  spec.summary       = %q{Microservices framework for Ruby}
  spec.homepage      = "https://github.com/teamsnap/emque-consuming"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = "~> 2.0"

  spec.add_dependency "celluloid", "0.15.2"
  spec.add_dependency "activesupport", "~> 4.1"
  spec.add_dependency "dante", "~> 0.2.0"
  spec.add_dependency "oj", "~> 2.10.2"
  spec.add_dependency "virtus", "~> 1.0.3"
  spec.add_dependency "puma"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "daemon_controller"
  spec.add_development_dependency "poseidon", "0.0.4"
  spec.add_development_dependency "poseidon_cluster", "~> 0.1.1"
  spec.add_development_dependency "bunny", "~> 1.4.1"
  spec.add_development_dependency "timecop", "~> 0.7.1"
end
