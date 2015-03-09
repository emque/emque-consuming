$TESTING = true
require "simplecov"
require "coveralls"

SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter "vendor"
end

require "timecop"
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

Timecop.safe_mode = true

RSpec.configure do |config|
  config.order = "random"
  config.include VerifyAndResetHelpers

  config.after(:each) do
    FileUtils.remove_dir("dummy/tmp", true)
  end

  config.around do |example|
    original_stdout = $stdout
    $stdout = StringIO.new
    example.run
    $stdout = original_stdout
  end
end
