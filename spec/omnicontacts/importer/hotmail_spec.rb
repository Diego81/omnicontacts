require "spec_helper"
require "omnicontacts/importer/hotmail"

describe OmniContacts::Importer::Hotmail do 

  let(:hotmail) {OmniContacts::Importer::Hotmail.new({}, "client_id", "client_secret") }

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
    }"}

    describe "fetch_contacts_from_authorization_code" do 
      
      it "should request the contacts by providing the token in the url" do
        hotmail.should_receive(:access_token_from_code).and_return(["token", "token_type"])
        hotmail.should_receive(:https_get) do |host, path, headers|
          path.should include("access_token=token")
          contacts_as_json
        end
        hotmail.fetch_contacts_from_authorization_code("code")
      end

      it "should correctly parse the contacts" do 
        hotmail.should_receive(:access_token_from_code).and_return(["token", "token_type"])
        hotmail.should_receive(:https_get).and_return(contacts_as_json)
        result = hotmail.fetch_contacts_from_authorization_code("code")
        result.size.should be(1)
        result.first[:name].should be_nil
        result.first[:email].should eq("henrik@hotmail.com")
      end
    end

end
