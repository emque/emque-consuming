module Emque
  module Consuming
    class Worker
      include Emque::Consuming::Actor

      def initialize(topic)
        self.topic = topic
        self.fetcher = Emque::Consuming::Fetcher.new_link(current_actor, topic)
        self.work_queues = {}
        self.name = "#{self.topic.capitalize} worker"
        self.shutdown = false
      end

      def start
        work
      end

      def stop
        logger.info "#{name} stopping..."

        self.shutdown = true
        fetcher.stop

        logger.info "#{name} stopped"
      end

      def receive_work(partition, messages)
        if messages.size > 0
          logger.info "Worker received #{messages.count} " +
                      "messages on partition #{partition}"

          work_queues[partition] ||= []
          work_queues[partition] += messages
        end

        after(1) { work }
      end

      private

      attr_accessor :name, :consumer_klass, :fetcher, :shutdown, :work_queues

      def fetch_work
        partition, queue = next_job

        if queue
          if fetcher.has_partition?(partition)
            return { :partition => partition, :message => queue.pop }
          else
            work_queues.delete(partition)
            fetch_work
          end
        else
          :not_found
        end
      end

      def next_job
        work_queues.find { |key, value| !value.empty? }
      end

      def work
        unless shutdown
          job = fetch_work

          if job.is_a?(Hash)
            logger.info "#{name} processing message #{job[:message].value} " +
                        "from partition #{job[:partition]}"

            fetcher.async.commit(job[:partition], job[:message].offset)

            message = Emque::Consuming::Message.new(
              :offset => job[:message].offset,
              :original => job[:message].value,
              :partition => job[:partition],
              :topic => job[:message].topic.to_sym
            )

            ::Emque::Comsuming::Consumer.new.consume(:process, message)

            after(0) { work }
          else
            fetcher.async.fetch
          end
        end
      end
    end
  end
end
