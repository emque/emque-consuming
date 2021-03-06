require "celluloid"
require "inflecto"
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

        config.app_name = Inflecto.underscore(to_s).gsub("/application","")

        load_app!
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

      def initialize_logger(daemonized: false)
        target = daemonized ? logfile : STDOUT
        Emque::Consuming::Logging.initialize_logger(target)
        Emque::Consuming.logger.level = config.log_level
        Emque::Consuming.logger.formatter = config.log_formatter
        Celluloid.logger = Emque::Consuming.logger
      end

      def initialize_router!
        self.router ||= Emque::Consuming::Router.new
        require_relative File.join(root, "config", "routes.rb")
      end

      def load_app!
        app_files = Dir[File.join(root, "app", "**", "*.rb")]

        app_files.each do |app_file|
          klass = Inflecto.classify(File.basename(app_file, ".rb"))
          emque_autoload(klass.to_sym, app_file)
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
        config.env_var || ENV["EMQUE_ENV"] || "development"
      end
    end
  end
end
