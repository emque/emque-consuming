require "thor"
require "active_support/core_ext/string"

module Emque
  class Cli < Thor
    include Thor::Actions

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), "..", "templates"))
    end

    desc "start", "Run Emque service"
    option "d", :type => :boolean
    option "pidfile", :aliases => ["-P"], :type => :string
    def start
      current_dir = Dir.pwd

      if File.exist?(File.join(current_dir, "config", "application.rb"))
        require_relative File.join(current_dir, "config", "application.rb")
        Emque::Consuming::Launcher.new(options).start
      end
    end

    desc "stop", "Stop Emque service"
    option "pidfile", :aliases => ["-P"], :type => :string, :required => true
    option "timeout", :type => :numeric, :default => 10
    def stop
      current_dir = Dir.pwd

      if File.exist?(File.join(current_dir, "config", "application.rb"))
        require_relative File.join(current_dir, "config", "application.rb")
        Emque::Consuming::Launcher.new(options).stop
      end
    end

    desc "new SERVICE_NAME", "Create a new Emque service. "
    def new(name)
      name = name.underscore
      target = File.join(Dir.pwd, name)

      opts = {
        :name => name.camelize,
        :underscore_name => name
      }

      template(File.join("Gemfile.tt"), File.join(target, "Gemfile"), opts)
      template(File.join("gitignore.tt"), File.join(target, ".gitignore"), opts)
      template(File.join("config/application.rb.tt"), File.join(target, "config/application.rb"), opts)

      %w{test development staging production}.each do |environment|
        template(File.join("config/environments/environment.rb.tt"), File.join(target, "config/environments/#{environment}.rb"), opts)
      end

      template(File.join("consumers/gitkeep.tt"), File.join(target, "consumers/.gitkeep"), opts)

      Dir.mkdir(File.join(target, "log"))
    end

    desc "console", "Open service pry console"
    method_option :aliases => "c"
    def console
      current_dir = Dir.pwd

      if File.exist?(File.join(current_dir, "config", "application.rb"))
        require File.join(current_dir, "config", "application.rb")
        require "pry"
        require_relative "console"
        Object.send(:include, Emque::Console)
        Pry.start
      end
    end
  end
end
