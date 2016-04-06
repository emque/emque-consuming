module Emque
  module Consuming
    class Router
      ConfigurationError = Class.new(StandardError)

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

            if mapping.middleware?
              message = message.with(
                :values =>
                  Oj.load(
                    mapping
                      .middleware
                      .inject(message.original) { |compiled, callable|
                        callable.call(compiled)
                      },
                    :symbol_keys => true
                  )
              )
            end

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

      def workers(topic)
        mappings[topic.to_sym].map(&:workers).max
      end

      private

      attr_accessor :mappings

      class Mapping
        attr_reader :consumer, :middleware, :topic, :workers

        def initialize(mapping, &block)
          self.topic = mapping.keys.first
          self.workers = mapping.fetch(:workers, 1)
          self.consumer = mapping.values.first
          self.mapping = {}
          self.middleware = []

          mapping.fetch(:middleware, []).map(&:use)
          self.instance_eval(&block)
        end

        def map(map)
          mapping.merge!(map)
        end

        def middleware?
          middleware.count > 0
        end

        def route(type)
          mapping[type]
        end

        def use(callable)
          unless callable.respond_to?(:call) and callable.arity == 1
            raise(
              ConfigurationError,
              "#{self.class.name}#use must receive a callable object with an " +
              "arity of one."
            )
          end

          middleware << callable
        end

        private

        attr_accessor :mapping
        attr_writer :consumer, :middleware, :topic, :workers
      end
    end
  end
end
