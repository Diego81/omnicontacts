require "simplecov"
SimpleCov.start

require "rspec"
require "rack/test"
RSpec.configure do |config|
  config.include Rack::Test::Methods
end
