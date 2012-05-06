require "spec_helper"
require "omnicontacts/authorization/oauth1"

describe OmniContacts::Authorization::OAuth1 do

  before(:all) do
    OAuth1TestClass= Struct.new(:consumer_key, :consumer_secret, :auth_host, :auth_token_path, :auth_path, :access_token_path, :callback)
    class OAuth1TestClass
      include OmniContacts::Authorization::OAuth1
    end
  end

  let(:test_target) do
    OAuth1TestClass.new("consumer_key", "secret1", "auth_host", "auth_token_path", "auth_path", "access_token_path", "callback")
  end

  describe "fetch_authorization_token" do

    it "should request the token providing all mandatory parameters" do
      test_target.should_receive(:https_post) do |host, path, params|
        host.should eq(test_target.auth_host)
        path.should eq(test_target.auth_token_path)
        params[:oauth_consumer_key].should eq(test_target.consumer_key)
        params[:oauth_nonce].should_not be_nil
        params[:oauth_signature_method].should eq("PLAINTEXT")
        params[:oauth_signature].should eq(test_target.consumer_secret + "%26")
        params[:oauth_timestamp].should_not be_nil
        params[:oauth_version].should eq("1.0")
        params[:oauth_callback].should eq(test_target.callback)
        "oauth_token=token&oauth_token_secret=token_secret"
      end
      test_target.fetch_authorization_token
    end

    it "should successfully parse the result" do
      test_target.should_receive(:https_post).and_return("oauth_token=token&oauth_token_secret=token_secret")
      test_target.fetch_authorization_token.should eq(["token", "token_secret"])
    end

    it "should raise an error if request is invalid" do
      test_target.should_receive(:https_post).and_return("invalid_request")
      expect { test_target.fetch_authorization_token }.should raise_error
    end

  end

  describe "authorization_url" do
    subject { test_target.authorization_url("token") }
    it { should eq("https://#{test_target.auth_host}#{test_target.auth_path}?oauth_token=token") }
  end

  describe "fetch_access_token" do
    it "should request the access token using all required parameters" do
      auth_token = "token"
      auth_token_secret = "token_secret"
      auth_verifier = "verifier"
      test_target.should_receive(:https_post) do |host, path, params|
        host.should eq(test_target.auth_host)
        path.should eq(test_target.access_token_path)
        params[:oauth_consumer_key].should eq(test_target.consumer_key)
        params[:oauth_nonce].should_not be_nil
        params[:oauth_signature_method].should eq("PLAINTEXT")
        params[:oauth_version].should eq("1.0")
        params[:oauth_signature].should eq("#{test_target.consumer_secret}%26#{auth_token_secret}")
        params[:oauth_token].should eq(auth_token)
        params[:oauth_verifier].should eq(auth_verifier)
        "oauth_token=access_token&oauth_token_secret=access_token_secret&other_param=other_value"
      end
      test_target.fetch_access_token auth_token, auth_token_secret, auth_verifier, ["other_param"]
    end

    it "should successfully extract access_token and the other fields" do
      test_target.should_receive(:https_post).and_return("oauth_token=access_token&oauth_token_secret=access_token_secret&other_param=other_value")
      test_target.fetch_access_token("token", "token_scret", "verified", ["other_param"]).should eq(["access_token", "access_token_secret", "other_value"])
    end
  end

  describe "oauth_signature" do
    subject { test_target.oauth_signature("GET", "http://social.yahooapis.com/v1/user", {:name => "diego", :surname => "castorina"}, "secret2") }
    it { should eq("ZqWoQISWcuz%2FSDnDxWihtsFDKwc%3D") }
  end
end
