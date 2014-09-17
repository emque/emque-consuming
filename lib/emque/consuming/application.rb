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
        #Emque::Producer::Config.app_name = app_name

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
        #Emque::Producer::Config.seed_brokers = config.seed_brokers
      end

      def self.config
        @config ||= Configuration.new
      end

      def self.logger
        @logger ||= initialize_logger
      end

      def self.logfile
        @logfile ||= File.join(self.root, "log/#{emque_env}.log").tap do |path|
          directory = File.dirname(path)
          Dir.mkdir(directory) unless File.exist?(directory)
        end
      end

      def self.emque_env
        ENV["EMQUE_ENV"] || "development"
      end

      def initialize
        ENV["EMQUE_ENV"] ||= "development"
        require "celluloid"
        require_relative File.join(self.class.root, "config", "environments", "#{self.class.emque_env}.rb")
      end

      def start(test_loop: 1)
        self.manager = Manager.new(Emque::Application.application.router.topic_mapping)

        unless $TESTING
          manager.async.start
        else
          test_loop.times do
            manager.async.start
          end
        end
      end

      def shutdown
        manager.shutdown
        manager.cleanup
        manager.terminate
      end

      private

      attr_accessor :manager

      def self.initialize_logger
        @logger = ActiveSupport::Logger.new(logfile)
        @logger.formatter = Emque::LogFormatter.new
        @logger
      end

      def self.internal_logger
        application.logger
      end
    end
  end
end
