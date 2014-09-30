# TODO: break out the kafka specific code, conditionally include kafka or http
require "emque/consuming/http/application"
require "emque/consuming/logging"

module Emque
  module Consuming
    module Http; end

    class << self
      def application
        Emque::Consuming::Http::Application.application
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
