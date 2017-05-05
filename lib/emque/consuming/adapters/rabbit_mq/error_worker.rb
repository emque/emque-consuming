require "bunny"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        class ErrorWorker
          include Emque::Consuming::Helpers

          def initialize(connection)
            self.connection = connection
            self.channel = connection.create_channel
          end

          def retry_errors
            logger.info "#{log_prefix} starting"
            channel.open if channel.closed?
            error_queue.message_count.times do
              delivery_info, properties, payload = error_queue.pop(
                {:manual_ack => true}
              )
              if delivery_info && properties && payload
                retry_message(delivery_info, properties, payload)
              end
            end
            channel.close
            logger.info "#{log_prefix} done"
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

          def log_prefix
            "RabbitMQ ErrorWorker:"
          end

          def retry_message(delivery_info, metadata, payload)
            begin
              logger.info "#{log_prefix} processing message #{metadata}"
              logger.debug "#{log_prefix} payload #{payload}"
              message = Emque::Consuming::Message.new(
                :original => payload
              )
              ::Emque::Consuming::Consumer.new.consume(:process, message)
              channel.ack(delivery_info.delivery_tag)
            rescue StandardError => exception
              logger.error "#{log_prefix} #{exception.class}: #{exception.message}"
              exception.backtrace.each { |bt| logger.error "#{log_prefix} #{bt}" }
              channel.nack(delivery_info.delivery_tag)
            end
          end
        end
      end
    end
  end
end
