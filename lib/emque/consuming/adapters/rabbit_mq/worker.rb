require "bunny"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        class Worker
          include Emque::Consuming::Actor
          include Emque::Consuming::RetryableErrors
          trap_exit :actor_died

          attr_accessor :topic

          def actor_died(actor, reason)
            unless shutdown
              logger.error "#{log_prefix} actor_died - died: #{reason}"
            end
          end

          def initialize(connection, topic)
            self.topic = topic
            self.name = "#{self.topic} worker"
            self.shutdown = false

            # @note: channels are not thread safe, so is better to use
            #        a new channel in each worker.
            # https://github.com/jhbabon/amqp-celluloid/blob/master/lib/consumer.rb
            self.channel = connection.create_channel

            if config.adapter.options[:prefetch]
              channel.prefetch(config.adapter.options[:prefetch])
            end

            self.queue =
              channel
                .queue(
                  "emque.#{config.app_name}.#{topic}",
                  :durable => config.adapter.options[:durable],
                  :auto_delete => config.adapter.options[:auto_delete],
                  :arguments => {
                    "x-dead-letter-exchange" => "#{config.app_name}.error"
                  }
                )
                .bind(
                  channel.fanout(topic, :durable => true, :auto_delete => false)
                )
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

          attr_accessor :name, :channel, :queue

          def enable_delayed_message
            config.enable_delayed_message
          end

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
              logger.error "#{log_prefix} #{exception.class}: #{exception.message}"
              exception.backtrace.each { |bt| logger.error "#{log_prefix} #{bt}" }
              if enable_delayed_message
                begin
                  publish_to_delayed_message(delivery_info, metadata, payload)
                rescue
                  channel.nack(delivery_info.delivery_tag)
                end
              else
                if retryable_errors.any? { |error| ex.class.to_s =~ /#{error}/ }
                  retry_error(delivery_info, metadata, payload, ex)
                else
                  channel.nack(delivery_info.delivery_tag)
                end
              end
            end
          end

          def publish_to_delayed_message(delivery_info, metadata, payload)
            headers = metadata[:headers] || {}
            headers["x-delay"] = 1000
            delayed_message_exchange.publish(payload, { :headers => headers })
            channel.ack(delivery_info.delivery_tag)
          end

          def delayed_message_exchange
            delayed_message_exchange = channel.exchange(
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
            channel.queue(
              "emque.#{config.app_name}.delayed_message",
              :durable => config.adapter.options[:durable],
              :auto_delete => config.adapter.options[:auto_delete],
              :arguments => {
                "x-dead-letter-exchange" => "#{config.app_name}.error"
              }
            ).bind(delayed_message_exchange)

            delayed_message_exchange
          end

          def log_prefix
            "RabbitMQ Worker: #{object_id} #{name}"
          end
        end
      end
    end
  end
end
