module Emque
  module Consuming
    class Manager
      include Emque::Consuming::Actor
      trap_exit :actor_died

      def actor_died(actor, reason)
        logger.error "Manager: actor_died - #{actor.inspect} died: #{reason}"
      end

      def initialize(topic_mapping)
        self.topic_mapping = topic_mapping
        initialize_workers
      end

      def start
        logger.info "Manager: starting #{@workers.count} workers..."

        @workers.each do |worker|
          worker.async.start
        end
      end

      def stop
        logger.info "Manager: stopping #{@workers.count} workers..."
        self.shutdown = true

        workers.each do |worker|
          logger.info "Manager: stopping #{worker.topic} worker..."
          worker.stop
        end

        terminate
      end

      private

      attr_accessor :workers, :shutdown, :topic_mapping

      def initialize_workers
        self.workers = [].tap { |workers|
          topic_mapping.keys.each do |topic|
            workers << Emque::Consuming::Worker.new_link(topic)
          end
        }
      end

    end
  end
end
