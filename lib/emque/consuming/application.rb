require "emque/consuming/core"
require "emque/consuming/actor"
require "emque/consuming/consumer"
require "emque/consuming/error_tracker"
require "emque/consuming/message"

def emque_autoload(klass, file)
  Kernel.autoload(klass, file)
end

module Emque
  module Consuming
    class ConfigurationError < StandardError; end

    module Application
      def self.included(descendant)
        Emque::Consuming.application = descendant

        descendant.class_eval do
          extend Emque::Consuming::Core
          include Emque::Consuming::Helpers

          attr_reader :error_tracker, :manager

          private :ensure_adapter_is_configured!, :initialize_error_tracker,
                  :initialize_manager, :log_prefix, :handle_shutdown
        end
      end

      def initialize
        self.class.instance = self

        logger.info "#{log_prefix}: initializing"

        ensure_adapter_is_configured!

        initialize_manager
        initialize_error_tracker
      end

      def notice_error(context)
        error_tracker.notice_error_for(context)
        verify_error_status
      end

      def restart
        stop
        initialize_manager
        error_tracker.occurrences.clear
        start
      end

      def start
        logger.info "#{log_prefix}: starting"
        manager.async.start
      end

      def stop
        logger.info "#{log_prefix}: stopping"
        manager.stop
      end

      def verify_error_status
        if error_tracker.limit_reached?
          if auto_shutdown_enabled
            handle_shutdown
            runner.stop
          end
        end
      end

      # private

      def auto_shutdown_enabled
        config.auto_shutdown
      end

      def ensure_adapter_is_configured!
        if config.adapter.nil?
          raise AdapterConfigurationError,
                "Adapter not found! use config.set_adapter(name, options)"
        end
      end

      def handle_shutdown
        context = {
          :limit => error_tracker.limit,
          :expiration => error_tracker.expiration,
          :occurrences => error_tracker.occurrences,
          :status => runner.status.to_h,
          :configuration => config.to_h
        }

        Emque::Consuming.logger.error("Error limit exceeded... shutting down")
        Emque::Consuming.logger.error(context)

        Emque::Consuming.config.shutdown_handlers.each do |handler|
          handler.call(context)
        end
      end

      def initialize_error_tracker
        @error_tracker = Emque::Consuming::ErrorTracker.new(
          :expiration => config.error_expiration,
          :limit => config.error_limit
        )
      end

      def initialize_manager
        @manager = config.adapter.manager.new
      end

      def log_prefix
        "#{config.app_name.capitalize} Application"
      end
    end
  end
end
