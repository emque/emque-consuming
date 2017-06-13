require "spec_helper"
require "emque/consuming/adapters/rabbit_mq/worker"
require "pry"

module Emque
  module Consuming
    module Adapters
      module RabbitMq
        class Worker
          def start
            logger.info "#{log_prefix} starting..."
            logger.info "RabbitMQ Worker: Skipping consuming during test."
            logger.debug "#{log_prefix} started"
          end
        end
      end
    end
  end
end

describe Emque::Consuming::Adapters::RabbitMq::Worker do
  describe "#initialize" do
    before do
      @connection = Bunny.new
      @connection.start
      @channel = @connection.create_channel
      @channel.queue_delete("emque.dummy.spec")
      @fanout = @channel.fanout("dummy.spec",
        :durable => true,
        :auto_delete => false
      )
      @queue = @channel
        .queue("emque.dummy.spec", {
          :durable => true,
          :auto_delete => false,
          :arguments => {
            "x-dead-letter-exchange" => "dummy.error"
          }
        }).bind(@fanout)
      @queue.publish(Oj.dump({
        :metadata => {
          :topic => "spec",
          :type => "dummy.spec"
        }
      }))
    end

    after do
      @channel.queue_delete("emque.dummy.spec")
      @connection.close
    end

    it "should not purge queues on start" do
      Dummy::Application.config.purge_queues_on_start = false
      Dummy::Application.config.set_adapter(:rabbit_mq)
      Dummy::Application.router.map do
        topic "spec" => SpecConsumer do; end
      end
      app = Dummy::Application.new
      connection = Bunny.new
      connection.start
      connection.with_channel do |channel|
        @queue = channel.queue("emque.dummy.spec", :passive => true)
        expect(@queue.message_count).to eq(1)
      end
      app.start
      sleep 0.3
      connection.with_channel do |channel|
        @queue = channel.queue("emque.dummy.spec", :passive => true)
        expect(@queue.message_count).to eq(1)
      end
    end

    it "should purge queues on start" do
      Dummy::Application.config.purge_queues_on_start = true
      Dummy::Application.config.set_adapter(:rabbit_mq)
      Dummy::Application.router.map do
       topic "spec" => SpecConsumer do; end
      end
      app = Dummy::Application.new
      connection = Bunny.new
      connection.start
      connection.with_channel do |channel|
        @queue = channel.queue("emque.dummy.spec", :passive => true)
        expect(@queue.message_count).to eq(1)
      end
      app.start
      sleep 0.3
      connection.with_channel do |channel|
        @queue = channel.queue("emque.dummy.spec", :passive => true)
        expect(@queue.message_count).to eq(0)
      end
    end
  end
end
