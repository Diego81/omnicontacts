require "simplecov"
SimpleCov.start do
  add_filter "spec/"
end

require "rspec"
require "rack/test"
RSpec.configure do |config|
  config.include Rack::Test::Methods
end

MOUNT_PATH = "/contacts/"
