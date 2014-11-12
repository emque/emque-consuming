require "emque/consuming/status/controller"
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
          :app => Emque::Consuming.application.config.app_name,
          :errors => {
            :count => service_app.error_tracker.count,
            :expire_after => service_app.error_tracker.expiration,
            :limit => service_app.error_tracker.limit
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
          controller =
            Emque::Consuming::Status::Controller.new(req[2..-1], service_app)
          controller.process ? render_status(controller.status) : render_404
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
