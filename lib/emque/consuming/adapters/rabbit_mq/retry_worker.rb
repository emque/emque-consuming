require "bunny"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        class RetryWorker
          include Emque::Consuming::Helpers

          def initialize(connection)
            self.channel = connection.create_channel
            self.queue = channel.queue(
              "#{config.app_name}.error",
              :durable => true,
              :auto_delete => false,
              :arguments => {
                "x-dead-letter-exchange" => "#{config.app_name}.error"
              }
            )
          end

          attr_accessor :channel, :queue

          def retry_errors
            logger.info "RabbitMQ RetryWorker: starting"
            loop do
              delivery_info, properties, payload = queue.pop(
                {:manual_ack => true}
              )
              break if delivery_info.nil? && properties.nil? && payload.nil?
              retry_message(delivery_info, properties, payload)
            end
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

>>>>>>> 8261078... blah
          def retry_message(delivery_info, metadata, payload)
            begin
              logger.info "RabbitMQ RetryWorker: processing message #{payload}"
              message = Emque::Consuming::Message.new(
                :original => payload
              )
              ::Emque::Consuming::Consumer.new.consume(:process, message)
              channel.ack(delivery_info.delivery_tag)
            rescue
              channel.nack(delivery_info.delivery_tag)
            end
          end
        end
      end
    end
  end
end
