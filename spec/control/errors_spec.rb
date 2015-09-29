require "spec_helper"
require "ostruct"

describe Emque::Consuming::Control::Errors do
  describe "#clear" do
    it "resets the error_tracker's occurances hash" do
      control = Emque::Consuming::Control::Errors.new
      config = Emque::Consuming::Configuration.new
      error_tracker = Emque::Consuming::ErrorTracker.new
      app = OpenStruct.new
      app.error_tracker = error_tracker
      application = OpenStruct.new
      application.config = config
      application.instance = app
      expect(Emque::Consuming).to receive(:application)
        .at_least(1).times
        .and_return(application)

      error_tracker.occurrences = {
        :one => 1,
        :two => 2
      }
      control.clear
      expect(error_tracker.occurrences).to eq({})
    end
  end

  describe "#down" do
    describe "when error_tracker limit is greater than 1" do
      it "lowers the limit by 1" do
        control = Emque::Consuming::Control::Errors.new
        config = Emque::Consuming::Configuration.new
        error_tracker = Emque::Consuming::ErrorTracker.new(:limit => 2)
        app = OpenStruct.new
        app.error_tracker = error_tracker
        application = OpenStruct.new
        application.config = config
        application.instance = app
        expect(Emque::Consuming).to receive(:application)
          .at_least(1).times
          .and_return(application)

        expect { control.down }.to change { error_tracker.limit }.to(1)
      end

      it "changes the config error_limit to the same value" do
        control = Emque::Consuming::Control::Errors.new
        config = Emque::Consuming::Configuration.new
        error_tracker = Emque::Consuming::ErrorTracker.new(:limit => 2)
        app = OpenStruct.new
        app.error_tracker = error_tracker
        application = OpenStruct.new
        application.config = config
        application.instance = app
        expect(Emque::Consuming).to receive(:application)
          .at_least(1).times
          .and_return(application)

        expect { control.down }.to change { config.error_limit }.to(1)
      end
    end

    describe "when error_tracker limit is 1" do
      it "does not change the limit" do
        control = Emque::Consuming::Control::Errors.new
        config = Emque::Consuming::Configuration.new
        error_tracker = Emque::Consuming::ErrorTracker.new(:limit => 1)
        app = OpenStruct.new
        app.error_tracker = error_tracker
        application = OpenStruct.new
        application.config = config
        application.instance = app
        expect(Emque::Consuming).to receive(:application)
          .at_least(1).times
          .and_return(application)

        expect { control.down }.to_not change { error_tracker.limit }
      end
    end
  end

  describe "#expire_after" do
    describe "when passed an integer" do
      it "changes the error_tracker expiration value to the value passed" do
        control = Emque::Consuming::Control::Errors.new
        config = Emque::Consuming::Configuration.new
        error_tracker = Emque::Consuming::ErrorTracker.new
        app = OpenStruct.new
        app.error_tracker = error_tracker
        application = OpenStruct.new
        application.config = config
        application.instance = app
        expect(Emque::Consuming).to receive(:application)
          .at_least(1).times
          .and_return(application)

        expect { control.expire_after(1000) }.to change {
          error_tracker.expiration
        }.to(1000)
      end

      it "changes the config error_expiration value to the value passed" do
        control = Emque::Consuming::Control::Errors.new
        config = Emque::Consuming::Configuration.new
        error_tracker = Emque::Consuming::ErrorTracker.new
        app = OpenStruct.new
        app.error_tracker = error_tracker
        application = OpenStruct.new
        application.config = config
        application.instance = app
        expect(Emque::Consuming).to receive(:application)
          .at_least(1).times
          .and_return(application)

        expect { control.expire_after(1000) }.to change {
          config.error_expiration
        }.to(1000)
      end
    end

    describe "when passed something other than an integer" do
      it "raises an argument error" do
        control = Emque::Consuming::Control::Errors.new
        expect { control.expire_after(:invalid) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#up" do
    it "increases the error_tracker limit by 1" do
      control = Emque::Consuming::Control::Errors.new
      config = Emque::Consuming::Configuration.new
      error_tracker = Emque::Consuming::ErrorTracker.new(:limit => 1)
      app = OpenStruct.new
      app.error_tracker = error_tracker
      application = OpenStruct.new
      application.config = config
      application.instance = app
      expect(Emque::Consuming).to receive(:application)
        .at_least(1).times
        .and_return(application)

      expect { control.up }.to change { error_tracker.limit }.to(2)
    end

    it "changes the config error_limit to the same value" do
      control = Emque::Consuming::Control::Errors.new
      config = Emque::Consuming::Configuration.new
      error_tracker = Emque::Consuming::ErrorTracker.new(:limit => 1)
      app = OpenStruct.new
      app.error_tracker = error_tracker
      application = OpenStruct.new
      application.config = config
      application.instance = app
      expect(Emque::Consuming).to receive(:application)
        .at_least(1).times
        .and_return(application)

      expect { control.up }.to change { config.error_limit }.to(2)
    end
  end

  describe "#retry" do
    it "starts the retry worker" do
      control = Emque::Consuming::Control::Errors.new
      config = Emque::Consuming::Configuration.new
      control.retry
    end
  end
end
