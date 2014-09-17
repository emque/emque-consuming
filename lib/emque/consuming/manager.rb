module Emque
  module Consuming
    class Manager
      include Emque::Consuming::Actor

      trap_exit :actor_died

      def actor_died(actor, reason)
        Emque::Consuming.logger.error "#{actor.inspect} died: #{reason}"
      end

      def initialize(topic_mapping)
        Emque::Consuming.logger.info "Manager: initializing"
      end

      def start
        Emque::Consuming.logger.info "Manager: starting workers"
      end

      def cleanup
        Emque::Consuming.logger.info "Manager: cleaning up workers)"
      end

      def shutdown
        Emque::Consuming.logger.info "Manager: shutting down workers)"
      end
    end
  end
end
