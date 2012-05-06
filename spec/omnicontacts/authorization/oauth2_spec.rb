require "spec_helper"
require "omnicontacts/authorization/oauth2"

describe OmniContacts::Authorization::OAuth2 do

  before(:all) do
    OAuth2TestClass= Struct.new(:auth_host, :authorize_path, :client_id, :client_secret, :scope, :redirect_uri, :auth_token_path)
    class OAuth2TestClass
      include OmniContacts::Authorization::OAuth2
    end
  end

  let(:test_target) do
    OAuth2TestClass.new("auth_host", "authorize_path", "client_id", "client_secret", "scope", "redirect_uri", "auth_token_path")
  end

  describe "authorization_url" do

    subject { test_target.authorization_url }

    it { should include("https://#{test_target.auth_host}#{test_target.authorize_path}") }
    it { should include("client_id=#{test_target.client_id}") }
    it { should include("scope=#{test_target.scope}") }
    it { should include("redirect_uri=#{test_target.redirect_uri}") }
    it { should include("access_type=offline") }
    it { should include("response_type=code") }
  end

  let(:access_token_response) { %[{"access_token": "access_token", "token_type":"token_type", "refresh_token":"refresh_token"}] }

  describe "fetch_access_token" do

    it "should provide all mandatory parameters in a https post request" do
      code = "code"
      test_target.should_receive(:https_post) do |host, path, params|
        host.should eq(test_target.auth_host)
        path.should eq(test_target.auth_token_path)
        params[:code].should eq(code)
        params[:client_id].should eq(test_target.client_id)
        params[:client_secret].should eq(test_target.client_secret)
        params[:redirect_uri].should eq(test_target.redirect_uri)
        params[:grant_type].should eq("authorization_code")
        access_token_response
      end
      test_target.fetch_access_token code
    end

    it "should successfully parse the token from the JSON response" do
      test_target.should_receive(:https_post).and_return(access_token_response)
      (access_token, token_type, refresh_token) = test_target.fetch_access_token "code"
      access_token.should eq("access_token")
      token_type.should eq("token_type")
      refresh_token.should eq("refresh_token")
    end

    it "should raise if the http request fails" do
      test_target.should_receive(:https_post).and_raise("Invalid code")
      expect { test_target.fetch_access_token("code") }.should raise_error
    end

    it "should raise an error if the JSON response contains an error field" do
      test_target.should_receive(:https_post).and_return(%[{"error": "error_message"}])
      expect { test_target.fetch_access_token("code") }.should raise_error
    end
  end

  describe "refresh_access_token" do
    it "should provide all mandatory fields in a https post request" do
      refresh_token = "refresh_token"
      test_target.should_receive(:https_post) do |host, path, params|
        host.should eq(test_target.auth_host)
        path.should eq(test_target.auth_token_path)
        params[:client_id].should eq(test_target.client_id)
        params[:client_secret].should eq(test_target.client_secret)
        params[:refresh_token].should eq(refresh_token)
        params[:grant_type].should eq("refresh_token")
        access_token_response
      end
      test_target.refresh_access_token refresh_token
    end

    it "should successfully parse the token from the JSON response" do
      test_target.should_receive(:https_post).and_return(access_token_response)
      (access_token, token_type, refresh_token) = test_target.refresh_access_token "refresh_token"
      access_token.should eq("access_token")
      token_type.should eq("token_type")
      refresh_token.should eq("refresh_token")
    end

  end

end
