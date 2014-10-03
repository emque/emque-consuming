require "bunny"

module Emque
  module Consuming
    module RabbitMq
      class Manager
        include Emque::Consuming::Actor
        trap_exit :actor_died

        def actor_died(actor, reason)
          logger.error "RabbitMQ Manager: actor_died - #{actor.inspect} died: #{reason}"
        end

        def initialize(topic_mapping)
          self.topic_mapping = topic_mapping
          rabbit_uri = Emque::Consuming::Application.application.config.rabbitmq_options[:url]
          @connection = Bunny.new rabbit_uri
          @connection.start
          initialize_workers
        end

        def start
          logger.info "RabbitMQ Manager: starting #{@workers.count} workers..."
          @workers.each do |worker|
            worker.async.start
          end
        end

        def stop
          logger.info "RabbitMQ Manager: stopping #{@workers.count} workers..."
          self.shutdown = true

          workers.each do |worker|
            logger.info "RabbitMQ Manager: stopping #{worker.topic} worker..."
            worker.stop
          end

          @connection.stop
        end

        private

        attr_accessor :workers, :shutdown, :topic_mapping

        def initialize_workers
          self.workers = [].tap { |workers|
            topic_mapping.keys.each do |topic|
              workers << Emque::Consuming::RabbitMq::Worker.new_link(@connection, topic)
            end
          }
        end

      end
    end
  end
end
