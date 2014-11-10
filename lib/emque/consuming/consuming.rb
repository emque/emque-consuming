require "emque/consuming/application"
require "emque/consuming/logging"

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

      def status
        application.status
      end
    end
  end
end
