# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'emque/consuming/version'

Gem::Specification.new do |spec|
  spec.name          = "emque-consuming"
  spec.version       = Emque::Consuming::VERSION
  spec.authors       = []
  spec.email         = []
  spec.summary       = %q{A gem for high-level interaction with Kafka}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = ""

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "celluloid"
  spec.add_dependency "poseidon"
  spec.add_dependency "poseidon_cluster"
  spec.add_dependency "thor"
  spec.add_dependency "dante"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "daemon_controller"
end
