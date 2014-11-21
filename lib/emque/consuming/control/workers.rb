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
          app.manager.worker(topic: topic.to_sym, command: :up)
        end

        def respond_to?(method)
          COMMANDS.include?(method.to_sym)
        end
      end
    end
  end
end
