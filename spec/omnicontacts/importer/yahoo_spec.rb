require "spec_helper"
require "omnicontacts/importer/yahoo"

describe OmniContacts::Importer::Yahoo do

  describe "fetch_contacts_from_token_and_verifier" do
    let(:contacts_as_json) {
      '{
        "contacts": {
          "start":1,
          "count":1,
          "contact":[
            {
              "id":10,
              "fields":[
                {"id":819, "type":"email", "value":"johnny@yahoo.com"},
                {"id":806,"type":"name","value":{"givenName":"John","middleName":"","familyName":"Smith"},"editedBy":"OWNER","categories":[]},
                {"id":33555343,"type":"guid","value":"7ET6MYV2UQ6VR6CBSNMCLFJIVI"},
                {"id":946,"type":"birthday","value":{"day":"22","month":"2","year":"1952"},"editedBy":"OWNER","categories":[]}
              ]
            }
          ]
        }
      }' }

    let(:yahoo) { OmniContacts::Importer::Yahoo.new({}, "consumer_key", "consumer_secret") }

    it "should request the contacts by specifying all required parameters" do
      yahoo.should_receive(:fetch_access_token).and_return(["access_token", "access_token_secret", "guid"])
      yahoo.should_receive(:http_get) do |host, path, params|
        params[:format].should eq("json")
        params[:oauth_consumer_key].should eq("consumer_key")
        params[:oauth_nonce].should_not be_nil
        params[:oauth_signature_method].should eq("HMAC-SHA1")
        params[:oauth_timestamp].should_not be_nil
        params[:oauth_token].should eq("access_token")
        params[:oauth_version].should eq("1.0")
        params[:view].should eq("compact")
        contacts_as_json
      end
      yahoo.fetch_contacts_from_token_and_verifier "auth_token", "auth_token_secret", "oauth_verifier"
    end

    it "should correctly parse id, name,email,gender, birthday, image source and relation" do
      yahoo.should_receive(:fetch_access_token).and_return(["access_token", "access_token_secret", "guid"])
      yahoo.should_receive(:http_get).and_return(contacts_as_json)
      result = yahoo.fetch_contacts_from_token_and_verifier "auth_token", "auth_token_secret", "oauth_verifier"
      result.size.should be(1)
      result.first[:id].should eq('10')
      result.first[:first_name].should eq('John')
      result.first[:last_name].should eq('Smith')
      result.first[:name].should eq("John Smith")
      result.first[:email].should eq("johnny@yahoo.com")
      result.first[:gender].should be_nil
      result.first[:birthday].should eq({:day=>22, :month=>2, :year=>1952})
      result.first[:relation].should be_nil
    end

    it "should return an empty list of contacts" do
      empty_contacts_list = '{"contacts": {"start":0, "count":0}}'
      yahoo.should_receive(:fetch_access_token).and_return(["access_token", "access_token_secret", "guid"])
      yahoo.should_receive(:http_get).and_return(empty_contacts_list)
      result = yahoo.fetch_contacts_from_token_and_verifier "auth_token", "auth_token_secret", "oauth_verifier"
      result.should be_empty
    end

  end
end
