require "spec_helper"
require "emque/consuming/retryable_errors"

describe Emque::Consuming::RetryableErrors do
  describe "retryable errors" do
    it "exponentially backs off the delay time" do
      test_class = Class.new { include Emque::Consuming::RetryableErrors }
      test = test_class.new
      retry1 = test.delay_ms_time(1)
      retry2 = test.delay_ms_time(2)
      retry3 = test.delay_ms_time(3)

      expect(retry1).to eq(1000)
      expect(retry2).to eq(4000)
      expect(retry3).to eq(12000)
    end
  end
end
