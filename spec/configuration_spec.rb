require "spec_helper"

describe Emque::Consuming::Configuration do
  describe "#log_level" do
    it "defaults to Logger::INFO" do
      config = Emque::Consuming::Configuration.new
      expect(config.log_level).to eq(Logger::INFO)
    end

    it "prefers the assigned value to the default" do
      config = Emque::Consuming::Configuration.new
      config.log_level = Logger::DEBUG
      expect(config.log_level).to eq(Logger::DEBUG)
    end
  end

  describe "#max_workers" do
    it "includes a reasonable, if arbitrary, default limit" do
      config = Emque::Consuming::Configuration.new

      expect(config.max_workers.fetch(:limit)).to eq 10
    end

    it "includes a generic, though still helpful, default message" do
      config = Emque::Consuming::Configuration.new

      expect(config.max_workers.fetch(:error_message)).to eq "Max workers reached."
    end
  end

  describe "#to_hsh" do
    it "returns a hash" do
      config = Emque::Consuming::Configuration.new
      expect(config.to_hsh).to be_a Hash
    end

    it "returns the value of all the accessors" do
      accessors = [
        :app_name, :adapter, :env, :error_handlers, :error_limit,
        :error_expiration, :log_level, :max_workers, :status_port,
        :status_host, :status, :socket_path, :shutdown_handlers
      ]
      config = Emque::Consuming::Configuration.new

      hsh = config.to_hsh

      expect(hsh.keys).to eq(accessors)
      accessors.each do |key|
        expect(hsh.fetch(key)).to eq(config.send(key))
      end
    end
  end

  describe "#to_h" do
    it "is an alias of to_hsh" do
      config = Emque::Consuming::Configuration.new

      expect(config.to_h).to eq(config.to_hsh)
    end
  end
end
