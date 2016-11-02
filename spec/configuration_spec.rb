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

  describe "delayed_message_workers" do
    it "has a default" do
      config = Emque::Consuming::Configuration.new
      expect(config.delayed_message_workers).to eq(1)
    end

    it "prefers the assigned value" do
      config = Emque::Consuming::Configuration.new
      config.delayed_message_workers = 2
      expect(config.delayed_message_workers).to eq(2)
    end
  end

  describe "retryable_errors" do
    it "has a default" do
      config = Emque::Consuming::Configuration.new
      expect(config.retryable_errors).to eq([])
    end

    it "prefers the assigned value" do
      config = Emque::Consuming::Configuration.new
      config.retryable_errors = ["TestError"]
      expect(config.retryable_errors).to eq(["TestError"])
    end
  end

  describe "retryable_error_limit" do
    it "has a default" do
      config = Emque::Consuming::Configuration.new
      expect(config.retryable_error_limit).to eq(3)
    end

    it "prefers the assigned value" do
      config = Emque::Consuming::Configuration.new
      config.retryable_error_limit = 4
      expect(config.retryable_error_limit).to eq(4)
    end
  end

  describe "purge_queues_on_start" do
    it "has a default" do
      config = Emque::Consuming::Configuration.new
      expect(config.purge_queues_on_start).to eq(false)
    end

    it "prefers the assigned value" do
      config = Emque::Consuming::Configuration.new
      config.purge_queues_on_start = true
      expect(config.purge_queues_on_start).to eq(true)
    end
  end

  describe "#to_hsh" do
    it "returns a hash" do
      config = Emque::Consuming::Configuration.new
      expect(config.to_hsh).to be_a Hash
    end

    it "returns the value of all the accessors" do
      accessors = [
        :app_name, :adapter, :auto_shutdown, :delayed_message_workers,
        :env, :enable_delayed_message, :error_handlers, :error_limit,
        :error_expiration, :purge_queues_on_start, :log_level,
        :retryable_errors, :retryable_error_limit, :status_port, :status_host,
        :status, :socket_path, :shutdown_handlers
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
