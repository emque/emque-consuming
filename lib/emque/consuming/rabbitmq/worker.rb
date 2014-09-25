require "bunny"

module Emque
  module Consuming
    module RabbitMq
      class Worker
        include Emque::Consuming::Actor
        trap_exit :actor_died

        attr_accessor :topic

        def actor_died(actor, reason)
          logger.error "RabbitMQ Worker: actor_died - #{actor.inspect} died: #{reason}"
        end

        def initialize(connection, topic)
          self.topic = topic
          self.name = "#{self.topic} worker"
          self.shutdown = false

          # @note: channels are not thread safe, so is better to use
          #        a new channel in each worker.
          # https://github.com/jhbabon/amqp-celluloid/blob/master/lib/consumer.rb
          @channel = connection.create_channel
          exchange = @channel.fanout(topic, :durable => true, :auto_delete => false)
          app_name = Emque::Consuming::Application.application.config.app_name
          @queue = @channel.
            queue("#{app_name}.#{topic}", :durable => true, :auto_delete => false).
            bind(exchange)
        end

        def start
          logger.info "RabbitMQ Worker: #{name} starting..."
          @queue.subscribe(:manual_ack => true) do |delivery_info, metadata, payload|
            process_message(delivery_info, metadata, payload)
          end
        end

        def stop
          logger.info "RabbitMQ Worker: #{name} stopping..."
          self.shutdown = true
          @channel.close
        end

        private

        attr_accessor :name, :channel, :consumer_klass, :shutdown

        def process_message(delivery_info, metadata, payload)
          logger.info "RabbitMQ Worker: #{name} processing message #{payload}"
          message = Emque::Consuming::Message.new(
            :offset => nil,
            :original => payload,
            :partition => nil,
            :topic => topic.to_sym
          )
          ::Emque::Consuming::Consumer.new.consume(:process, message)
          @channel.ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
