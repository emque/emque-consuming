require "spec_helper"
require "ostruct"

describe Emque::Consuming::Control::Workers do
  describe "#down" do
    it "decreases the manager's worker count" do
      topic = :events
      control = Emque::Consuming::Control::Workers.new
      app = OpenStruct.new
      config = Emque::Consuming::Configuration.new
      app.manager = OpenStruct.new
      application = OpenStruct.new
      application.config = config
      application.instance = app

      expect(control).to receive(:app).and_return(app)
      expect(app).to receive(:manager).at_least(1).times
      expect(app.manager).to receive(:worker).with(topic: topic, command: :down)

      control.down(topic)
    end
  end

  describe "#up" do
    context "max workers is less than amount defined in application config" do
      it "instructs the manager to increase the worker count" do
        topic = :events
        control = Emque::Consuming::Control::Workers.new
        app = OpenStruct.new
        config = Emque::Consuming::Configuration.new
        app.manager = OpenStruct.new
        application = OpenStruct.new
        application.config = config
        application.instance = app

        expect(control).to receive(:app).at_least(1).times.and_return(app)
        expect(app).to receive(:manager).at_least(1).times
        expect(app.manager).to receive(:worker).with(topic: topic, command: :up)
        expect(app.manager).to receive(:worker_count).and_return(5)

        control.up(topic)
      end
    end

    context "max workers equal to amount defined in application config" do
      it "does not instruct the manager to increase the worker count" do
        topic = :events
        control = Emque::Consuming::Control::Workers.new
        app = OpenStruct.new
        config = Emque::Consuming::Configuration.new
        app.manager = OpenStruct.new
        application = OpenStruct.new
        application.config = config
        application.instance = app

        expect(control).to receive(:app).at_least(1).times.and_return(app)
        expect(app).to receive(:manager).at_least(1).times
        expect(app.manager).to receive(:worker_count).and_return(15)

        expect(app.manager).to_not receive(:worker).with(topic: topic, command: :up)

        control.up(topic)
      end
    end
  end
end
