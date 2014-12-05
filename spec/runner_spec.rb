require "spec_helper"

describe Emque::Consuming::Runner do
  describe "#initialize" do
    it "initializes a new control object" do
      expect(Emque::Consuming::Control).to receive(:new).and_return(nil)
      Emque::Consuming::Runner.new
    end

    it "initializes a new status object" do
      expect(Emque::Consuming::Status).to receive(:new).and_return(nil)
      Emque::Consuming::Runner.new
    end

    it "initializes the logger" do
      app = double(:application, :root => "/")
      expect(app).to receive(:config)
        .and_return(Emque::Consuming::Configuration.new)
      expect(Emque::Consuming).to receive(:application)
        .at_least(1).times
        .and_return(app)
      expect(app).to receive(:initialize_logger).and_return(nil)

      Emque::Consuming::Runner.new
    end

    it "stores itself on the class variable instance" do
      instance = Emque::Consuming::Runner.new
      expect(Emque::Consuming::Runner.instance).to eq(instance)
    end

    it "creates a new pidfile object" do
      expect(Emque::Consuming::Pidfile).to receive(:new).and_return(nil)
      Emque::Consuming::Runner.new
    end

    it "passes valid options to the app configuration" do
      valid_opts = {
        :app_name => "testing",
        :error_limit => 5,
        :status => :one
      }
      invalid_opts = {
        :not => :valid,
        :also => :not_valid,
        :another => 50
      }

      app = double(:application, :initialize_logger => nil, :root => "/")
      config = Emque::Consuming::Configuration.new
      expect(Emque::Consuming).to receive(:application)
        .at_least(1).times
        .and_return(app)
      expect(app).to receive(:config)
        .at_least(1).times
        .and_return(config)

      valid_opts.each do |meth, val|
        expect(config).to receive("#{meth}=").with(val)
      end

      invalid_opts.each do |meth, val|
        expect(config).to_not receive("#{meth}=")
      end

      Emque::Consuming::Runner.new(valid_opts.merge(invalid_opts))
    end
  end

  describe "#start" do
    it "exits if the specified pidfile already exists" do
      runner = Emque::Consuming::Runner.new
      expect(runner).to receive(:pid)
        .at_least(1).times
        .and_return(double(:pid, :running? => true))

      expect { runner.start }.to raise_error(SystemExit)
    end

    it "daemonizes the process if the daemon option is set" do
      runner = Emque::Consuming::Runner.new(:daemon => true)
      expect(runner).to receive(:receivers).at_least(1).times.and_return([])
      expect(runner).to receive(:persist).and_return(double(:join => true))
      expect(runner).to receive(:pid)
        .at_least(1).times
        .and_return(double(:running? => false, :write => true))

      expect(runner).to receive(:daemonize!).and_return(true)
      runner.start
    end

    it "creates a unix socket receiver and starts it" do
      runner = Emque::Consuming::Runner.new
      expect(runner).to receive(:persist).and_return(double(:join => true))
      expect(runner).to receive(:pid)
        .at_least(1).times
        .and_return(double(:running? => false, :write => true))
      socket = double(:unix_socket, :start => true)

      expect(Emque::Consuming::CommandReceivers::UnixSocket)
        .to receive(:new).and_return(socket)
      expect(socket).to receive(:start)
      runner.start
    end

    it "creates a http receiver and starts it if the status is set to :on" do
      runner = Emque::Consuming::Runner.new(:status => :on)
      expect(runner).to receive(:persist).and_return(double(:join => true))
      expect(runner).to receive(:pid)
        .at_least(1).times
        .and_return(double(:running? => false, :write => true))
      http = double(:http_server, :start => true)

      expect(Emque::Consuming::CommandReceivers::HttpServer)
        .to receive(:new).and_return(http)
      expect(http).to receive(:start)
      runner.start
    end

    it "starts the application" do
      runner = Emque::Consuming::Runner.new
      expect(runner).to receive(:persist).and_return(double(:join => true))
      expect(runner).to receive(:pid)
        .at_least(1).times
        .and_return(double(:running? => false, :write => true))
      socket = double(:unix_socket, :start => true)
      expect(Emque::Consuming::CommandReceivers::UnixSocket)
        .to receive(:new).and_return(socket)
      app = Emque::Consuming.application.new
      expect(Emque::Consuming.application).to receive(:instance)
        .at_least(1).times
        .and_return(app)

      expect(app).to receive(:start)
      runner.start
    end
  end
end
