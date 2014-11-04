module Emque
  module Consuming
    class Tasks
      include Rake::DSL if defined? Rake::DSL

      def install_tasks
        namespace :emque do
          desc "Show the available routes"
          task :routes do
            require "table_print"
            tp(
              [].tap { |routes|
                Emque::Consuming.application.new
                router = Emque::Consuming.application.router
                mappings = router.instance_eval { @mappings }

                mappings.each { |topic, maps|
                  maps.each { |mapping|
                    mapping.instance_eval { @mapping }.each { |route, method|
                      routes << {
                        :route => route,
                        :topic => topic,
                        :consumer => mapping.consumer,
                        :method => method,
                        :workers => router.workers(topic)
                      }
                    }
                  }
                }
              },
              {:route => {:width => 50}},
              :topic,
              :consumer,
              :method,
              :workers
            )
          end
        end
      end
    end
  end
end

Emque::Consuming::Tasks.new.install_tasks
