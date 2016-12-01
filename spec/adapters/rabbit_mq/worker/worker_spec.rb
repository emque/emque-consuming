require "spec_helper"
require "emque/consuming/adapters/rabbit_mq/worker"
require "pry"

describe Emque::Consuming::Adapters::RabbitMq::Worker do
  describe "#initialize" do
    Dummy::Application.config.purge_queues_on_start = false
    Dummy::Application.config.set_adapter(:rabbit_mq)
    Dummy::Application.router.map do
      topic "events" => EventsConsumer do
        map "events.new" => "new_event"
      end
    end

    app = Dummy::Application.new
    connection = Bunny.new
    connection.start
    manager = Dummy::Application.config.adapter.manager.new
    app.start

    # expect(queue.message_count).to be eq(10)

    # app.manager.workers.first.last.first.send(:queue).publish("tsting", :routing_key => "events")
    # app.manager.workers.first.last.first.send(:channel).default_exchange.publish("test")
    # app.manager.workers.first.last.first.send(:queue).message_count
  end
end
