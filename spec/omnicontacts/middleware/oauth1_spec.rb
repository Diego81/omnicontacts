require "spec_helper"
require "omnicontacts/middleware/oauth1"

describe OmniContacts::Middleware::OAuth1 do

  before(:all) do
    class OAuth1Middleware < OmniContacts::Middleware::OAuth1
      def request_token
        ["auth_token", "auth_token_secret"]
      end

      def authorization_url auth_token
        "http://www.example.com"
      end

      def callback_path
        "/callback_path"
      end

      def fetch_contacts_from_token_and_verifier oauth_token, ouath_token_secret, oauth_verifier
        [{:name => "John Doe", :email => "john@example.com"}]
      end
    end
  end

  let(:app) {
    @token_persistence_class = Class.new
    Rack::Builder.new do |b|
      b.use OAuth1Middleware, "consumer_id", "consumer_secret", @token_persistence_class
      b.run lambda{ |env| [200, {"Content-Type" => "text/html"}, ["Hello World"]] }
    end.to_app
  }

  describe "visiting the listening path" do
    it "should save the authorization token and redirect to the authorization url" do
      allow_message_expectations_on_nil #for some reason I get warnings during test even tough @token_persistence_class is not nil
      persistent_token = double
      @token_persistence_class.should_receive(:new).and_return(persistent_token)
      persistent_token.should_receive(:oauth_token=).with("auth_token")
      persistent_token.should_receive(:oauth_token_secret=).with("auth_token_secret")
      persistent_token.should_receive(:save).and_return(true)
      get "/contacts/oauth1middleware"
      last_response.should be_redirect
      last_response.headers['location'].should eq("http://www.example.com")
    end
  end

  describe "visiting the callback url after authorization" do
    it "should return the list of contacts" do
      allow_message_expectations_on_nil
      persisted_token = double
      @token_persistence_class.should_receive(:find_by_oauth_token).and_return(persisted_token)
      persisted_token.should_receive(:oauth_token).and_return("oauth_token")
      persisted_token.should_receive(:oauth_token_secret).and_return("oauth_token_secret")
      get "/callback_path?oauth_token=token&oauth_verifier=verifier"
      last_response.should be_ok
      last_request.env["omnicontacts.contacts"].size.should be(1)
    end
  end
end
