require "logger"

module Emque
  module Consuming
    module Http
      class Configuration
        attr_accessor :app_name, :approach, :error_handlers
        attr_writer :log_level

        def initialize
          @app_name = ""
          @approach = :undefined
          @error_handlers = []
          @log_level      = nil
        end

        def log_level
          @log_level ||= Logger::INFO
        end
      end
    end
  end
end
