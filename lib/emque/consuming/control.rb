require "emque/consuming/control/errors"
require "emque/consuming/control/workers"

module Emque
  module Consuming
    class Control
      include Emque::Consuming::Helpers

      def initialize
        @errors = Emque::Consuming::Control::Errors.new
        @workers = Emque::Consuming::Control::Workers.new
      end

      def errors(*args)
        if args[0] && @errors.respond_to?(args[0])
          @errors.send(args.shift, *args)
          true
        else
          @errors
        end
      end

      def workers(topic = nil, command = nil, *args)
        if command && topic && @workers.respond_to?(command)
          @workers.send(command, topic, *args)
          true
        else
          @workers
        end
      end
    end
  end
end
