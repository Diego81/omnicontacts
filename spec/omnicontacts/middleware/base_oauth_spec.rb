require "spec_helper"
require "omnicontacts/middleware/base_oauth"

describe OmniContacts::Middleware::BaseOAuth do
  
  before(:all) do 
    class TestProvider < OmniContacts::Middleware::BaseOAuth
      def initialize app, consumer_key, consumer_secret, options = {}
        super app, options
      end
      
      def redirect_path
        "/contacts/testprovider/callback"
      end
    end
    OmniContacts.integration_test.enabled = true
  end

  let(:app) {
    Rack::Builder.new do |b|
      b.use TestProvider, "consumer_id", "consumer_secret"
      b.run lambda { |env| [200, {"Content-Type" => "text/html"}, ["Hello World"]] }
    end.to_app
  }
  
  it "should return a preconfigured list of contacts" do
    OmniContacts.integration_test.mock(:testprovider, :email => "user@example.com")
    get "/contacts/testprovider"    
    get "/contacts/testprovider/callback"    
    last_request.env["omnicontacts.contacts"].first[:email].should eq("user@example.com")
  end

  it "should redurect to failure url" do
    OmniContacts.integration_test.mock(:testprovider, "some_error" )
    get "/contacts/testprovider"
    get "/contacts/testprovider/callback"
    last_response.should be_redirect
    last_response.headers["location"].should eq("/contacts/failure?error_message=internal_error")
  end
  
  after(:all) do 
    OmniContacts.integration_test.enabled = false
    OmniContacts.integration_test.clear_mocks
  end
  
end