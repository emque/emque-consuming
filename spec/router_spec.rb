require "spec_helper"
require "emque/consuming/consumer"
require "emque/consuming/consumer/common"

describe Emque::Consuming::Router do
  describe "#topic" do
    it "uses strings as mapping keys" do
      router = Emque::Consuming::Router.new
      mappings = router.topic("events" => "EventsConsumer") do
        map "events.new" => "new_event"
      end
    end
  end
end
