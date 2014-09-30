require "emque/consuming/http/configuration"
require "emque/consuming/logging"
require "emque/consuming/http/launcher"
require "emque/consuming/http/router"
require "emque/consuming/message"
require "emque/consuming/consumer/common"

def emque_autoload(klass, file)
  Kernel.autoload(klass, file)
end

module Emque
  module Consuming
    module Http
      class Application
        class << self
          attr_accessor :root, :application, :router
        end

        attr_accessor :router

        def self.inherited(subclass)
          Emque::Consuming::Http::Application.application = subclass
          call_stack = caller_locations.map(&:path)
          subclass.root = File.expand_path(
            "../..",
            call_stack.find { |call| call !~ %r{lib/emque} }
          )

          app_name = subclass.to_s.underscore.gsub("/application","")
          Emque::Consuming::Http::Application.application.config.app_name = app_name

          subclass.load_service!
        end

        def self.load_service!
          service_files = Dir[File.join(root, "service", "**", "*.rb")]

          service_files.each do |service_file|
            klass = File.basename(service_file, ".rb").classify
            emque_autoload(klass.to_sym, service_file)
          end
        end

        def self.configure(&block)
          instance_exec(&block)
        end

        def self.config
          @config ||= Emque::Consuming::Http::Configuration.new
        end

        def self.logfile
          @logfile ||= File.join(self.root, "log/#{emque_env}.log").tap do |path|
            directory = File.dirname(path)
            Dir.mkdir(directory) unless File.exist?(directory)
          end
        end

        def self.logger
          Emque::Consuming.logger
        end

        def self.emque_env
          # TODO: These ENV vars should probably be kept in sync
          ENV["EMQUE_ENV"] || ENV["RACK_ENV"] || "development"
        end

        def initialize(app = nil)
          require_relative File.join(self.class.root, "config", "environments", "#{self.class.emque_env}.rb")

          initialize_logger
          logger.info "Application: initializing"

          @app = app
          self.class.router ||= Emque::Consuming::Http::Router.new
          require_relative File.join(self.class.root, "config", "routes.rb")
        end

        def call(env)
          self.class.router.call(env)
        end

        def initialize_logger
          Emque::Consuming::Logging.initialize_logger(self.class.logfile)
          Emque::Consuming.logger.level = self.class.config.log_level
        end

        def logger
          self.class.logger
        end
      end
    end
  end
end
