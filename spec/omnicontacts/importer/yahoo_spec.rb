require "spec_helper"
require "omnicontacts/importer/yahoo"

describe OmniContacts::Importer::Yahoo do

  describe "fetch_contacts_from_token_and_verifier" do
    let(:self_response) {
      '{"profile":{
                  "guid":"PCLASP523T3E2R5TFMHDW9KWQQ",
                  "birthdate": "06/21",
                  "emails":[{"handle":"chrisjohnson@gmail.com", "id":10, "primary":true, "type":"HOME"}, {"handle":"xyz@xyz.com", "id":11, "type":"HOME"}],
                  "familyName": "Johnson",
                  "gender":"M",
                  "givenName":"Chris",
                  "image":{"imageUrl":"https://avatars.zenfs.com/users/23T3E2R5TFMHDW-AFE-I7lUpIsGQ==.large.png"}
                }
      }'
    }

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
                {"id":946,"type":"birthday","value":{"day":"22","month":"2","year":"1952"},"editedBy":"OWNER","categories":[]},
                {"id":21, "type":"address", "value":{"street":"1313 Trashview Court\nApt. 13", "city":"Nowheresville", "stateOrProvince":"OK", "postalCode":"66666", "country":"", "countryCode":""}, "editedBy":"OWNER", "flags":["HOME"], "categories":[]}
              ]
            }
          ]
        }
      }' }

    let(:yahoo) { OmniContacts::Importer::Yahoo.new({}, "consumer_key", "consumer_secret") }

    before(:each) do
      yahoo.instance_variable_set(:@env, {})
    end

    it "should request the contacts by specifying all required parameters" do
      yahoo.should_receive(:fetch_access_token).and_return(["access_token", "access_token_secret", "guid"])

      yahoo.should_receive(:https_get) do |host, path, params|
        params[:format].should eq("json")
        params[:oauth_consumer_key].should eq("consumer_key")
        params[:oauth_nonce].should_not be_nil
        params[:oauth_signature_method].should eq("HMAC-SHA1")
        params[:oauth_timestamp].should_not be_nil
        params[:oauth_token].should eq("access_token")
        params[:oauth_version].should eq("1.0")
        self_response
      end

      yahoo.should_receive(:https_get) do |host, path, params|
        params[:format].should eq("json")
        params[:oauth_consumer_key].should eq("consumer_key")
        params[:oauth_nonce].should_not be_nil
        params[:oauth_signature_method].should eq("HMAC-SHA1")
        params[:oauth_timestamp].should_not be_nil
        params[:oauth_token].should eq("access_token")
        params[:oauth_version].should eq("1.0")
        contacts_as_json
      end
      yahoo.fetch_contacts_from_token_and_verifier "auth_token", "auth_token_secret", "oauth_verifier"
    end

    it "should correctly parse id, name,email,gender, birthday, snailmail address, image source and relation for contact and logged in user" do
      yahoo.should_receive(:fetch_access_token).and_return(["access_token", "access_token_secret", "guid"])
      yahoo.should_receive(:https_get).and_return(self_response)
      yahoo.should_receive(:https_get).and_return(contacts_as_json)
      result = yahoo.fetch_contacts_from_token_and_verifier "auth_token", "auth_token_secret", "oauth_verifier"

      result.size.should be(1)
      result.first[:id].should eq('10')
      result.first[:first_name].should eq('John')
      result.first[:last_name].should eq('Smith')
      result.first[:name].should eq("John Smith")
      result.first[:email].should eq("johnny@yahoo.com")
      result.first[:gender].should be_nil
      result.first[:birthday].should eq({:day=>22, :month=>2, :year=>1952})
      result.first[:address_1].should eq('1313 Trashview Court')
      result.first[:address_2].should eq('Apt. 13')
      result.first[:city].should eq('Nowheresville')
      result.first[:region].should eq('OK')
      result.first[:postcode].should eq('66666')
      result.first[:relation].should be_nil
    end

    it "should return an empty list of contacts" do
      empty_contacts_list = '{"contacts": {"start":0, "count":0}}'
      yahoo.should_receive(:fetch_access_token).and_return(["access_token", "access_token_secret", "guid"])
      yahoo.should_receive(:https_get).and_return(self_response)
      yahoo.should_receive(:https_get).and_return(empty_contacts_list)
      result = yahoo.fetch_contacts_from_token_and_verifier "auth_token", "auth_token_secret", "oauth_verifier"

      result.should be_empty
    end

    it "should correctly parse and set logged in user information" do
      yahoo.should_receive(:fetch_access_token).and_return(["access_token", "access_token_secret", "guid"])
      yahoo.should_receive(:https_get).and_return(self_response)
      yahoo.should_receive(:https_get).and_return(contacts_as_json)
      yahoo.fetch_contacts_from_token_and_verifier "auth_token", "auth_token_secret", "oauth_verifier"

      user = yahoo.instance_variable_get(:@env)["omnicontacts.user"]
      user.should_not be_nil
      user[:id].should eq('PCLASP523T3E2R5TFMHDW9KWQQ')
      user[:first_name].should eq('Chris')
      user[:last_name].should eq('Johnson')
      user[:name].should eq('Chris Johnson')
      user[:gender].should eq('male')
      user[:birthday].should eq({:day=>21, :month=>06, :year=>nil})
      user[:email].should eq('chrisjohnson@gmail.com')
      user[:profile_picture].should eq('https://avatars.zenfs.com/users/23T3E2R5TFMHDW-AFE-I7lUpIsGQ==.large.png')
    end

  end
end
