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
        def self.included(descendant)
          descendant.class_eval do
            attr_reader :message
            private :handle_error, :pipe
          end
        end

        def consume(handler_method, message)
          send(handler_method, message)
        end

        def pipe(message, through: [])
          through.reduce(message) { |msg, method|
            break unless msg.continue?

            begin
              send(method, msg)
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

          Emque::Consuming.application.instance.notice_error(context)
        end
      end
    end
  end
end
