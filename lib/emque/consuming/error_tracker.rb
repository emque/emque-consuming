require "digest"
require "set"

module Emque
  module Consuming
    class ErrorTracker
      attr_reader :limit

      def initialize(limit: 5)
        self.limit = limit
        self.by_context = Set.new
      end

      def notice_error_for(context)
        by_context.add(key_for(context))
      end

      def limit_reached?
        by_context.count >= limit
      end

      private

      attr_accessor :by_context
      attr_writer :limit

      def key_for(context)
        Digest::SHA256.hexdigest(context.to_s)
      end
    end
  end
end
