require "rubygems"
require "bundler/gem_tasks"
require "rake/clean"
require "rspec/core/rake_task"
require "coveralls/rake/task"

CLOBBER.include("coverage")

RSpec::Core::RakeTask.new(:spec) do |t|
  t.fail_on_error = false
end
task :default => :spec

Coverall::RakeTask.new
