require "spec_helper"

describe Emque::Consuming::Cli do
  describe "starting a console" do
    it "passes to console command to a new runner instance" do
      runner = double(:runner, :send => true)

      expect(Emque::Consuming::Runner).to receive(:new).and_return(runner)
      expect(runner).to receive(:send).with(:console)

      Emque::Consuming::Cli.new(["console"])
    end
  end

  describe "starting an instance" do
    it "passes the start command to a new runner instance" do
      runner = double(:runner, :send => true)

      expect(Emque::Consuming::Runner).to receive(:new).and_return(runner)
      expect(runner).to receive(:send).with(:start)

      Emque::Consuming::Cli.new(["start"])
    end

    it "passes valid arguments along to the new runner" do
      command = ["start"]
      valid_args = [
        "-P", "tmp/pidfile.pid",
        "-d",
        "-S", "tmp/socket.sock",
        "-e", "20",
        "-x", "1000",
        "--app-name", "testing",
        "--env", "test"
      ]
      expected_options = {
        :pidfile => "tmp/pidfile.pid",
        :socket_path => "tmp/socket.sock",
        :error_limit => 20,
        :error_expiration => 1000,
        :app_name => "testing",
        :env => "test"
      }
      argv = valid_args + command
      runner = double(:runner, :send => true)

      expect(Emque::Consuming::Runner).to receive(:new)
        .with(expected_options)
        .and_return(runner)

      Emque::Consuming::Cli.new(argv)
    end

    describe "with no options" do
      it "passes the default options to the runner" do
        expected_options = {
        }
        runner = double(:runner, :send => true)

        expect(Emque::Consuming::Runner).to receive(:new)
          .with(expected_options)
          .and_return(runner)

        Emque::Consuming::Cli.new(["start"])
      end
    end
  end

  describe "stopping an instance" do
    it "passes the stop command to a new runner instance" do
      runner = double(:runner, :send => true)

      expect(Emque::Consuming::Runner).to receive(:new).and_return(runner)
      expect(runner).to receive(:send).with(:stop)

      Emque::Consuming::Cli.new(["stop"])
    end
  end

  describe "creating a new application" do
    it "passes the new command to a new application generator instance" do
      generator = double(:generator, :generate => true)

      expect(Emque::Consuming::Generators::Application).to receive(:new)
        .and_return(generator)
      expect(generator).to receive(:generate)

      Emque::Consuming::Cli.new(["new", "testapplication"])
    end

    it "passes valid arguments along to the new application generator" do
      application_name = "testapplication"
      command = ["new", application_name]
      valid_args = [
        "-P", "tmp/pidfile.pid",
        "-S", "tmp/socket.sock",
        "-e", "20",
        "-x", "1000",
        "--app-name", "testing",
        "--env", "test"
      ]
      expected_options = {
        :pidfile => "tmp/pidfile.pid",
        :socket_path => "tmp/socket.sock",
        :error_limit => 20,
        :error_expiration => 1000,
        :app_name => "testing",
        :env => "test"
      }
      argv = valid_args + command
      generator = double(:generator, :generate => true)

      expect(Emque::Consuming::Generators::Application).to receive(:new)
        .with(expected_options, application_name)
        .and_return(generator)

      Emque::Consuming::Cli.new(argv)
    end

    it "exits if no application name is passed" do
      expect { Emque::Consuming::Cli.new(["new"]) }.to raise_error(SystemExit)
    end
  end

  it "exits if an invalid command is passed" do
    expect { Emque::Consuming::Cli.new(["invalid"]) }.to raise_error(SystemExit)
  end

  it "exits if help is passed as a command" do
    expect { Emque::Consuming::Cli.new(["help"]) }.to raise_error(SystemExit)
  end
end
