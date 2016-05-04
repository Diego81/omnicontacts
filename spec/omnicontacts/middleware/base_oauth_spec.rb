require "spec_helper"
require "omnicontacts"
require "omnicontacts/middleware/base_oauth"

describe OmniContacts::Middleware::BaseOAuth do
  
  before(:all) do 
    class TestProvider < OmniContacts::Middleware::BaseOAuth
      def initialize app, consumer_key, consumer_secret, options = {}
        super app, options
      end
      
      def redirect_path
        "#{ MOUNT_PATH }testprovider/callback"
      end

      def self.mock_session
        @mock_session ||= {}
      end

      def session
        TestProvider.mock_session
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
    get "#{ MOUNT_PATH }testprovider"
    get "#{ MOUNT_PATH }testprovider/callback"
    last_request.env["omnicontacts.contacts"].first[:email].should eq("user@example.com")
  end

  it "should redirect to failure url" do
    OmniContacts.integration_test.mock(:testprovider, "some_error" )
    get "#{ MOUNT_PATH }testprovider"
    get "#{MOUNT_PATH }testprovider/callback"
    last_response.should be_redirect
    last_response.headers["location"].should eq("#{ MOUNT_PATH }failure?error_message=internal_error&importer=testprovider")
  end
  
  it "should pass through state query params to the failure url" do
    OmniContacts.integration_test.mock(:testprovider, "some_error" )
    get "#{MOUNT_PATH }testprovider/callback?state=/parent/resource/id"
    last_response.headers["location"].should eq("#{ MOUNT_PATH }failure?error_message=internal_error&importer=testprovider&state=/parent/resource/id")
  end

  it "should store request params in session" do
    OmniContacts.integration_test.mock(:testprovider, :email => "user@example.com")
    get "#{ MOUNT_PATH }testprovider?foo=bar"
    app.session['omnicontacts.params'].should eq({'foo' => 'bar'})
  end

  it "should pass the params from session to callback environment " do
    OmniContacts.integration_test.mock(:testprovider, :email => "user@example.com")
    app.session.merge!({'omnicontacts.params' => {'foo' => 'bar'}})
    get "#{MOUNT_PATH }testprovider/callback?state=/parent/resource/id"
    last_request.env["omnicontacts.params"].should eq({'foo' => 'bar'})
  end

  it "should pass the params from session on failure" do
    OmniContacts.integration_test.mock(:testprovider, "some_error" )
    get "#{ MOUNT_PATH }testprovider"
    app.session.merge!({'omnicontacts.params' => {'foo' => 'bar'}})
    get "#{MOUNT_PATH }testprovider/callback"
    last_response.should be_redirect
    last_response.headers["location"].should be_include("foo=bar")
  end
  
  after(:all) do 
    OmniContacts.integration_test.enabled = false
    OmniContacts.integration_test.clear_mocks
  end
end
