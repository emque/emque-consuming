require "oj"
require_relative "consumer/common"
require_relative "retryable_errors"

module Emque
  module Consuming
    class BlockingFailure < StandardError; end

    class Consumer
      include Emque::Consuming.consumer

      def process(message)
        pipe(message, :through => [:parse, :route])
      end

      private

      def parse(message)
        message.with(
          :values =>
            Oj.load(message.original, :symbol_keys => true)
        )
      end

      def route(message)
        Emque::Consuming.application.router.route(
          message.values.fetch(:metadata).fetch(:topic),
          message.values.fetch(:metadata).fetch(:type),
          message
        )
      end
    end
  end
end
