require "puma/cli"

module Emque
  module Consuming
    module Http
      class Launcher
        attr_accessor :runner

        def initialize(options)
          self.runner = Puma::CLI.new([])
          self.runner.options[:app] = Emque::Consuming.application.new
        end

        def start
          runner.run
        end

        def stop
          runner.stop
        end
      end
    end
  end
end
