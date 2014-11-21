module Emque
  module Consuming
    module Helpers
      private

      def app
        @app ||=
          Emque::Consuming.application.instance ||
          Emque::Consuming.application.new
      end

      def config
        Emque::Consuming.application.config
      end

      def logger
        Emque::Consuming.application.logger
      end

      def router
        Emque::Consuming.application.router
      end

      def runner
        Emque::Consuming.runner
      end
    end
  end
end
