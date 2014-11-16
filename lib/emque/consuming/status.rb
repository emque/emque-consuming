module Emque
  module Consuming
    class Status
      include Emque::Consuming::Helpers

      def to_hsh
        {
          :app => config.app_name,
          :errors => {
            :count => app.error_tracker.count,
            :expire_after => app.error_tracker.expiration,
            :limit => app.error_tracker.limit
          },
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
