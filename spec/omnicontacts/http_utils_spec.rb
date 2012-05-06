require "spec_helper"
require "omnicontacts/http_utils"

describe OmniContacts::HTTPUtils do

  describe "to_query_string" do
    it "should create a query string from a map" do
      OmniContacts::HTTPUtils.to_query_string(:name => "john", :surname => "doe").should eq("name=john&surname=doe")
    end
  end

  describe "encode" do
    it "should encode the space" do
      OmniContacts::HTTPUtils.encode("name=\"john\"").should eq("name%3D%22john%22")
    end
  end

  describe "query_string_to_map" do
    it "should split a query string into a map" do
      query_string = "name=john&surname=doe"
      result = OmniContacts::HTTPUtils.query_string_to_map(query_string)
      result["name"].should eq("john")
      result["surname"].should eq("doe")
    end
  end

  describe "host_url_from_rack_env" do
    it "should calculate the host url using the HTTP_HOST variable" do
      env = {"rack.url_scheme" => "http", "HTTP_HOST" => "localhost:8080", "SERVER_NAME" => "localhost", "SERVER_PORT" => 8080}
      OmniContacts::HTTPUtils.host_url_from_rack_env(env).should eq("http://localhost:8080")
    end

    it "should calculate the host url using SERVER_NAME and SERVER_PORT variables" do
      env = {"rack.url_scheme" => "http", "SERVER_NAME" => "localhost", "SERVER_PORT" => 8080}
      OmniContacts::HTTPUtils.host_url_from_rack_env(env).should eq("http://localhost:8080")
    end
  end

  describe "https_post" do

    before(:each) do
      @connection = double
      Net::HTTP.should_receive(:new).and_return(@connection)
      @connection.should_receive(:use_ssl=).with(true)
      @test_target = Object.new
      @test_target.extend OmniContacts::HTTPUtils
      @response = double
    end

    it "should execute a request with success" do
      @test_target.should_receive(:ssl_ca_file).and_return(nil)
      @connection.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      @connection.should_receive(:request_post).and_return(@response)
      @response.should_receive(:code).and_return("200")
      @response.should_receive(:body).and_return("some content")
      @test_target.send(:https_post, "host", "path", {})
    end

    it "should raise an exception with response code != 200" do
      @test_target.should_receive(:ssl_ca_file).and_return(nil)
      @connection.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      @connection.should_receive(:request_get).and_return(@response)
      @response.should_receive(:code).and_return("500")
      @response.should_receive(:body).and_return("some error message")
      expect { @test_target.send(:https_get, "host", "path", {}) }.should raise_error
    end
  end
end
