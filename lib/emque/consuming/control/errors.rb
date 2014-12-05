module Emque
  module Consuming
    class Control
      class Errors
        include Emque::Consuming::Helpers

        COMMANDS = [:clear, :down, :expire_after, :up]

        def clear
          app.error_tracker.occurrences.clear
        end

        def down
          if app.error_tracker.limit > 1
            config.error_limit = app.error_tracker.limit -= 1
            app.verify_error_status
          end
        end

        def expire_after(seconds)
          unless seconds.is_a?(Integer)
            raise ArgumentError, "first argument must be an integer"
          end
          config.error_expiration = app.error_tracker.expiration = seconds
        end

        def up
          config.error_limit = app.error_tracker.limit += 1
        end

        def respond_to?(method)
          COMMANDS.include?(method.to_sym)
        end
      end
    end
  end
end
