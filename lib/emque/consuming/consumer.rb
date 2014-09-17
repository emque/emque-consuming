require "active_support/core_ext"
require "oj"
require_relative "consumer/common"

module Emque
  module Consuming
    class BlockingFailure < StandardError; end

    class Consumer
      include ::Emque::Consuming.consumer

      def process(message)
        pipe(message, :through => [:parse, :validate, :route])
      end

      private

      def parse(message)
        message.with(
          :values =>
            Oj.load(message.original, :symbol_keys => true)
        )
      end

      def route(message)
        Emque::Application.application.router.route(
          message.topic,
          message.values.fetch(:metadata).fetch(:type),
          message
        )
      end

      def validate(message)
        message.tap do |msg|
          if message.values.fetch(:partition_key)
            # NOTE: still don't understand why...
            raise Emque::Consuming::BlockingFailure
          end
        end
      end
    end
  end
end
