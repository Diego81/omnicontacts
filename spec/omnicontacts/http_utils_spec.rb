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
      env = {"rack.url_scheme" => "http", "HTTP_HOST" => "localhost:8080","SERVER_NAME" => "localhost", "SERVER_PORT" => 8080}
      OmniContacts::HTTPUtils.host_url_from_rack_env(env).should eq("http://localhost:8080")
    end

    it "should calculate the host url using SERVER_NAME and SERVER_PORT variables" do
      env = {"rack.url_scheme" => "http", "SERVER_NAME" => "localhost", "SERVER_PORT" => 8080}
      OmniContacts::HTTPUtils.host_url_from_rack_env(env).should eq("http://localhost:8080")
    end
  end
end
