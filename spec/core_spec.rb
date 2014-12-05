require "spec_helper"

describe Emque::Consuming::Core do
  class CoreContainer
    extend Emque::Consuming::Core
  end

  describe ".extended" do
    it "adds a .root accessor" do
      expect(CoreContainer).to respond_to(:root)
      expect(CoreContainer).to respond_to(:root=)
    end

    it "adds a .topic_mapping accessor" do
      expect(CoreContainer).to respond_to(:topic_mapping)
      expect(CoreContainer).to respond_to(:topic_mapping=)
    end

    it "adds a .router accessor" do
      expect(CoreContainer).to respond_to(:router)
      expect(CoreContainer).to respond_to(:router=)
    end

    it "adds an .instance accessor" do
      expect(CoreContainer).to respond_to(:instance)
      expect(CoreContainer).to respond_to(:instance=)
    end

    it "adds an alias, configure, for instance_exec" do
      expect(CoreContainer).to respond_to(:configure)
    end
  end

  describe ".config" do
    describe "when @config is not set" do
      it "initializes a new Emque::Consuming::Configuration object" do
        expect(Emque::Consuming::Configuration).to receive(:new)
        CoreContainer.config
      end

      it "assigns the new configuration to @config and returns it" do
        config = double(:config)
        expect(Emque::Consuming::Configuration).to receive(:new)
          .and_return(config)

        expect(CoreContainer.config).to eq(config)
        expect(CoreContainer.instance_variable_get(:@config)).to eq(config)

        CoreContainer.instance_variable_set(:@config, nil)
      end
    end

    describe "when @config is set" do
      it "returns the value of @config and does not initialize a new object" do
        config = double(:config)
        klass = Class.new(Object) do
          @config = config
          extend Emque::Consuming::Core
        end

        expect(Emque::Consuming::Configuration).to_not receive(:new)
        expect(klass.config).to eq(config)
      end
    end
  end

  describe ".emque_env" do
    it "returns the value of config.env_var if it is set" do
      CoreContainer.config.env = "some_env_name"

      expect(CoreContainer.emque_env).to eq("some_env_name")

      CoreContainer.instance_variable_set(:@config, nil)
    end

    describe "when config.emque_env is not set" do
      it "returns the ENV value, EMQUE_ENV, if it's set" do
        CoreContainer.config.env = nil
        old_emque_env_val = ENV["EMQUE_ENV"]
        ENV["EMQUE_ENV"] = "some_other_env_name"

        expect(CoreContainer.emque_env).to eq(ENV["EMQUE_ENV"])

        ENV["EMQUE_ENV"] = old_emque_env_val
        CoreContainer.instance_variable_set(:@config, nil)
      end

      describe "and the ENV value EMQUE_ENV is not set" do
        it "returns the ENV value, RACK_ENV, if it's set" do
          CoreContainer.config.env = nil
          old_emque_env_val = ENV["EMQUE_ENV"]
          ENV["EMQUE_ENV"] = nil
          old_rack_env_val = ENV["RACK_ENV"]
          ENV["RACK_ENV"] = "yet_another_env_name"

          expect(CoreContainer.emque_env).to eq(ENV["RACK_ENV"])

          ENV["EMQUE_ENV"] = old_emque_env_val
          ENV["RACK_ENV"] = old_rack_env_val
          CoreContainer.instance_variable_set(:@config, nil)
        end

        describe "and the ENV value RACK_ENV is not set" do
          it "defaults to development" do
            CoreContainer.config.env = nil
            old_emque_env_val = ENV["EMQUE_ENV"]
            ENV["EMQUE_ENV"] = nil
            old_rack_env_val = ENV["RACK_ENV"]
            ENV["RACK_ENV"] = nil

            expect(CoreContainer.emque_env).to eq("development")

            ENV["EMQUE_ENV"] = old_emque_env_val
            ENV["RACK_ENV"] = old_rack_env_val
            CoreContainer.instance_variable_set(:@config, nil)
          end
        end
      end
    end
  end
end
