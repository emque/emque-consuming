module Emque
  module Consuming
    module CommandReceivers
      NotImplemented = Class.new(StandardError)

      class Base
        include Emque::Consuming::Helpers

        def restart
          stop if running?
          start
        end

        def start
          raise NotImplemented
        end

        def stop
          thread.exit if running?
          status
        end

        def status
          thread ? (thread.status || "stopped") : "stopped"
        end

        private

        attr_reader :thread

        def running?
          thread && !thread.stop?
        end
      end
    end
  end
end
