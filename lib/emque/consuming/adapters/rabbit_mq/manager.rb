require "bunny"
require_relative "error_worker"
require_relative "delayed_message_worker"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        class Manager
          include Emque::Consuming::Actor
          trap_exit :actor_died

          def actor_died(actor, reason)
            unless shutdown
              logger.error "RabbitMQ Manager: actor_died - #{actor.inspect} " +
                           "died: #{reason}"
            end
          end

          def start
            setup_connection
            initialize_error_queue
            initialize_workers
            initialize_delayed_message_workers if enable_delayed_message
            logger.info "RabbitMQ Manager: starting #{worker_count} workers..."
            workers(:flatten => true).each do |worker|
              worker.async.start
            end
            if enable_delayed_message
              delayed_message_workers.each do |worker|
                worker.async.start
              end
            end
          end

          def stop
            logger.info "RabbitMQ Manager: stopping #{worker_count} workers..."

            super do
              workers(:flatten => true).each do |worker|
                logger.info "RabbitMQ Manager: stopping #{worker.topic} worker..."
                worker.stop
              end
              if enable_delayed_message
                delayed_message_workers.each_with_index do |worker, i|
                  logger.info "RabbitMQ Manager: stopping #{worker.class} #{i + 1} worker..."
                  worker.stop
                end
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

          def delayed_message_workers
            @delayed_message_workers
          end

          def retry_errors
            ErrorWorker.new(@connection).retry_errors
          end

          private

          attr_writer :workers, :delayed_message_workers

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

          def initialize_delayed_message_workers
            self.delayed_message_workers = [].tap { |workers|
              config.delayed_message_workers.times do
                workers << DelayedMessageWorker.new_link(@connection)
              end
            }
          end

          def enable_delayed_message
            config.enable_delayed_message
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
            Worker.new_link(@connection, topic)
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
