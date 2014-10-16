require "spec_helper"
require "emque/consuming/application"

class MockManager
  def initialize(*args); end
  def async; self; end
  def start; end
  def stop; end
end

module Emque
  module Consuming
    module Adapter
      module Test
        def self.load
          # nothing to see here
        end

        def self.manager
          MockManager
        end
      end
    end
  end
end

class MockApp < Emque::Consuming::Application
  DOMAIN = "example.com"
  PROTOCOL = "http"

  config.consuming_adapter = :test

  self.root = File.expand_path("../dummy/", __FILE__)
end

describe Emque::Consuming::Application do
  describe "#notice_error" do
    it "does not trigger a shutdown if the limit has not been reached" do
      MockApp.config.error_limit = 2
      app = MockApp.new

      expect(app).to_not receive(:shutdown)

      app.notice_error({ :test => 'failure' })
    end

    it "triggers a shutdown one the error_limit is reached" do
      MockApp.config.error_limit = 2
      app = MockApp.new

      expect(app).to receive(:shutdown).exactly(1).times

      app.notice_error({ :test => 'failure' })
      app.notice_error({ :test => 'another failure' })
    end
  end
end
