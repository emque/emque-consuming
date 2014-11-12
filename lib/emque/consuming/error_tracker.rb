require "digest"

module Emque
  module Consuming
    class ErrorTracker
      attr_accessor :occurrences, :limit, :expiration

      def initialize(limit: 5, expiration: 3600)
        self.limit = limit
        self.expiration = expiration
        self.occurrences = {}
      end

      def notice_error_for(context)
        occurrences[key_for(context)] = Time.now + expiration
      end

      def limit_reached?
        count >= limit
      end

      def count
        recent_errors.keys.count
      end

      private

      def recent_errors
        occurrences.delete_if do |key, expiration_time|
          expiration_time < Time.now
        end
      end

      def key_for(context)
        Digest::SHA256.hexdigest(context.to_s)
      end
    end
  end
end
