require "bunny"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        class Manager
          include Emque::Consuming::Actor
          trap_exit :actor_died

          def actor_died(actor, reason)
            unless shutdown
              logger.error "RabbitMQ Manager: actor_died - #{actor.inspect} "+
                           "died: #{reason}"
            end
          end

          def start
            setup_connection
            initialize_error_queue
            initialize_delayed_message_queue
            initialize_workers
            logger.info "RabbitMQ Manager: starting #{worker_count} workers..."
            workers(:flatten => true).each do |worker|
              worker.async.start
            end
          end

          def stop
            logger.info "RabbitMQ Manager: stopping #{worker_count} workers..."

            super do
              workers(:flatten => true).each do |worker|
                logger.info "RabbitMQ Manager: stopping #{worker.topic} worker..."
                worker.stop
              end
            end

            @connection.stop
          end

          def worker(topic:, command:)
            if workers.has_key?(topic)
              case command
              when :down
                worker = workers[topic].pop
                worker.stop if worker
              when :up
                workers[topic] << new_worker(topic)
                workers[topic].last.async.start
              end
            end
          end

          def workers(flatten: false)
            flatten ? @workers.values.flatten : @workers
          end

          def retry_errors
            RetryWorker.new(@connection).retry_errors
          end

          private

          attr_writer :workers
          attr_accessor :delayed_message_exchange, :delayed_queue

          def initialize_workers
            self.workers = {}.tap { |workers|
              router.topic_mapping.keys.each do |topic|
                workers[topic] ||= []
                router.workers(topic).times do
                  workers[topic] << new_worker(topic)
                end
              end
            }
          end

          def enable_delayed_message
            config.enable_delayed_message
          end

          def initialize_delayed_message_queue
            if enable_delayed_message
              channel = @connection.create_channel
              self.delayed_message_exchange = channel.exchange(
                "emque.#{config.app_name}.delayed_message",
                {
                  :type => "x-delayed-message",
                  :durable => true,
                  :auto_delete => false,
                  :arguments => {
                    "x-delayed-type" => "direct",
                  }
                }
              )

              self.delayed_queue = channel.queue(
                "emque.#{config.app_name}.delayed_message",
                :durable => config.adapter.options[:durable],
                :auto_delete => config.adapter.options[:auto_delete],
                :arguments => {
                  "x-dead-letter-exchange" => "#{config.app_name}.error"
                }
              ).bind(delayed_message_exchange)
            end
          end

          def initialize_error_queue
            channel = @connection.create_channel
            error_exchange = channel.fanout(
              "#{config.app_name}.error",
              :durable => true,
              :auto_delete => false
            )
            channel.queue(
              "emque.#{config.app_name}.error",
              :durable => true,
              :auto_delete => false,
              :arguments => {
                "x-dead-letter-exchange" => "#{config.app_name}.error"
              }
            ).bind(error_exchange)
            channel.close
          end

          def new_worker(topic)
            # rethink this one, get timeout errors when attempting to subscribe
            # migrate logic to a delayed_message worker from mq worker
            # and recreate queues there?
            if enable_delayed_message
              options = {
                :delayed_message_exchange => delayed_message_exchange,
                :delayed_queue => delayed_queue
              }
            else
              options = {}
            end
            Worker.new_link(@connection, topic, options)
          end

          def setup_connection
            @connection = Bunny.new(config.adapter.options[:url])
            @connection.start
          end

          def worker_count
            workers(:flatten => true).size
          end
        end
      end
    end
  end
end
