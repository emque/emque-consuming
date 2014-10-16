module Emque
  module Consuming
    def self.consumer
      Module.new do
        define_singleton_method(:included) do |descendant|
          descendant.send(:include, ::Emque::Consuming::Consumer::Common)
        end
      end
    end

    class Consumer
      module Common
        def self.included(base)
          base.send(:attr_reader, :message)
        end

        def consume(handler_method, message)
          send(handler_method, message)
        end

        private

        def pipe(message, through: [])
          through.reduce(message) { |msg, method|
            begin
              msg ? send(method, msg) : msg
            rescue => e
              handle_error(e, { method: method, message: msg })
            end
          }
        end

        def handle_error(e, method:, message:)
          context = {
            :consumer => self.class.name,
            :message => {
              :current => message.values,
              :original => message.original
            },
            :offset => message.offset,
            :partition => message.partition,
            :pipe_method => method,
            :topic => message.topic
          }

          # log the error by default
          Emque::Consuming.logger.error("Error consuming message #{e}")
          Emque::Consuming.logger.error(context)
          Emque::Consuming.logger.error e.backtrace.join("\n") unless e.backtrace.nil?

          Emque::Consuming.config.error_handlers.each do |handler|
            handler.call(e, context)
          end

          Emque::Consuming.application.notice_error(context)
        end
      end
    end
  end
end
