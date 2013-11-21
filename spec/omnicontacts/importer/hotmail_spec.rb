require "spec_helper"
require "omnicontacts/importer/hotmail"

describe OmniContacts::Importer::Hotmail do

  let(:permissions) { "perm1, perm2" }
  let(:hotmail) { OmniContacts::Importer::Hotmail.new({}, "client_id", "client_secret", {:permissions => permissions}) }

  let(:self_response) {
    '{
      "id": "4502de12390223d0",
      "name": "Chris Johnson",
      "first_name": "Chris",
      "last_name": "Johnson",
      "birth_day": 21,
      "birth_month": 6,
      "birth_year": 1982,
      "gender": null,
      "emails": {"preferred":"chrisjohnson@gmail.com", "account":"chrisjohn@gmail.com", "personal":null, "business":null}
    }'
  }

  let(:contacts_as_json) {
    '{
   "data": [
       {
         "id": "contact.7fac34bb000000000000000000000000",
         "first_name": "John",
         "last_name": "Smith",
         "name": "John Smith",
         "gender": null,
         "user_id": "123456",
         "is_friend": false,
         "is_favorite": false,
         "birth_day": 5,
         "birth_month": 6,
         "birth_year":1952,
         "email_hashes":["1234567890"]
      }
    ]}'
  }

  describe "fetch_contacts_using_access_token" do

    let(:token) { "token" }
    let(:token_type) { "token_type" }

    before(:each) do
      hotmail.instance_variable_set(:@env, {"HTTP_HOST" => "http://example.com"})
    end

    it "should request the contacts by providing the token in the url" do
      hotmail.should_receive(:https_get) do |host, path, params, headers|
        params[:access_token].should eq(token)
        self_response
      end

      hotmail.should_receive(:https_get) do |host, path, params, headers|
        params[:access_token].should eq(token)
        contacts_as_json
      end
      hotmail.fetch_contacts_using_access_token token, token_type
    end

    it "should set requested permissions in the authorization url" do
      hotmail.authorization_url.should match(/scope=#{Regexp.quote(CGI.escape(permissions))}/)
    end

    it "should correctly parse id, name, email, gender, birthday, profile picture, relation and email hashes" do
      hotmail.should_receive(:https_get).and_return(self_response)
      hotmail.should_receive(:https_get).and_return(contacts_as_json)
      result = hotmail.fetch_contacts_using_access_token token, token_type

      result.size.should be(1)
      result.first[:id].should eq('123456')
      result.first[:first_name].should eq("John")
      result.first[:last_name].should eq('Smith')
      result.first[:name].should eq("John Smith")
      result.first[:email].should be_nil
      result.first[:gender].should be_nil
      result.first[:birthday].should eq({:day=>5, :month=>6, :year=>1952})
      result.first[:profile_picture].should eq('https://apis.live.net/v5.0/123456/picture')
      result.first[:relation].should be_nil
      result.first[:email_hashes].should eq(["1234567890"])
    end

    it "should correctly parse and set logged in user information" do
      hotmail.should_receive(:https_get).and_return(self_response)
      hotmail.should_receive(:https_get).and_return(contacts_as_json)

      hotmail.fetch_contacts_using_access_token token, token_type

      user = hotmail.instance_variable_get(:@env)["omnicontacts.user"]
      user.should_not be_nil
      user[:id].should eq('4502de12390223d0')
      user[:first_name].should eq('Chris')
      user[:last_name].should eq('Johnson')
      user[:name].should eq('Chris Johnson')
      user[:gender].should be_nil
      user[:birthday].should eq({:day=>21, :month=>06, :year=>1982})
      user[:email].should eq('chrisjohn@gmail.com')
      user[:profile_picture].should eq('https://apis.live.net/v5.0/4502de12390223d0/picture')
    end
  end

end
