require "celluloid"
require "emque/consuming/configuration"
require "emque/consuming/adapter"
require "emque/consuming/logging"
require "emque/consuming/router"
require "emque/consuming/helpers"

module Emque
  module Consuming
    module Core
      def self.extended(descendant)
        descendant.class_eval do
          class << self
            attr_accessor :root, :topic_mapping, :router, :instance

            alias :configure :instance_exec
          end
        end
      end

      def initialize_core!
        unless root
          call_stack = caller_locations.map(&:path)
          self.root = File.expand_path(
            "../..",
            call_stack.find { |call| call !~ %r{lib/emque} }
          )
        end

        self.topic_mapping = {}

        config.app_name = to_s.underscore.gsub("/application","")

        load_service!
        initialize_environment!
        initialize_router!
      end

      def config
        @config ||= Emque::Consuming::Configuration.new
      end

      def initialize_environment!
        require_relative File.join(
          root,
          "config",
          "environments",
          "#{emque_env}.rb"
        )
      end

      def initialize_logger
        Emque::Consuming::Logging.initialize_logger(logfile)
        Emque::Consuming.logger.level = config.log_level
        Celluloid.logger = Emque::Consuming.logger
      end

      def initialize_router!
        self.router ||= Emque::Consuming::Router.new
        require_relative File.join(root, "config", "routes.rb")
      end

      def load_service!
        service_files = Dir[File.join(root, "service", "**", "*.rb")]

        service_files.each do |service_file|
          klass = File.basename(service_file, ".rb").classify
          emque_autoload(klass.to_sym, service_file)
        end
      end

      def logfile
        @logfile ||= File.join(root, "log/#{emque_env}.log").tap do |path|
          directory = File.dirname(path)
          Dir.mkdir(directory) unless File.exist?(directory)
        end
      end

      def logger
        Emque::Consuming.logger
      end

      def emque_env
        config.env || ENV["EMQUE_ENV"] || ENV["RACK_ENV"] || "development"
      end
    end
  end
end
