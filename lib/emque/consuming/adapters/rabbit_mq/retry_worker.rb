require "bunny"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        class RetryWorker
          include Emque::Consuming::Helpers

          def initialize(connection)
            self.connection = connection
            self.channel = connection.create_channel
          end

          def retry_errors
            logger.info "RabbitMQ RetryWorker: starting"
            channel.open if channel.closed?
            error_queue.message_count.times do
              delivery_info, properties, payload = error_queue.pop(
                {:manual_ack => true}
              )
              retry_message(delivery_info, properties, payload)
            end
            channel.close
            logger.info "RabbitMQ RetryWorker: done"
          end

          private

          attr_accessor :connection, :channel

          def error_queue
            channel.queue(
              "emque.#{config.app_name}.error",
              :durable => true,
              :auto_delete => false,
              :arguments => {
                "x-dead-letter-exchange" => "#{config.app_name}.error"
              }
            )
          end

          def retry_message(delivery_info, metadata, payload)
            begin
              logger.info "RabbitMQ RetryWorker: processing message #{payload}"
              message = Emque::Consuming::Message.new(
                :original => payload
              )
              ::Emque::Consuming::Consumer.new.consume(:process, message)
              channel.ack(delivery_info.delivery_tag)
            rescue StandardError
              channel.nack(delivery_info.delivery_tag)
            end
          end
        end
      end
    end
  end
end
