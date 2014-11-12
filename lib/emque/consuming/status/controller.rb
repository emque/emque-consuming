module Emque
  module Consuming
    class Status
      class Controller
        attr_reader :status

        def initialize(request, service_app)
          self.app = service_app
          self.args = request
          self.status = {}
          self.subject = args.shift.to_sym
        end

        def process
          case subject
          when :errors
            errors_control
          else
            workers_control
          end
        end

        private

        attr_accessor :app, :args, :subject
        attr_writer :status

        def errors_control
          case args[0]
          when "up"
            app.error_tracker.limit += 1
            status[:message] = "Increased the error threshold"
            return true
          when "down"
            app.error_tracker.limit -= 1 if app.error_tracker.limit > 1
            app.verify_error_status
            status[:message] = "Decreased the error threshold"
            return true
          when "expire_after"
            if args[1]
              app.error_tracker.expiration = args[1].to_i
              status[:message] = "Changed the error time to expiration"
              return true
            end
          when "clear"
            app.error_tracker.occurrences.clear
            status[:message] = "Cleared the outstanding errors"
            return true
          end
          false
        end

        def workers_control
          if app.manager.workers.has_key?(subject) &&
            ["up", "down"].include?(args[0])
            puts "processing #{args[0]} on #{subject}"
            app.manager.worker(topic: subject, command: args[0].to_sym)
            puts "done"
            status[:message] = "Processed command #{args[0]} for #{subject}"
            true
          else
            false
          end
        end
      end
    end
  end
end
