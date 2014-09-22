require "celluloid"

module Emque
  module Consuming
    module Actor
      def self.included(klass)
        klass.send(:include, Celluloid)
      end

      def logger
        Emque::Consuming.logger
      end
    end
  end
end
