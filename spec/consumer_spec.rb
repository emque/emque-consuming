require "spec_helper"
require "emque/consuming/consumer"
require "emque/consuming/consumer/common"

class MyConsumer
  include Emque::Consuming.consumer

  def my_event(message)
    pipe(message, :through => [
      :keep_pipe_going, :another_method
    ])
  end

  def my_stop_event(message)
    pipe(message, :through => [
      :stop_pipe, :another_method
    ])
  end

  private

  def stop_pipe(message)
    nil
  end

  def keep_pipe_going(message)
    message
  end

  def another_method(message)
    message
  end

end

describe Emque::Consuming::Consumer do
  describe "#pipe" do
    context "when continuing pipe" do
      it "calls all methods in the pipe chain" do
        consumer = MyConsumer.new
        expect(consumer).to receive(:another_method)
        consumer.my_event "mymessage"
      end
    end

    context "when stopping pipe" do
      it "stops after stop method" do
        consumer = MyConsumer.new
        expect(consumer).not_to receive(:another_method)
        consumer.my_stop_event "mymessage"
      end
    end
  end
end
