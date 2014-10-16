require "spec_helper"
require "emque/consuming/error_tracker"

describe Emque::Consuming::ErrorTracker do
  describe "#limit_reached?" do
    it "is false initially" do
      tracker = Emque::Consuming::ErrorTracker.new

      expect(tracker.limit_reached?).to eq(false)
    end

    it "is true once n(limit) unique values are noticed" do
      tracker = Emque::Consuming::ErrorTracker.new(:limit => 2)

      tracker.notice_error_for({ :first => 'value' })
      expect(tracker.limit_reached?).to eq(false)

      tracker.notice_error_for({ :first => 'value' })
      expect(tracker.limit_reached?).to eq(false)

      tracker.notice_error_for({ :second => 'value' })
      expect(tracker.limit_reached?).to eq(true)

      tracker.notice_error_for({ :third => 'value' })
      expect(tracker.limit_reached?).to eq(true)
    end
  end
end
