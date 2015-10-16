module Emque
  module Consuming
    class Control
      class Workers
        include Emque::Consuming::Helpers

        COMMANDS = [:down, :up]

        def down(topic)
          app.manager.worker(topic: topic.to_sym, command: :down)
        end

        def up(topic)
          if app.manager.worker_count < config.max_workers.fetch(:limit)
            app.manager.worker(topic: topic.to_sym, command: :up)
          else
            :max_worker_limit_reached
          end
        end

        def respond_to?(method)
          COMMANDS.include?(method.to_sym)
        end
      end
    end
  end
end
