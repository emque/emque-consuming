module Emque
  module Consuming
    class MetadataFailure < StandardError; end

    class Fetcher
      include Emque::Consuming::Actor
      trap_exit :actor_died

      def actor_died(actor, reason)
        logger.error "Fetcher: actor_died - #{actor.inspect} died: #{reason}"
      end

      def initialize(worker, topic)
        self.worker = worker
        self.topic = topic
        self.shutdown = false
        build_topic_consumer
      end

      def stop
        logger.info "Fetcher: stopping..."
        self.shutdown = true
        topic_consumer.close
        terminate
      end

      def fetch
        unless shutdown
          begin
            topic_consumer.fetch(:commit => false) do |partition, messages|
              worker.async.push_work(partition, messages)
            end
          rescue => ex
            handle_error(ex)
            raise
          end
        end
      end

      def commit(partition, offset)
        if (offset + 1) > topic_consumer.offset(partition)
          logger.info "Fetcher: commiting #{offset + 1} to partition #{partition}"
          topic_consumer.commit(partition, offset + 1)
        end
      end

      def has_partition?(partition)
        topic_consumer.claimed.include?(partition)
      end

      private

      attr_accessor :worker, :topic, :shutdown, :topic_consumer

      def build_topic_consumer
        pool = Poseidon::BrokerPool.new(
          SecureRandom.hex,
          Emque::Consuming::Application.application.config.seed_brokers
        )

        count = 0

        while count < 4 do
          break unless Poseidon::ClusterMetadata
            .new
            .tap { |m| m.update(pool.fetch_metadata([topic.to_s])) }
            .metadata_for_topics([topic.to_s])[topic.to_s]
            .struct
            .error == 5

          count += 1

          raise MetadataFailure if count == 4

          sleep 1
        end

        app_name = Emque::Consuming::Application.application.config.app_name

        self.topic_consumer = Poseidon::ConsumerGroup.new(
          "#{app_name}_#{topic}_group",
          Emque::Consuming::Application.application.config.seed_brokers,
          Emque::Consuming::Application.application.config.zookeepers,
          topic.to_s
        )
      end

      def handle_error(e)
        Emque::Consuming::Application.error_handlers.each do |handler|
          begin
            handler.call(e, nil)
          rescue => ex
            logger.error "Error handler raised an error"
            logger.error ex
            logger.error ex.backtrace.join("\n") unless ex.backtrace.nil?
          end
        end
      end
    end
  end
end
