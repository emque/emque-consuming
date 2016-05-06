module Emque
  module Consuming
    module Adapters
      module RabbitMq
        def self.default_options
          {
            :url => "amqp://guest:guest@localhost:5672",
            :prefetch => nil,
            :durable => true,
            :auto_delete => false
          }
        end

        def self.load
          require_relative "rabbit_mq/manager"
          require_relative "rabbit_mq/worker"
          require_relative "rabbit_mq/retry_worker"
          require_relative "rabbit_mq/delayed_message_worker"
        end

        def self.manager
          Emque::Consuming::Adapters::RabbitMq::Manager
        end
      end
    end
  end
end
