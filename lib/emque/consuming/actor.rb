require "celluloid"

module Emque
  module Consuming
    module Actor
      def self.included(klass)
        klass.send(:include, Celluloid)
        klass.send(:trap_exit, :actor_died)
      end

      def logger
        Emque::Consuming::Application.internal_logger
      end

      def actor_died(actor, reason)
        logger.error "#{actor} died: #{reason}"
      end
    end
  end
end
