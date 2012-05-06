require "spec_helper"
require "omnicontacts/importer/hotmail"

describe OmniContacts::Importer::Hotmail do

  let(:hotmail) { OmniContacts::Importer::Hotmail.new({}, "client_id", "client_secret") }

  let(:contacts_as_json) {
    "{
       \"data\":
       [{
       \"id\": \"contact.b4466224b2ca42798c3d4ea90c75aa56\", 
       \"first_name\": null, 
       \"last_name\": null, 
       \"name\": \"henrik@hotmail.com\", 
       \"gender\": null, 
       \"is_friend\": false,
       \"is_favorite\": false,  
       \"user_id\": null, 
       \"birth_day\": 29, 
       \"birth_month\": 3 
       }]
    }" }

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

    it "should correctly parse the contacts" do
      hotmail.should_receive(:https_get).and_return(contacts_as_json)
      result = hotmail.fetch_contacts_using_access_token token, token_type
      result.size.should be(1)
      result.first[:name].should be_nil
      result.first[:email].should eq("henrik@hotmail.com")
    end
  end

end
