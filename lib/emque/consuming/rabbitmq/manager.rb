require "bunny"

module Emque
  module Consuming
    module RabbitMq
      class Manager
        include Emque::Consuming::Actor
        trap_exit :actor_died

        def actor_died(actor, reason)
          logger.error "RabbitMQ Manager: actor_died - #{actor.inspect} "+
                       "died: #{reason}"
        end

        def initialize(router)
          self.router = router
          rabbit_uri =
            Emque::Consuming::Application
              .application
              .config
              .rabbitmq_options[:url]

          @connection = Bunny.new rabbit_uri
          @connection.start
          initialize_workers
        end

        def start
          logger.info "RabbitMQ Manager: starting #{worker_count} workers..."
          workers(:flatten => true).each do |worker|
            worker.async.start
          end
        end

        def stop
          logger.info "RabbitMQ Manager: stopping #{worker_count} workers..."
          self.shutdown = true

          workers(:flatten => true).each do |worker|
            logger.info "RabbitMQ Manager: stopping #{worker.topic} worker..."
            worker.stop
          end

          @connection.stop
        end

        private

        attr_accessor :shutdown, :router
        attr_writer :workers

        def initialize_workers
          self.workers = {}.tap { |workers|
            router.topic_mapping.keys.each do |topic|
              workers[topic] ||= []
              router.workers(topic).times do
                workers[topic] <<
                  Emque::Consuming::RabbitMq::Worker
                    .new_link(@connection, topic)
              end
            end
          }
        end

        def worker_count
          workers(:flatten => true).size
        end

        def workers(flatten: false)
          flatten ? @workers.values.flatten : @workers
        end

      end
    end
  end
end
