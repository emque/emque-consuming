require_relative "configuration"
require_relative "logging"

module Emque
  module Consuming
    class << self
      def application
        Emque::Consuming::Application.application
      end

      # The Configuration instance used to configure the Emque::Consuming environment
      def config
        application.config
      end

      def logger
        Emque::Consuming::Logging.logger
      end

      def logger=(log)
        Emque::Consuming::Logging.logger = log
      end
    end
  end
end
