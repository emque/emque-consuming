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
          end
        end

        def consume(handler_method, message)
          send(handler_method, message)
        end

        def pipe_config
          @pipe_config ||= Pipe::Config.new(
            :stop_on => ->(msg, _, _) { !(msg.respond_to?(:continue?) && msg.continue?) }
          )
        end
      end
    end
  end
end
