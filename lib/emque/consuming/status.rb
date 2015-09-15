module Emque
  module Consuming
    class Status
      include Emque::Consuming::Helpers

      def to_hsh
        {
          :app => config.app_name,
          :workers => {}.tap { |worker_stats|
            app.manager.workers.each { |topic, workers|
              worker_stats[topic] = {
                :count => workers.size
              }
            }
          }
        }
      end
      alias :to_h :to_hsh
    end
  end
end
