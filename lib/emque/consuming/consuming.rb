require "emque/consuming/runner"
require "emque/consuming/logging"

module Emque
  module Consuming
    class << self
      attr_accessor :application

      # The Configuration instance used to configure the Emque::Consuming environment
      def config
        Emque::Consuming.application.config
      end

      def logger
        Emque::Consuming::Logging.logger
      end

      def logger=(log)
        Emque::Consuming::Logging.logger = log
      end

      def runner
        Emque::Consuming::Runner.instance
      end
    end
  end
end
