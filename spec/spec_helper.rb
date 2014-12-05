$TESTING = true

require "pry"
require "fileutils"
require_relative "dummy/config/application"

module VerifyAndResetHelpers
  def verify(object)
    RSpec::Mocks.proxy_for(object).verify
  end

  def reset(object)
    RSpec::Mocks.proxy_for(object).reset
  end
end

RSpec.configure do |config|
  config.order = "random"

  config.include VerifyAndResetHelpers

  config.after(:each) do
    FileUtils.remove_dir("dummy/tmp", true)
    Timecop.return
  end
end
