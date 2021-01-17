module Emque
  module Consuming
    class Tasks
      include Rake::DSL if defined? Rake::DSL
      include Emque::Consuming::Helpers

      def install_tasks
        namespace :emque do
          desc "Show the current configuration of a running instance " +
               "(accepts SOCKET)"
          task :configuration do
            puts with_transmitter(:send, :configuration)
          end

          desc "Start a pry console"
          task :console do
            Emque::Consuming::Runner.new.console
          end

          namespace :errors do
            desc "Clear all outstanding errors (accepts SOCKET)"
            task :clear do
              puts with_transmitter(:send, :errors, :clear)
            end

            desc "Change the number of seconds to SECONDS before future " +
                 "errors expire (accepts SOCKET)"
            task :expire_after do
              seconds = ENV.fetch("SECONDS", 3600)
              puts with_transmitter(:send, :errors, :expire_after, seconds)
            end

            namespace :limit do
              desc "Decrease the error limit (accepts SOCKET)"
              task :down do
                puts with_transmitter(:send, :errors, :down)
              end

              desc "Increase the error limit (accepts SOCKET)"
              task :up do
                puts with_transmitter(:send, :errors, :up)
              end
            end
          end

          desc "Show the available routes"
          task :routes do
            require "table_print"
            tp(
              [].tap { |routes|
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

          desc "Restart the workers inside a running instance " +
               "(does not reload code; accepts SOCKET)"
          task :restart do
            with_transmitter(:send, :restart)
          end

          desc "Show the current status of a running instance " +
               "(accepts SOCKET)"
          task :status do
            puts with_transmitter(:send, :status)
          end

          desc "Start a new instance (accepts PIDFILE)"
          task :start do
            pidfile = ENV.fetch("PIDFILE", "tmp/pids/#{config.app_name}.pid")

            Emque::Consuming::Runner.new({
              :pidfile => pidfile
            }).start
          end

          desc "Stop a running instance (accepts SOCKET)"
          task :stop do
            resp = with_transmitter(:send, :stop)
            puts resp.length > 0 ? resp : "stopped"
          end
        end
      end

      private

      def with_transmitter(method, command, *args)
        socket_path = ENV.fetch("SOCKET", config.socket_path)
        require "emque/consuming/transmitter"
        Emque::Consuming::Transmitter.send(
          :command => command,
          :socket_path => socket_path,
          :args => args
        )
      end
    end
  end
end

Emque::Consuming::Tasks.new.install_tasks
