require "emque/consuming/configuration"
require "emque/consuming/logging"
require_relative "consumer"
require_relative "actor"
require_relative "launcher"
require_relative "router"
require_relative "worker"
require_relative "fetcher"
require_relative "message"

def emque_autoload(klass, file)
  Kernel.autoload(klass, file)
end

module Emque
  module Consuming
    class Application
      class << self
        attr_accessor :root, :topic_mapping, :application, :router
      end

      def self.inherited(subclass)
        Emque::Consuming::Application.application = subclass
        call_stack = caller_locations.map(&:path)
        subclass.root = File.expand_path(
          "../..",
          call_stack.find { |call| call !~ %r{lib/emque} }
        )

        app_name = subclass.to_s.underscore.gsub("/application","")
        Emque::Consuming::Application.application.config.app_name = app_name

        subclass.topic_mapping = {}
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
        @config ||= Emque::Consuming::Configuration.new
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
        ENV["EMQUE_ENV"] || "development"
      end

      def initialize
        require_relative File.join(self.class.root, "config", "environments", "#{self.class.emque_env}.rb")

        initialize_logger
        logger.info "Application: initializing"

        require "celluloid/autostart"
        Celluloid.logger = Emque::Consuming.logger

        require_relative "manager"

        self.class.router ||= Emque::Consuming::Router.new
        require_relative File.join(self.class.root, "config", "routes.rb")
      end

      def initialize_logger
        Emque::Consuming::Logging.initialize_logger(self.class.logfile)
        Emque::Consuming.logger.level = self.class.config.log_level
      end

      def start(test_loop: 1)
        logger.info "Application: starting"
        self.manager = Manager.new(Emque::Consuming::Application.application.router.topic_mapping)

        unless $TESTING
          manager.async.start
        else
          test_loop.times do
            manager.async.start
          end
        end
      end

      def shutdown
        manager.stop
      end

      def logger
        self.class.logger
      end

      private

      attr_accessor :manager
    end
  end
end
