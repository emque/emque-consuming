require "bunny"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        class DelayedMessageWorker
          include Emque::Consuming::Actor
          include Emque::Consuming::RetryableErrors
          trap_exit :actor_died

          def actor_died(actor, reason)
            unless shutdown
              logger.error "#{log_prefix} actor_died - died: #{reason}"
            end
          end

          def initialize(connection)
            self.channel = connection.create_channel

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

            self.queue = channel.queue(
              "emque.#{config.app_name}.delayed_message",
              :durable => config.adapter.options[:durable],
              :auto_delete => config.adapter.options[:auto_delete],
              :arguments => {
                "x-dead-letter-exchange" => "#{config.app_name}.error"
              }
            ).bind(delayed_message_exchange)
          end

          def start
            logger.info "#{log_prefix} starting..."
            queue.subscribe(:manual_ack => true, &method(:process_message))
            logger.debug "#{log_prefix} started"
          end

          def stop
            logger.debug "#{log_prefix} stopping..."
            super do
              logger.debug "#{log_prefix} closing channel"
              channel.close
            end
            logger.debug "#{log_prefix} stopped"
          end

          private

          attr_accessor :channel, :delayed_message_exchange, :queue

          def process_message(delivery_info, metadata, payload)
            begin
              logger.info "#{log_prefix} processing message #{metadata}"
              logger.debug "#{log_prefix} payload #{payload}"
              message = Emque::Consuming::Message.new(
                :original => payload
              )
              ::Emque::Consuming::Consumer.new.consume(:process, message)
              channel.ack(delivery_info.delivery_tag)
            rescue StandardError => exception
              if retryable_errors.any? { |error| exception.class.to_s =~ /#{error}/ }
                retry_error(delivery_info, metadata, payload, exception)
              else
                channel.nack(delivery_info.delivery_tag)
              end
            end
          end

          def log_prefix
            "RabbitMQ DelayedMessageWorker:"
          end
        end
      end
    end
  end
end
