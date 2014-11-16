module Emque
  module Consuming
    module Actor
      def self.included(descendant)
        descendant.class_eval do
          include Celluloid
          include Emque::Consuming::Helpers
          attr_accessor :shutdown
          private :shutdown=
          private :shutdown
        end
      end

      def stop(&block)
        self.shutdown = true
        block.call if block_given?
        terminate
      end
    end
  end
end
