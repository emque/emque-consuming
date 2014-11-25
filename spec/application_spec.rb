require "spec_helper"

describe Emque::Consuming::Application do
  describe "#notice_error" do
    it "does not trigger a shutdown if the limit has not been reached" do
      Dummy::Application.config.error_limit = 2
      app = Dummy::Application.new
      Emque::Consuming::Runner.instance = double(:runner)

      expect(Emque::Consuming::Runner.instance).to_not receive(:stop)

      app.notice_error({ :test => "failure" })
    end

    it "triggers a shutdown one the error_limit is reached" do
      Dummy::Application.config.error_limit = 2
      app = Dummy::Application.new
      Emque::Consuming::Runner.instance =
        double(:runner, :status => double(:status, :to_h => {}))

      expect(Emque::Consuming::Runner.instance)
        .to receive(:stop).exactly(1).times

      app.notice_error({ :test => "failure" })
      app.notice_error({ :test => "another failure" })
    end
  end
end
