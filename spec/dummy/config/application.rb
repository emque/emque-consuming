require "emque/consuming"
require "emque/consuming/adapters/rabbit_mq/manager"

ENV["EMQUE_ENV"] = "test"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        def self.default_options; {}; end
        def self.load; end
        def self.manager
          Emque::Consuming::Adapters::RabbitMq::Manager
        end
      end
      module TestAdapter
        def self.default_options; {}; end
        def self.load; end
        def self.manager
          Emque::Consuming::Adapters::TestAdapter::Manager
        end

        class Manager
          def async; self; end
          def start; end
          def stop; end
          def worker(topic:, command:); end
          def workers(flatten: false); end
          def retry_errors; end
        end
      end
    end
  end
end

module Dummy
  class Application
    include Emque::Consuming::Application

    self.root = File.expand_path("../..", __FILE__)

    initialize_core!

    config.set_adapter(:test_adapter)
  end
end
