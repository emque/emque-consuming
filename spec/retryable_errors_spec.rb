require "spec_helper"
require "emque/consuming/retryable_errors"
require "pry"

describe Emque::Consuming::RetryableErrors do
  it "exponentially backs off the delay" do
    retry1 = Emque::Consuming::RetryableErrors.delay_ms_time(1)
    retry2 = Emque::Consuming::RetryableErrors.delay_ms_time(2)
    retry3 = Emque::Consuming::RetryableErrors.delay_ms_time(3)

    expect(retry1).to be > 500
    expect(retry2).to be > retry1
    expect(retry3).to be > retry2
  end

  it "retries errors" do
    # todo

  end
end
