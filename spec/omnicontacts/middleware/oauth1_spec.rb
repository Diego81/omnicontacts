require "spec_helper"
require "omnicontacts/middleware/oauth1"

describe OmniContacts::Middleware::OAuth1 do

  before(:all) do
    class OAuth1Middleware < OmniContacts::Middleware::OAuth1
      def self.mock_auth_token_resp
        @mock_auth_token_resp ||= Object.new
      end

      def fetch_authorization_token
        OAuth1Middleware.mock_auth_token_resp.body
      end

      def authorization_url auth_token
        "http://www.example.com"
      end

      def fetch_contacts_from_token_and_verifier oauth_token, ouath_token_secret, oauth_verifier
        [{:name => "John Doe", :email => "john@example.com"}]
      end

      def self.mock_session
        @mock_session ||= {}
      end

      def session
        OAuth1Middleware.mock_session
      end
    end
  end

  let(:app) {
    Rack::Builder.new do |b|
      b.use OAuth1Middleware, "consumer_id", "consumer_secret"
      b.run lambda { |env| [200, {"Content-Type" => "text/html"}, ["Hello World"]] }
    end.to_app
  }

  context "visiting the listening path" do
    it "should save the authorization token and redirect to the authorization url" do
      OAuth1Middleware.mock_auth_token_resp.should_receive(:body).and_return(["auth_token", "auth_token_secret"])
      get "/contacts/oauth1middleware"
      last_response.should be_redirect
      last_response.headers['location'].should eq("http://www.example.com")
    end

    it "should redirect to failure url if fetching the request token does not succeed" do
      OAuth1Middleware.mock_auth_token_resp.should_receive(:body).and_raise("Request failed")
      get "contacts/oauth1middleware"
      last_response.should be_redirect
      last_response.headers["location"].should eq("/contacts/failure?error_message=internal_error")
    end
  end

  context "visiting the callback url after authorization" do
    it "should return the list of contacts" do
      OAuth1Middleware.mock_session.should_receive(:[]).and_return("oauth_token_secret")
      get "/contacts/oauth1middleware/callback?oauth_token=token&oauth_verifier=verifier"
      last_response.should be_ok
      last_request.env["omnicontacts.contacts"].size.should be(1)
    end

    it "should redirect to failure url if oauth_token_secret is not found in the session" do
      OAuth1Middleware.mock_session.should_receive(:[]).and_return(nil)
      get "/contacts/oauth1middleware/callback?oauth_token=token&oauth_verifier=verifier"
      last_response.should be_redirect
      last_response.headers["location"].should eq("/contacts/failure?error_message=not_authorized")
    end
  end
end
