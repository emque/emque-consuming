require "puma/cli"
require "emque/consuming/command_receivers/base"

module Emque
  module Consuming
    module CommandReceivers
      class HttpServer < Base
        attr_accessor :puma

        def initialize
          ENV["RACK_ENV"] = Emque::Consuming.application.emque_env
          initialize_puma
        end

        def start
          puma.options[:app] = Handler.new
          @thread = Thread.new { puma.run }
          status
        end

        private

        def initialize_puma
          self.puma =
            Puma::CLI.new(
              [],
              Puma::Events.new(
                Logger.new(:info),
                Logger.new(:error)
              )
            )

          puma.options[:binds] = [
            "tcp://#{config.status_host}"+
            ":#{config.status_port}"
          ]

          puma.define_singleton_method :set_process_title do
            # we don't want puma to take over the process name
          end
        end

        class Handler
          include Emque::Consuming::Helpers

          def call(env)
            req = env["REQUEST_URI"].split("/")

            case req[1]
            when "status"
              return render_status
            when "control"
              case req[2]
              when "errors"
                if req[3..-1] && app.runner.control.errors(*req[3..-1]) == true
                  return render_status
                end
              else
                if req[2].is_a?(String) &&
                   app.manager.workers.has_key?(req[2].to_sym) &&
                   runner.control.workers(*req[2..-1]) == true
                  return render_status
                end
              end
            end

            render_404
          end

          def render_404
            [404, {}, ["Not Found"]]
          end

          def render_status(additional = {})
            [
              200,
              {},
              [
                Oj.dump(
                  runner.status.to_hsh.merge(additional),
                  :mode => :compat
                )
              ]
            ]
          end
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
