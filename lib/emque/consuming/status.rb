require "emque/consuming/status/tcp_handler"

module Emque
  module Consuming
    class Status
      delegate :start, :stop, :restart, :running?, :to => :status_app

      def initialize(app)
        self.service_app = app
        self.status_app = TcpHandler.new
      end

      def call(env)
        handle_request(env)
      end

      def to_hsh
        {
          :errors => {
            :count => service_app.error_tracker.count
          },
          :workers => {}.tap { |worker_stats|
            service_app.manager.workers.each { |topic, workers|
              worker_stats[topic] = {
                :count => workers.size
              }
            }
          }
        }
      end
      alias :to_h :to_hsh

      private

      attr_accessor :service_app, :status_app

      def handle_request(env)
        req = env["REQUEST_URI"].split("/")

        case req[1]
        when "status"
          render_status
        when "control"
          handle_control_request(req[2..-1])
        else
          render_404
        end
      end

      def handle_control_request(args)
        if args.is_a?(Array) &&
           args[0] &&
           args[1] &&
           service_app.manager.workers.has_key?(args[0].to_sym)

          service_app
            .manager
            .worker(topic: args[0].to_sym, command: args[1].to_sym)

          render_status(
            :message => "Processed command #{args[1]} for #{args[0]}"
          )
        else
          render_404
        end
      end

      def render_404
        [404, {}, ["Not Found"]]
      end

      def render_status(additional = {})
        [200, {}, [Oj.dump(to_hsh.merge(additional), :mode => :compat)]]
      end
    end
  end
end
