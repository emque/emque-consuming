require_relative "configuration"
require_relative "logging"

module Emque
  module Consuming
    class << self
      def logger
        Emque::Consuming::Logging.logger
      end

      def logger=(log)
        Emque::Consuming::Logging.logger = log
      end

      def error_handlers
        @configuration.error_handlers
      end
    end
  end
end
