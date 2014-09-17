module Emque
  module Consuming
    class Router
      def initialize
        self.mappings = {}
      end

      def map(&block)
        self.instance_eval(&block)
      end

      def topic(mapping, &block)
        raise ArgumentError, "Exactly one mapping allowed per topic call." unless mapping.count == 1
        mapping = Mapping.new(mapping, &block)
        mappings[mapping.topic.to_sym] = mapping
      end

      def route(topic, type, message)
        mapping = mappings[topic.to_sym]
        method = mapping.route(type.to_s)

        if method
          consumer = mapping.consumer

          consumer.new.consume(method, message)
        end
      end

      def topic_mapping
        mappings.inject({}) do |hash, (topic, mapping)|
          hash.tap do |h|
            h[topic] = mapping.consumer
          end
        end
      end

      private

      attr_accessor :mappings

      class Mapping
        attr_reader :consumer, :topic

        def initialize(mapping, &block)
          self.topic = mapping.keys.first
          self.consumer = mapping.values.first
          self.mapping = {}

          self.instance_eval(&block)
        end

        def map(map)
          mapping.merge!(map.symbolize_keys)
        end

        def route(type)
          mapping[type.to_sym]
        end

        private

        attr_accessor :mapping
        attr_writer :consumer, :topic
      end
    end
  end
end
