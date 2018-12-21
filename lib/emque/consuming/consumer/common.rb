require "pipe"

module Emque
  module Consuming
    def self.consumer
      Module.new do
        define_singleton_method(:included) do |descendant|
          descendant.send(:include, ::Pipe)
          descendant.send(:include, ::Emque::Consuming::Consumer::Common)
        end
      end
    end

    class Consumer
      module Common
        def self.included(descendant)
          descendant.class_eval do
            attr_reader :message
            private :handle_error, :pipe
          end
        end

        def consume(handler_method, message)
          send(handler_method, message)
        end

        def pipe_config
          @pipe_config ||= Pipe::Config.new(
            :error_handlers => [method(:handle_error)],
            :raise_on_error => false,
            :stop_on => ->(msg, _, _) { !(msg.respond_to?(:continue?) && msg.continue?) }
          )
        end

        def handle_error(e, method:, subject:)
          context = {
            :consumer => self.class.name,
            :message => {
              :current => subject.values,
              :original => subject.original
            },
            :offset => subject.offset,
            :partition => subject.partition,
            :pipe_method => method,
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
end
