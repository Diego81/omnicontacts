require "spec_helper"
require "omnicontacts/importer/hotmail"

describe OmniContacts::Importer::Hotmail do

  let(:hotmail) { OmniContacts::Importer::Hotmail.new({}, "client_id", "client_secret") }

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
         "birth_year":1952
      }
    ]}'
  }

  describe "fetch_contacts_using_access_token" do

    let(:token) { "token" }
    let(:token_type) { "token_type" }

    it "should request the contacts by providing the token in the url" do
      hotmail.should_receive(:https_get) do |host, path, params, headers|
        params[:access_token].should eq(token)
        contacts_as_json
      end
      hotmail.fetch_contacts_using_access_token token, token_type
    end

    it "should correctly parse id, name,email,gender, birthday, profile picture and relation" do
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
    end
  end

end
