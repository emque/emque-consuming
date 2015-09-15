require "logger"

module Emque
  module Consuming
    class Configuration
      attr_accessor :app_name, :adapter, :error_handlers, :status,
        :status_port, :status_host, :socket_path
      attr_writer :env, :log_level

      def initialize
        @app_name = ""
        @error_handlers     = []
        @log_level          = nil
        @status_port        = 10000
        @status_host        = "0.0.0.0"
        @status             = :off # :on
        @socket_path        = "tmp/emque.sock"
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
            :adapter,
            :env,
            :error_handlers,
            :log_level,
            :status_port,
            :status_host,
            :status,
            :socket_path
          ].each { |attr|
            config[attr] = send(attr)
          }
        }
      end
      alias :to_h :to_hsh
    end
  end
end
