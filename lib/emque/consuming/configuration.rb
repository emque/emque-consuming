require "logger"

module Emque
  module Consuming
    class Configuration
      attr_accessor :app_name, :adapter, :env, :error_handlers, :error_limit,
        :error_expiration, :status, :status_port, :status_host, :socket_path
      attr_writer :log_level

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
            :error_handlers,
            :error_limit,
            :error_expiration,
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
