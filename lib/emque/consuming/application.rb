require "emque/consuming/configuration"
require "emque/consuming/logging"
require "emque/consuming/consumer"
require "emque/consuming/actor"
require "emque/consuming/launcher"
require "emque/consuming/router"
require "emque/consuming/message"
require "emque/consuming/error_tracker"

def emque_autoload(klass, file)
  Kernel.autoload(klass, file)
end

module Emque
  module Consuming
    class ConfigurationError < StandardError; end

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

      attr_reader :error_tracker

      def initialize
        require_relative File.join(self.class.root, "config", "environments", "#{self.class.emque_env}.rb")

        initialize_logger
        logger.info "Application: initializing"

        require "celluloid"
        Celluloid.logger = Emque::Consuming.logger

        if consuming_adapter == :rabbitmq
          require_relative "rabbitmq/manager"
          require_relative "rabbitmq/worker"
        elsif consuming_adapter == :kafka
          require_relative "kafka/manager"
          require_relative "kafka/worker"
          require_relative "kafka/fetcher"
        else
          raise ConfigurationError, "Unknown consuming adapter"
        end

        self.class.router ||= Emque::Consuming::Router.new
        require_relative File.join(self.class.root, "config", "routes.rb")

        self.error_tracker = Emque::Consuming::ErrorTracker.new(
          :limit => Emque::Consuming::Application.application.config.error_limit
        )
      end

      def initialize_logger
        Emque::Consuming::Logging.initialize_logger(self.class.logfile)
        Emque::Consuming.logger.level = self.class.config.log_level
      end

      def start(test_loop: 1)
        logger.info "Application: starting"
        if consuming_adapter == :rabbitmq
          self.manager = Emque::Consuming::RabbitMq::Manager.new(
            Emque::Consuming::Application.application.router.topic_mapping)
        elsif consuming_adapter == :kafka
          self.manager = Emque::Consuming::Kafka::Manager.new(
            Emque::Consuming::Application.application.router.topic_mapping)
        else
          raise ConfigurationError, "Unknown consuming adapter"
        end
        manager.async.start
      end

      def shutdown
        logger.info "Application: shutting down"
        manager.stop
      end

      def logger
        self.class.logger
      end

      def consuming_adapter
        Emque::Consuming::Application.application.config.consuming_adapter
      end

      def notice_error(context)
        error_tracker.notice_error_for(context)
        shutdown if error_tracker.limit_reached?
      end

      private

      attr_accessor :manager
      attr_writer :error_tracker
    end
  end
end
