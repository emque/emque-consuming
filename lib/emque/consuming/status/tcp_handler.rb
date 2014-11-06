require "puma/cli"

module Emque
  module Consuming
    class Status
      class TcpHandler
        attr_accessor :process, :thread

        def initialize
          self.process =
            Puma::CLI.new(
              [],
              Puma::Events.new(
                Emque::Consuming::Status::TcpHandler::Logger.new(:info),
                Emque::Consuming::Status::TcpHandler::Logger.new(:error)
              )
            )

          self.process.options[:binds] = [
            "tcp://#{Emque::Consuming.config.status_host}"+
            ":#{Emque::Consuming.config.status_port}"
          ]
        end

        def restart
          stop if running?
          start
        end

        def start
          self.process.options[:app] = Emque::Consuming.status
          self.thread = Thread.new { process.run }
          status
        end

        def status
          running? ? :running : :stopped
        end

        def stop
          thread.exit if running?
          status
        end

        def running?
          thread && !thread.stop?
        end

        class Logger
          attr_accessor :sync, :method

          def initialize(method)
            self.method = method
          end

          def puts(str)
            Emque::Consuming.logger.send(method, str)
          end
          alias :write :puts
        end
      end
    end
  end
end
