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
        mapping = Mapping.new(mapping, &block)
        mappings[mapping.topic.to_sym] ||= []
        mappings[mapping.topic.to_sym] << mapping
      end

      def route(topic, type, message)
        mappings[topic.to_sym].each do |mapping|
          method = mapping.route(type.to_s)

          if method
            consumer = mapping.consumer

            consumer.new.consume(method, message)
          end
        end
      end

      def topic_mapping
        mappings.inject({}) do |hash, (topic, maps)|
          hash.tap do |h|
            h[topic] = maps.map(&:consumer)
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
