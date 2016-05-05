require "bunny"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        class Worker
          include Emque::Consuming::Actor
          trap_exit :actor_died

          attr_accessor :topic

          def actor_died(actor, reason)
            unless shutdown
              logger.error "#{log_prefix} actor_died - died: #{reason}"
            end
          end

          def initialize(connection, topic, options = {})
            self.topic = topic
            self.name = "#{self.topic} worker"
            self.shutdown = false
            self.delayed_message_exchange = options[:delayed_message_exchange]
            self.delayed_queue = options[:delayed_queue]

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
            if enable_delayed_message
              delayed_queue.subscribe(
                :manual_ack => true,
                &method(:process_message)
              )
            end
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

          attr_accessor :name, :channel, :queue, :delayed_queue,
            :delayed_message_exchange

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
            rescue StandardError => ex
              if enable_delayed_message
                if retryable_errors.any? { |error| ex.class.to_s =~ /#{error}/ }
                  retry_errors(delivery_info, metadata, payload, ex)
                else
                  channel.nack(delivery_info.delivery_tag)
                end
              else
                channel.nack(delivery_info.delivery_tag)
              end
            end
          end

          def retry_errors(delivery_info, metadata, payload, ex)
            headers = metadata[:headers] || {}
            retry_count = headers.fetch("x-retry-count", 0)

            if retry_count <= retryable_error_limit
              logger.info("Retrying Retryable Error #{ex.class}, with count #{retry_count}")
              headers["x-retry-count"] = retry_count + 1
              headers["x-delay"] = delay_ms_time(retry_count)
              channel.ack(delivery_info.delivery_tag)
              delayed_message_exchange.publish(payload, {:headers =>headers})
            else
              logger.info("Retryable Error: #{ex.class} ran out of retries at #{retry_count}")
              channel.nack(delivery_info.delivery_tag)
            end
          end

          def delay_ms_time(retry_count)
            500 * ( 2 ** retry_count) * rand(1..10)
          end

          def retryable_errors
            config.retryable_errors
          end

          def retryable_error_limit
            config.retryable_error_limit
          end

          def log_prefix
            "RabbitMQ Worker: #{object_id} #{name}"
          end
        end
      end
    end
  end
end
