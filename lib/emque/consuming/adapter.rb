module Emque
  module Consuming
    class AdapterConfigurationError < StandardError; end

    module Adapter
      def self.load(name)
        fetch(name).load
      end

      def self.manager(name)
        fetch(name).manager
      end

      def self.fetch(name)
        const_name = "Emque::Consuming::Adapter::#{name.to_s.capitalize}"
        if const_defined?(const_name)
          const_name.constantize
        else
          raise AdapterConfigurationError, "Unknown consuming adapter"
        end
      end

      module Kafka
        def self.load
          require_relative "kafka/manager"
          require_relative "kafka/worker"
          require_relative "kafka/fetcher"
        end

        def self.manager
          Emque::Consuming::Kafka::Manager
        end
      end

      module Rabbitmq
        def self.load
          require_relative "rabbitmq/manager"
          require_relative "rabbitmq/worker"
        end

        def self.manager
          Emque::Consuming::RabbitMq::Manager
        end
      end
    end
  end
end
