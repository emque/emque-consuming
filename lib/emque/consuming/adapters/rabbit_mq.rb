module Emque
  module Consuming
    module Adapters
      module RabbitMq
        def self.default_options
          {:url => "amqp://guest:guest@localhost:5672", :prefetch => nil}
        end

        def self.load
          require_relative "rabbit_mq/manager"
          require_relative "rabbit_mq/worker"
        end

        def self.manager
          Emque::Consuming::Adapters::RabbitMq::Manager
        end
      end
    end
  end
end
