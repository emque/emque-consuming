module Emque
  module Consuming
    class Configuration
      attr_accessor :app_name
      attr_accessor :seed_brokers
      attr_accessor :zookeepers
      attr_accessor :error_handlers

      def initialize
        @app_name = ""
        @seed_brokers = ["localhost:9092"]
        @zookeepers = ["localhost:2181"]
        @error_handlers = []
      end
    end
  end
end
