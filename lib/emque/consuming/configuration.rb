require "logger"

module Emque
  module Consuming
    class Configuration
      attr_accessor :adapter, :error_handlers, :error_limit, :error_expiration,
        :status, :status_port, :status_host, :socket_path, :shutdown_handlers
      attr_writer :env, :log_level
      attr_reader :app_name

      def initialize
        @app_name = ""
        @error_handlers     = []
        @error_limit        = 5
        @error_expiration   = 3600 # 60 minutes
        @log_level          = nil
        @status_port        = 10000
        @status_host        = "0.0.0.0"
        @status             = :off # :on
        @socket_path        = "tmp/emque.sock"
        @shutdown_handlers  = []
      end

      def app_name=(value)
        @human_app_name = nil
        @app_name = value
      end

      def env
        Emque::Consuming.application.emque_env
      end

      def env_var
        @env
      end

      def human_app_name
        @human_app_name ||= app_name
          .split(/[_\-\.]/)
          .map(&:capitalize)
          .tap { |parts| parts << "Application" }
          .join(" ")
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
            :adapter,
            :env,
            :error_handlers,
            :error_limit,
            :error_expiration,
            :log_level,
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
