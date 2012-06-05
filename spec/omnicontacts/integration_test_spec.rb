require "spec_helper"
require "omnicontacts/integration_test"

describe IntegrationTest do

  context "mock_initial_request" do
    it "should redirect to the provider's redirect_path" do
      provider = mock
      redirect_path = "/redirect_path"
      provider.stub(:redirect_path => redirect_path)
      IntegrationTest.instance.mock_authorization_from_user(provider)[1]["location"].should eq(redirect_path)
    end
  end
  
  context "mock_callback" do

    before(:each) {
      @env = {}
      @provider = self.mock
      @provider.stub(:class_name => "test")
      IntegrationTest.instance.clear_mocks
    }
    
    it "should return an empty contacts list" do
      IntegrationTest.instance.mock_fetch_contacts(@provider).should be_empty
    end
    
    it "should return a configured list of contacts " do
      contacts = [:name => 'John Doe', :email => 'john@doe.com']
      IntegrationTest.instance.mock('test', contacts)
      result = IntegrationTest.instance.mock_fetch_contacts(@provider)
      result.size.should be(1)
      result.first[:email].should eq(contacts.first[:email])
      result.first[:name].should eq(contacts.first[:name])
    end

    it "should return a single element list of contacts " do
      contact = {:name => 'John Doe', :email => 'john@doe.com'}
      IntegrationTest.instance.mock('test', contact)
      result = IntegrationTest.instance.mock_fetch_contacts(@provider)
      result.size.should be(1)
      result.first[:email].should eq(contact[:email])
      result.first[:name].should eq(contact[:name])
    end
    
    it "should throw an exception" do
      IntegrationTest.instance.mock('test', :some_error)
      expect {IntegrationTest.instance.mock_fetch_contacts(@provider)}.should raise_error
    end
  end
end