require "spec_helper"

describe Emque::Consuming::Control do
  describe "#initialize" do
    it "creates a new errors control object" do
      expect(Emque::Consuming::Control::Errors).to receive(:new)
      Emque::Consuming::Control.new
    end

    it "creates a new workers control object" do
      expect(Emque::Consuming::Control::Workers).to receive(:new)
      Emque::Consuming::Control.new
    end
  end
end
