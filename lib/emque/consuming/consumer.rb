require_relative "consumer/common"
require_relative "retryable_errors"

module Emque
  module Consuming
    class BlockingFailure < StandardError; end

    class Consumer
      include Emque::Consuming.consumer

      def process(message)
        pipe(message, :through => [:parse, :route])
      rescue => e
        handle_error(e, message)
        raise
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

      def handle_error(e, subject)
        context = {
          :consumer => self.class.name,
          :message => {
            :current => subject.values,
            :original => subject.original
          },
          :topic => subject.topic
        }

        # log the error by default
        Emque::Consuming.logger.error("Error consuming message #{e}")
        Emque::Consuming.logger.error(context)
        Emque::Consuming.logger.error e.backtrace.join("\n") unless e.backtrace.nil?

        Emque::Consuming.config.error_handlers.each do |handler|
          handler.call(e, context)
        end

        Emque::Consuming.application.instance.notice_error(context)
      end
    end
  end
end
