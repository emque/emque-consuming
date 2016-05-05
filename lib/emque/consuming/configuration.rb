require "logger"

module Emque
  module Consuming
    class Configuration
      attr_accessor :app_name, :adapter, :auto_shutdown, :enable_delayed_message
        :error_handlers, :error_limit, :error_expiration, :retryable_errors,
        :retryable_error_limit, :status, :status_port, :status_host,
        :socket_path, :shutdown_handlers
      attr_writer :env, :log_level

      def initialize
        @app_name               = ""
        @auto_shutdown      = false
        @enable_delayed_message = false
        @error_handlers         = []
        @error_limit            = 5
        @error_expiration       = 3600 # 60 minutes
        @log_level              = nil
        @retryable_errors       = []
        @retryable_error_limit  = 3
        @status_port            = 10000
        @status_host            = "0.0.0.0"
        @status                 = :off # :on
        @socket_path            = "tmp/emque.sock"
        @shutdown_handlers      = []
      end

      def env
        Emque::Consuming.application.emque_env
      end

      def env_var
        @env
      end

      def log_level
        @log_level ||= Logger::INFO
      end

      def set_adapter(name, options = {})
        @adapter = Emque::Consuming::Adapter.new(name, options)
      end

      def to_hsh
        {}.tap { |config|
          [
            :app_name,
            :auto_shutdown,
            :adapter,
            :env,
            :enable_delayed_message,
            :error_handlers,
            :error_limit,
            :error_expiration,
            :log_level,
            :retryable_errors,
            :retryable_error_limit,
            :status_port,
            :status_host,
            :status,
            :socket_path,
            :shutdown_handlers
          ].each { |attr|
            config[attr] = send(attr)
          }
        }
      end
      alias :to_h :to_hsh
    end
  end
end
