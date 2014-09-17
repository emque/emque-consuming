module Emque
  module Consuming
    class Manager
      include Emque::Consuming::Actor

      def initialize(topic_mapping)
        logger.info "Manager: initializing"

        self.topic_mapping = topic_mapping
        initialize_workers
      end

      def start
        logger.info "Manager: starting workers"

        @workers.each do |worker|
          worker.async.start
        end
      end

      def stop
        logger.info "Manager: stopping workers"

        self.shutdown = true

        workers.each do |worker|
          logger.info "Manager: stopping #{worker.topic} worker..."
          worker.stop
        end

        logger.info "Manager: terminating"

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

      def logger
        Emque::Consuming.logger
      end
    end
  end
end
