require "spec_helper"
require "timecop"
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

    it "takes expiration time into account" do
      current_time = Time.now
      Timecop.freeze(current_time)

      tracker = Emque::Consuming::ErrorTracker.new(
        :limit => 2, :expiration => 60
      )

      tracker.notice_error_for({ :first => 'value' })

      Timecop.travel(current_time + 61)

      tracker.notice_error_for({ :second => 'value' })
      expect(tracker.limit_reached?).to eq(false)

      tracker.notice_error_for({ :first => 'value '})
      expect(tracker.limit_reached?).to eq(true)
    end
  end
end
